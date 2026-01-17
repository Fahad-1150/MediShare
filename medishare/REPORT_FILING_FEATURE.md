# Report Filing Feature - Implementation Complete ✅

## Overview
After a donation is successfully completed (status = RECEIVED, shown as "DONATED"), both the donor and receiver can file reports about the transaction.

## How It Works

### For Receivers (My Requests Page)
When a request status changes to **RECEIVED** (marked as Received):
- The page shows a "File Report" button
- Clicking it opens the report form
- Receiver can file complaints, feedback, issues, or quality reports
- Report is linked with their user ID as receiver

### For Donors (Requested to Me Page)
When a request status changes to **RECEIVED** (marked as Donated):
- The page shows a "File Report" button
- Clicking it opens the report form
- Donor can file complaints, feedback, issues, or quality reports
- Report is linked with their user ID as donor

## User Flow

### Scenario 1: Receiver Files Report

```
Receiver's "My Requests" Page
    ↓
Request shows status: RECEIVED (shown as "DONATED")
    ↓
Click "File Report" button
    ↓
FileReportPage opens with:
  - requestId (auto-filled)
  - donationId (auto-filled)
  - otherUserId = donor
  - isDonor = false (receiver)
    ↓
Select report type:
  • Complaint (late delivery, wrong medicine, etc.)
  • Feedback (suggestions, compliments)
  • Issue (technical problem)
  • Quality (damaged, expired, etc.)
    ↓
Enter detailed comment
    ↓
Click "Submit Report"
    ↓
Report saved to database with:
  ✓ receiver_id (current user)
  ✓ donor_id (other user)
  ✓ request_id (transaction)
  ✓ donation_id (which donation)
  ✓ report_type (selected type)
  ✓ comment (what user entered)
  ✓ status = "pending"
  ✓ created_at (timestamp)
```

### Scenario 2: Donor Files Report

```
Donor's "Requested to Me" Page
    ↓
Request shows status: RECEIVED (shown as "DONATED")
    ↓
Click "File Report" button
    ↓
FileReportPage opens with:
  - requestId (auto-filled)
  - donationId (auto-filled)
  - otherUserId = receiver
  - isDonor = true (donor)
    ↓
Select report type:
  • Complaint (medicine not accepted, etc.)
  • Feedback (appreciation, suggestions)
  • Issue (delivery issue)
  • Quality (damage during delivery)
    ↓
Enter detailed comment
    ↓
Click "Submit Report"
    ↓
Report saved to database with:
  ✓ receiver_id (other user)
  ✓ donor_id (current user)
  ✓ request_id (transaction)
  ✓ donation_id (which donation)
  ✓ report_type (selected type)
  ✓ comment (what user entered)
  ✓ status = "pending"
  ✓ created_at (timestamp)
```

## Files Modified

### 1. `lib/pages/my_requests.dart`
- Added import: `import 'file_report_page.dart';`
- Added condition: `else if (request.status == RequestStatus.received)`
- Shows "File Report" button after donation completed
- Button opens FileReportPage with receiver settings

### 2. `lib/pages/requested_to_me.dart`
- Added import: `import 'file_report_page.dart';`
- Updated received status UI to include "File Report" button
- Button opens FileReportPage with donor settings

## Report Button Details

### In "My Requests" (Receiver)
```dart
OutlinedButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FileReportPage(
          requestId: request.requestId,
          donationId: request.assignedDonationId ?? '',
          otherUserId: request.donorId ?? '', // who donated
          isDonor: false, // I'm the receiver
        ),
      ),
    );
  },
  child: const Text('File Report'),
)
```

### In "Requested to Me" (Donor)
```dart
OutlinedButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FileReportPage(
          requestId: request.requestId,
          donationId: request.assignedDonationId ?? '',
          otherUserId: request.requesterId, // who requested
          isDonor: true, // I'm the donor
        ),
      ),
    );
  },
  child: const Text('File Report'),
)
```

## Report Types Available

| Type | Used For |
|------|----------|
| **Complaint** | Report issues or problems (late, wrong medicine, etc.) |
| **Feedback** | Positive/constructive feedback for improvement |
| **Issue** | Technical or delivery issues |
| **Quality** | Medicine condition/quality problems (damaged, expired) |

## Admin Review Process

Admins can:
1. View all pending reports: `/admin-reports`
2. Review report details and comments
3. Add admin notes
4. Change status to: reviewed, resolved, or closed
5. Track which transactions have complaints

## Status Progression

```
PENDING → REVIEWED → RESOLVED → CLOSED
```

- **PENDING**: Just filed, awaiting admin
- **REVIEWED**: Admin has looked at it
- **RESOLVED**: Issue fixed or addressed
- **CLOSED**: Report finalized

## Database Recording

Each report is stored with:
- Receiver and donor IDs (both identified)
- Request and donation references (context)
- Report type (categorization)
- Comment (what happened)
- Status and admin notes (tracking)
- Timestamps (audit trail)

## Testing Checklist

- [ ] Complete a donation (status = RECEIVED)
- [ ] Receiver can see "File Report" button
- [ ] Donor can see "File Report" button
- [ ] Can open FileReportPage from both sides
- [ ] Can select report type
- [ ] Can enter comments
- [ ] Report saves correctly with all fields
- [ ] Admin can view and manage reports

## Complete! 🎉

Both users can now report issues after any completed donation. The reports are tracked, audited, and can be reviewed by admins.
