import 'package:flutter/material.dart';
import 'add_donation.dart';
import 'my_donations.dart';
import 'auth_selector.dart';

class Dashboard extends StatefulWidget {
  final String userName, phone, cnic, city, area;
  const Dashboard({super.key, required this.userName, required this.phone, required this.cnic, required this.city, required this.area});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Donor Dashboard")),
      drawer: Drawer(
        child: ListView(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Colors.green),
              accountName: Text(widget.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
              accountEmail: const Text("Thank you for helping others"),
              currentAccountPicture: const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.volunteer_activism, color: Colors.green)),
            ),
            ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: const Text("Add Donation"),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddDonationPage(donorPhone: widget.phone, donorArea: widget.area))),
            ),
            ListTile(
              leading: const Icon(Icons.list_alt),
              title: const Text("My Donations"),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MyDonationsPage(userPhone: widget.phone))),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text("Welcome, ${widget.userName} 👋", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const Text("Your generosity helps feed those in need", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 4,
            child: Column(
              children: [
                _infoTile(Icons.phone, "Phone", widget.phone),
                _infoTile(Icons.badge, "CNIC", widget.cnic),
                _infoTile(Icons.location_city, "City", widget.city),
                _infoTile(Icons.place, "Area", widget.area),
              ],
            ),
          ),
          const SizedBox(height: 30),
          _logoutButton(),
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) => ListTile(
    leading: CircleAvatar(backgroundColor: Colors.green.shade100, child: Icon(icon, color: Colors.green)),
    title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
    subtitle: Text(value),
  );

  Widget _logoutButton() => OutlinedButton.icon(
    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), side: const BorderSide(color: Colors.red)),
    onPressed: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const AuthSelector()), (_) => false),
    icon: const Icon(Icons.logout, color: Colors.red),
    label: const Text("Logout", style: TextStyle(color: Colors.red)),
  );
}