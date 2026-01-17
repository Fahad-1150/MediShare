# View Reports Feature Implementation

## Overview
Added a comprehensive "View Reports" page that displays all reports filed for a specific transaction, showing who reported, status, admin comments, and all details.

## Features Implemented

### 1. ViewReportsPage (`lib/pages/view_reports_page.dart`)
A new dedicated page that displays all reports for a transaction with the following:

**Report Display Information:**
- **Report Type Badge**: Color-coded badges showing complaint, feedback, issue, or quality
  - Complaint: Red
  - Feedback: Blue
  - Issue: Orange
  - Quality: Purple
- **Status Badge**: Shows pending, reviewed, resolved, or closed
  - Pending: Amber
  - Reviewed: Blue
  - Resolved: Green
  - Closed: Grey
- **Report Details**: Full comment/description in a styled box
- **Filing Date**: When the report was filed (formatted as DD/MM/YYYY HH:MM)
- **Admin Response**: If available, displays admin notes in a blue highlighted section
- **Resolution Date**: If resolved, shows when it was resolved

**UI Elements:**
- Clean Material Design with card-based layout
- Responsive button layout
- Empty state when no reports exist
- Error handling for failed data loads
- Timestamps for all events

### 2. Updated My Requests Page (`lib/pages/my_requests.dart`)
- Added import for ViewReportsPage
- When request status is RECEIVED (shown as "DONATED"):
  - "File Report" button (blue, left side)
  - "View Reports" button (purple, right side)
  - Buttons are side-by-side in a Row for better UX

### 3. Updated Requested To Me Page (`lib/pages/requested_to_me.dart`)
- Added import for ViewReportsPage
- When request status is RECEIVED (shown as "Donated"):
  - "File Report" button (orange, left side)
  - "View Reports" button (purple, right side)
  - Buttons are side-by-side in a Row for better UX

## Data Flow

```
Transaction Completed (Status: RECEIVED)
    ↓
User clicks "View Reports"
    ↓
ViewReportsPage queries ReportService.getReportsByRequest()
    ↓
All reports for that request are fetched and displayed
    ↓
Each report shows:
    - Who reported (tracked via reporter_id)
    - Report type & status
    - Full comment/details
    - Admin response (if any)
    - Timestamps
```

## Technical Details

**Methods Used:**
- `ReportService.getReportsByRequest(requestId)`: Fetches all reports for a specific transaction
- `Report.fromJson()`: Parses database records into Report objects
- Enum parsing for ReportType and ReportStatus with color mapping

**Color Scheme:**
- Report Types: complaint (red), feedback (blue), issue (orange), quality (purple)
- Report Status: pending (amber), reviewed (blue), resolved (green), closed (grey)
- Admin response section: blue background with blue border

**Formatting:**
- Date/Time: DD/MM/YYYY HH:MM format
- Comments: Multi-line text with 1.5 line height for readability
- Layout: Responsive with proper spacing and sizing

## User Experience

1. **Receiver View** (My Requests Page)
   - After marking donation as received, sees two options
   - Can file a new report or view existing reports
   - Different colored buttons help distinguish actions

2. **Donor View** (Requested To Me Page)
   - After donation marked as received
   - Can file a report about the request or view existing reports
   - Same dual-button interface for consistency

3. **Report Visibility**
   - Both parties involved in transaction can see all reports
   - Admin comments are clearly highlighted
   - Status changes are reflected with color coding

## Integration Points

- ✅ FileReportPage: Files new reports
- ✅ ViewReportsPage: Views existing reports
- ✅ ReportService: Provides data layer
- ✅ Report Model: Data structure with serialization
- ✅ My Requests Page: Receiver's transaction view
- ✅ Requested To Me Page: Donor's transaction view
