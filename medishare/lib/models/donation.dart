/// Donation status in the system
enum DonationStatus { pending, approved, claimed, expired, rejected }

/// Donation model - represents a medicine donation
class Donation {
  final String donationId;
  final String donorId; // User who donated
  final String medicineName;
  final String medicineType; // Tablet, Capsule, Injection, etc.
  final int quantity;
  final DateTime expiryDate;
  final String donorLocation;
  final double latitude;
  final double longitude;
  final String? photoUrl;
  final DonationStatus status;
  final String? claimedByUserId; // Who claimed it
  final DateTime createdAt;
  final DateTime? approvedAt;
  final DateTime? claimedAt;
  final String? adminNotes;
  final String? description;

  Donation({
    required this.donationId,
    required this.donorId,
    required this.medicineName,
    required this.medicineType,
    required this.quantity,
    required this.expiryDate,
    required this.donorLocation,
    required this.latitude,
    required this.longitude,
    this.photoUrl,
    this.status = DonationStatus.pending,
    this.claimedByUserId,
    DateTime? createdAt,
    this.approvedAt,
    this.claimedAt,
    this.adminNotes,
    this.description,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Check if donation is expiring in 7 days
  bool get isExpiringsoon {
    final daysUntilExpiry = expiryDate.difference(DateTime.now()).inDays;
    return daysUntilExpiry <= 7 && daysUntilExpiry > 0;
  }

  /// Check if donation is expired
  bool get isExpired => DateTime.now().isAfter(expiryDate);

  /// Copy with modifications
  Donation copyWith({
    String? donationId,
    String? donorId,
    String? medicineName,
    String? medicineType,
    int? quantity,
    DateTime? expiryDate,
    String? donorLocation,
    double? latitude,
    double? longitude,
    String? photoUrl,
    DonationStatus? status,
    String? claimedByUserId,
    DateTime? createdAt,
    DateTime? approvedAt,
    DateTime? claimedAt,
    String? adminNotes,
    String? description,
  }) {
    return Donation(
      donationId: donationId ?? this.donationId,
      donorId: donorId ?? this.donorId,
      medicineName: medicineName ?? this.medicineName,
      medicineType: medicineType ?? this.medicineType,
      quantity: quantity ?? this.quantity,
      expiryDate: expiryDate ?? this.expiryDate,
      donorLocation: donorLocation ?? this.donorLocation,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      photoUrl: photoUrl ?? this.photoUrl,
      status: status ?? this.status,
      claimedByUserId: claimedByUserId ?? this.claimedByUserId,
      createdAt: createdAt ?? this.createdAt,
      approvedAt: approvedAt ?? this.approvedAt,
      claimedAt: claimedAt ?? this.claimedAt,
      adminNotes: adminNotes ?? this.adminNotes,
      description: description ?? this.description,
    );
  }
}
