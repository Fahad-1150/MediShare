class Medicine {
  final String name;
  final String type;
  final int quantity;
  final DateTime expiryDate;
  final String location;
  final String photoUrl;

  Medicine({
    required this.name,
    required this.type,
    required this.quantity,
    required this.expiryDate,
    required this.location,
    required this.photoUrl,
  });
}
