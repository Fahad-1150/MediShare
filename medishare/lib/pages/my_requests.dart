import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/auth_state.dart';
import '../services/request_service.dart';
import '../services/donation_service.dart';
import '../models/request.dart';
import '../models/donation.dart';
import 'file_report_page.dart';
import 'view_reports_page.dart';
import 'chat_page.dart';

class MyRequestsPage extends StatefulWidget {
  const MyRequestsPage({super.key});

  @override
  State<MyRequestsPage> createState() => _MyRequestsPageState();
}

class _MyRequestsPageState extends State<MyRequestsPage> {
  final RequestService _requestService = RequestService();
  final DonationService _donationService = DonationService();
  late Future<List<MedicineRequest>> _myRequests;
  Map<String, Donation?> _donations = {};
  String statusFilter =
      'All'; // 'All', 'pending', 'approved', 'received', 'cancelled'

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthState>();
    _myRequests = _loadRequests(auth.user!.userId);
  }

  Future<List<MedicineRequest>> _loadRequests(String userId) async {
    try {
      var requests = await _requestService.getRequestsByRequester(userId);

      // Load donation info for approved/fulfilled requests to check availability
      for (final request in requests) {
        if (request.assignedDonationId != null) {
          try {
            final donation = await _donationService.getDonationById(
              request.assignedDonationId!,
            );
            _donations[request.assignedDonationId!] = donation;
          } catch (e) {
            // Handle error silently
          }
        }
      }

      return requests;
    } catch (e) {
      throw Exception('Failed to load requests: $e');
    }
  }

  Future<void> _confirmReceived(MedicineRequest request) async {
    if (request.assignedDonationId == null) return;

    try {
      // Update status to received
      await _requestService.updateRequestStatus(
        request.requestId,
        RequestStatus.received,
      );

      // Reduce the quantity from the donation
      await _donationService.reduceDonationQuantity(
        request.assignedDonationId!,
        request.quantity,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Medicine received! Transaction completed.'),
          ),
        );
        final auth = context.read<AuthState>();
        setState(() {
          _myRequests = _requestService.getRequestsByRequester(
            auth.user!.userId,
          );
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _cancelRequest(MedicineRequest request) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Request?'),
        content: const Text('Are you sure you want to cancel this request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _requestService.updateRequestStatus(
        request.requestId,
        RequestStatus.cancelled,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request cancelled successfully')),
        );
        final auth = context.read<AuthState>();
        setState(() {
          _myRequests = _requestService.getRequestsByRequester(
            auth.user!.userId,
          );
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  List<MedicineRequest> _filterRequests(List<MedicineRequest> requests) {
    if (statusFilter == 'All') return requests;

    return requests.where((request) {
      return request.status.toString().split('.').last == statusFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'My Requests',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildStatusFilter(),
            const SizedBox(height: 24),
            _buildRequestsList(auth),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'My Requests',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Track your medicine requests',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.inbox, color: Colors.blue, size: 24),
        ),
      ],
    );
  }

  Widget _buildStatusFilter() {
    final statuses = ['All', 'pending', 'approved', 'received', 'cancelled'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: statuses.map((status) {
          final isActive = statusFilter == status;
          final statusLabel = status == 'All'
              ? 'All'
              : status == 'pending'
              ? 'Pending'
              : status == 'approved'
              ? 'Approved'
              : status == 'received'
              ? 'Received'
              : 'Cancelled';

          Color getStatusColor(String s) {
            switch (s) {
              case 'pending':
                return Colors.amber;
              case 'approved':
                return Colors.blue;
              case 'received':
                return Colors.green;
              case 'cancelled':
                return Colors.red;
              default:
                return Colors.grey;
            }
          }

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ChoiceChip(
              label: Text(statusLabel),
              selected: isActive,
              onSelected: (_) => setState(() => statusFilter = status),
              selectedColor: getStatusColor(status),
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: isActive ? Colors.white : Colors.black54,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              shape: StadiumBorder(
                side: BorderSide(
                  color: isActive
                      ? getStatusColor(status)
                      : Colors.grey.shade300,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRequestsList(AuthState auth) {
    return FutureBuilder<List<MedicineRequest>>(
      future: _myRequests,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                const SizedBox(height: 16),
                Text(
                  'Error loading requests',
                  style: TextStyle(color: Colors.red.shade300, fontSize: 16),
                ),
              ],
            ),
          );
        }

        final requests = snapshot.data ?? [];
        final filteredRequests = _filterRequests(requests);

        if (requests.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text(
                    'No requests yet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your medicine requests will appear here',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pushNamed(context, '/browse'),
                    child: const Text(
                      'Browse Medicines',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (filteredRequests.isEmpty && requests.isNotEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.filter_alt_off,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No requests with this status',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Try changing the filter',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filteredRequests.length,
          itemBuilder: (context, index) {
            final request = filteredRequests[index];
            final donation = request.assignedDonationId != null
                ? _donations[request.assignedDonationId!]
                : null;

            // Check if donation is unavailable
            final isUnavailable =
                request.status == RequestStatus.approved &&
                donation != null &&
                donation.quantity == 0;

            return _buildRequestCard(request, isUnavailable);
          },
        );
      },
    );
  }

  Widget _buildRequestCard(MedicineRequest request, bool isUnavailable) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isUnavailable ? Colors.red.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnavailable ? Colors.red.shade300 : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Request header with name and status
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: isUnavailable
                        ? Colors.red.shade100
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isUnavailable
                          ? Colors.red.shade300
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Icon(
                    Icons.medical_services,
                    color: isUnavailable
                        ? Colors.red.shade400
                        : Colors.grey.shade400,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.medicineName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        request.medicineType,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isUnavailable
                              ? Colors.red.withOpacity(0.1)
                              : _getStatusColor(
                                  request.status,
                                ).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isUnavailable
                              ? 'UNAVAILABLE'
                              : _getStatusText(request.status),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isUnavailable
                                ? Colors.red
                                : _getStatusColor(request.status),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Details section
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildDetailItem('Quantity', '${request.quantity}'),
                    _buildDetailItem(
                      'Requested',
                      '${request.createdAt.day}/${request.createdAt.month}/${request.createdAt.year}',
                    ),
                    _buildDetailItem('Reason', request.reason ?? 'N/A'),
                  ],
                ),
                const SizedBox(height: 12),
                Container(height: 1, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Location',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        request.requesterLocation,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                if (request.status == RequestStatus.pending ||
                    request.status == RequestStatus.approved) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => _cancelRequest(request),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cancel Request',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ] else if (request.status == RequestStatus.fulfilled) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => _confirmReceived(request),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Mark as Received',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ] else if (request.status == RequestStatus.received) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FileReportPage(
                                  requestId: request.requestId,
                                  donationId: request.assignedDonationId ?? '',
                                  otherUserId: request.donorId ?? '',
                                  isDonor: false,
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
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ViewReportsPage(
                                  requestId: request.requestId,
                                ),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.purple,
                            side: const BorderSide(color: Colors.purple),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'View Reports',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatPage(
                                  requestId: request.requestId,
                                  otherUserId: request.donorId ?? '',
                                  otherUserName: 'Donor',
                                ),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.green,
                            side: const BorderSide(color: Colors.green),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Chat',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else if (request.status == RequestStatus.pending ||
                    request.status == RequestStatus.approved ||
                    request.status == RequestStatus.rejected) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatPage(
                              requestId: request.requestId,
                              otherUserId: request.donorId ?? '',
                              otherUserName: 'Donor',
                            ),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green,
                        side: const BorderSide(color: Colors.green),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Chat with Donor',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Color _getStatusColor(RequestStatus status) {
    switch (status) {
      case RequestStatus.pending:
        return Colors.amber;
      case RequestStatus.approved:
        return Colors.green;
      case RequestStatus.fulfilled:
        return Colors.blue;
      case RequestStatus.rejected:
        return Colors.red;
      case RequestStatus.cancelled:
        return Colors.grey;
      case RequestStatus.received:
        return Colors.teal;
    }
  }

  String _getStatusText(RequestStatus status) {
    switch (status) {
      case RequestStatus.pending:
        return 'REQUESTED';
      case RequestStatus.approved:
        return 'APPROVED';
      case RequestStatus.fulfilled:
        return 'DELIVERED';
      case RequestStatus.rejected:
        return 'REJECTED';
      case RequestStatus.cancelled:
        return 'CANCELLED';
      case RequestStatus.received:
        return 'DONATED';
    }
  }
}
