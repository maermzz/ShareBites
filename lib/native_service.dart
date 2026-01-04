import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'db/app_database.dart';

typedef CreateContextC = Pointer<Void> Function();
typedef AddDonationC = Int32 Function(Pointer<Void>, Pointer<Utf8>, Pointer<Utf8>, Int32, Int32, Int32, Pointer<Utf8>);
typedef ClaimDonationC = Int32 Function(Pointer<Void>, Int32, Pointer<Utf8>, Int32);
typedef MarkDeliveredC = Int32 Function(Pointer<Void>, Int32);
typedef GetListC = Pointer<Utf8> Function(Pointer<Void>, Pointer<Utf8>);
typedef SimpleActionC = Int32 Function(Pointer<Void>);
typedef RegisterReceiverC = Void Function(Pointer<Void>, Pointer<Utf8>);

typedef CreateContextDart = Pointer<Void> Function();
typedef AddDonationDart = int Function(Pointer<Void>, Pointer<Utf8>, Pointer<Utf8>, int, int, int, Pointer<Utf8>);
typedef ClaimDonationDart = int Function(Pointer<Void>, int, Pointer<Utf8>, int);
typedef MarkDeliveredDart = int Function(Pointer<Void>, int);
typedef GetListDart = Pointer<Utf8> Function(Pointer<Void>, Pointer<Utf8>);
typedef SimpleActionDart = int Function(Pointer<Void>);
typedef RegisterReceiverDart = void Function(Pointer<Void>, Pointer<Utf8>);

class NativeService {
  static final NativeService _instance = NativeService._internal();
  factory NativeService() => _instance;

  late DynamicLibrary _lib;
  late Pointer<Void> _context;

  late AddDonationDart _addDonation;
  late ClaimDonationDart _claimDonation;
  late MarkDeliveredDart _markDelivered;
  late GetListDart _getMatches;
  late GetListDart _getHistory;
  late GetListDart _getAccepted;
  late GetListDart _getDelivered;
  late SimpleActionDart _undoLastAction;
  late RegisterReceiverDart _registerReceiver;

  final Map<int, int> _sqlToCpp = {};
  final Map<int, int> _cppToSql = {};

  NativeService._internal() {
    _lib = Platform.isWindows ? DynamicLibrary.open('sharebites_backend.dll') : DynamicLibrary.process();
    _context = _lib.lookupFunction<CreateContextC, CreateContextDart>('create_context')();
    _addDonation = _lib.lookupFunction<AddDonationC, AddDonationDart>('add_donation_validated');
    _claimDonation = _lib.lookupFunction<ClaimDonationC, ClaimDonationDart>('claim_donation');
    _markDelivered = _lib.lookupFunction<MarkDeliveredC, MarkDeliveredDart>('mark_as_delivered');
    _getMatches = _lib.lookupFunction<GetListC, GetListDart>('get_receiver_matches');
    _getHistory = _lib.lookupFunction<GetListC, GetListDart>('get_donor_history');
    _getAccepted = _lib.lookupFunction<GetListC, GetListDart>('get_accepted_donations');
    _getDelivered = _lib.lookupFunction<GetListC, GetListDart>('get_delivered_history');
    _undoLastAction = _lib.lookupFunction<SimpleActionC, SimpleActionDart>('undo_last_action');
    _registerReceiver = _lib.lookupFunction<RegisterReceiverC, RegisterReceiverDart>('register_active_receiver');
  }

  Future<void> syncWithDatabase() async {
    final donations = await AppDatabase.getAllDonations();
    _sqlToCpp.clear();
    _cppToSql.clear();

    for (var d in donations) {
      final nP = (d['name'] ?? "").toString().toNativeUtf8();
      final pP = (d['donorPhone'] ?? "").toString().toNativeUtf8();
      final aP = (d['area'] ?? "").toString().toNativeUtf8();

      int cppId = _addDonation(_context, nP, pP, 0, d['expiryDate'], d['weight'], aP);
      _sqlToCpp[d['id']] = cppId;
      _cppToSql[cppId] = d['id'];

      if (d['status'] >= 1) {
        final rP = (d['receiverPhone'] ?? "").toString().toNativeUtf8();
        _claimDonation(_context, cppId, rP, d['pickupDate'] ?? 0);
        malloc.free(rP);
      }
      if (d['status'] == 2) _markDelivered(_context, cppId);
      malloc.free(nP); malloc.free(pP); malloc.free(aP);
    }
  }

  Future<bool> addDonation(String name, String phone, String expiry, int weight, String area) async {
    int expiryInt = int.parse(expiry.replaceAll('-', ''));
    final nP = name.toNativeUtf8(); final pP = phone.toNativeUtf8(); final aP = area.toNativeUtf8();
    int cppId = _addDonation(_context, nP, pP, 0, expiryInt, weight, aP);
    malloc.free(nP); malloc.free(pP); malloc.free(aP);

    if (cppId > 0) {
      int sqlId = await AppDatabase.saveDonation({
        'name': name, 'donorPhone': phone, 'expiryDate': expiryInt,
        'weight': weight, 'area': area, 'status': 0
      });
      _sqlToCpp[sqlId] = cppId;
      _cppToSql[cppId] = sqlId;
      return true;
    }
    return false;
  }

  bool claimDonation(int sqliteId, String phone, String pickupDate) {
    int? cppId = _sqlToCpp[sqliteId];
    if (cppId == null) return false;
    int dateInt = int.parse(pickupDate.replaceAll('-', ''));
    AppDatabase.updateDonationStatus(sqliteId, 1, receiverPhone: phone, pickupDate: dateInt);
    final pP = phone.toNativeUtf8();
    int res = _claimDonation(_context, cppId, pP, dateInt);
    malloc.free(pP);
    return res == 1;
  }

  bool markAsDelivered(int sqliteId) {
    int? cppId = _sqlToCpp[sqliteId];
    if (cppId == null) return false;
    AppDatabase.updateDonationStatus(sqliteId, 2);
    return _markDelivered(_context, cppId) == 1;
  }

  List<Map<String, dynamic>> getMatchesForArea(String area) {
    final aP = area.toNativeUtf8();
    _registerReceiver(_context, aP);
    final res = _getMatches(_context, aP);
    malloc.free(aP);
    return _parseResult(res.toDartString());
  }

  List<Map<String, dynamic>> getDonorHistory(String phone) {
    final pP = phone.toNativeUtf8();
    final res = _getHistory(_context, pP);
    malloc.free(pP);
    return _parseResult(res.toDartString());
  }

  List<Map<String, dynamic>> getAcceptedDonations(String phone) {
    final pP = phone.toNativeUtf8();
    final res = _getAccepted(_context, pP);
    malloc.free(pP);
    return _parseResult(res.toDartString());
  }

  List<Map<String, dynamic>> getDeliveredHistory(String phone) {
    final pP = phone.toNativeUtf8();
    final res = _getDelivered(_context, pP);
    malloc.free(pP);
    return _parseResult(res.toDartString());
  }

  List<Map<String, dynamic>> _parseResult(String raw) {
    List<Map<String, dynamic>> list = [];
    if (raw.isEmpty) return list;
    for (var item in raw.split(';')) {
      if (item.isEmpty) continue;
      var p = item.split('|');
      if (p.length < 6) continue;
      int cppId = int.tryParse(p[0]) ?? 0;
      int finalId = _cppToSql[cppId] ?? cppId;
      int statusVal = p.length >= 7 ? (int.tryParse(p[5]) ?? 0) : 1;
      list.add({
        "id": finalId,
        "title": p[1],
        "pickupDate": _formatDate(p[2]),
        "expiry": _formatDate(p[3]),
        "area": p[4],
        "status": statusVal == 1 ? "Claimed" : (statusVal == 2 ? "Delivered" : "Pending"),
        "statusCode": statusVal,
        "weight": p.length >= 7 ? p[6] : p[5],
      });
    }
    return list;
  }

  String _formatDate(String iso) {
    if (iso == "0" || iso.length != 8) return "TBD";
    return "${iso.substring(0, 4)}-${iso.substring(4, 6)}-${iso.substring(6, 8)}";
  }
}