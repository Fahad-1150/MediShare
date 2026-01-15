import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/auth_state.dart';
import '../services/donation_service.dart';
import '../services/report_service.dart';
import '../services/request_service.dart';
import '../models/donation.dart';

class RequestPage extends StatefulWidget {
  const RequestPage({super.key});

  @override
  State<RequestPage> createState() => _RequestPageState();
}

class _RequestPageState extends State<RequestPage> {
  final DonationService _donationService = DonationService();
  final ReportService _reportService = ReportService();
  final RequestService _requestService = RequestService();

  String _searchTerm = '';
  String _filterType = 'All';
  bool _isLoading = false;
  List<Donation> _donations = [];
  String? _currentUserId;

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
    final auth = context.read<AuthState>();
    _currentUserId = auth.isLoggedIn ? auth.user?.userId : null;
    _loadDonations();
  }

  Future<void> _loadDonations() async {
    setState(() => _isLoading = true);

    try {
      final donations = await _donationService.getApprovedDonations();
      List<Donation> filtered = donations;
      if (_currentUserId != null) {
        filtered = donations.where((d) => d.donorId != _currentUserId).toList();
      }
      setState(() {
        _donations = filtered;
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

  Future<void> _requestMedicine(Donation donation) async {
    final auth = context.read<AuthState>();

    if (!auth.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to request medicine')),
      );
      return;
    }

    // Show quantity selection dialog
    final requestedQuantity = await showDialog<int>(
      context: context,
      builder: (context) => _QuantitySelectionDialog(
        maxQuantity: donation.quantity,
        medicineName: donation.medicineName,
      ),
    );

    if (requestedQuantity == null || requestedQuantity <= 0) return;

    try {
      await _requestService.createRequest(
        requesterId: auth.user!.userId,
        donorId: donation.donorId,
        medicineName: donation.medicineName,
        medicineType: donation.medicineType,
        quantity: requestedQuantity,
        requesterLocation: auth.user!.location,
        latitude: auth.user!.latitude,
        longitude: auth.user!.longitude,
        reason:
            'Requesting ${requestedQuantity} units of ${donation.medicineName}',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Request for ${requestedQuantity} units submitted successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        // Refresh the donations list to show updated quantities
        _loadDonations();
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
        reportService: _reportService,
        onReport: (reason, description) {
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
                  borderSide: const BorderSide(
                    color: Color.fromARGB(255, 4, 113, 78),
                    width: 2,
                  ),
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
                    onRequest: () => _requestMedicine(donation),
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
  final VoidCallback onRequest;
  final VoidCallback onReport;

  const _DonationCard({
    required this.donation,
    required this.onRequest,
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
              color: const Color.fromARGB(255, 4, 113, 78).withOpacity(0.1),
            ),
            child: Center(
              child: Icon(
                Icons.medication,
                size: 40,
                color: const Color.fromARGB(255, 4, 113, 78),
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
                          onPressed: onRequest,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            backgroundColor: const Color.fromARGB(
                              255,
                              4,
                              113,
                              78,
                            ),
                          ),
                          child: const Text(
                            'Request',
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
  final Function(String reason, String description) onReport;
  final ReportService reportService;

  const _ReportDialog({
    required this.donation,
    required this.reporterId,
    required this.onReport,
    required this.reportService,
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
        ElevatedButton(
          onPressed: () async {
            try {
              await widget.reportService.createReport(
                reporterId: widget.reporterId,
                donationId: widget.donation.donationId,
                reason: _selectedReason,
                description: _descriptionController.text,
              );
              if (context.mounted) {
                Navigator.pop(context);
                widget.onReport(_selectedReason, _descriptionController.text);
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error submitting report: $e')),
                );
              }
            }
          },
          child: const Text('Report'),
        ),
      ],
    );
  }
}

/// Quantity selection dialog for medicine requests
class _QuantitySelectionDialog extends StatefulWidget {
  final int maxQuantity;
  final String medicineName;

  const _QuantitySelectionDialog({
    required this.maxQuantity,
    required this.medicineName,
  });

  @override
  State<_QuantitySelectionDialog> createState() =>
      _QuantitySelectionDialogState();
}

class _QuantitySelectionDialogState extends State<_QuantitySelectionDialog> {
  late int _selectedQuantity;

  @override
  void initState() {
    super.initState();
    _selectedQuantity = 1; // Default to 1 unit
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Request ${widget.medicineName}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Available quantity: ${widget.maxQuantity} units'),
          const SizedBox(height: 16),
          const Text(
            'Select quantity to request:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _selectedQuantity > 1
                    ? () => setState(() => _selectedQuantity--)
                    : null,
                icon: const Icon(Icons.remove),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$_selectedQuantity',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: _selectedQuantity < widget.maxQuantity
                    ? () => setState(() => _selectedQuantity++)
                    : null,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Requesting $_selectedQuantity of ${widget.maxQuantity} available units',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _selectedQuantity),
          child: const Text('Request'),
        ),
      ],
    );
  }
}
