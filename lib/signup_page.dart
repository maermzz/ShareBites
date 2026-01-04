import 'package:flutter/material.dart';
import 'dashboard.dart';
import 'db/app_database.dart';

class DonatorSignUpPage extends StatefulWidget {
  const DonatorSignUpPage({super.key});

  @override
  State<DonatorSignUpPage> createState() => _DonatorSignUpPageState();
}

class _DonatorSignUpPageState extends State<DonatorSignUpPage> {
  final name = TextEditingController();
  final phone = TextEditingController();
  final cnic = TextEditingController();

  String city = "Islamabad";
  String area = "F-10";

  // ---------------- VALIDATION ----------------
  bool _validName(String v) => RegExp(r'^[a-zA-Z ]+$').hasMatch(v);
  bool _validPhone(String v) => RegExp(r'^03[0-9]{9}$').hasMatch(v);
  bool _validCNIC(String v) => RegExp(r'^[0-9]{13}$').hasMatch(v);

  // ---------------- SHOW SNACKBAR ----------------
  void _showError(String msg) {
    FocusScope.of(context).unfocus(); // hide keyboard
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    });
  }

  // ---------------- SUBMIT ----------------
  Future<void> _submit() async {
    if (name.text.isEmpty || phone.text.isEmpty || cnic.text.isEmpty) {
      _showError("All fields are required");
      return;
    }
    if (!_validName(name.text)) {
      _showError("Name can only contain letters");
      return;
    }
    if (!_validPhone(phone.text)) {
      _showError("Phone must be 11 digits and start with 03");
      return;
    }
    if (!_validCNIC(cnic.text)) {
      _showError("CNIC must be exactly 13 digits");
      return;
    }

    try {
      final exists = await AppDatabase.donatorExists(cnic.text);
      if (exists) {
        _showError("This CNIC is already registered as a donor");
        return;
      }

      await AppDatabase.insertDonator(
        name: name.text,
        phone: phone.text,
        cnic: cnic.text,
        city: city,
        area: area,
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => Dashboard(
            userName: name.text,
            phone: phone.text,
            cnic: cnic.text,
            city: city,
            area: area,
          ),
        ),
      );
    } catch (e) {
      _showError("Something went wrong. Please try again.");
    }
  }

  // ---------------- BUILD UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Donor Registration")),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            "Become a Food Donor 🍲",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: name,
            decoration: const InputDecoration(
              labelText: "Full Name",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: "Phone Number",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: cnic,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: "CNIC",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField(
            value: city,
            decoration: const InputDecoration(
              labelText: "City",
              border: OutlineInputBorder(),
            ),
            items: ["Islamabad", "Rawalpindi", "Lahore"]
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) => setState(() {
              city = v.toString();
              area = "F-10"; // reset area when city changes
            }),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField(
            value: area,
            decoration: const InputDecoration(
              labelText: "Area",
              border: OutlineInputBorder(),
            ),
            items: ["E-10", "E-11", "F-10", "F-11", "G-10", "G-11", "H-12", "Blue Area"]
                .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                .toList(),
            onChanged: (v) => setState(() => area = v.toString()),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text(
              "Create Donor Account",
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
