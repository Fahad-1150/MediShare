import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification.dart' as notif_model;
import 'donation_service.dart';
import 'notification_service.dart';

/// Service for managing expiry and sending notifications
class ExpiryService {
  final _supabase = Supabase.instance.client;
  final _donationService = DonationService();
  final _notificationService = NotificationService();

  /// Check for expiring donations and create notifications
  Future<void> checkAndNotifyExpiringDonations() async {
    try {
      // Get all expiring donations (within 7 days)
      final expiringDonations = await _donationService.getExpiringDonations();

      for (var donation in expiringDonations) {
        // Check if notification already sent (within last day)
        final existingNotif = await _supabase
            .from('notifications')
            .select()
            .eq('related_donation_id', donation.donationId)
            .eq('type', 'expiry_warning')
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();

        // Only send if no recent notification exists
        if (existingNotif == null) {
          final daysUntilExpiry = donation.expiryDate
              .difference(DateTime.now())
              .inDays;

          await _notificationService.createNotification(
            userId: donation.donorId,
            type: notif_model.NotificationType.expiryWarning,
            title: 'Medicine Expiring Soon',
            message:
                '${donation.medicineName} will expire in $daysUntilExpiry days',
            relatedId: donation.donationId,
          );
        }
      }
    } catch (e) {
      throw Exception('Failed to check expiring donations: $e');
    }
  }

  /// Mark all expired donations as expired status
  Future<void> markExpiredDonations() async {
    try {
      await _donationService.markExpiredDonations();
    } catch (e) {
      throw Exception('Failed to mark expired donations: $e');
    }
  }

  /// Notify donor when their donation is claimed
  Future<void> notifyDonationClaimed(
    String donorId,
    String medicineName,
    String donationId,
  ) async {
    try {
      await _notificationService.createNotification(
        userId: donorId,
        type: notif_model.NotificationType.donationClaimed,
        title: 'Your Donation Claimed',
        message: '$medicineName has been claimed by someone in need',
        relatedId: donationId,
      );
    } catch (e) {
      throw Exception('Failed to notify donation claimed: $e');
    }
  }

  /// Notify admin when new report is submitted
  Future<void> notifyAdminNewReport(String reportId) async {
    try {
      // Get all admins
      final admins = await _supabase
          .from('users_profile')
          .select()
          .eq('role', 'admin');

      for (var admin in admins as List) {
        await _notificationService.createNotification(
          userId: admin['id'] as String,
          type: notif_model.NotificationType.reportSubmitted,
          title: 'New Safety Report',
          message: 'A safety report requires your review',
          relatedId: reportId,
        );
      }
    } catch (e) {
      throw Exception('Failed to notify admins: $e');
    }
  }

  /// Notify donor when their donation is approved
  Future<void> notifyDonationApproved(
    String donorId,
    String medicineName,
    String donationId,
  ) async {
    try {
      await _notificationService.createNotification(
        userId: donorId,
        type: notif_model.NotificationType.donationApproved,
        title: 'Donation Approved',
        message: '$medicineName has been approved and is now available',
        relatedId: donationId,
      );
    } catch (e) {
      throw Exception('Failed to notify donation approved: $e');
    }
  }

  /// Notify donor when their donation is rejected
  Future<void> notifyDonationRejected(
    String donorId,
    String medicineName,
    String donationId,
    String? reason,
  ) async {
    try {
      final message = reason != null
          ? '$medicineName was rejected: $reason'
          : '$medicineName was rejected by admin';

      await _notificationService.createNotification(
        userId: donorId,
        type: notif_model.NotificationType.donationRejected,
        title: 'Donation Rejected',
        message: message,
        relatedId: donationId,
      );
    } catch (e) {
      throw Exception('Failed to notify donation rejected: $e');
    }
  }
}
