/// Legacy medicine model - kept for backward compatibility
/// New donations should use the Donation model from donation.dart
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

  /// Check if medicine is expiring in 90 days
  bool get isExpiringSoon => expiryDate.difference(DateTime.now()).inDays < 90;

  /// Check if medicine is expired
  bool get isExpired => DateTime.now().isAfter(expiryDate);
}
