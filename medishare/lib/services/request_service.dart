import '../models/request.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';
import 'donation_service.dart';

/// Service for managing medicine requests using Supabase
class RequestService {
  final _supabase = Supabase.instance.client;

  /// Map Supabase row to MedicineRequest model
  MedicineRequest _mapRowToRequest(Map<String, dynamic> row) {
    return MedicineRequest(
      requestId: row['id'] as String,
      requesterId: row['requester_id'] as String,
      donorId: row['donor_id'] as String?,
      medicineName: row['medicine_name'] as String,
      medicineType: row['medicine_type'] as String,
      quantity: row['quantity'] as int,
      requesterLocation: row['requester_location'] as String,
      latitude: (row['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (row['longitude'] as num?)?.toDouble() ?? 0.0,
      reason: row['reason'] as String?,
      status: _parseStatus(row['status'] as String),
      assignedDonationId: row['assigned_donation_id'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
      fulfilledAt: row['fulfilled_at'] != null
          ? DateTime.parse(row['fulfilled_at'] as String)
          : null,
    );
  }

  /// Parse status string to enum
  RequestStatus _parseStatus(String status) {
    return RequestStatus.values.firstWhere(
      (e) => e.toString().split('.').last == status,
      orElse: () => RequestStatus.pending,
    );
  }

  /// Create a new request in Supabase
  Future<String> createRequest({
    required String requesterId,
    String? donorId,
    required String medicineName,
    required String medicineType,
    required int quantity,
    required String requesterLocation,
    required double latitude,
    required double longitude,
    String? reason,
  }) async {
    try {
      final requestId = 'REQ_${DateTime.now().millisecondsSinceEpoch}';

      await _supabase.from('requests').insert({
        'id': requestId,
        'requester_id': requesterId,
        'donor_id': donorId,
        'medicine_name': medicineName,
        'medicine_type': medicineType,
        'quantity': quantity,
        'requester_location': requesterLocation,
        'latitude': latitude,
        'longitude': longitude,
        'reason': reason,
        'status': 'pending',
      });

      return requestId;
    } catch (e) {
      throw Exception('Failed to create request: $e');
    }
  }

  /// Get all requests from Supabase
  Future<List<MedicineRequest>> getAllRequests() async {
    try {
      final response = await _supabase
          .from('requests')
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map((row) => _mapRowToRequest(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch requests: $e');
    }
  }

  /// Get pending requests (for admin review)
  Future<List<MedicineRequest>> getPendingRequests() async {
    try {
      final response = await _supabase
          .from('requests')
          .select()
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      return (response as List)
          .map((row) => _mapRowToRequest(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch pending requests: $e');
    }
  }

  /// Get requests by requester
  Future<List<MedicineRequest>> getRequestsByRequester(
    String requesterId,
  ) async {
    try {
      final response = await _supabase
          .from('requests')
          .select()
          .eq('requester_id', requesterId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((row) => _mapRowToRequest(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch requests: $e');
    }
  }

  /// Get requests by donation ID
  Future<List<MedicineRequest>> getRequestsByDonation(String donationId) async {
    try {
      final response = await _supabase
          .from('requests')
          .select()
          .eq('assigned_donation_id', donationId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((row) => _mapRowToRequest(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch requests for donation: $e');
    }
  }

  /// Get requests by donor ID (all requests made to a specific donor)
  Future<List<MedicineRequest>> getRequestsByDonor(String donorId) async {
    try {
      final response = await _supabase
          .from('requests')
          .select()
          .eq('donor_id', donorId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((row) => _mapRowToRequest(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch requests for donor: $e');
    }
  }

  /// Search requests
  Future<List<MedicineRequest>> searchRequests(String query) async {
    try {
      final response = await _supabase
          .from('requests')
          .select()
          .order('created_at', ascending: false);

      final lowerQuery = query.toLowerCase();
      return (response as List)
          .map((row) => _mapRowToRequest(row as Map<String, dynamic>))
          .where((r) {
            return r.medicineName.toLowerCase().contains(lowerQuery) ||
                r.medicineType.toLowerCase().contains(lowerQuery);
          })
          .toList();
    } catch (e) {
      throw Exception('Failed to search requests: $e');
    }
  }

  /// Update request status
  Future<void> updateRequestStatus(
    String requestId,
    RequestStatus status, {
    String? assignedDonationId,
  }) async {
    try {
      // Get the request first to know its current state
      final request = await getRequestById(requestId);
      if (request == null) {
        throw Exception('Request not found');
      }

      final statusStr = status.toString().split('.').last;
      final updateData = {
        'status': statusStr,
        if (assignedDonationId != null)
          'assigned_donation_id': assignedDonationId,
        if (status == RequestStatus.fulfilled)
          'fulfilled_at': DateTime.now().toIso8601String(),
      };

      await _supabase.from('requests').update(updateData).eq('id', requestId);

      // If approving a request with an assigned donation, reduce the donation quantity
      if (status == RequestStatus.approved &&
          (assignedDonationId != null || request.assignedDonationId != null)) {
        final donationId = assignedDonationId ?? request.assignedDonationId!;
        final donationService = DonationService();

        // Reduce the donation quantity by the requested amount
        try {
          await donationService.reduceDonationQuantity(
            donationId,
            request.quantity,
          );
        } catch (e) {
          // Log the error but don't fail the request status update
          // as the status has already been updated
          print('Error reducing donation quantity: $e');
        }
      }

      // If cancelling a request that was approved, restore the donation quantity
      if (status == RequestStatus.cancelled &&
          (request.status == RequestStatus.approved ||
              request.status == RequestStatus.fulfilled) &&
          request.assignedDonationId != null) {
        final donationService = DonationService();

        try {
          // Get current donation and restore quantity
          final donation = await donationService.getDonationById(
            request.assignedDonationId!,
          );
          if (donation != null) {
            await donationService.updateDonationQuantity(
              request.assignedDonationId!,
              donation.quantity + request.quantity,
            );
          }
        } catch (e) {
          print('Error restoring donation quantity: $e');
        }
      }
    } catch (e) {
      throw Exception('Failed to update request status: $e');
    }
  }

  /// Get request by ID
  Future<MedicineRequest?> getRequestById(String requestId) async {
    try {
      final response = await _supabase
          .from('requests')
          .select()
          .eq('id', requestId)
          .maybeSingle();

      return response != null ? _mapRowToRequest(response) : null;
    } catch (e) {
      return null;
    }
  }

  /// Get nearby requests (for donors)
  Future<List<MedicineRequest>> getNearbyRequests(
    double latitude,
    double longitude, {
    double radiusKm = 25,
  }) async {
    try {
      final response = await _supabase
          .from('requests')
          .select()
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      final requests = (response as List)
          .map((row) => _mapRowToRequest(row as Map<String, dynamic>))
          .toList();

      return requests.where((request) {
        final distance = _calculateDistance(
          latitude,
          longitude,
          request.latitude,
          request.longitude,
        );
        return distance <= radiusKm;
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch nearby requests: $e');
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
