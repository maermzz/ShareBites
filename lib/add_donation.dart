import 'package:flutter/material.dart';
import 'native_service.dart';

class AddDonationPage extends StatefulWidget {
  final String donorPhone;
  final String donorArea;

  const AddDonationPage({super.key, required this.donorPhone, required this.donorArea});

  @override
  State<AddDonationPage> createState() => _AddDonationPageState();
}

class _AddDonationPageState extends State<AddDonationPage> {
  String groceryType = "Rice";
  double weightKg = 5;
  DateTime? expiryDate;

  String _formatDate(DateTime d) =>
      "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

  // FIX 1: Added 'async' to the function signature
  void submitDonation() async {
    if (expiryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select an expiry date")));
      return;
    }

    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final tomorrowAtMidnight = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);

    if (expiryDate!.isBefore(tomorrowAtMidnight)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: Minimum expiry must be at least 1 day from now.")),
      );
      return;
    }

    try {
      // Show a loading indicator if needed

      // FIX 2: Added 'await' before NativeService().addDonation
      bool success = await NativeService().addDonation(
        groceryType,
        widget.donorPhone,
        _formatDate(expiryDate!),
        weightKg.toInt(),
        widget.donorArea,
      );

      if (success) {
        if (!mounted) return; // Best practice for async calls in State
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Donation posted!")));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to add donation logic error.")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Post a Donation")),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text("Location: ${widget.donorArea}",
              style: const TextStyle(fontSize: 16, color: Colors.green, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            value: groceryType,
            decoration: const InputDecoration(labelText: "Item Category", border: OutlineInputBorder()),
            items: ["Rice", "Wheat", "Sugar", "Flour", "Oil"]
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (v) => setState(() => groceryType = v!),
          ),
          const SizedBox(height: 24),
          Text("Weight: ${weightKg.toInt()} kg"),
          Slider(
              value: weightKg,
              min: 1,
              max: 50,
              divisions: 49,
              onChanged: (v) => setState(() => weightKg = v)
          ),
          const SizedBox(height: 20),
          ListTile(
            tileColor: Colors.grey.shade100,
            title: Text("Expiry Date: ${expiryDate == null ? 'Select Date' : _formatDate(expiryDate!)}"),
            subtitle: const Text("Must be at least tomorrow."),
            trailing: const Icon(Icons.event_note),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now().add(const Duration(days: 1)),
                firstDate: DateTime.now().add(const Duration(days: 1)),
                lastDate: DateTime(2030),
              );
              if (picked != null) setState(() => expiryDate = picked);
            },
          ),
          const SizedBox(height: 40),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: submitDonation,
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white
              ),
              child: const Text("Add Donation", style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}