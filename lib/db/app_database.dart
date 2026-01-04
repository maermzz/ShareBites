import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class AppDatabase {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    sqfliteFfiInit();
    final projectDir = Directory.current.path;
    final dbFolder = Directory(join(projectDir, 'db'));
    if (!await dbFolder.exists()) {
      await dbFolder.create(recursive: true);
    }
    final path = join(dbFolder.path, 'app.db');
    return databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: _onCreate,
      ),
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    // User tables for authentication
    await db.execute('''
      CREATE TABLE donators (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        cnic TEXT NOT NULL UNIQUE,
        city TEXT NOT NULL,
        area TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE receivers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        cnic TEXT NOT NULL UNIQUE,
        city TEXT NOT NULL,
        area TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');

    // Donation table for permanent file storage (Required by Template)
    await db.execute('''
      CREATE TABLE donations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        donorPhone TEXT,
        receiverPhone TEXT,
        pickupDate INTEGER,
        expiryDate INTEGER,
        area TEXT,
        weight INTEGER,
        status INTEGER DEFAULT 0
      )
    ''');
  }

  // ================= DONATOR LOGIC =================
  static Future<void> insertDonator({
    required String name,
    required String phone,
    required String cnic,
    required String city,
    required String area,
  }) async {
    final db = await database;
    await db.insert('donators', {
      'name': name,
      'phone': phone,
      'cnic': cnic,
      'city': city,
      'area': area,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  static Future<bool> donatorExists(String cnic) async {
    final db = await database;
    final result = await db.query('donators', where: 'cnic = ?', whereArgs: [cnic], limit: 1);
    return result.isNotEmpty;
  }

  static Future<Map<String, dynamic>?> getDonatorByCnic(String cnic) async {
    final db = await database;
    final result = await db.query('donators', where: 'cnic = ?', whereArgs: [cnic], limit: 1);
    return result.isEmpty ? null : result.first;
  }

  // ================= RECEIVER LOGIC =================
  static Future<void> insertReceiver({
    required String name,
    required String phone,
    required String cnic,
    required String city,
    required String area,
  }) async {
    final db = await database;
    await db.insert('receivers', {
      'name': name,
      'phone': phone,
      'cnic': cnic,
      'city': city,
      'area': area,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  static Future<bool> receiverExists(String cnic) async {
    final db = await database;
    final result = await db.query('receivers', where: 'cnic = ?', whereArgs: [cnic], limit: 1);
    return result.isNotEmpty;
  }

  static Future<Map<String, dynamic>?> getReceiverByCnic(String cnic) async {
    final db = await database;
    final result = await db.query('receivers', where: 'cnic = ?', whereArgs: [cnic], limit: 1);
    return result.isEmpty ? null : result.first;
  }

  // ================= DONATION LOGIC =================
  static Future<int> saveDonation(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert('donations', data);
  }

  static Future<void> updateDonationStatus(int id, int status, {String? receiverPhone, int? pickupDate}) async {
    final db = await database;
    Map<String, dynamic> values = {'status': status};
    if (receiverPhone != null) values['receiverPhone'] = receiverPhone;
    if (pickupDate != null) values['pickupDate'] = pickupDate;
    await db.update('donations', values, where: 'id = ?', whereArgs: [id]);
  }

  static Future<List<Map<String, dynamic>>> getAllDonations() async {
    final db = await database;
    return await db.query('donations', orderBy: 'id ASC');
  }
}