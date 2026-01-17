# Integration Guide: Adding Report Buttons

## 1. Add Report Button to "My Requests" Page

In `lib/pages/my_requests.dart`, add this import at the top:
```dart
import 'file_report_page.dart';
```

Then in the `_buildRequestCard()` method, add this button after the "Mark as Received" button:

```dart
if (request.status == RequestStatus.received) ...[
  const SizedBox(height: 8),
  SizedBox(
    width: double.infinity,
    child: OutlinedButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FileReportPage(
              requestId: request.requestId,
              donationId: request.assignedDonationId ?? '',
              otherUserId: request.donorId ?? '',
              isDonor: false, // I'm the receiver
            ),
          ),
        );
      },
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.blue,
        side: const BorderSide(color: Colors.blue),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: const Text(
        'File Report',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
  ),
],
```

**Location in code:**
```dart
else if (request.status == RequestStatus.fulfilled) ...[
  // ... "Mark as Received" button ...
] else if (request.status == RequestStatus.received) ...[
  // ... add report button here ...
]
```

---

## 2. Add Report Button to "Requested to Me" Page

In `lib/pages/requested_to_me.dart`, add this import at the top:
```dart
import 'file_report_page.dart';
```

Then in the `_buildRequestCard()` method, add this button after the "Receiver Confirmed" button:

```dart
else if (request.status == RequestStatus.received)
  Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.green.shade50,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      children: [
        const Text(
          'Donated',
          style: TextStyle(
            color: Colors.green,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FileReportPage(
                    requestId: request.requestId,
                    donationId: request.assignedDonationId ?? '',
                    otherUserId: request.requesterId,
                    isDonor: true, // I'm the donor
                  ),
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.orange,
              side: const BorderSide(color: Colors.orange),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'File Report',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    ),
  )
```

**Replace the existing:**
```dart
else if (request.status == RequestStatus.received)
  const Center(
    child: Text(
      'Donated',
      style: TextStyle(
        color: Colors.green,
        fontWeight: FontWeight.bold,
        fontSize: 14,
      ),
    ),
  ),
```

---

## 3. Create Admin Reports Dashboard (Optional)

Create `lib/pages/admin_reports_page.dart`:

```dart
import 'package:flutter/material.dart';
import '../services/report_service.dart';
import '../models/report.dart';
import 'file_report_page.dart';

class AdminReportsPage extends StatefulWidget {
  const AdminReportsPage({super.key});

  @override
  State<AdminReportsPage> createState() => _AdminReportsPageState();
}

class _AdminReportsPageState extends State<AdminReportsPage> {
  final ReportService _reportService = ReportService();
  late Future<List<Report>> _reports;

  @override
  void initState() {
    super.initState();
    _reports = _reportService.getAllReports();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Reports'),
      ),
      body: FutureBuilder<List<Report>>(
        future: _reports,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final reports = snapshot.data ?? [];

          return ListView.builder(
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];
              return _buildReportCard(report);
            },
          );
        },
      ),
    );
  }

  Widget _buildReportCard(Report report) {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Type: ${report.reportType.toString().split('.').last.toUpperCase()}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(report.status),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    report.status.toString().split('.').last.toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Comment: ${report.comment}'),
            const SizedBox(height: 12),
            Text('Submitted: ${report.createdAt.toString()}'),
            const SizedBox(height: 12),
            if (report.status == ReportStatus.pending)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        await _reportService.updateReportStatus(
                          report.id,
                          ReportStatus.reviewed,
                        );
                        setState(() {
                          _reports = _reportService.getAllReports();
                        });
                      },
                      child: const Text('Mark Reviewed'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        await _reportService.updateReportStatus(
                          report.id,
                          ReportStatus.resolved,
                          adminNotes: 'Resolved by admin',
                        );
                        setState(() {
                          _reports = _reportService.getAllReports();
                        });
                      },
                      child: const Text('Resolve'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(ReportStatus status) {
    switch (status) {
      case ReportStatus.pending:
        return Colors.orange;
      case ReportStatus.reviewed:
        return Colors.blue;
      case ReportStatus.resolved:
        return Colors.green;
      case ReportStatus.closed:
        return Colors.grey;
    }
  }
}
```

---

## 4. Add Route to Main.dart

In `lib/main.dart`, add:

```dart
routes: {
  // ... existing routes ...
  '/file-report': (_) => const FileReportPage(),
  '/admin-reports': (_) => const AdminReportsPage(),
},
```

---

## Testing Checklist

- [ ] User can access "File Report" button on completed transactions
- [ ] Report form displays all report types
- [ ] Comment can be entered and submitted
- [ ] Admin can view all reports
- [ ] Admin can change report status
- [ ] Timestamps are recorded correctly
- [ ] Only relevant users can see their reports

---

## Complete! 🎉

Your reports system is now fully integrated. Users can file reports about any transaction, and admins can manage them!
