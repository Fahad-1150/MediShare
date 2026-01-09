import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/user_service.dart';
import '../models/notification.dart' as notif_model;
import '../services/notification_service.dart';

/// Global authentication and app state management
class AuthState extends ChangeNotifier {
  UserModel? user;
  final UserService _userService = UserService();
  final NotificationService _notificationService = NotificationService();

  bool isLoading = false;
  String? errorMessage;
  int unreadNotificationCount = 0;
  List<notif_model.Notification> notifications = [];

  /// Login user
  Future<bool> login({required String email, required String password}) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      final loginUser = await _userService.loginUser(
        email: email,
        password: password,
      );

      if (loginUser != null) {
        user = loginUser;
        await _loadNotifications();
        isLoading = false;
        notifyListeners();
        return true;
      }

      errorMessage = 'Login failed. Please check your credentials.';
      isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      errorMessage = e.toString();
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Register user
  Future<bool> register({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String location,
    double latitude = 0.0,
    double longitude = 0.0,
  }) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      final newUser = await _userService.registerUser(
        email: email,
        password: password,
        name: name,
        phone: phone,
        location: location,
        latitude: latitude,
        longitude: longitude,
      );

      user = newUser;
      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = e.toString();
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Logout user
  void logout() {
    user = null;
    notifications = [];
    unreadNotificationCount = 0;
    errorMessage = null;
    notifyListeners();
  }

  /// Check if logged in
  bool get isLoggedIn => user != null;

  /// Check if user is admin
  bool get isAdmin => user?.role == UserRole.admin;

  /// Load user notifications
  Future<void> _loadNotifications() async {
    if (user == null) return;

    try {
      notifications = await _notificationService.getUserNotifications(
        user!.userId,
      );
      unreadNotificationCount = await _notificationService.getUnreadCount(
        user!.userId,
      );
      notifyListeners();
    } catch (e) {
      errorMessage = 'Failed to load notifications: $e';
      notifyListeners();
    }
  }

  /// Refresh notifications
  Future<void> refreshNotifications() async {
    await _loadNotifications();
  }

  /// Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _notificationService.markAsRead(notificationId);
      await _loadNotifications();
    } catch (e) {
      errorMessage = 'Failed to mark notification as read: $e';
      notifyListeners();
    }
  }

  /// Mark all notifications as read
  Future<void> markAllNotificationsAsRead() async {
    if (user == null) return;

    try {
      await _notificationService.markAllAsRead(user!.userId);
      await _loadNotifications();
    } catch (e) {
      errorMessage = 'Failed to mark all as read: $e';
      notifyListeners();
    }
  }
}
