/// Report status
enum ReportStatus { pending, reviewing, resolved, dismissed }

/// Unsafe Medicine Report model
class Report {
  final String reportId;
  final String reporterId; // User reporting
  final String donationId; // Which donation is unsafe
  final String reason; // Why it's unsafe
  final String description;
  final List<String>? photoUrls; // Evidence photos
  final ReportStatus status;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String? adminNotes;
  final String? resolution;

  Report({
    required this.reportId,
    required this.reporterId,
    required this.donationId,
    required this.reason,
    required this.description,
    this.photoUrls,
    this.status = ReportStatus.pending,
    DateTime? createdAt,
    this.resolvedAt,
    this.adminNotes,
    this.resolution,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Copy with modifications
  Report copyWith({
    String? reportId,
    String? reporterId,
    String? donationId,
    String? reason,
    String? description,
    List<String>? photoUrls,
    ReportStatus? status,
    DateTime? createdAt,
    DateTime? resolvedAt,
    String? adminNotes,
    String? resolution,
  }) {
    return Report(
      reportId: reportId ?? this.reportId,
      reporterId: reporterId ?? this.reporterId,
      donationId: donationId ?? this.donationId,
      reason: reason ?? this.reason,
      description: description ?? this.description,
      photoUrls: photoUrls ?? this.photoUrls,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      adminNotes: adminNotes ?? this.adminNotes,
      resolution: resolution ?? this.resolution,
    );
  }
}
