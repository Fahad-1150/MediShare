import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import '../state/auth_state.dart';
import '../services/donation_service.dart';
import '../services/request_service.dart';
import '../models/donation.dart';
import 'donate_medicine_page.dart';

class MyMedicinesPage extends StatefulWidget {
  const MyMedicinesPage({super.key});

  @override
  State<MyMedicinesPage> createState() => _MyMedicinesPageState();
}

class _MyMedicinesPageState extends State<MyMedicinesPage> {
  final DonationService _donationService = DonationService();
  final RequestService _requestService = RequestService();
  late Future<List<Donation>> _myMedicines;
  Map<String, int> _requestCounts = {};
  String _filterType = 'all'; // 'all' or 'near-expiry'

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthState>();
    _loadMedicines(auth.user!.userId);
  }

  void _loadMedicines(String userId) {
    setState(() {
      _myMedicines = _donationService.getDonationsByDonor(userId);
    });
    _loadRequestCounts(userId);
  }

  Future<void> _loadRequestCounts(String userId) async {
    final donations = await _donationService.getDonationsByDonor(userId);

    for (final donation in donations) {
      try {
        final requests = await _requestService.getRequestsByDonation(
          donation.donationId,
        );
        setState(() => _requestCounts[donation.donationId] = requests.length);
      } catch (e) {
        // Handle error silently
      }
    }
  }

  Future<void> _deleteMedicine(Donation medicine) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Medicine'),
        content: Text(
          'Are you sure you want to delete ${medicine.medicineName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _donationService.deleteDonation(medicine.donationId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Medicine deleted successfully')),
          );
          final auth = context.read<AuthState>();
          _loadMedicines(auth.user!.userId);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting medicine: $e')),
          );
        }
      }
    }
  }

  Future<void> _editMedicine(Donation medicine) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DonateMedicinePage(donationToEdit: medicine),
      ),
    );
    if (mounted) {
      final auth = context.read<AuthState>();
      _loadMedicines(auth.user!.userId);
    }
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
          'My Medicines',
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
            _buildMedicinesList(auth),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'My Medicines',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _filterType == 'near-expiry'
                      ? 'Expiring within 30 days'
                      : 'All medicines you have added',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.medical_information,
                color: Colors.orange,
                size: 24,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildFilterButtons(),
      ],
    );
  }

  Widget _buildFilterButtons() {
    return Row(
      children: [
        _buildFilterButton('All', 'all'),
        const SizedBox(width: 12),
        _buildFilterButton('Near Expiry (<30 days)', 'near-expiry'),
      ],
    );
  }

  Widget _buildFilterButton(String label, String filterValue) {
    final isActive = _filterType == filterValue;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _filterType = filterValue),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color: isActive ? Colors.orange : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? Colors.orange : Colors.grey.shade300,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isActive ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMedicinesList(AuthState auth) {
    return FutureBuilder<List<Donation>>(
      future: _myMedicines,
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
                  'Error loading medicines',
                  style: TextStyle(color: Colors.red.shade300, fontSize: 16),
                ),
              ],
            ),
          );
        }

        var medicines = snapshot.data ?? [];
        medicines = _filterMedicines(medicines);

        if (medicines.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.medical_information,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _filterType == 'near-expiry'
                        ? 'No medicines expiring soon'
                        : 'No medicines added yet',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _filterType == 'near-expiry'
                        ? 'All your medicines are still fresh!'
                        : 'Start by adding your first medicine',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pushNamed(context, '/donate'),
                    child: const Text(
                      'Add Medicine',
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

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: medicines.length,
          itemBuilder: (context, index) {
            final medicine = medicines[index];
            return _buildMedicineCard(medicine);
          },
        );
      },
    );
  }

  Widget _buildMedicineCard(Donation medicine) {
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
          // Medicine header with name and status
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: _buildMedicineImage(medicine.photoUrl),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medicine.medicineName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        medicine.medicineType,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () {
                          final requestCount =
                              _requestCounts[medicine.donationId] ?? 0;
                          if (requestCount > 0) {
                            Navigator.pushNamed(
                              context,
                              '/requests-to-me',
                              arguments: {
                                'donationId': medicine.donationId,
                                'medicineName': medicine.medicineName,
                              },
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(
                              medicine.status,
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                medicine.status
                                    .toString()
                                    .split('.')
                                    .last
                                    .toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: _getStatusColor(medicine.status),
                                ),
                              ),
                              if (_requestCounts[medicine.donationId] != null &&
                                  _requestCounts[medicine.donationId]! > 0) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${_requestCounts[medicine.donationId]}',
                                    style: const TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ],
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
            decoration: BoxDecoration(color: Colors.grey.shade50),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildDetailItem('Quantity', '${medicine.quantity}'),
                    _buildDetailItem(
                      'Expiry',
                      '${medicine.expiryDate.year}-${medicine.expiryDate.month.toString().padLeft(2, '0')}-${medicine.expiryDate.day.toString().padLeft(2, '0')}',
                    ),
                    _buildDetailItem(
                      'Description',
                      medicine.description ?? 'N/A',
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
                        medicine.donorLocation,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Actions section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _editMedicine(medicine),
                  icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                  label: const Text(
                    'Edit',
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _deleteMedicine(medicine),
                  icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                  label: const Text(
                    'Delete',
                    style: TextStyle(color: Colors.red),
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

  Color _getStatusColor(DonationStatus status) {
    switch (status) {
      case DonationStatus.pending:
        return Colors.amber;
      case DonationStatus.approved:
        return Colors.green;
      case DonationStatus.rejected:
        return Colors.red;
      case DonationStatus.claimed:
        return Colors.blue;
      case DonationStatus.expired:
        return Colors.grey;
    }
  }

  Widget _buildMedicineImage(String? photoUrl) {
    if (photoUrl == null || photoUrl.isEmpty) {
      return Icon(Icons.medication, color: Colors.grey.shade400, size: 32);
    }

    try {
      // Check if it's a valid base64 string
      if (!_isValidBase64(photoUrl)) {
        return Icon(Icons.medication, color: Colors.grey.shade400, size: 32);
      }

      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(
          base64Decode(photoUrl),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('Error decoding image: $error');
            return Icon(
              Icons.medication,
              color: Colors.grey.shade400,
              size: 32,
            );
          },
        ),
      );
    } catch (e) {
      print('Exception in _buildMedicineImage: $e');
      return Icon(Icons.medication, color: Colors.grey.shade400, size: 32);
    }
  }

  bool _isValidBase64(String str) {
    try {
      if (str.isEmpty) return false;
      // Check if string contains only valid base64 characters
      final base64Pattern = RegExp(r'^[A-Za-z0-9+/]*={0,2}$');
      if (!base64Pattern.hasMatch(str)) return false;
      // Try to decode
      base64Decode(str);
      return true;
    } catch (e) {
      return false;
    }
  }

  bool _isExpiringsoon(DateTime expiryDate) {
    final today = DateTime.now();
    final daysUntilExpiry = expiryDate.difference(today).inDays;
    return daysUntilExpiry < 30 && daysUntilExpiry >= 0;
  }

  List<Donation> _filterMedicines(List<Donation> medicines) {
    if (_filterType == 'near-expiry') {
      return medicines
          .where((medicine) => _isExpiringsoon(medicine.expiryDate))
          .toList();
    }
    return medicines;
  }
}
