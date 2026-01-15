import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/auth_state.dart';
import '../services/request_service.dart';
import '../services/user_service.dart';
import '../services/donation_service.dart';
import '../models/request.dart';
import '../models/user.dart';
import '../models/donation.dart';

class RequestedToMePage extends StatefulWidget {
  const RequestedToMePage({super.key});

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
      final requests = await _requestService.getRequestsByDonor(userId);

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

        // Load donation info if assigned
        if (request.assignedDonationId != null &&
            !_donations.containsKey(request.assignedDonationId)) {
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

      // Reduce the available quantity instead of claiming the entire donation
      await _donationService.reduceDonationQuantity(
        donation.donationId,
        request.quantity,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Request fulfilled successfully! ${request.quantity} units dispensed.',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Requested to Me',
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
            const Text(
              'All Requests',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Requests for all your donations',
              style: TextStyle(fontSize: 12, color: Colors.grey),
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
                    style: TextStyle(color: Colors.grey),
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
            final donation = request.assignedDonationId != null
                ? _donations[request.assignedDonationId]
                : null;
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
                if (request.status == RequestStatus.approved &&
                    donation != null) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => _fulfillRequest(request, donation),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Mark as Done',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
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
    }
  }

  String _getStatusText(RequestStatus status) {
    switch (status) {
      case RequestStatus.pending:
        return 'PENDING';
      case RequestStatus.approved:
        return 'APPROVED';
      case RequestStatus.fulfilled:
        return 'FULFILLED';
      case RequestStatus.rejected:
        return 'REJECTED';
      case RequestStatus.cancelled:
        return 'CANCELLED';
    }
  }
}
