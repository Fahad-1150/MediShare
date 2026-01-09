import '../models/report.dart';

/// Service for managing safety reports
class ReportService {
  // Mock data storage
  static final List<Report> _reports = _initializeMockReports();
  static int _idCounter = 1;

  /// Initialize with mock reports
  static List<Report> _initializeMockReports() {
    return [
      Report(
        reportId: 'RPT_001',
        reporterId: 'USER_001',
        donationId: 'DON_005',
        reason: 'Expired Medicine',
        description:
            'The medicine package appears to be expired based on visual inspection',
        status: ReportStatus.pending,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
    ];
  }

  /// Create a new report
  Future<String> createReport({
    required String reporterId,
    required String donationId,
    required String reason,
    required String description,
    List<String>? photoUrls,
  }) async {
    try {
      final reportId = 'REP_${_idCounter++}';

      final report = Report(
        reportId: reportId,
        reporterId: reporterId,
        donationId: donationId,
        reason: reason,
        description: description,
        photoUrls: photoUrls,
        status: ReportStatus.pending,
      );

      _reports.add(report);
      return reportId;
    } catch (e) {
      throw Exception('Failed to create report: $e');
    }
  }

  /// Get all reports
  Future<List<Report>> getAllReports() async {
    return _reports;
  }

  /// Get pending reports (for admin review)
  Future<List<Report>> getPendingReports() async {
    return _reports.where((r) => r.status == ReportStatus.pending).toList();
  }

  /// Get reports by reporter
  Future<List<Report>> getReportsByReporter(String reporterId) async {
    return _reports.where((r) => r.reporterId == reporterId).toList();
  }

  /// Get reports for a donation
  Future<List<Report>> getReportsForDonation(String donationId) async {
    return _reports.where((r) => r.donationId == donationId).toList();
  }

  /// Update report status
  Future<void> updateReportStatus(
    String reportId,
    ReportStatus status, {
    String? adminNotes,
    String? resolution,
  }) async {
    try {
      final index = _reports.indexWhere((r) => r.reportId == reportId);
      if (index != -1) {
        _reports[index] = _reports[index].copyWith(
          status: status,
          adminNotes: adminNotes,
          resolution: resolution,
          resolvedAt: status != ReportStatus.pending ? DateTime.now() : null,
        );
      }
    } catch (e) {
      throw Exception('Failed to update report status: $e');
    }
  }

  /// Get report by ID
  Future<Report?> getReportById(String reportId) async {
    try {
      return _reports.firstWhere((r) => r.reportId == reportId);
    } catch (e) {
      return null;
    }
  }

  /// Count pending reports
  Future<int> getPendingReportCount() async {
    return _reports.where((r) => r.status == ReportStatus.pending).length;
  }
}
