import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/auth_state.dart';
import '../services/request_service.dart';
import '../services/user_service.dart';
import '../services/donation_service.dart';
import '../models/request.dart';
import '../models/user.dart';
import '../models/donation.dart';
import 'file_report_page.dart';
import 'view_reports_page.dart';
import 'chat_page.dart';

class RequestedToMePage extends StatefulWidget {
  final String? donationId;
  final String? medicineName;

  const RequestedToMePage({super.key, this.donationId, this.medicineName});

  @override
  State<RequestedToMePage> createState() => _RequestedToMePageState();
}

class _RequestedToMePageState extends State<RequestedToMePage> {
  final RequestService _requestService = RequestService();
  final UserService _userService = UserService();
  final DonationService _donationService = DonationService();
  late Future<List<MedicineRequest>> _requests;
  Map<String, UserModel?> _requesters = {};
  Map<String, Donation?> _donations = {};

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthState>();
    _requests = _loadRequests(auth.user!.userId);
  }

  Future<List<MedicineRequest>> _loadRequests(String userId) async {
    try {
      // Get all requests made to this donor
      var requests = await _requestService.getRequestsByDonor(userId);

      // Filter by medicine name if provided
      if (widget.medicineName != null) {
        requests = requests.where((r) {
          return r.medicineName == widget.medicineName;
        }).toList();
      }

      // Load requester info and donation info for each request
      for (final request in requests) {
        // Load requester info
        if (!_requesters.containsKey(request.requesterId)) {
          try {
            final user = await _userService.getUserById(request.requesterId);
            _requesters[request.requesterId] = user;
          } catch (e) {
            // Handle error silently
          }
        }

        // Load requester info and donation info for each request
        for (final request in requests) {
          // Load requester info
          if (!_requesters.containsKey(request.requesterId)) {
            try {
              final user = await _userService.getUserById(request.requesterId);
              _requesters[request.requesterId] = user;
            } catch (e) {
              // Handle error silently
            }
          }

          // Determine which donation ID to load
          // If we are in a specific donation view, use that ID
          // Otherwise use the assigned donation ID from the request
          final donationIdToLoad =
              widget.donationId ?? request.assignedDonationId;

          // Load donation info if assigned (always load to get updated quantity)
          if (donationIdToLoad != null) {
            try {
              final donation = await _donationService.getDonationById(
                donationIdToLoad,
              );
              _donations[donationIdToLoad] = donation;
            } catch (e) {
              // Handle error silently
            }
          }
        }
      }

      return requests;
    } catch (e) {
      throw Exception('Failed to load requests: $e');
    }
  }

  Future<void> _acceptRequest(MedicineRequest request) async {
    String? selectedDonationId = widget.donationId;

    // If no donation ID was provided, ask user to select one
    if (selectedDonationId == null) {
      selectedDonationId = await _showDonationSelectionDialog(request);
      if (selectedDonationId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a donation to proceed')),
        );
        return;
      }
    }

    try {
      await _requestService.updateRequestStatus(
        request.requestId,
        RequestStatus.approved,
        assignedDonationId: selectedDonationId,
      );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Request accepted')));
        final auth = context.read<AuthState>();
        setState(() {
          _requests = _loadRequests(auth.user!.userId);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<String?> _showDonationSelectionDialog(MedicineRequest request) async {
    final auth = context.read<AuthState>();
    final donations = await _donationService.getDonationsByDonor(
      auth.user!.userId,
    );

    // Filter donations that match the requested medicine
    final matchingDonations = donations
        .where(
          (d) =>
              d.medicineName.toLowerCase() ==
              request.medicineName.toLowerCase(),
        )
        .toList();

    if (matchingDonations.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No matching donations available for this medicine'),
          ),
        );
      }
      return null;
    }

    String? selectedId;

    if (mounted) {
      selectedId = await showDialog<String>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('Select Donation'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: matchingDonations.map((donation) {
                return ListTile(
                  title: Text(
                    '${donation.medicineName} - Qty: ${donation.quantity}',
                  ),
                  subtitle: Text(
                    'Expires: ${donation.expiryDate.day}/${donation.expiryDate.month}/${donation.expiryDate.year}',
                  ),
                  onTap: () => Navigator.pop(context, donation.donationId),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
    }

    return selectedId;
  }

  Future<void> _rejectRequest(MedicineRequest request) async {
    try {
      await _requestService.updateRequestStatus(
        request.requestId,
        RequestStatus.rejected,
      );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Request rejected')));
        final auth = context.read<AuthState>();
        setState(() {
          _requests = _loadRequests(auth.user!.userId);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _fulfillRequest(
    MedicineRequest request,
    Donation donation,
  ) async {
    try {
      await _requestService.updateRequestStatus(
        request.requestId,
        RequestStatus.fulfilled,
        assignedDonationId: donation.donationId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Marked as fulfilled. Waiting for requester confirmation.',
            ),
          ),
        );
        // Refresh the requests
        final auth = context.read<AuthState>();
        setState(() {
          _requests = _loadRequests(auth.user!.userId);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _confirmReceiptAndCompleteDonation(
    MedicineRequest request,
  ) async {
    try {
      // Get the assigned donation to reduce quantity
      if (request.assignedDonationId != null) {
        final donation = await _donationService.getDonationById(
          request.assignedDonationId!,
        );

        if (donation != null) {
          // Reduce the donation quantity
          await _donationService.reduceDonationQuantity(
            request.assignedDonationId!,
            request.quantity,
          );
        }
      }

      // Mark request as received
      await _requestService.updateRequestStatus(
        request.requestId,
        RequestStatus.received,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Donation completed successfully! Quantity reduced.'),
          ),
        );
        // Refresh the requests
        final auth = context.read<AuthState>();
        setState(() {
          _requests = _loadRequests(auth.user!.userId);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          widget.medicineName != null
              ? 'Requests for ${widget.medicineName}'
              : 'Requested to Me',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildRequestsList(),
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
            Text(
              widget.medicineName != null
                  ? 'Requests for ${widget.medicineName}'
                  : 'All Requests',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.medicineName != null
                  ? 'People who requested this medicine'
                  : 'Requests for all your donations',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 4, 113, 78).withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.people_alt,
            color: Color.fromARGB(255, 4, 113, 78),
            size: 24,
          ),
        ),
      ],
    );
  }

  Widget _buildRequestsList() {
    return FutureBuilder<List<MedicineRequest>>(
      future: _requests,
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
                  const Text(
                    'Requests for your donations will appear here',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            // Use the specific donation if provided, otherwise the assigned one
            final donationId = widget.donationId ?? request.assignedDonationId;
            final donation = donationId != null ? _donations[donationId] : null;
            final requester = _requesters[request.requesterId];
            return _buildRequestCard(request, donation, requester);
          },
        );
      },
    );
  }

  Widget _buildRequestCard(
    MedicineRequest request,
    Donation? donation,
    UserModel? requester,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
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
          // Medicine info header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.medication, color: Colors.blue.shade600, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    donation?.medicineName ?? request.medicineName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(request.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _getStatusText(request.status),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(request.status),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Requester info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.green.withOpacity(0.1),
                  child: const Icon(
                    Icons.person,
                    color: Colors.green,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        requester?.name ?? 'Loading...',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        requester?.email ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
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
                    _buildDetailItem('Phone', requester?.phone ?? 'N/A'),
                    _buildDetailItem('Quantity', '${request.quantity}'),
                    _buildDetailItem(
                      'Requested',
                      '${request.createdAt.day}/${request.createdAt.month}/${request.createdAt.year}',
                    ),
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
                if (request.reason != null && request.reason!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(height: 1, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reason',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          request.reason!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                if (request.status == RequestStatus.pending)
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _acceptRequest(request),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Accept',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _rejectRequest(request),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Reject',
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
                                  otherUserId: request.requesterId,
                                  otherUserName: requester?.name ?? 'Requester',
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
                  )
                else if (request.status == RequestStatus.approved)
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: donation != null
                                ? () => _fulfillRequest(request, donation!)
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: donation != null
                                  ? Colors.green
                                  : Colors.grey,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              donation != null
                                  ? 'Mark as Delivered'
                                  : 'Loading donation...',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatPage(
                                    requestId: request.requestId,
                                    otherUserId: request.requesterId,
                                    otherUserName:
                                        requester?.name ?? 'Requester',
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
                              'Chat',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                else if (request.status == RequestStatus.fulfilled)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Waiting for receiver to confirm',
                          style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'The receiver will confirm when they receive the medicine',
                          style: TextStyle(color: Colors.orange, fontSize: 12),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () =>
                                _confirmReceiptAndCompleteDonation(request),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Receiver Confirmed',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
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
                                        donationId:
                                            request.assignedDonationId ?? '',
                                        otherUserId: request.requesterId,
                                        isDonor: true,
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
                                    borderRadius: BorderRadius.circular(8),
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
                                        otherUserId: request.requesterId,
                                        otherUserName:
                                            requester?.name ?? 'Requester',
                                      ),
                                    ),
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.blue,
                                  side: const BorderSide(color: Colors.blue),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
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
                      ],
                    ),
                  ),
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
        return 'PENDING';
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
