import 'package:flutter/material.dart';
import 'dashboard.dart';
import 'receiver_dashboard.dart';
import 'db/app_database.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final phone = TextEditingController();
  final cnic = TextEditingController();

  bool _validPhone(String v) => RegExp(r'^03[0-9]{9}$').hasMatch(v);
  bool _validCNIC(String v) => RegExp(r'^[0-9]{13}$').hasMatch(v);

  void _showError(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _login() async {
    if (phone.text.isEmpty || cnic.text.isEmpty) {
      _showError("All fields are required");
      return;
    }

    if (!_validPhone(phone.text)) {
      _showError("Phone number must start with 03 and be 11 digits");
      return;
    }

    if (!_validCNIC(cnic.text)) {
      _showError("CNIC must be exactly 13 digits");
      return;
    }

    try {
      // Check Donator table first
      final donator = await AppDatabase.getDonatorByCnic(cnic.text);
      if (donator != null) {
        if (donator['phone'] != phone.text) {
          _showError("Phone number does not match donor record");
          return;
        }

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => Dashboard(
              userName: donator['name'],
              phone: donator['phone'],
              cnic: donator['cnic'],
              city: donator['city'],
              area: donator['area'],
            ),
          ),
        );
        return;
      }

      // Check Receiver table
      final receiver = await AppDatabase.getReceiverByCnic(cnic.text);
      if (receiver != null) {
        if (receiver['phone'] != phone.text) {
          _showError("Phone number does not match receiver record");
          return;
        }

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ReceiverDashboard(
              userName: receiver['name'],
              phone: receiver['phone'],
              cnic: receiver['cnic'],
              city: receiver['city'],
              area: receiver['area'],
            ),
          ),
        );
        return;
      }

      _showError("No account found. Please sign up first.");
    } catch (e) {
      _showError("Login failed. Please try again.");
      print("LOGIN ERROR: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            "Welcome Back 👋",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            "Login to continue donating or receiving food",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
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
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: _login,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text(
              "Login",
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
