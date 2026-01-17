# Reports System Documentation

## Overview
A comprehensive reporting system where both donors and receivers can file reports about donations and requests, with admin review capabilities.

## Database Schema

### Reports Table

```sql
CREATE TABLE reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  receiver_id UUID NOT NULL REFERENCES auth.users(id),
  donor_id UUID NOT NULL REFERENCES auth.users(id),
  request_id VARCHAR(255) NOT NULL,
  donation_id VARCHAR(255) NOT NULL,
  report_type VARCHAR(50) CHECK (report_type IN ('complaint', 'feedback', 'issue', 'quality')),
  comment TEXT NOT NULL,
  status VARCHAR(50) DEFAULT 'pending' CHECK (status IN ('pending', 'reviewed', 'resolved', 'closed')),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  admin_notes TEXT,
  resolved_at TIMESTAMP
);
```

## Fields Description

| Field | Type | Description |
|-------|------|-------------|
| `id` | UUID | Unique identifier for the report |
| `receiver_id` | UUID | ID of the user receiving medicine (foreign key to auth.users) |
| `donor_id` | UUID | ID of the user donating medicine (foreign key to auth.users) |
| `request_id` | VARCHAR | Reference to the associated medicine request |
| `donation_id` | VARCHAR | Reference to the associated donation |
| `report_type` | VARCHAR | Type of report: complaint, feedback, issue, or quality |
| `comment` | TEXT | Detailed description/comment about the report |
| `status` | VARCHAR | Report status: pending, reviewed, resolved, or closed |
| `created_at` | TIMESTAMP | When the report was created |
| `updated_at` | TIMESTAMP | When the report was last updated |
| `admin_notes` | TEXT | Notes added by admin during review |
| `resolved_at` | TIMESTAMP | When the report was resolved |

## Enum Types

### ReportType
- **complaint**: User has a complaint about the transaction
- **feedback**: User providing feedback or suggestions
- **issue**: Technical or delivery issue occurred
- **quality**: Quality/condition issue with medicine

### ReportStatus
- **pending**: Report just created, awaiting admin review
- **reviewed**: Admin has reviewed the report
- **resolved**: Issue has been resolved
- **closed**: Report is closed

## Usage

### Creating a Report

**Donor reporting about a transaction:**
```dart
await reportService.createReport(
  receiverId: 'receiver-user-id',
  donorId: 'donor-user-id',
  requestId: 'req_12345',
  donationId: 'don_12345',
  reportType: ReportType.complaint,
  comment: 'Medicine was not picked up as scheduled',
);
```

**Receiver reporting about received medicine:**
```dart
await reportService.createReport(
  receiverId: 'receiver-user-id',
  donorId: 'donor-user-id',
  requestId: 'req_12345',
  donationId: 'don_12345',
  reportType: ReportType.quality,
  comment: 'Medicine packaging was damaged',
);
```

### Retrieving Reports

```dart
// Get reports filed by receiver
List<Report> received = await reportService.getReportsByReceiver(userId);

// Get reports filed against donor
List<Report> filed = await reportService.getReportsByDonor(userId);

// Get all reports for a request
List<Report> reports = await reportService.getReportsByRequest(requestId);

// Get pending reports (admin)
List<Report> pending = await reportService.getPendingReports();

// Get statistics
Map<String, dynamic> stats = await reportService.getReportsStats();
```

### Admin Actions

```dart
// Review and resolve a report
await reportService.updateReportStatus(
  reportId,
  ReportStatus.reviewed,
  adminNotes: 'Verified complaint. Donor action required.',
);

// Mark as resolved
await reportService.updateReportStatus(
  reportId,
  ReportStatus.resolved,
  adminNotes: 'Issue resolved between parties.',
);
```

## Security Features

- **Row Level Security (RLS)** enabled
- Users can only view their own reports
- Admins have full access
- Users can only create reports for their transactions
- Timestamp tracking for audit purposes

## Indexes

- `idx_reports_receiver_id` - Fast lookup by receiver
- `idx_reports_donor_id` - Fast lookup by donor
- `idx_reports_request_id` - Fast lookup by request
- `idx_reports_donation_id` - Fast lookup by donation
- `idx_reports_status` - Fast filtering by status
- `idx_reports_created_at` - Fast sorting and date filtering

## Integration Points

Reports are linked to:
- **Requests Table** - via `request_id`
- **Donations Table** - via `donation_id`
- **Users** - via `receiver_id` and `donor_id`

This allows complete transaction history and dispute resolution tracking.
