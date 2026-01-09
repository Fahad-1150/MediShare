import '../models/user.dart';

/// Service for managing user authentication and data
class UserService {
  // Mock data storage
  static final List<UserModel> _users = _initializeMockUsers();

  // Password storage for mock auth (in production, use proper password hashing)
  static final Map<String, String> _passwords = {
    'nfahad066@gmail.com': '12345678',
    'fahad@gmail.com': '11111111',
    'jane@example.com': '12345678',
    'ahmed@example.com': '12345678',
  };

  /// Initialize with mock users
  static List<UserModel> _initializeMockUsers() {
    return [
      UserModel(
        userId: 'ADMIN_001',
        name: 'Admin User',
        email: 'nfahad066@gmail.com',
        phone: '+8801234567890',
        role: UserRole.admin,
        isVerified: true,
        location: 'Dhaka',
        latitude: 23.8103,
        longitude: 90.4125,
      ),
      UserModel(
        userId: 'USER_001',
        name: 'Fahad',
        email: 'fahad@gmail.com.com',
        phone: '+8801700000001',
        role: UserRole.user,
        isVerified: true,
        location: 'Dhaka',
        latitude: 23.8110,
        longitude: 90.4120,
      ),
      UserModel(
        userId: 'USER_002',
        name: 'Jane Smith',
        email: 'jane@example.com',
        phone: '+8801700000002',
        role: UserRole.user,
        isVerified: true,
        location: 'Chittagong',
        latitude: 22.3569,
        longitude: 91.7832,
      ),
      UserModel(
        userId: 'USER_003',
        name: 'Ahmed Khan',
        email: 'ahmed@example.com',
        phone: '+8801700000003',
        role: UserRole.user,
        isVerified: true,
        location: 'Sylhet',
        latitude: 24.8949,
        longitude: 91.8687,
      ),
    ];
  }

  /// Register a new user
  Future<UserModel> registerUser({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String location,
    double latitude = 0.0,
    double longitude = 0.0,
  }) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();
      // Check if user already exists
      final exists = _users.any(
        (u) => u.email.toLowerCase() == normalizedEmail,
      );
      if (exists) {
        throw Exception('User with this email already exists');
      }

      final userId = 'USER_${DateTime.now().millisecondsSinceEpoch}';

      final user = UserModel(
        userId: userId,
        name: name,
        email: normalizedEmail,
        phone: phone,
        role: UserRole.user,
        isVerified: false,
        location: location,
        latitude: latitude,
        longitude: longitude,
      );

      _users.add(user);
      _passwords[normalizedEmail] = password; // Store password for this user
      return user;
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  /// Login user with password validation
  Future<UserModel?> loginUser({
    required String email,
    required String password,
  }) async {
    // Normalize and validate email
    final normalizedEmail = email.trim().toLowerCase();
    if (!normalizedEmail.contains('@')) {
      throw Exception('Invalid email format');
    }

    // Check if password matches
    final storedPassword = _passwords[normalizedEmail];
    if (storedPassword == null || storedPassword != password) {
      throw Exception('Invalid credentials');
    }

    // Find and return user
    final user = _users.firstWhere(
      (u) => u.email.toLowerCase() == normalizedEmail,
      orElse: () => throw Exception('User not found'),
    );

    return user;
  }

  /// Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      return _users.firstWhere((u) => u.userId == userId);
    } catch (e) {
      return null;
    }
  }

  /// Get user by email
  Future<UserModel?> getUserByEmail(String email) async {
    try {
      return _users.firstWhere((u) => u.email == email);
    } catch (e) {
      return null;
    }
  }

  /// Update user
  Future<UserModel> updateUser(UserModel user) async {
    try {
      final index = _users.indexWhere((u) => u.userId == user.userId);
      if (index != -1) {
        _users[index] = user;
        return user;
      }
      throw Exception('User not found');
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  /// Update user location
  Future<void> updateUserLocation(
    String userId,
    String location,
    double latitude,
    double longitude,
  ) async {
    try {
      final user = await getUserById(userId);
      if (user != null) {
        final updated = user.copyWith(
          location: location,
          latitude: latitude,
          longitude: longitude,
        );
        await updateUser(updated);
      }
    } catch (e) {
      throw Exception('Failed to update location: $e');
    }
  }

  /// Get all users
  Future<List<UserModel>> getAllUsers() async {
    return _users;
  }

  /// Get all admins
  Future<List<UserModel>> getAllAdmins() async {
    return _users.where((u) => u.role == UserRole.admin).toList();
  }

  /// Make user admin
  Future<void> makeAdmin(String userId) async {
    try {
      final user = await getUserById(userId);
      if (user != null) {
        final updated = user.copyWith(role: UserRole.admin);
        await updateUser(updated);
      }
    } catch (e) {
      throw Exception('Failed to make user admin: $e');
    }
  }

  /// Verify user
  Future<void> verifyUser(String userId) async {
    try {
      final user = await getUserById(userId);
      if (user != null) {
        final updated = user.copyWith(isVerified: true);
        await updateUser(updated);
      }
    } catch (e) {
      throw Exception('Failed to verify user: $e');
    }
  }

  /// Add donation to user's list
  Future<void> addDonation(String userId, String donationId) async {
    try {
      final user = await getUserById(userId);
      if (user != null) {
        final updated = user.copyWith(
          donatedMedicineIds: [...user.donatedMedicineIds, donationId],
        );
        await updateUser(updated);
      }
    } catch (e) {
      throw Exception('Failed to add donation: $e');
    }
  }

  /// Add request to user's list
  Future<void> addRequest(String userId, String requestId) async {
    try {
      final user = await getUserById(userId);
      if (user != null) {
        final updated = user.copyWith(
          requestedMedicineIds: [...user.requestedMedicineIds, requestId],
        );
        await updateUser(updated);
      }
    } catch (e) {
      throw Exception('Failed to add request: $e');
    }
  }
}
