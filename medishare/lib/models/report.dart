/// Report status
enum ReportStatus { pending, reviewed, resolved, closed }

/// Report type
enum ReportType { complaint, feedback, issue, quality }

/// Donor and Receiver Report model
class Report {
  final String id;
  final String reporterId; // User who filed the report
  final String receiverId; // User receiving medicine
  final String donorId; // User donating medicine
  final String requestId; // Related request
  final String donationId; // Related donation
  final ReportType reportType;
  final String comment;
  final ReportStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? adminNotes;
  final DateTime? resolvedAt;

  Report({
    required this.id,
    required this.reporterId,
    required this.receiverId,
    required this.donorId,
    required this.requestId,
    required this.donationId,
    required this.reportType,
    required this.comment,
    this.status = ReportStatus.pending,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.adminNotes,
    this.resolvedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  /// Create from JSON
  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'] as String,
      reporterId: json['reporter_id'] as String,
      receiverId: json['receiver_id'] as String,
      donorId: json['donor_id'] as String,
      requestId: json['request_id'] as String,
      donationId: json['donation_id'] as String,
      reportType: _parseReportType(json['report_type'] as String),
      comment: json['comment'] as String,
      status: _parseReportStatus(json['status'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      adminNotes: json['admin_notes'] as String?,
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'] as String)
          : null,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reporter_id': reporterId,
      'receiver_id': receiverId,
      'donor_id': donorId,
      'request_id': requestId,
      'donation_id': donationId,
      'report_type': reportType.toString().split('.').last,
      'comment': comment,
      'status': status.toString().split('.').last,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'admin_notes': adminNotes,
      'resolved_at': resolvedAt?.toIso8601String(),
    };
  }

  /// Copy with modifications
  Report copyWith({
    String? id,
    String? reporterId,
    String? receiverId,
    String? donorId,
    String? requestId,
    String? donationId,
    ReportType? reportType,
    String? comment,
    ReportStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? adminNotes,
    DateTime? resolvedAt,
  }) {
    return Report(
      id: id ?? this.id,
      reporterId: reporterId ?? this.reporterId,
      receiverId: receiverId ?? this.receiverId,
      donorId: donorId ?? this.donorId,
      requestId: requestId ?? this.requestId,
      donationId: donationId ?? this.donationId,
      reportType: reportType ?? this.reportType,
      comment: comment ?? this.comment,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      adminNotes: adminNotes ?? this.adminNotes,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }

  /// Parse report type from string
  static ReportType _parseReportType(String type) {
    return ReportType.values.firstWhere(
      (e) => e.toString().split('.').last == type,
      orElse: () => ReportType.feedback,
    );
  }

  /// Parse report status from string
  static ReportStatus _parseReportStatus(String status) {
    return ReportStatus.values.firstWhere(
      (e) => e.toString().split('.').last == status,
      orElse: () => ReportStatus.pending,
    );
  }
}
