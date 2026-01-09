/// User roles in the system
enum UserRole { user, admin }

/// User model - single role that can both donate and request medicine
class UserModel {
  final String userId;
  final String name;
  final String email;
  final String phone;
  final UserRole role; // 'user' or 'admin'
  final bool isVerified;
  final String location; // For location-based filtering
  final double latitude;
  final double longitude;
  final List<String> donatedMedicineIds; // Track user's donations
  final List<String> requestedMedicineIds; // Track user's requests
  final DateTime createdAt;

  UserModel({
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.isVerified = false,
    this.location = '',
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.donatedMedicineIds = const [],
    this.requestedMedicineIds = const [],
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Create a copy with modifications
  UserModel copyWith({
    String? userId,
    String? name,
    String? email,
    String? phone,
    UserRole? role,
    bool? isVerified,
    String? location,
    double? latitude,
    double? longitude,
    List<String>? donatedMedicineIds,
    List<String>? requestedMedicineIds,
    DateTime? createdAt,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      isVerified: isVerified ?? this.isVerified,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      donatedMedicineIds: donatedMedicineIds ?? this.donatedMedicineIds,
      requestedMedicineIds: requestedMedicineIds ?? this.requestedMedicineIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
