import '../models/request.dart';
import 'dart:math';

/// Service for managing medicine requests
class RequestService {
  // Mock data storage
  static final List<MedicineRequest> _requests = _initializeMockRequests();
  static int _idCounter = 1;

  /// Initialize with mock requests
  static List<MedicineRequest> _initializeMockRequests() {
    return [
      MedicineRequest(
        requestId: 'REQ_001',
        requesterId: 'USER_002',
        medicineName: 'Paracetamol',
        medicineType: 'Tablet',
        quantity: 20,
        requesterLocation: 'Chittagong',
        latitude: 22.3569,
        longitude: 91.7832,
        status: RequestStatus.fulfilled,
        assignedDonationId: 'DON_001',
        fulfilledAt: DateTime.now().subtract(const Duration(days: 1)),
        reason: 'Fever and headache relief',
      ),
      MedicineRequest(
        requestId: 'REQ_002',
        requesterId: 'USER_003',
        medicineName: 'Amoxicillin',
        medicineType: 'Capsule',
        quantity: 10,
        requesterLocation: 'Sylhet',
        latitude: 24.8949,
        longitude: 91.8687,
        status: RequestStatus.fulfilled,
        assignedDonationId: 'DON_002',
        fulfilledAt: DateTime.now(),
        reason: 'Bacterial infection treatment',
      ),
      MedicineRequest(
        requestId: 'REQ_003',
        requesterId: 'USER_001',
        medicineName: 'Vitamin D',
        medicineType: 'Tablet',
        quantity: 30,
        requesterLocation: 'Dhaka',
        latitude: 23.8110,
        longitude: 90.4120,
        status: RequestStatus.pending,
        reason: 'Vitamin D deficiency supplement',
      ),
    ];
  }

  /// Create a new request
  Future<String> createRequest({
    required String requesterId,
    required String medicineName,
    required String medicineType,
    required int quantity,
    required String requesterLocation,
    required double latitude,
    required double longitude,
    String? reason,
  }) async {
    try {
      final requestId = 'REQ_${_idCounter++}';

      final request = MedicineRequest(
        requestId: requestId,
        requesterId: requesterId,
        medicineName: medicineName,
        medicineType: medicineType,
        quantity: quantity,
        requesterLocation: requesterLocation,
        latitude: latitude,
        longitude: longitude,
        reason: reason,
        status: RequestStatus.pending,
      );

      _requests.add(request);
      return requestId;
    } catch (e) {
      throw Exception('Failed to create request: $e');
    }
  }

  /// Get all requests
  Future<List<MedicineRequest>> getAllRequests() async {
    return _requests;
  }

  /// Get pending requests (for admin review)
  Future<List<MedicineRequest>> getPendingRequests() async {
    return _requests.where((r) => r.status == RequestStatus.pending).toList();
  }

  /// Get requests by requester
  Future<List<MedicineRequest>> getRequestsByRequester(
    String requesterId,
  ) async {
    return _requests.where((r) => r.requesterId == requesterId).toList();
  }

  /// Search requests
  Future<List<MedicineRequest>> searchRequests(String query) async {
    final lowerQuery = query.toLowerCase();
    return _requests.where((r) {
      return r.medicineName.toLowerCase().contains(lowerQuery) ||
          r.medicineType.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Update request status
  Future<void> updateRequestStatus(
    String requestId,
    RequestStatus status, {
    String? assignedDonationId,
    String? adminNotes,
  }) async {
    try {
      final index = _requests.indexWhere((r) => r.requestId == requestId);
      if (index != -1) {
        _requests[index] = _requests[index].copyWith(
          status: status,
          assignedDonationId: assignedDonationId,
          adminNotes: adminNotes,
          fulfilledAt: status == RequestStatus.fulfilled
              ? DateTime.now()
              : null,
        );
      }
    } catch (e) {
      throw Exception('Failed to update request status: $e');
    }
  }

  /// Get request by ID
  Future<MedicineRequest?> getRequestById(String requestId) async {
    try {
      return _requests.firstWhere((r) => r.requestId == requestId);
    } catch (e) {
      return null;
    }
  }

  /// Find matching donations for a request
  Future<List<String>> findMatchingDonations(
    String medicineName,
    String medicineType,
    int quantity,
  ) async {
    // This would be used to suggest which donations could fulfill a request
    // For now, returning empty list - would be implemented with donation service
    return [];
  }

  /// Get nearby requests (for donors)
  Future<List<MedicineRequest>> getNearbyRequests(
    double latitude,
    double longitude, {
    double radiusKm = 25,
  }) async {
    return _requests.where((request) {
      if (request.status != RequestStatus.pending) return false;

      final distance = _calculateDistance(
        latitude,
        longitude,
        request.latitude,
        request.longitude,
      );

      return distance <= radiusKm;
    }).toList();
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
