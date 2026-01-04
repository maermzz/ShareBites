import 'package:flutter/material.dart';
import 'native_service.dart';

class AcceptedDonationsPage extends StatefulWidget {
  final String userPhone;
  const AcceptedDonationsPage({super.key, required this.userPhone});

  @override
  State<AcceptedDonationsPage> createState() => _AcceptedDonationsPageState();
}

class _AcceptedDonationsPageState extends State<AcceptedDonationsPage> {
  List<Map<String, dynamic>> accepted = [];

  @override
  void initState() {
    super.initState();
    _loadAndSortData();
  }

  void _loadAndSortData() {
    List<Map<String, dynamic>> data = NativeService().getAcceptedDonations(widget.userPhone);
    data.sort((a, b) {
      DateTime dateA = DateTime.tryParse(a['expiry'] ?? "") ?? DateTime(2099);
      DateTime dateB = DateTime.tryParse(b['expiry'] ?? "") ?? DateTime(2099);
      int dateCompare = dateA.compareTo(dateB);
      if (dateCompare != 0) return dateCompare;
      double weightA = double.tryParse(a['weight'].toString()) ?? 0.0;
      double weightB = double.tryParse(b['weight'].toString()) ?? 0.0;
      return weightB.compareTo(weightA);
    });
    setState(() => accepted = data);
  }

  void _markAsDelivered(int id) {
    // 1. INSTANT UI UPDATE (Optimistic)
    // We remove it from the list immediately so the user sees it disappear smoothly
    setState(() {
      accepted.removeWhere((item) => item['id'] == id);
    });

    // 2. BACKEND UPDATE
    // We process the actual delivery in the background
    bool success = NativeService().markAsDelivered(id);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Donation delivered successfully!")),
      );
    } else {
      // If it failed, we reload the data to bring the item back
      _loadAndSortData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: Could not update status.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Accepted Donations"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: accepted.isEmpty
          ? const Center(child: Text("No active claims found."))
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 16, 8),
            child: Text("PRIORITY LIST: Items expiring soonest are at the top.",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: accepted.length,
              itemBuilder: (context, index) {
                final item = accepted[index];
                return Card(
                  key: ValueKey(item['id']), // Helps Flutter track the card for smooth removal
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 2,
                  child: ListTile(
                    title: Text("${item['title']} (${item['weight']} kg)",
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      "Location: ${item['area']}\nPick-up: ${item['pickupDate']}\nExpiry: ${item['expiry']}",
                      style: const TextStyle(height: 1.4),
                    ),
                    isThreeLine: true,
                    trailing: ElevatedButton(
                      onPressed: () => _markAsDelivered(item['id']),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
                      child: const Text("Deliver", style: TextStyle(color: Colors.white, fontSize: 11)),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}