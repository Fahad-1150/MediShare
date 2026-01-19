import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/auth_state.dart';
import '../services/donation_service.dart';
import '../services/user_service.dart';
import '../services/report_service.dart';
import '../services/request_service.dart';
import '../services/chat_service.dart';
import '../models/donation.dart';
import '../models/user.dart';
import '../models/report.dart';
import '../models/request.dart';
import '../models/chat_message.dart';
import '../widgets/medicine_details_dialog.dart';

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  final DonationService _donationService = DonationService();
  final UserService _userService = UserService();
  final ReportService _reportService = ReportService();
  final RequestService _requestService = RequestService();
  final ChatService _chatService = ChatService();
  int _expandedSection = -1;
  String _userSearchFilter = '';
  String _requestSearchFilter = '';
  String _medicineSearchFilter = '';
  String _reportSearchFilter = '';
  String _chatSearchFilter = '';

  // Filters and Sorting
  String _requestStatusFilter = 'All';
  bool _requestSortNewest = true;

  String _userRoleFilter = 'All';
  bool _userSortNewest = true;

  String _medicineStatusFilter = 'All';
  bool _medicineSortNewest = true;

  bool _chatSortNewest = true;

  String _reportStatusFilter = 'All';
  bool _reportSortNewest = true;

  // Verification Queue Filters
  String _verificationSearchFilter = '';
  String _verificationExpiryFilter = 'All'; // All, Expiring Soon, Fresh
  String _verificationDonorFilter = '';
  String _verificationApprovalFilter = 'Pending'; // Pending, All

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();

    if (!auth.isAdmin) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outlined, size: 64, color: Colors.red.shade300),
              const SizedBox(height: 24),
              const Text(
                'Access Denied',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'You do not have admin privileges',
                style: TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 32),
            _buildVerificationQueue(),
            const SizedBox(height: 32),
            _buildViewAllRequestsSection(),
            const SizedBox(height: 24),
            _buildViewAllUsersSection(),
            const SizedBox(height: 24),
            _buildViewAllMedicinesSection(),
            const SizedBox(height: 24),
            _buildViewAllChatsSection(),
            const SizedBox(height: 24),
            _buildViewAllReportsSection(),
            const SizedBox(height: 32),
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
              'Admin Control',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Donation Verification & Management',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.admin_panel_settings,
            color: Colors.red.shade600,
            size: 24,
          ),
        ),
      ],
    );
  }

  Widget _buildVerificationQueue() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Verification Queue',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Pending Review',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber.shade700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Search Filter by Medicine Name
        TextField(
          decoration: InputDecoration(
            hintText: 'Search by medicine name...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          onChanged: (value) =>
              setState(() => _verificationSearchFilter = value),
        ),
        const SizedBox(height: 12),
        // Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              // Expiring Soon Filter
              FilterChip(
                label: const Text('Expiring Soon (≤7 days)'),
                selected: _verificationExpiryFilter == 'Expiring Soon',
                onSelected: (selected) => setState(() {
                  _verificationExpiryFilter = selected
                      ? 'Expiring Soon'
                      : 'All';
                }),
                backgroundColor: Colors.grey.shade200,
                selectedColor: Colors.orange.shade300,
              ),
              const SizedBox(width: 8),
              // Fresh Stock Filter
              FilterChip(
                label: const Text('Fresh Stock (>7 days)'),
                selected: _verificationExpiryFilter == 'Fresh',
                onSelected: (selected) => setState(() {
                  _verificationExpiryFilter = selected ? 'Fresh' : 'All';
                }),
                backgroundColor: Colors.grey.shade200,
                selectedColor: Colors.green.shade300,
              ),
              const SizedBox(width: 8),
              // All Status Filter
              FilterChip(
                label: const Text('Show All Status'),
                selected: _verificationApprovalFilter == 'All',
                onSelected: (selected) => setState(() {
                  _verificationApprovalFilter = selected ? 'All' : 'Pending';
                }),
                backgroundColor: Colors.grey.shade200,
                selectedColor: Colors.blue.shade300,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Search Filter by Donor Name
        TextField(
          decoration: InputDecoration(
            hintText: 'Search by donor name...',
            prefixIcon: const Icon(Icons.person),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          onChanged: (value) =>
              setState(() => _verificationDonorFilter = value),
        ),
        const SizedBox(height: 16),
        FutureBuilder<List<Donation>>(
          future: _donationService.getPendingDonations(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            var donations = snapshot.data ?? [];

            // Apply Filters
            // Filter by medicine name
            if (_verificationSearchFilter.isNotEmpty) {
              donations = donations
                  .where(
                    (d) => (d.medicineName ?? '').toLowerCase().contains(
                      _verificationSearchFilter.toLowerCase(),
                    ),
                  )
                  .toList();
            }

            // Filter by expiry date
            if (_verificationExpiryFilter == 'Expiring Soon') {
              donations = donations.where((d) {
                final daysUntilExpiry = d.expiryDate
                    .difference(DateTime.now())
                    .inDays;
                return daysUntilExpiry >= 0 && daysUntilExpiry <= 7;
              }).toList();
            } else if (_verificationExpiryFilter == 'Fresh') {
              donations = donations.where((d) {
                final daysUntilExpiry = d.expiryDate
                    .difference(DateTime.now())
                    .inDays;
                return daysUntilExpiry > 7;
              }).toList();
            }

            if (donations.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Text(
                    'No donations match your filters',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ),
              );
            }

            return FutureBuilder<List<UserModel>>(
              future: _userService.getAllUsers(),
              builder: (context, userSnapshot) {
                final users = userSnapshot.data ?? [];

                // Filter by donor name
                var filteredDonations = donations;
                if (_verificationDonorFilter.isNotEmpty && users.isNotEmpty) {
                  final filteredUserIds = users
                      .where(
                        (u) => (u.name ?? '').toLowerCase().contains(
                          _verificationDonorFilter.toLowerCase(),
                        ),
                      )
                      .map((u) => u.userId)
                      .toList();
                  filteredDonations = filteredDonations
                      .where((d) => filteredUserIds.contains(d.donorId))
                      .toList();
                }

                if (filteredDonations.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Text(
                        'No donations match your filters',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredDonations.length,
                  itemBuilder: (context, index) {
                    return _buildDonationCard(filteredDonations[index]);
                  },
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildDonationCard(Donation donation) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      donation.donationId,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal.shade600,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      donation.medicineName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${donation.medicineType} • ${donation.donorLocation}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Icon(
                  Icons.medication,
                  color: Colors.grey.shade400,
                  size: 32,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      'Quantity',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${donation.quantity}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(width: 1, height: 30, color: Colors.grey.shade300),
                Column(
                  children: [
                    Text(
                      'Expiry',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${donation.expiryDate.year}-${donation.expiryDate.month.toString().padLeft(2, '0')}-${donation.expiryDate.day.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(width: 1, height: 30, color: Colors.grey.shade300),
                Column(
                  children: [
                    Text(
                      'Status',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Pending',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) =>
                          MedicineDetailsDialog(donation: donation),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  child: const Text(
                    'See Details',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    await _donationService.updateDonationStatus(
                      donation.donationId,
                      DonationStatus.approved,
                    );
                    setState(() {});
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Approved: ${donation.medicineName}'),
                          backgroundColor: Colors.teal,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade600,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  child: const Text(
                    'Approve',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    await _donationService.updateDonationStatus(
                      donation.donationId,
                      DonationStatus.rejected,
                    );
                    setState(() {});
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Rejected: ${donation.medicineName}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade500,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(color: Colors.red.shade200),
                  ),
                  child: Text(
                    'Reject',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade500,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildViewAllRequestsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() {
            _expandedSection = _expandedSection == 3 ? -1 : 3;
          }),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _expandedSection == 3
                  ? Colors.purple.shade50
                  : Colors.grey.shade800,
              borderRadius: BorderRadius.circular(16),
              border: _expandedSection == 3
                  ? Border.all(color: Colors.purple.shade300, width: 2)
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'View All Medicine Requests',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: _expandedSection == 3
                        ? Colors.purple.shade900
                        : Colors.white,
                  ),
                ),
                Icon(
                  _expandedSection == 3 ? Icons.expand_less : Icons.expand_more,
                  color: _expandedSection == 3
                      ? Colors.purple
                      : Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
        if (_expandedSection == 3) ...[
          const SizedBox(height: 12),
          TextField(
            decoration: InputDecoration(
              hintText: 'Search requests by medicine name...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onChanged: (value) => setState(() => _requestSearchFilter = value),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _requestStatusFilter,
                  decoration: InputDecoration(
                    labelText: 'Status',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items:
                      [
                            'All',
                            'Pending',
                            'Approved',
                            'Fulfilled',
                            'Rejected',
                            'Cancelled',
                            'Received',
                          ]
                          .map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                          )
                          .toList(),
                  onChanged: (v) => setState(() => _requestStatusFilter = v!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<bool>(
                  value: _requestSortNewest,
                  decoration: InputDecoration(
                    labelText: 'Sort',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: true, child: Text('Newest')),
                    DropdownMenuItem(value: false, child: Text('Oldest')),
                  ],
                  onChanged: (v) => setState(() => _requestSortNewest = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<dynamic>>(
            future: _requestService.getAllRequests(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'No requests found',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),
                );
              }

              // Cast to typed list for processing
              var requests = List<MedicineRequest>.from(snapshot.data!);

              // Filter by Status
              if (_requestStatusFilter != 'All') {
                requests = requests
                    .where(
                      (r) =>
                          r.status.toString().split('.').last.toLowerCase() ==
                          _requestStatusFilter.toLowerCase(),
                    )
                    .toList();
              }

              // Filter by Search
              if (_requestSearchFilter.isNotEmpty) {
                requests = requests
                    .where(
                      (r) => (r.medicineName).toLowerCase().contains(
                        _requestSearchFilter.toLowerCase(),
                      ),
                    )
                    .toList();
              }

              // Sort
              requests.sort(
                (a, b) => _requestSortNewest
                    ? b.createdAt.compareTo(a.createdAt)
                    : a.createdAt.compareTo(b.createdAt),
              );

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: requests.length,
                itemBuilder: (context, index) {
                  final request = requests[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    request.medicineName ?? 'N/A',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'ID: ${request.requestId ?? 'N/A'}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.purple.shade100,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _getStatusString(request.status),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Quantity: ${request.quantity ?? 0} | Type: ${request.medicineType ?? 'N/A'}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _showRequestDetails(request),
                                icon: const Icon(Icons.info, size: 16),
                                label: const Text('Details'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () =>
                                    _deleteRequest(request.requestId),
                                icon: const Icon(Icons.delete, size: 16),
                                label: const Text('Delete'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: const BorderSide(color: Colors.red),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildViewAllUsersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() {
            _expandedSection = _expandedSection == 0 ? -1 : 0;
          }),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _expandedSection == 0
                  ? Colors.blue.shade50
                  : Colors.grey.shade800,
              borderRadius: BorderRadius.circular(16),
              border: _expandedSection == 0
                  ? Border.all(color: Colors.blue.shade300, width: 2)
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'View All Users',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: _expandedSection == 0
                        ? Colors.blue.shade900
                        : Colors.white,
                  ),
                ),
                Icon(
                  _expandedSection == 0 ? Icons.expand_less : Icons.expand_more,
                  color: _expandedSection == 0
                      ? Colors.blue
                      : Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
        if (_expandedSection == 0) ...[
          const SizedBox(height: 12),
          TextField(
            decoration: InputDecoration(
              hintText: 'Search users by name or email...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onChanged: (value) => setState(() => _userSearchFilter = value),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _userRoleFilter,
                  decoration: InputDecoration(
                    labelText: 'Role',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: ['All', 'User', 'Admin']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => setState(() => _userRoleFilter = v!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<bool>(
                  value: _userSortNewest,
                  decoration: InputDecoration(
                    labelText: 'Sort',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: true, child: Text('Newest')),
                    DropdownMenuItem(value: false, child: Text('Oldest')),
                  ],
                  onChanged: (v) => setState(() => _userSortNewest = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<dynamic>>(
            future: _userService.getAllUsers(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'No users found',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),
                );
              }

              var users = List<UserModel>.from(snapshot.data!);

              // Filter by Role
              if (_userRoleFilter != 'All') {
                users = users
                    .where(
                      (u) =>
                          u.role.toString().split('.').last.toLowerCase() ==
                          _userRoleFilter.toLowerCase(),
                    )
                    .toList();
              }

              // Filter by Search
              if (_userSearchFilter.isNotEmpty) {
                final query = _userSearchFilter.toLowerCase();
                users = users
                    .where(
                      (u) =>
                          (u.name).toLowerCase().contains(query) ||
                          (u.email).toLowerCase().contains(query),
                    )
                    .toList();
              }

              // Sort
              users.sort(
                (a, b) => _userSortNewest
                    ? b.createdAt.compareTo(a.createdAt)
                    : a.createdAt.compareTo(b.createdAt),
              );

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    user.email,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: user.role == UserRole.admin
                                    ? Colors.red.shade100
                                    : Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                user.role
                                    .toString()
                                    .split('.')
                                    .last
                                    .toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: user.role == UserRole.admin
                                      ? Colors.red.shade700
                                      : Colors.blue.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Location: ${user.location}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _showUserDetails(user),
                                icon: const Icon(Icons.edit, size: 16),
                                label: const Text('Edit'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _deleteUser(user.userId),
                                icon: const Icon(Icons.delete, size: 16),
                                label: const Text('Delete'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: const BorderSide(color: Colors.red),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildViewAllMedicinesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() {
            _expandedSection = _expandedSection == 1 ? -1 : 1;
          }),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _expandedSection == 1
                  ? Colors.green.shade50
                  : Colors.grey.shade800,
              borderRadius: BorderRadius.circular(16),
              border: _expandedSection == 1
                  ? Border.all(color: Colors.green.shade300, width: 2)
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'View All Medicines',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: _expandedSection == 1
                        ? Colors.green.shade900
                        : Colors.white,
                  ),
                ),
                Icon(
                  _expandedSection == 1 ? Icons.expand_less : Icons.expand_more,
                  color: _expandedSection == 1
                      ? Colors.green
                      : Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
        if (_expandedSection == 1) ...[
          const SizedBox(height: 12),
          TextField(
            decoration: InputDecoration(
              hintText: 'Search medicines by name...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onChanged: (value) => setState(() => _medicineSearchFilter = value),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _medicineStatusFilter,
                  decoration: InputDecoration(
                    labelText: 'Status',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items:
                      [
                            'All',
                            'Pending',
                            'Approved',
                            'Claimed',
                            'Expired',
                            'Rejected',
                          ]
                          .map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                          )
                          .toList(),
                  onChanged: (v) => setState(() => _medicineStatusFilter = v!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<bool>(
                  value: _medicineSortNewest,
                  decoration: InputDecoration(
                    labelText: 'Sort',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: true, child: Text('Newest')),
                    DropdownMenuItem(value: false, child: Text('Oldest')),
                  ],
                  onChanged: (v) => setState(() => _medicineSortNewest = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<Donation>>(
            future: _donationService.getAllDonations(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'No medicines found',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),
                );
              }

              var donations = List<Donation>.from(snapshot.data!);

              // Filter by Status
              if (_medicineStatusFilter != 'All') {
                donations = donations
                    .where(
                      (d) =>
                          d.status.toString().split('.').last.toLowerCase() ==
                          _medicineStatusFilter.toLowerCase(),
                    )
                    .toList();
              }

              // Filter by Search
              if (_medicineSearchFilter.isNotEmpty) {
                donations = donations
                    .where(
                      (d) => d.medicineName.toLowerCase().contains(
                        _medicineSearchFilter.toLowerCase(),
                      ),
                    )
                    .toList();
              }

              // Sort
              donations.sort(
                (a, b) => _medicineSortNewest
                    ? b.createdAt.compareTo(a.createdAt)
                    : a.createdAt.compareTo(b.createdAt),
              );

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: donations.length,
                itemBuilder: (context, index) {
                  final donation = donations[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                donation.medicineName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: donation.status == DonationStatus.pending
                                    ? Colors.orange.shade100
                                    : donation.status == DonationStatus.approved
                                    ? Colors.green.shade100
                                    : Colors.red.shade100,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                donation.status
                                    .toString()
                                    .split('.')
                                    .last
                                    .toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      donation.status == DonationStatus.pending
                                      ? Colors.orange.shade700
                                      : donation.status ==
                                            DonationStatus.approved
                                      ? Colors.green.shade700
                                      : Colors.red.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Type: ${donation.medicineType}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Qty: ${donation.quantity} | Expires: ${donation.expiryDate}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'From: ${donation.donorLocation}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _showMedicineDetails(donation),
                                icon: const Icon(Icons.edit, size: 16),
                                label: const Text('Edit'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () =>
                                    _deleteMedicine(donation.donationId),
                                icon: const Icon(Icons.delete, size: 16),
                                label: const Text('Delete'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: const BorderSide(color: Colors.red),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildViewAllReportsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() {
            _expandedSection = _expandedSection == 2 ? -1 : 2;
          }),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _expandedSection == 2
                  ? Colors.red.shade50
                  : Colors.grey.shade800,
              borderRadius: BorderRadius.circular(16),
              border: _expandedSection == 2
                  ? Border.all(color: Colors.red.shade300, width: 2)
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'View All Reports',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: _expandedSection == 2
                        ? Colors.red.shade900
                        : Colors.white,
                  ),
                ),
                Icon(
                  _expandedSection == 2 ? Icons.expand_less : Icons.expand_more,
                  color: _expandedSection == 2
                      ? Colors.red
                      : Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
        if (_expandedSection == 2) ...[
          const SizedBox(height: 12),
          TextField(
            decoration: InputDecoration(
              hintText: 'Search reports by type...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onChanged: (value) => setState(() => _reportSearchFilter = value),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _reportStatusFilter,
                  decoration: InputDecoration(
                    labelText: 'Status',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: ['All', 'Pending', 'Reviewed', 'Resolved', 'Closed']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => setState(() => _reportStatusFilter = v!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<bool>(
                  value: _reportSortNewest,
                  decoration: InputDecoration(
                    labelText: 'Sort',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: true, child: Text('Newest')),
                    DropdownMenuItem(value: false, child: Text('Oldest')),
                  ],
                  onChanged: (v) => setState(() => _reportSortNewest = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<dynamic>>(
            future: _reportService.getAllReports(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'No reports found',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),
                );
              }

              var reports = List<Report>.from(snapshot.data!);

              // Filter by Status
              if (_reportStatusFilter != 'All') {
                reports = reports
                    .where(
                      (r) =>
                          r.status.toString().split('.').last.toLowerCase() ==
                          _reportStatusFilter.toLowerCase(),
                    )
                    .toList();
              }

              // Filter by Search (Type)
              if (_reportSearchFilter.isNotEmpty) {
                reports = reports
                    .where(
                      (r) => r.reportType
                          .toString()
                          .split('.')
                          .last
                          .toLowerCase()
                          .contains(_reportSearchFilter.toLowerCase()),
                    )
                    .toList();
              }

              // Sort
              reports.sort(
                (a, b) => _reportSortNewest
                    ? b.createdAt.compareTo(a.createdAt)
                    : a.createdAt.compareTo(b.createdAt),
              );

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: reports.length,
                itemBuilder: (context, index) {
                  final report = reports[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                report.reportType
                                    .toString()
                                    .split('.')
                                    .last
                                    .toUpperCase(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.yellow.shade100,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                report.status
                                    .toString()
                                    .split('.')
                                    .last
                                    .toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.yellow.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Description: ${report.comment}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Reported by: ${report.reporterId}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Date: ${report.createdAt}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _showReportDetails(report),
                                icon: const Icon(Icons.info, size: 16),
                                label: const Text('Details'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _deleteReport(report.id),
                                icon: const Icon(Icons.delete, size: 16),
                                label: const Text('Delete'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: const BorderSide(color: Colors.red),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildViewAllChatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() {
            _expandedSection = _expandedSection == 4 ? -1 : 4;
          }),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _expandedSection == 4
                  ? Colors.indigo.shade50
                  : Colors.grey.shade800,
              borderRadius: BorderRadius.circular(16),
              border: _expandedSection == 4
                  ? Border.all(color: Colors.indigo.shade300, width: 2)
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'View All Chat Messages',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: _expandedSection == 4
                        ? Colors.indigo.shade900
                        : Colors.white,
                  ),
                ),
                Icon(
                  _expandedSection == 4 ? Icons.expand_less : Icons.expand_more,
                  color: _expandedSection == 4
                      ? Colors.indigo
                      : Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
        if (_expandedSection == 4) ...[
          const SizedBox(height: 12),
          TextField(
            decoration: InputDecoration(
              hintText: 'Search messages by sender/receiver...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onChanged: (value) => setState(() => _chatSearchFilter = value),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<bool>(
                  value: _chatSortNewest,
                  decoration: InputDecoration(
                    labelText: 'Sort',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: true, child: Text('Newest')),
                    DropdownMenuItem(value: false, child: Text('Oldest')),
                  ],
                  onChanged: (v) => setState(() => _chatSortNewest = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<dynamic>>(
            future: _chatService.getAllMessages(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'No messages found',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),
                );
              }

              var messages = List<ChatMessage>.from(snapshot.data!);

              // Filter by Search
              if (_chatSearchFilter.isNotEmpty) {
                final query = _chatSearchFilter.toLowerCase();
                messages = messages
                    .where(
                      (m) =>
                          (m.senderId ?? '').toLowerCase().contains(query) ||
                          (m.recipientId ?? '').toLowerCase().contains(query),
                    )
                    .toList();
              }

              // Sort
              messages.sort(
                (a, b) => _chatSortNewest
                    ? b.createdAt.compareTo(a.createdAt)
                    : a.createdAt.compareTo(b.createdAt),
              );

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'From: ${message.senderId ?? 'N/A'} To: ${message.recipientId ?? 'N/A'}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Message: ${(message.message ?? 'No content').length > 50 ? '${(message.message ?? 'No content').substring(0, 50)}...' : message.message ?? 'No content'}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: (message.isRead ?? false)
                                    ? Colors.green.shade100
                                    : Colors.yellow.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                (message.isRead ?? false) ? 'READ' : 'UNREAD',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: (message.isRead ?? false)
                                      ? Colors.green.shade700
                                      : Colors.yellow.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Time: ${message.createdAt ?? 'N/A'}',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: () => _deleteMessage(message.id),
                          icon: const Icon(Icons.delete, size: 16),
                          label: const Text('Delete Message'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ],
    );
  }

  // Delete methods
  void _deleteRequest(String? requestId) {
    if (requestId == null) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Request?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _requestService.deleteRequest(requestId);
                Navigator.pop(context);
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Request deleted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _deleteUser(String? userId) {
    if (userId == null) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User?'),
        content: const Text(
          'This will remove all user data. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _userService.deleteUser(userId);
                Navigator.pop(context);
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('User deleted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _deleteMedicine(String? medicineId) {
    if (medicineId == null) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Medicine?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _donationService.deleteDonation(medicineId);
                Navigator.pop(context);
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Medicine deleted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _deleteReport(String? reportId) {
    if (reportId == null) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Report?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _reportService.deleteReport(reportId);
                Navigator.pop(context);
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Report deleted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _deleteMessage(String? messageId) {
    if (messageId == null) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _chatService.deleteMessage(messageId);
                Navigator.pop(context);
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Message deleted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // Detail view methods
  void _showRequestDetails(dynamic request) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('ID', request.requestId ?? 'N/A'),
              _buildDetailRow('Medicine', request.medicineName ?? 'N/A'),
              _buildDetailRow('Type', request.medicineType ?? 'N/A'),
              _buildDetailRow('Quantity', '${request.quantity ?? 0}'),
              _buildDetailRow('Status', _getStatusString(request.status)),
              _buildDetailRow('Requester', request.requesterId ?? 'N/A'),
              _buildDetailRow('Location', request.requesterLocation ?? 'N/A'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showUserDetails(dynamic user) {
    final userModel = user as UserModel;
    final nameController = TextEditingController(text: userModel.name);
    final emailController = TextEditingController(text: userModel.email);
    final phoneController = TextEditingController(text: userModel.phone);
    final locationController = TextEditingController(text: userModel.location);
    UserRole selectedRole = userModel.role;
    bool isVerified = userModel.isVerified;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Edit User Details'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDetailRow('ID', userModel.userId),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: locationController,
                    decoration: const InputDecoration(
                      labelText: 'Location',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Verified User'),
                    value: isVerified,
                    onChanged: (val) => setState(() => isVerified = val),
                    activeColor: const Color.fromARGB(255, 4, 113, 78),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Role',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  DropdownButton<UserRole>(
                    value: selectedRole,
                    isExpanded: true,
                    items: UserRole.values.map((role) {
                      return DropdownMenuItem(
                        value: role,
                        child: Text(
                          role.toString().split('.').last.toUpperCase(),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => selectedRole = val);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    final updatedUser = userModel.copyWith(
                      name: nameController.text,
                      email: emailController.text,
                      phone: phoneController.text,
                      location: locationController.text,
                      role: selectedRole,
                      isVerified: isVerified,
                    );
                    await _userService.updateUser(updatedUser);
                    if (mounted) {
                      Navigator.pop(context);
                      this.setState(() {}); // Refresh parent list
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('User updated successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 4, 113, 78),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showMedicineDetails(Donation donation) {
    showDialog(
      context: context,
      builder: (context) => MedicineDetailsDialog(donation: donation),
    );
  }

  void _showReportDetails(dynamic report) {
    final feedbackController = TextEditingController(
      text: report.adminNotes ?? '',
    );
    ReportStatus selectedStatus = report.status;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Report Details'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDetailRow('ID', report.id),
                  _buildDetailRow(
                    'Type',
                    report.reportType.toString().split('.').last,
                  ),
                  _buildDetailRow('Description', report.comment),
                  _buildDetailRow(
                    'Status',
                    report.status.toString().split('.').last,
                  ),
                  _buildDetailRow('Reported By', report.reporterId),
                  _buildDetailRow('Date', report.createdAt.toString()),
                  const SizedBox(height: 16),
                  const Text(
                    'Update Status',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<ReportStatus>(
                    value: selectedStatus,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: ReportStatus.values.map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Text(
                          status.toString().split('.').last.toUpperCase(),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => selectedStatus = value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Admin Feedback',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: feedbackController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Enter feedback...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await _reportService.updateReportStatus(
                      report.id,
                      selectedStatus,
                      adminNotes: feedbackController.text,
                    );
                    if (mounted) {
                      Navigator.pop(context);
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Report updated successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 4, 113, 78),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Update Report'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  /// Helper method to safely convert status to uppercase string
  String _getStatusString(dynamic status) {
    if (status == null) return 'N/A';
    if (status is String) return status.toUpperCase();
    return status.toString().split('.').last.toUpperCase();
  }
}
