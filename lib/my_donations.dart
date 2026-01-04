import 'package:flutter/material.dart';
import 'native_service.dart';

class MyDonationsPage extends StatefulWidget {
  final String userPhone;
  const MyDonationsPage({super.key, required this.userPhone});

  @override
  State<MyDonationsPage> createState() => _MyDonationsPageState();
}

class _MyDonationsPageState extends State<MyDonationsPage> {
  List<Map<String, dynamic>> history = [];
  double totalKgDonated = 0.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final data = NativeService().getDonorHistory(widget.userPhone);
    double weightSum = 0.0;

    for (var item in data) {
      if (item['statusCode'] == 1 || item['statusCode'] == 2) {
        weightSum += double.tryParse(item['weight'].toString()) ?? 0.0;
      }
    }

    setState(() {
      history = data;
      totalKgDonated = weightSum;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Donations")),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Column(
              children: [
                const Text("Your Impact Report", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                Text("${totalKgDonated.toStringAsFixed(1)} kg",
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green)),
                const Text("Total weight successfully claimed", style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
          Expanded(
            child: history.isEmpty
                ? const Center(child: Text("No donations posted yet."))
                : ListView.builder(
              itemCount: history.length,
              itemBuilder: (context, index) {
                final item = history[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text("${item['title']} (${item['weight']} kg)",
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                        "Expiry: ${item['expiry']}${item['statusCode'] > 0 ? '\nPick-up: ${item['pickupDate']}' : ''}"),
                    trailing: Chip(
                      label: Text(item['status']),
                      backgroundColor: _getStatusColor(item['statusCode']),
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

  Color _getStatusColor(int statusCode) {
    if (statusCode == 1) return Colors.green.shade100;
    if (statusCode == 2) return Colors.blue.shade100;
    return Colors.orange.shade100;
  }
}