class Donation {
  String title;
  String date;     // donation date
  String expiry;   // expiry date
  String status;

  Donation({
    required this.title,
    required this.date,
    this.expiry = "",
    this.status = "Pending",
  });
}
