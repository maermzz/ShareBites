import 'native_service.dart';

class DonationStore {
  /// Adds a donation to the C++ Master Record.
  /// NativeService now expects 5 parameters: title, phone, expiry, weight, area.
  static void addDonation({
    required String title,
    required String phone,
    required String expiry,
    required int weight, // Added weight parameter
    required String area,
  }) {
    // Pass 5 arguments to match the updated NativeService signature
    NativeService().addDonation(title, phone, expiry, weight, area);
  }

  /// Fetches history for a specific donor from the C++ Backend.
  static List<Map<String, dynamic>> getMyDonations(String phone) {
    return NativeService().getDonorHistory(phone);
  }

  /// Fetches matching donations for a receiver using Dijkstra logic.
  static List<Map<String, dynamic>> getMatches(String area) {
    return NativeService().getMatchesForArea(area);
  }

  /// Marks an item as claimed in the C++ backend.
  /// NativeService now expects 3 parameters: id, receiverPhone, pickupDate.
  static bool claim(int id, String receiverPhone, String pickupDate) {
    return NativeService().claimDonation(id, receiverPhone, pickupDate);
  }
}