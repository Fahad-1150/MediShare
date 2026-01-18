import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart';

/// Service for managing user authentication and data using Supabase
class UserService {
  final _supabase = Supabase.instance.client;

  UserModel _mapProfileToUser(Map<String, dynamic> p) {
    final roleStr = (p['role'] ?? 'user') as String;
    return UserModel(
      userId: p['id'] as String,
      name: (p['full_name'] ?? '') as String,
      email: (p['email'] ?? '') as String,
      phone: (p['phone'] ?? '') as String,
      role: roleStr == 'admin' ? UserRole.admin : UserRole.user,
      isVerified: (p['is_verified'] ?? false) as bool,
      location: (p['location_url'] ?? '') as String,
      latitude: 0.0,
      longitude: 0.0,
      donatedMedicineIds: const [],
      requestedMedicineIds: const [],
    );
  }

  /// Register a new user (creates auth user and inserts profile)
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

      // Create auth user
      final res = await _supabase.auth.signUp(
        email: normalizedEmail,
        password: password,
      );

      final authUser = res.user;
      if (authUser == null) throw Exception('Failed to create account');

      // Insert profile row (storing plaintext password for legacy compatibility).
      // NOTE: Storing plaintext passwords is insecure — consider hashing or removing this later.
      final profile = {
        'id': authUser.id,
        'full_name': name,
        'email': normalizedEmail,
        'phone': phone,
        'location_url': location,
        'password': password,
      };

      final insertRes = await _supabase
          .from('users_profile')
          .insert(profile)
          .select()
          .single();
      final inserted = Map<String, dynamic>.from(insertRes);

      return _mapProfileToUser(inserted);
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  /// Login user with Supabase auth and fetch profile
  Future<UserModel?> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();

      if (!normalizedEmail.contains('@')) {
        throw Exception('Invalid email format');
      }

      // Use Supabase auth to sign in
      // Attempt to sign in with Supabase auth; if email is unconfirmed, fall back to profile password match
      User? authUser;
      try {
        final res = await _supabase.auth.signInWithPassword(
          email: normalizedEmail,
          password: password,
        );
        authUser = res.user;
      } on AuthApiException catch (e) {
        final msg = e.message.toLowerCase();
        if (msg.contains('email not confirmed') ||
            e.code == 'email_not_confirmed') {
          // we'll try fallback below using profile password
          authUser = null;
        } else {
          throw Exception('Login failed: $e');
        }
      } catch (e) {
        throw Exception('Login failed: $e');
      }

      // Fetch profile by id if auth succeeded, otherwise by email for fallback
      Map<String, dynamic>? profile;
      if (authUser != null) {
        final profileRes = await _supabase
            .from('users_profile')
            .select()
            .eq('id', authUser.id)
            .maybeSingle();
        if (profileRes == null) {
          final byEmail = await _supabase
              .from('users_profile')
              .select()
              .eq('email', normalizedEmail)
              .maybeSingle();
          if (byEmail == null) throw Exception('Profile not found');
          profile = Map<String, dynamic>.from(byEmail);
        } else {
          profile = Map<String, dynamic>.from(profileRes);
        }
      } else {
        // Fallback: use profile password column to authenticate (legacy support)
        final byEmail = await _supabase
            .from('users_profile')
            .select()
            .eq('email', normalizedEmail)
            .maybeSingle();

        // If profile row missing entirely, give helpful guidance
        if (byEmail == null) {
          // Special admin shortcut: allow admin login even if profile missing
          if (normalizedEmail == 'nfahad066@gmail.com' &&
              password == '12345678') {
            profile = {
              'id': 'ADMIN_TEMP',
              'full_name': 'Admin User',
              'email': normalizedEmail,
              'phone': '',
              'location_url': '',
              'role': 'admin',
              'is_verified': true,
            };
          } else {
            throw Exception(
              'Invalid credentials or profile not found. If your email is unconfirmed, confirm it in Supabase or run the DB migration to add the password column.',
            );
          }
        } else {
          final p = Map<String, dynamic>.from(byEmail);
          final storedPassword = p['password'] as String?;
          if (storedPassword == null || storedPassword != password) {
            // If password column is missing, instruct to run migration
            if (storedPassword == null) {
              throw Exception(
                'Login failed: no password stored in profile. Run the provided SQL migration to add the password column, or confirm your email.',
              );
            }
            throw Exception('Invalid credentials');
          }
          profile = p;
        }
      }

      // Special admin override based on credentials
      if (normalizedEmail == 'nfahad066@gmail.com' && password == '12345678') {
        profile['role'] = 'admin';
        // persist role change (best-effort) — ignore failures if DB lacks 'role' column
        try {
          await _supabase
              .from('users_profile')
              .update({'role': 'admin'})
              .eq('id', profile['id']);
        } catch (_) {
          // ignore DB errors (e.g., missing column) — role will be treated as admin in-memory
        }
      }

      return _mapProfileToUser(profile);
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  /// Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      final res = await _supabase
          .from('users_profile')
          .select()
          .eq('id', userId)
          .maybeSingle();
      if (res == null) return null;
      return _mapProfileToUser(Map<String, dynamic>.from(res));
    } catch (e) {
      return null;
    }
  }

  /// Get user by email
  Future<UserModel?> getUserByEmail(String email) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();
      final res = await _supabase
          .from('users_profile')
          .select()
          .eq('email', normalizedEmail)
          .maybeSingle();
      if (res == null) return null;
      return _mapProfileToUser(Map<String, dynamic>.from(res));
    } catch (e) {
      return null;
    }
  }

  /// Update user
  Future<UserModel> updateUser(UserModel user) async {
    try {
      final payload = {
        'full_name': user.name,
        'email': user.email,
        'phone': user.phone,
        'location_url': user.location,
        'role': user.role == UserRole.admin ? 'admin' : 'user',
        'is_verified': user.isVerified,
      };
      final res = await _supabase
          .from('users_profile')
          .update(payload)
          .eq('id', user.userId)
          .select()
          .single();
      return _mapProfileToUser(Map<String, dynamic>.from(res));
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
    final res = await _supabase
        .from('users_profile')
        .select()
        .order('created_at');

    return List<Map<String, dynamic>>.from(
      res as List,
    ).map(_mapProfileToUser).toList();
  }

  /// Get all admins
  Future<List<UserModel>> getAllAdmins() async {
    final res = await _supabase
        .from('users_profile')
        .select()
        .eq('role', 'admin');

    return List<Map<String, dynamic>>.from(
      res as List,
    ).map(_mapProfileToUser).toList();
  }

  /// Make user admin
  Future<void> makeAdmin(String userId) async {
    try {
      await _supabase
          .from('users_profile')
          .update({'role': 'admin'})
          .eq('id', userId);
    } catch (e) {
      throw Exception('Failed to make user admin: $e');
    }
  }

  /// Verify user
  Future<void> verifyUser(String userId) async {
    try {
      await _supabase
          .from('users_profile')
          .update({'is_verified': true})
          .eq('id', userId);
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

  /// Delete a user (admin only)
  Future<void> deleteUser(String userId) async {
    try {
      await _supabase.from('users_profile').delete().eq('id', userId);
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }
}
