import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification.dart' as notif_model;
import '../models/donation.dart';
import 'donation_service.dart';
import 'notification_service.dart';

/// Service for managing expiry and sending notifications
class ExpiryService {
  final _supabase = Supabase.instance.client;
  final _donationService = DonationService();
  final _notificationService = NotificationService();

  /// Map Supabase row to Donation model
  Donation _mapRowToDonation(Map<String, dynamic> row) {
    return Donation(
      donationId: row['id'] as String,
      donorId: row['donor_id'] as String,
      medicineName: row['medicine_name'] as String,
      medicineType: row['medicine_type'] as String,
      quantity: row['quantity'] as int,
      expiryDate: DateTime.parse(row['expiry_date'] as String),
      donorLocation: row['donor_location'] as String,
      latitude: (row['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (row['longitude'] as num?)?.toDouble() ?? 0.0,
      photoUrl: row['photo_url'] as String?,
      description: row['description'] as String?,
      status: _parseStatus(row['status'] as String),
      claimedByUserId: row['claimed_by_user_id'] as String?,
      adminNotes: row['admin_notes'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
      approvedAt: row['approved_at'] != null
          ? DateTime.parse(row['approved_at'] as String)
          : null,
      claimedAt: row['claimed_at'] != null
          ? DateTime.parse(row['claimed_at'] as String)
          : null,
    );
  }

  /// Parse status string to enum
  DonationStatus _parseStatus(String status) {
    return DonationStatus.values.firstWhere(
      (e) => e.toString().split('.').last == status,
      orElse: () => DonationStatus.pending,
    );
  }

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
      final expiredDonations = await _supabase
          .from('donations')
          .select()
          .neq('status', 'expired')
          .order('expiry_date', ascending: true);

      for (var row in expiredDonations as List) {
        final donation = _mapRowToDonation(row as Map<String, dynamic>);
        if (donation.isExpired) {
          await _supabase
              .from('donations')
              .update({'status': 'expired'})
              .eq('id', donation.donationId);
        }
      }
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
