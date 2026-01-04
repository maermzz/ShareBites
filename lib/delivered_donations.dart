import 'package:flutter/material.dart';
import 'native_service.dart';

class DeliveredDonationsPage extends StatelessWidget {
  final String userPhone;
  const DeliveredDonationsPage({super.key, required this.userPhone});

  @override
  Widget build(BuildContext context) {
    final delivered = NativeService().getDeliveredHistory(userPhone);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Delivery History"),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
      ),
      body: delivered.isEmpty
          ? const Center(child: Text("No delivered items yet."))
          : ListView.builder(
        itemCount: delivered.length,
        itemBuilder: (context, index) {
          final item = delivered[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: const Icon(Icons.task_alt, color: Colors.blueGrey),
              title: Text("${item['title']} (${item['weight']} kg)",
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("Completed on: ${item['pickupDate']}"),
              trailing: const Text("DELIVERED",
                  style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold, fontSize: 10)),
            ),
          );
        },
      ),
    );
  }
}