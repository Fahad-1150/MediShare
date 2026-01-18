import '../models/report.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Service for managing reports from donors and receivers using Supabase
class ReportService {
  final _supabase = Supabase.instance.client;

  /// Map Supabase row to Report model
  Report _mapRowToReport(Map<String, dynamic> row) {
    return Report.fromJson(row);
  }

  /// Create a new report
  Future<String> createReport({
    required String reporterId, // Current user filing the report
    required String receiverId,
    required String donorId,
    required String requestId,
    required String donationId,
    required ReportType reportType,
    required String comment,
  }) async {
    try {
      final reportId = const Uuid().v4(); // Generate UUID

      final response = await _supabase
          .from('reports')
          .insert({
            'id': reportId,
            'reporter_id': reporterId,
            'receiver_id': receiverId,
            'donor_id': donorId,
            'request_id': requestId,
            'donation_id': donationId,
            'report_type': reportType.toString().split('.').last,
            'comment': comment,
            'status': 'pending',
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return response['id'] as String;
    } catch (e) {
      throw Exception('Failed to create report: $e');
    }
  }

  /// Get all reports from Supabase
  Future<List<Report>> getAllReports() async {
    try {
      final response = await _supabase
          .from('reports')
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map((row) => _mapRowToReport(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch reports: $e');
    }
  }

  /// Get pending reports (for admin review)
  Future<List<Report>> getPendingReports() async {
    try {
      final response = await _supabase
          .from('reports')
          .select()
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      return (response as List)
          .map((row) => _mapRowToReport(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch pending reports: $e');
    }
  }

  /// Get reports by receiver ID
  Future<List<Report>> getReportsByReceiver(String receiverId) async {
    try {
      final response = await _supabase
          .from('reports')
          .select()
          .eq('receiver_id', receiverId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((row) => _mapRowToReport(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch reports: $e');
    }
  }

  /// Get reports by donor ID
  Future<List<Report>> getReportsByDonor(String donorId) async {
    try {
      final response = await _supabase
          .from('reports')
          .select()
          .eq('donor_id', donorId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((row) => _mapRowToReport(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch reports: $e');
    }
  }

  /// Get reports for a specific request
  Future<List<Report>> getReportsByRequest(String requestId) async {
    try {
      final response = await _supabase
          .from('reports')
          .select()
          .eq('request_id', requestId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((row) => _mapRowToReport(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch reports: $e');
    }
  }

  /// Update report status (admin only)
  Future<void> updateReportStatus(
    String reportId,
    ReportStatus status, {
    String? adminNotes,
  }) async {
    try {
      final updateData = {
        'status': status.toString().split('.').last,
        'updated_at': DateTime.now().toIso8601String(),
        if (adminNotes != null) 'admin_notes': adminNotes,
        if (status == ReportStatus.resolved)
          'resolved_at': DateTime.now().toIso8601String(),
      };

      await _supabase.from('reports').update(updateData).eq('id', reportId);
    } catch (e) {
      throw Exception('Failed to update report status: $e');
    }
  }

  /// Get report by ID
  Future<Report?> getReportById(String reportId) async {
    try {
      final response = await _supabase
          .from('reports')
          .select()
          .eq('id', reportId)
          .maybeSingle();

      return response != null ? _mapRowToReport(response) : null;
    } catch (e) {
      return null;
    }
  }

  /// Count pending reports
  Future<int> getPendingReportCount() async {
    try {
      final response = await _supabase
          .from('reports')
          .select()
          .eq('status', 'pending')
          .count(CountOption.exact);

      return response.count;
    } catch (e) {
      return 0;
    }
  }

  /// Get reports statistics
  Future<Map<String, dynamic>> getReportsStats() async {
    try {
      final response = await _supabase
          .from('reports')
          .select()
          .order('created_at', ascending: false);

      final reports = (response as List)
          .map((row) => _mapRowToReport(row as Map<String, dynamic>))
          .toList();

      final pending = reports
          .where((r) => r.status == ReportStatus.pending)
          .length;
      final reviewed = reports
          .where((r) => r.status == ReportStatus.reviewed)
          .length;
      final resolved = reports
          .where((r) => r.status == ReportStatus.resolved)
          .length;

      return {
        'total': reports.length,
        'pending': pending,
        'reviewed': reviewed,
        'resolved': resolved,
        'closed': reports.where((r) => r.status == ReportStatus.closed).length,
      };
    } catch (e) {
      throw Exception('Failed to get reports stats: $e');
    }
  }

  /// Delete a report (admin only)
  Future<void> deleteReport(String reportId) async {
    try {
      await _supabase.from('reports').delete().eq('id', reportId);
    } catch (e) {
      throw Exception('Failed to delete report: $e');
    }
  }
}
