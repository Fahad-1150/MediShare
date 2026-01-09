import '../models/donation.dart';
import 'dart:math';

/// Service for managing medicine donations
/// In production, this would connect to Firestore
class DonationService {
  // Mock data storage
  static final List<Donation> _donations = _initializeMockDonations();
  static int _idCounter = 1;

  /// Initialize with mock donations
  static List<Donation> _initializeMockDonations() {
    return [
      Donation(
        donationId: 'DON_001',
        donorId: 'USER_001',
        medicineName: 'Paracetamol',
        medicineType: 'Tablet',
        quantity: 50,
        expiryDate: DateTime(2025, 12, 31),
        donorLocation: 'Dhaka',
        latitude: 23.8110,
        longitude: 90.4120,
        description: 'Unused paracetamol tablets',
        status: DonationStatus.approved,
        approvedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      Donation(
        donationId: 'DON_002',
        donorId: 'USER_002',
        medicineName: 'Amoxicillin',
        medicineType: 'Capsule',
        quantity: 30,
        expiryDate: DateTime(2026, 3, 15),
        donorLocation: 'Chittagong',
        latitude: 22.3569,
        longitude: 91.7832,
        description: 'Antibiotic capsules',
        status: DonationStatus.approved,
        approvedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Donation(
        donationId: 'DON_003',
        donorId: 'USER_001',
        medicineName: 'Ibuprofen',
        medicineType: 'Tablet',
        quantity: 20,
        expiryDate: DateTime(2025, 8, 10),
        donorLocation: 'Dhaka',
        latitude: 23.8110,
        longitude: 90.4120,
        description: 'Pain reliever',
        status: DonationStatus.approved,
        approvedAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
      Donation(
        donationId: 'DON_004',
        donorId: 'USER_003',
        medicineName: 'Vitamin C',
        medicineType: 'Tablet',
        quantity: 60,
        expiryDate: DateTime(2026, 6, 30),
        donorLocation: 'Sylhet',
        latitude: 24.8949,
        longitude: 91.8687,
        description: 'Multivitamin supplement',
        status: DonationStatus.approved,
        approvedAt: DateTime.now(),
      ),
      Donation(
        donationId: 'DON_005',
        donorId: 'USER_002',
        medicineName: 'Antihistamine',
        medicineType: 'Tablet',
        quantity: 15,
        expiryDate: DateTime(2026, 1, 20),
        donorLocation: 'Chittagong',
        latitude: 22.3569,
        longitude: 91.7832,
        description: 'Allergy medicine',
        status: DonationStatus.pending,
      ),
    ];
  }

  /// Add a new donation
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
    String? description,
  }) async {
    try {
      final donationId = 'DON_${_idCounter++}';

      final donation = Donation(
        donationId: donationId,
        donorId: donorId,
        medicineName: medicineName,
        medicineType: medicineType,
        quantity: quantity,
        expiryDate: expiryDate,
        donorLocation: donorLocation,
        latitude: latitude,
        longitude: longitude,
        photoUrl: photoUrl,
        status: DonationStatus.pending,
        description: description,
      );

      _donations.add(donation);
      return donationId;
    } catch (e) {
      throw Exception('Failed to create donation: $e');
    }
  }

  /// Get all donations
  Future<List<Donation>> getAllDonations() async {
    return _donations;
  }

  /// Get approved donations
  Future<List<Donation>> getApprovedDonations() async {
    return _donations
        .where((d) => d.status == DonationStatus.approved)
        .toList();
  }

  /// Get pending donations (for admin review)
  Future<List<Donation>> getPendingDonations() async {
    return _donations.where((d) => d.status == DonationStatus.pending).toList();
  }

  /// Get donations by donor
  Future<List<Donation>> getDonationsByDonor(String donorId) async {
    return _donations.where((d) => d.donorId == donorId).toList();
  }

  /// Get nearby donations (within X km)
  Future<List<Donation>> getNearbyDonations(
    double latitude,
    double longitude, {
    double radiusKm = 25,
  }) async {
    return _donations.where((donation) {
      if (donation.status != DonationStatus.approved) return false;

      final distance = _calculateDistance(
        latitude,
        longitude,
        donation.latitude,
        donation.longitude,
      );

      return distance <= radiusKm;
    }).toList();
  }

  /// Search donations
  Future<List<Donation>> searchDonations(String query) async {
    final lowerQuery = query.toLowerCase();
    return _donations.where((d) {
      return d.medicineName.toLowerCase().contains(lowerQuery) ||
          d.medicineType.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Update donation status
  Future<void> updateDonationStatus(
    String donationId,
    DonationStatus status, {
    String? adminNotes,
  }) async {
    try {
      final index = _donations.indexWhere((d) => d.donationId == donationId);
      if (index != -1) {
        _donations[index] = _donations[index].copyWith(
          status: status,
          adminNotes: adminNotes,
          approvedAt: status == DonationStatus.approved ? DateTime.now() : null,
        );
      }
    } catch (e) {
      throw Exception('Failed to update donation status: $e');
    }
  }

  /// Claim a donation
  Future<void> claimDonation(String donationId, String claimerId) async {
    try {
      final index = _donations.indexWhere((d) => d.donationId == donationId);
      if (index != -1) {
        _donations[index] = _donations[index].copyWith(
          claimedByUserId: claimerId,
          status: DonationStatus.claimed,
          claimedAt: DateTime.now(),
        );
      }
    } catch (e) {
      throw Exception('Failed to claim donation: $e');
    }
  }

  /// Get donation by ID
  Future<Donation?> getDonationById(String donationId) async {
    try {
      return _donations.firstWhere((d) => d.donationId == donationId);
    } catch (e) {
      return null;
    }
  }

  /// Check for expiring donations (within 7 days)
  Future<List<Donation>> getExpiringDonations() async {
    return _donations.where((d) => d.isExpiringsoon).toList();
  }

  /// Mark expired donations
  Future<void> markExpiredDonations() async {
    for (int i = 0; i < _donations.length; i++) {
      if (_donations[i].isExpired &&
          _donations[i].status != DonationStatus.expired) {
        _donations[i] = _donations[i].copyWith(status: DonationStatus.expired);
      }
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
