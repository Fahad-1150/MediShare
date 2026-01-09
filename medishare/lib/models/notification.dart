/// Notification type
enum NotificationType {
  donationApproved,
  donationClaimed,
  requestFulfilled,
  expiryWarning,
  reportResolved,
}

/// System Notification model
class Notification {
  final String notificationId;
  final String userId; // Recipient
  final NotificationType type;
  final String title;
  final String message;
  final String? relatedId; // donationId, requestId, reportId, etc.
  final bool isRead;
  final DateTime createdAt;

  Notification({
    required this.notificationId,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.relatedId,
    this.isRead = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Copy with modifications
  Notification copyWith({
    String? notificationId,
    String? userId,
    NotificationType? type,
    String? title,
    String? message,
    String? relatedId,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return Notification(
      notificationId: notificationId ?? this.notificationId,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      relatedId: relatedId ?? this.relatedId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
