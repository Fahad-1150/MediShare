import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/auth_state.dart';
import '../services/donation_service.dart';
import '../models/donation.dart';

class RequestPage extends StatefulWidget {
  const RequestPage({super.key});

  @override
  State<RequestPage> createState() => _RequestPageState();
}

class _RequestPageState extends State<RequestPage> {
  final DonationService _donationService = DonationService();

  String _searchTerm = '';
  String _filterType = 'All';
  bool _isLoading = false;
  List<Donation> _donations = [];

  final List<String> _medicineTypes = [
    'All',
    'Tablet',
    'Capsule',
    'Injection',
    'Syrup',
    'Cream',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadDonations();
  }

  Future<void> _loadDonations() async {
    setState(() => _isLoading = true);

    try {
      final donations = await _donationService.getApprovedDonations();
      setState(() {
        _donations = donations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading medicines: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _claimMedicine(Donation donation) async {
    final auth = context.read<AuthState>();

    if (!auth.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to claim medicine')),
      );
      return;
    }

    // Confirm claim
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Claim Medicine?'),
        content: Text(
          'Do you want to claim ${donation.medicineName}?\n\nQuantity: ${donation.quantity} units\nExpiry: ${donation.expiryDate.day}/${donation.expiryDate.month}/${donation.expiryDate.year}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Claim'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _donationService.claimDonation(
        donation.donationId,
        auth.user!.userId,
      );

      await _loadDonations();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Medicine claimed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _reportMedicine(Donation donation) async {
    final auth = context.read<AuthState>();

    if (!auth.isLoggedIn) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please login to report')));
      return;
    }

    // Show report dialog
    showDialog(
      context: context,
      builder: (context) => _ReportDialog(
        donation: donation,
        reporterId: auth.user!.userId,
        onReport: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Report submitted. Admin will review it.'),
              backgroundColor: Colors.orange,
            ),
          );
        },
      ),
    );
  }

  List<Donation> get _filteredDonations {
    return _donations.where((donation) {
      final matchesSearch =
          _searchTerm.isEmpty ||
          donation.medicineName.toLowerCase().contains(
            _searchTerm.toLowerCase(),
          ) ||
          donation.medicineType.toLowerCase().contains(
            _searchTerm.toLowerCase(),
          );

      final matchesType =
          _filterType == 'All' || donation.medicineType == _filterType;

      return matchesSearch && matchesType;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth < 400 ? 1 : 2;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Available Medicines',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            const Text(
              'Browse and request medicines shared by donors',
              style: TextStyle(color: Colors.black54, fontSize: 14),
            ),
            const SizedBox(height: 24),
            // Search bar
            TextField(
              onChanged: (value) => setState(() => _searchTerm = value),
              decoration: InputDecoration(
                hintText: 'Search medicine...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Filter chips
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _medicineTypes.length,
                itemBuilder: (context, index) {
                  final type = _medicineTypes[index];
                  final isSelected = _filterType == type;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(type),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() => _filterType = type);
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            // Results
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_filteredDonations.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Column(
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        size: 64,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No medicines found',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: 0.65,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: _filteredDonations.length,
                itemBuilder: (context, index) {
                  final donation = _filteredDonations[index];
                  return _DonationCard(
                    donation: donation,
                    onClaim: () => _claimMedicine(donation),
                    onReport: () => _reportMedicine(donation),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// Custom donation card with actions
class _DonationCard extends StatelessWidget {
  final Donation donation;
  final VoidCallback onClaim;
  final VoidCallback onReport;

  const _DonationCard({
    required this.donation,
    required this.onClaim,
    required this.onReport,
  });

  @override
  Widget build(BuildContext context) {
    final isExpiringSoon = donation.isExpiringsoon;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image placeholder
          Container(
            height: 120,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              color: Colors.blue.shade50,
            ),
            child: Center(
              child: Icon(
                Icons.medication,
                size: 40,
                color: Colors.blue.shade300,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    donation.medicineName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    donation.medicineType,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${donation.quantity} units',
                        style: const TextStyle(fontSize: 12),
                      ),
                      Text(
                        '${donation.expiryDate.day}/${donation.expiryDate.month}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isExpiringSoon ? Colors.orange : Colors.black,
                          fontWeight: isExpiringSoon
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: onClaim,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            backgroundColor: Colors.blue,
                          ),
                          child: const Text(
                            'Claim',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        onPressed: onReport,
                        icon: const Icon(Icons.report_problem_outlined),
                        iconSize: 18,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Report',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Report medicine dialog
class _ReportDialog extends StatefulWidget {
  final Donation donation;
  final String reporterId;
  final VoidCallback onReport;

  const _ReportDialog({
    required this.donation,
    required this.reporterId,
    required this.onReport,
  });

  @override
  State<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<_ReportDialog> {
  final _reasonController = TextEditingController();
  final _descriptionController = TextEditingController();

  final List<String> _reasons = [
    'Expired medicine',
    'Damaged packaging',
    'Suspicious appearance',
    'Wrong medicine',
    'Other',
  ];

  String _selectedReason = 'Expired medicine';

  @override
  void dispose() {
    _reasonController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Report Medicine'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Why are you reporting this medicine?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            DropdownMenu<String>(
              width: 300,
              initialSelection: _selectedReason,
              onSelected: (String? value) {
                if (value != null) {
                  setState(() => _selectedReason = value);
                }
              },
              dropdownMenuEntries: _reasons
                  .map(
                    (String reason) =>
                        DropdownMenuEntry<String>(value: reason, label: reason),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            const Text(
              'Additional details',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Describe the issue...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: widget.onReport, child: const Text('Report')),
      ],
    );
  }
}
