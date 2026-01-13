import '../models/report.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for managing safety reports using Supabase
class ReportService {
  final _supabase = Supabase.instance.client;

  /// Map Supabase row to Report model
  Report _mapRowToReport(Map<String, dynamic> row) {
    return Report(
      reportId: row['id'] as String,
      reporterId: row['reporter_id'] as String,
      donationId: row['donation_id'] as String,
      reason: row['reason'] as String,
      description: row['description'],
      photoUrls: row['photo_urls'] != null
          ? List<String>.from(row['photo_urls'] as List)
          : null,
      status: _parseStatus(row['status'] as String),
      adminNotes: row['admin_notes'] as String?,
      resolution: row['resolution'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
      resolvedAt: row['resolved_at'] != null
          ? DateTime.parse(row['resolved_at'] as String)
          : null,
    );
  }

  /// Parse status string to enum
  ReportStatus _parseStatus(String status) {
    return ReportStatus.values.firstWhere(
      (e) => e.toString().split('.').last == status,
      orElse: () => ReportStatus.pending,
    );
  }

  /// Create a new report in Supabase
  Future<String> createReport({
    required String reporterId,
    required String donationId,
    required String reason,
    required String description,
    List<String>? photoUrls,
  }) async {
    try {
      final reportId = 'RPT_${DateTime.now().millisecondsSinceEpoch}';

      await _supabase.from('reports').insert({
        'id': reportId,
        'reporter_id': reporterId,
        'donation_id': donationId,
        'reason': reason,
        'description': description,
        'photo_urls': photoUrls,
        'status': 'pending',
      });

      return reportId;
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

  /// Get reports by reporter
  Future<List<Report>> getReportsByReporter(String reporterId) async {
    try {
      final response = await _supabase
          .from('reports')
          .select()
          .eq('reporter_id', reporterId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((row) => _mapRowToReport(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch reports: $e');
    }
  }

  /// Get reports for a donation
  Future<List<Report>> getReportsForDonation(String donationId) async {
    try {
      final response = await _supabase
          .from('reports')
          .select()
          .eq('donation_id', donationId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((row) => _mapRowToReport(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch reports: $e');
    }
  }

  /// Update report status
  Future<void> updateReportStatus(
    String reportId,
    ReportStatus status, {
    String? adminNotes,
    String? resolution,
  }) async {
    try {
      final statusStr = status.toString().split('.').last;
      final updateData = {
        'status': statusStr,
        if (adminNotes != null) 'admin_notes': adminNotes,
        if (resolution != null) 'resolution': resolution,
        if (status != ReportStatus.pending)
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
}
