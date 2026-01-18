import 'package:flutter/material.dart';
import 'dart:convert';
import '../models/donation.dart';
import '../services/donation_service.dart';

class MedicineListPage extends StatefulWidget {
  const MedicineListPage({super.key});

  @override
  State<MedicineListPage> createState() => _MedicineListPageState();
}

class _MedicineListPageState extends State<MedicineListPage> {
  final DonationService _donationService = DonationService();
  String searchTerm = '';
  String filterType = 'All';
  late Future<List<Donation>> _medicinesFuture;

  @override
  void initState() {
    super.initState();
    _medicinesFuture = _donationService.getApprovedDonations();
  }

  List<String> get medicineTypes {
    return [
      'All',
      'Tablet',
      'Capsule',
      'Injection',
      'Syrup',
      'Ointment',
      'Powder',
    ];
  }

  List<Donation> _filterMedicines(List<Donation> medicines) {
    return medicines.where((medicine) {
      final matchesSearch =
          medicine.medicineName.toLowerCase().contains(
            searchTerm.toLowerCase(),
          ) ||
          medicine.medicineType.toLowerCase().contains(
            searchTerm.toLowerCase(),
          ) ||
          medicine.donorLocation.toLowerCase().contains(
            searchTerm.toLowerCase(),
          );

      final matchesType =
          filterType == 'All' || medicine.medicineType == filterType;

      // Only show approved and not expired medicines
      final isValid =
          medicine.status == DonationStatus.approved && !medicine.isExpired;

      return matchesSearch && matchesType && isValid;
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
              'Browse donations shared by verified community members.',
              style: TextStyle(color: Colors.black54, fontSize: 14),
            ),
            const SizedBox(height: 24),
            _searchBar(),
            const SizedBox(height: 16),
            _filterChips(),
            const SizedBox(height: 24),
            FutureBuilder<List<Donation>>(
              future: _medicinesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return _errorState(snapshot.error.toString());
                }

                final medicines = snapshot.data ?? [];
                final filtered = _filterMedicines(medicines);

                if (filtered.isEmpty) {
                  return _emptyState();
                }

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.7,
                  ),
                  itemBuilder: (_, index) {
                    return _buildDonationCard(filtered[index]);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _searchBar() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Search medicine name, type or location',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      onChanged: (value) {
        setState(() => searchTerm = value);
      },
    );
  }

  Widget _filterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: medicineTypes.map((type) {
          final active = filterType == type;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ChoiceChip(
              label: Text(type),
              selected: active,
              onSelected: (_) => setState(() => filterType = type),
              selectedColor: Colors.black,
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: active ? Colors.white : Colors.black54,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              shape: StadiumBorder(
                side: BorderSide(
                  color: active ? Colors.black : Colors.grey.shade300,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDonationCard(Donation donation) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/medicine-details', arguments: donation);
      },
      child: Container(
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
            // Medicine Image
            Container(
              height: 140,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: _buildMedicineImage(donation.photoUrl),
            ),
            // Medicine Info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    donation.medicineName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    donation.medicineType,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 12,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          donation.donorLocation,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Qty: ${donation.quantity}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Available',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
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
    );
  }

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.grey.shade200,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: const [
          Icon(Icons.search_off, size: 56, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No medicines found',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 6),
          Text(
            'Try adjusting your search or filters.',
            style: TextStyle(color: Colors.black54, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _errorState(String error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.grey.shade200,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 56, color: Colors.red.shade300),
          const SizedBox(height: 16),
          const Text(
            'Error loading medicines',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Please try again later',
            style: TextStyle(color: Colors.black54, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicineImage(String? photoUrl) {
    if (photoUrl == null || photoUrl.isEmpty) {
      return Center(
        child: Icon(Icons.medication, size: 60, color: Colors.grey.shade400),
      );
    }

    try {
      // Check if it's a valid base64 string
      if (!_isValidBase64(photoUrl)) {
        return Center(
          child: Icon(Icons.medication, size: 60, color: Colors.grey.shade400),
        );
      }

      return ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        child: Image.memory(
          base64Decode(photoUrl),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('Error decoding image: $error');
            return Center(
              child: Icon(
                Icons.medication,
                size: 60,
                color: Colors.grey.shade400,
              ),
            );
          },
        ),
      );
    } catch (e) {
      print('Exception in _buildMedicineImage: $e');
      return Center(
        child: Icon(Icons.medication, size: 60, color: Colors.grey.shade400),
      );
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
}
