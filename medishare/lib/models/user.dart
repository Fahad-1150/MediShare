enum UserRole { donor, receiver }

class UserModel {
  final String userId;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final bool isVerified;

  UserModel({
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.isVerified,
  });
}
