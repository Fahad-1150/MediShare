/// Request status
enum RequestStatus {
  pending,
  approved,
  fulfilled,
  rejected,
  cancelled,
  received,
}

/// Medicine Request model - represents a user's request for medicine
class MedicineRequest {
  final String requestId;
  final String requesterId; // User requesting
  final String?
  donorId; // Donor this request is for (when requesting specific donation)
  final String medicineName;
  final String medicineType;
  final int quantity;
  final String requesterLocation;
  final double latitude;
  final double longitude;
  final RequestStatus status;
  final String? assignedDonationId; // Which donation fulfilled this
  final DateTime createdAt;
  final DateTime? fulfilledAt;
  final String? reason; // Why they need it
  final String? adminNotes;

  MedicineRequest({
    required this.requestId,
    required this.requesterId,
    this.donorId,
    required this.medicineName,
    required this.medicineType,
    required this.quantity,
    required this.requesterLocation,
    required this.latitude,
    required this.longitude,
    this.status = RequestStatus.pending,
    this.assignedDonationId,
    DateTime? createdAt,
    this.fulfilledAt,
    this.reason,
    this.adminNotes,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Copy with modifications
  MedicineRequest copyWith({
    String? requestId,
    String? requesterId,
    String? donorId,
    String? medicineName,
    String? medicineType,
    int? quantity,
    String? requesterLocation,
    double? latitude,
    double? longitude,
    RequestStatus? status,
    String? assignedDonationId,
    DateTime? createdAt,
    DateTime? fulfilledAt,
    String? reason,
    String? adminNotes,
  }) {
    return MedicineRequest(
      requestId: requestId ?? this.requestId,
      requesterId: requesterId ?? this.requesterId,
      donorId: donorId ?? this.donorId,
      medicineName: medicineName ?? this.medicineName,
      medicineType: medicineType ?? this.medicineType,
      quantity: quantity ?? this.quantity,
      requesterLocation: requesterLocation ?? this.requesterLocation,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      status: status ?? this.status,
      assignedDonationId: assignedDonationId ?? this.assignedDonationId,
      createdAt: createdAt ?? this.createdAt,
      fulfilledAt: fulfilledAt ?? this.fulfilledAt,
      reason: reason ?? this.reason,
      adminNotes: adminNotes ?? this.adminNotes,
    );
  }
}
