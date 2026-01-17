# Reports System - Complete Implementation

## What Was Created

### 1. **SQL Schema** (`sql/create_reports_table.sql`)
A complete PostgreSQL table with:
- **receiver_id**: User receiving medicine (UUID)
- **donor_id**: User donating medicine (UUID)
- **request_id**: Reference to medicine request
- **donation_id**: Reference to donation
- **report_type**: complaint, feedback, issue, or quality
- **comment**: Detailed text description
- **status**: pending, reviewed, resolved, closed
- **created_at**: Timestamp when created
- **updated_at**: Timestamp when last updated
- **admin_notes**: Admin comments during review
- **resolved_at**: When issue was resolved

**Security Features:**
- Row Level Security (RLS) enabled
- Users can only view their own reports
- Admin has full access
- Proper indexes for performance

---

### 2. **Report Model** (`lib/models/report.dart`)
Updated with new fields:
```dart
class Report {
  - id: UUID
  - receiverId: UUID
  - donorId: UUID
  - requestId: VARCHAR
  - donationId: VARCHAR
  - reportType: ReportType enum
  - comment: String
  - status: ReportStatus enum
  - createdAt: DateTime
  - updatedAt: DateTime
  - adminNotes: String?
  - resolvedAt: DateTime?
}

enum ReportType { complaint, feedback, issue, quality }
enum ReportStatus { pending, reviewed, resolved, closed }
```

---

### 3. **Report Service** (`lib/services/report_service.dart`)
Methods available:

**Creating Reports:**
```dart
Future<String> createReport({
  required String receiverId,
  required String donorId,
  required String requestId,
  required String donationId,
  required ReportType reportType,
  required String comment,
})
```

**Retrieving Reports:**
```dart
Future<List<Report>> getReportsByReceiver(String receiverId)
Future<List<Report>> getReportsByDonor(String donorId)
Future<List<Report>> getReportsByRequest(String requestId)
Future<List<Report>> getAllReports() // Admin only
Future<List<Report>> getPendingReports() // Admin only
Future<Report?> getReportById(String reportId)
```

**Admin Functions:**
```dart
Future<void> updateReportStatus(
  String reportId,
  ReportStatus status,
  {String? adminNotes}
)
Future<Map<String, dynamic>> getReportsStats()
Future<int> getPendingReportCount()
```

---

### 4. **File Report Page** (`lib/pages/file_report_page.dart`)
User-friendly form for filing reports with:
- Report type dropdown (complaint, feedback, issue, quality)
- Text area for detailed comments
- Submit button with loading state
- Info message about report review
- Automatic capture of receiver/donor IDs

---

## How to Use

### For Users (File a Report)

**Add to Request Details Page:**
```dart
ElevatedButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FileReportPage(
          requestId: request.requestId,
          donationId: request.assignedDonationId,
          otherUserId: otherUserId, // donor or receiver
          isDonor: true, // current user role
        ),
      ),
    );
  },
  child: const Text('File Report'),
)
```

### For Admin (View & Manage Reports)

**View All Reports:**
```dart
final reports = await reportService.getAllReports();
```

**View Pending Reports:**
```dart
final pending = await reportService.getPendingReports();
```

**Review & Update:**
```dart
await reportService.updateReportStatus(
  reportId,
  ReportStatus.reviewed,
  adminNotes: 'Reviewed and verified.',
);
```

**Get Statistics:**
```dart
final stats = await reportService.getReportsStats();
// Returns: {total, pending, reviewed, resolved, closed}
```

---

## Example Workflow

### Donor Files Complaint:
```dart
await reportService.createReport(
  receiverId: 'receiver-abc123',      // who received
  donorId: 'donor-xyz789',             // who donated (current user)
  requestId: 'req_12345',              // request reference
  donationId: 'don_67890',             // donation reference
  reportType: ReportType.complaint,    // complaint type
  comment: 'Medicine was not collected as agreed',
);
```

### Receiver Files Quality Issue:
```dart
await reportService.createReport(
  receiverId: 'receiver-abc123',       // current user
  donorId: 'donor-xyz789',             // who donated
  requestId: 'req_12345',
  donationId: 'don_67890',
  reportType: ReportType.quality,      // quality issue
  comment: 'Packaging was damaged, medicine inside is leaked',
);
```

### Admin Reviews:
```dart
// Get pending reports
final pending = await reportService.getPendingReports();

// Review and add notes
await reportService.updateReportStatus(
  pending[0].id,
  ReportStatus.reviewed,
  adminNotes: 'Verified complaint. Will contact donor.',
);

// Resolve
await reportService.updateReportStatus(
  pending[0].id,
  ReportStatus.resolved,
  adminNotes: 'Donor agreed to refund. Issue resolved.',
);
```

---

## Database Execution

Run this SQL to create the table:

```bash
# Via Supabase Dashboard:
1. Go to SQL Editor
2. Copy contents from: sql/create_reports_table.sql
3. Execute

# OR via CLI:
supabase db push
```

---

## Integration Checklist

- ✅ SQL Schema created
- ✅ Report model updated with new fields
- ✅ ReportService updated with new methods
- ✅ File Report Page UI created
- ✅ All methods fully documented

## What's Next?

1. **Add Report Button** to request details pages (My Requests & Requested to Me)
2. **Create Admin Reports Dashboard** to review and manage reports
3. **Add Notifications** when report is filed or status changes
4. **Email Integration** to notify users of report decisions
5. **Analytics** dashboard showing report trends

---

## Files Modified/Created

| File | Type | Purpose |
|------|------|---------|
| `sql/create_reports_table.sql` | SQL | Database schema |
| `lib/models/report.dart` | Model | Report data structure |
| `lib/services/report_service.dart` | Service | Database operations |
| `lib/pages/file_report_page.dart` | UI | Report filing form |
| `REPORTS_SYSTEM.md` | Docs | System documentation |

All files are ready to use! 🚀
