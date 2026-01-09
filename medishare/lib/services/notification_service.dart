import '../models/notification.dart' as notif_model;

/// Service for managing notifications
class NotificationService {
  // Mock data storage
  static final List<notif_model.Notification> _notifications =
      _initializeMockNotifications();
  static int _idCounter = 1;

  /// Initialize with mock notifications
  static List<notif_model.Notification> _initializeMockNotifications() {
    return [
      notif_model.Notification(
        notificationId: 'NOT_001',
        userId: 'USER_001',
        type: notif_model.NotificationType.donationApproved,
        title: 'New Donation Available',
        message: 'Paracetamol tablets are now available in your area',
        relatedId: 'DON_001',
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      notif_model.Notification(
        notificationId: 'NOT_002',
        userId: 'USER_002',
        type: notif_model.NotificationType.donationClaimed,
        title: 'Your Donation Claimed',
        message: 'Someone claimed your Paracetamol donation',
        relatedId: 'DON_001',
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
      notif_model.Notification(
        notificationId: 'NOT_003',
        userId: 'ADMIN_001',
        type: notif_model.NotificationType.reportResolved,
        title: 'New Safety Report',
        message: 'A safety report has been submitted for review',
        relatedId: 'RPT_001',
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
      ),
    ];
  }

  /// Create a new notification
  Future<String> createNotification({
    required String userId,
    required notif_model.NotificationType type,
    required String title,
    required String message,
    String? relatedId,
  }) async {
    try {
      final notifId = 'NOTIF_${_idCounter++}';

      final notification = notif_model.Notification(
        notificationId: notifId,
        userId: userId,
        type: type,
        title: title,
        message: message,
        relatedId: relatedId,
      );

      _notifications.add(notification);
      return notifId;
    } catch (e) {
      throw Exception('Failed to create notification: $e');
    }
  }

  /// Get notifications for user
  Future<List<notif_model.Notification>> getUserNotifications(
    String userId,
  ) async {
    return _notifications
        .where((n) => n.userId == userId)
        .toList()
        .reversed
        .toList(); // Most recent first
  }

  /// Get unread notifications
  Future<List<notif_model.Notification>> getUnreadNotifications(
    String userId,
  ) async {
    return _notifications
        .where((n) => n.userId == userId && !n.isRead)
        .toList();
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      final index = _notifications.indexWhere(
        (n) => n.notificationId == notificationId,
      );
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
      }
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  /// Mark all notifications as read for user
  Future<void> markAllAsRead(String userId) async {
    try {
      for (int i = 0; i < _notifications.length; i++) {
        if (_notifications[i].userId == userId && !_notifications[i].isRead) {
          _notifications[i] = _notifications[i].copyWith(isRead: true);
        }
      }
    } catch (e) {
      throw Exception('Failed to mark all as read: $e');
    }
  }

  /// Get unread count
  Future<int> getUnreadCount(String userId) async {
    return _notifications.where((n) => n.userId == userId && !n.isRead).length;
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      _notifications.removeWhere((n) => n.notificationId == notificationId);
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
    }
  }
}
