import 'package:flutter/material.dart';
import 'accepted_donations.dart';
import 'delivered_donations.dart';
import 'auth_selector.dart';
import 'native_service.dart';

class ReceiverDashboard extends StatefulWidget {
  final String userName, phone, cnic, city, area;
  const ReceiverDashboard({super.key, required this.userName, required this.phone, required this.cnic, required this.city, required this.area});

  @override
  State<ReceiverDashboard> createState() => _ReceiverDashboardState();
}

class _ReceiverDashboardState extends State<ReceiverDashboard> {
  List<Map<String, dynamic>> availableDonations = [];

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  void _loadMatches() {
    List<Map<String, dynamic>> matches = NativeService().getMatchesForArea(widget.area);

    // Sort logic: Expiry first (soonest), then Weight (heaviest)
    matches.sort((a, b) {
      DateTime dateA = DateTime.tryParse(a['expiry'] ?? "") ?? DateTime(2099);
      DateTime dateB = DateTime.tryParse(b['expiry'] ?? "") ?? DateTime(2099);
      int dateCompare = dateA.compareTo(dateB);
      if (dateCompare != 0) return dateCompare;

      double weightA = double.tryParse(a['weight'].toString()) ?? 0.0;
      double weightB = double.tryParse(b['weight'].toString()) ?? 0.0;
      return weightB.compareTo(weightA);
    });

    setState(() => availableDonations = matches);
  }

  Future<void> _claim(Map<String, dynamic> item) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      helpText: "Select your Pick-up Date",
    );

    if (pickedDate == null) return;

    DateTime expiry = DateTime.parse(item['expiry']);
    if (pickedDate.isAfter(expiry)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: Pick-up date cannot be after expiry date!")),
      );
      return;
    }

    String dateStr = "${pickedDate.year}${pickedDate.month.toString().padLeft(2, '0')}${pickedDate.day.toString().padLeft(2, '0')}";

    if (NativeService().claimDonation(item['id'], widget.phone, dateStr)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Donation claimed!")));
      _loadMatches();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Receiver Dashboard"), backgroundColor: Colors.green, foregroundColor: Colors.white),
      drawer: _buildDrawer(),
      body: Column(
        children: [
          ListTile(
            title: Text("Welcome, ${widget.userName} 🤍", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            subtitle: Text("Available in ${widget.area}"),
          ),
          Expanded(
            child: availableDonations.isEmpty
                ? const Center(child: Text("No donations available nearby."))
                : ListView.builder(
              itemCount: availableDonations.length,
              itemBuilder: (context, index) {
                final d = availableDonations[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text("${d['title']} (${d['weight']} kg)", style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("Expires: ${d['expiry']} \nArea: ${d['area']}"),
                    trailing: ElevatedButton(
                      onPressed: () => _claim(d),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      child: const Text("Claim", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                );
              },
            ),
          ),
          _logoutButton(),
        ],
      ),
    );
  }

  Widget _buildDrawer() => Drawer(
    child: ListView(
      children: [
        UserAccountsDrawerHeader(
          decoration: const BoxDecoration(color: Colors.green),
          accountName: Text(widget.userName),
          accountEmail: const Text("Receiver Profile"),
          currentAccountPicture: const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.person, color: Colors.green)),
        ),
        ListTile(
          leading: const Icon(Icons.check_circle),
          title: const Text("Accepted Donations"),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AcceptedDonationsPage(userPhone: widget.phone))),
        ),
        ListTile(
          leading: const Icon(Icons.history),
          title: const Text("Delivery History"),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DeliveredDonationsPage(userPhone: widget.phone))),
        ),
      ],
    ),
  );

  Widget _logoutButton() => Padding(
    padding: const EdgeInsets.all(20),
    child: OutlinedButton.icon(
      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50), side: const BorderSide(color: Colors.red)),
      onPressed: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const AuthSelector()), (_) => false),
      icon: const Icon(Icons.logout, color: Colors.red),
      label: const Text("Logout", style: TextStyle(color: Colors.red)),
    ),
  );
}