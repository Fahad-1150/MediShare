import '../models/donation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';

/// Service for managing medicine donations using Supabase
class DonationService {
  final _supabase = Supabase.instance.client;

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

  /// Create a new donation in Supabase
  Future<String> createDonation({
    required String donorId,
    required String medicineName,
    required String medicineType,
    required int quantity,
    required DateTime expiryDate,
    required String donorLocation,
    required double latitude,
    required double longitude,
    String? photoUrl,
    String? dosage,
    String? description,
  }) async {
    try {
      final donationId = 'DON_${DateTime.now().millisecondsSinceEpoch}';

      await _supabase
          .from('donations')
          .insert({
            'id': donationId,
            'donor_id': donorId,
            'medicine_name': medicineName,
            'medicine_type': medicineType,
            'quantity': quantity,
            'expiry_date': expiryDate.toIso8601String().split('T')[0],
            'donor_location': donorLocation,
            'latitude': latitude,
            'longitude': longitude,
            'photo_url': photoUrl,
            'dosage': dosage,
            'description': description,
            'status': 'pending',
          })
          .select()
          .single();

      return donationId;
    } catch (e) {
      throw Exception('Failed to create donation: $e');
    }
  }

  /// Get all donations from Supabase
  Future<List<Donation>> getAllDonations() async {
    try {
      final response = await _supabase
          .from('donations')
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map((row) => _mapRowToDonation(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch donations: $e');
    }
  }

  /// Get approved donations from Supabase
  Future<List<Donation>> getApprovedDonations() async {
    try {
      final response = await _supabase
          .from('donations')
          .select()
          .eq('status', 'approved')
          .order('created_at', ascending: false);

      return (response as List)
          .map((row) => _mapRowToDonation(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch approved donations: $e');
    }
  }

  /// Get pending donations (for admin review)
  Future<List<Donation>> getPendingDonations() async {
    try {
      final response = await _supabase
          .from('donations')
          .select()
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      return (response as List)
          .map((row) => _mapRowToDonation(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch pending donations: $e');
    }
  }

  /// Get donations by donor
  Future<List<Donation>> getDonationsByDonor(String donorId) async {
    try {
      final response = await _supabase
          .from('donations')
          .select()
          .eq('donor_id', donorId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((row) => _mapRowToDonation(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch donations: $e');
    }
  }

  /// Get nearby donations (within X km)
  Future<List<Donation>> getNearbyDonations(
    double latitude,
    double longitude, {
    double radiusKm = 25,
  }) async {
    try {
      final response = await _supabase
          .from('donations')
          .select()
          .eq('status', 'approved')
          .order('created_at', ascending: false);

      final donations = (response as List)
          .map((row) => _mapRowToDonation(row as Map<String, dynamic>))
          .toList();

      return donations.where((donation) {
        final distance = _calculateDistance(
          latitude,
          longitude,
          donation.latitude,
          donation.longitude,
        );
        return distance <= radiusKm;
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch nearby donations: $e');
    }
  }

  /// Search donations
  Future<List<Donation>> searchDonations(String query) async {
    try {
      final response = await _supabase
          .from('donations')
          .select()
          .eq('status', 'approved')
          .order('created_at', ascending: false);

      final lowerQuery = query.toLowerCase();
      return (response as List)
          .map((row) => _mapRowToDonation(row as Map<String, dynamic>))
          .where((d) {
            return d.medicineName.toLowerCase().contains(lowerQuery) ||
                d.medicineType.toLowerCase().contains(lowerQuery);
          })
          .toList();
    } catch (e) {
      throw Exception('Failed to search donations: $e');
    }
  }

  /// Update donation status
  Future<void> updateDonationStatus(
    String donationId,
    DonationStatus status, {
    String? adminNotes,
  }) async {
    try {
      final statusStr = status.toString().split('.').last;
      final updateData = {
        'status': statusStr,
        if (adminNotes != null) 'admin_notes': adminNotes,
        if (status == DonationStatus.approved)
          'approved_at': DateTime.now().toIso8601String(),
      };

      await _supabase.from('donations').update(updateData).eq('id', donationId);
    } catch (e) {
      throw Exception('Failed to update donation status: $e');
    }
  }

  /// Claim a donation
  Future<void> claimDonation(String donationId, String claimerId) async {
    try {
      await _supabase
          .from('donations')
          .update({
            'claimed_by_user_id': claimerId,
            'status': 'claimed',
            'claimed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', donationId);
    } catch (e) {
      throw Exception('Failed to claim donation: $e');
    }
  }

  /// Get donation by ID
  Future<Donation?> getDonationById(String donationId) async {
    try {
      final response = await _supabase
          .from('donations')
          .select()
          .eq('id', donationId)
          .maybeSingle();

      return response != null ? _mapRowToDonation(response) : null;
    } catch (e) {
      return null;
    }
  }

  /// Check for expiring donations (within 7 days)
  Future<List<Donation>> getExpiringDonations() async {
    try {
      final response = await _supabase
          .from('donations')
          .select()
          .eq('status', 'approved')
          .order('expiry_date', ascending: true);

      return (response as List)
          .map((row) => _mapRowToDonation(row as Map<String, dynamic>))
          .where((d) => d.isExpiringsoon)
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch expiring donations: $e');
    }
  }

  /// Mark expired donations
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

  /// Calculate distance between two coordinates (Haversine formula)
  static double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusKm = 6371;

    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadiusKm * c;
  }

  static double _toRadians(double degrees) {
    return degrees * pi / 180;
  }
}
