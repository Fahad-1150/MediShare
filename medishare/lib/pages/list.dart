import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../state/auth_state.dart';
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
  String locationFilter = 'All'; // 'All', 'NearMe', or specific location
  double? userLatitude;
  double? userLongitude;
  bool isLoadingLocation = false;
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

  Future<void> _getCurrentLocation() async {
    try {
      setState(() => isLoadingLocation = true);

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enable location services')),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permission denied')),
            );
          }
          return;
        }
      }

      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        userLatitude = position.latitude;
        userLongitude = position.longitude;
        locationFilter = 'NearMe';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location enabled! Showing nearby medicines'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => isLoadingLocation = false);
      }
    }
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const p = 0.017453292519943295;
    final a =
        0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }

  List<Donation> _filterMedicines(
    List<Donation> medicines,
    String? currentUserId,
  ) {
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

      // Location filter
      bool matchesLocation = true;
      if (locationFilter == 'NearMe' &&
          userLatitude != null &&
          userLongitude != null) {
        final distance = _calculateDistance(
          userLatitude!,
          userLongitude!,
          medicine.latitude,
          medicine.longitude,
        );
        matchesLocation = distance <= 5; // 5 km radius
      }

      // Only show approved and not expired medicines
      final isValid =
          medicine.status == DonationStatus.approved && !medicine.isExpired;

      final isNotMine =
          currentUserId == null || medicine.donorId != currentUserId;

      return matchesSearch &&
          matchesType &&
          matchesLocation &&
          isValid &&
          isNotMine;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
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
            const SizedBox(height: 16),
            _locationFilter(),
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
                final filtered = _filterMedicines(medicines, auth.user?.userId);

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

  Widget _locationFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Filter by Location',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        const SizedBox(width: 10),
        Row(
          children: [
            Expanded(
              child: ChoiceChip(
                label: const Text('All Locations'),
                selected: locationFilter == 'All',
                onSelected: (_) => setState(() {
                  locationFilter = 'All';
                  userLatitude = null;
                  userLongitude = null;
                }),
                selectedColor: Colors.blue,
                backgroundColor: Colors.white,
                labelStyle: TextStyle(
                  color: locationFilter == 'All'
                      ? Colors.white
                      : Colors.black54,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                shape: StadiumBorder(
                  side: BorderSide(
                    color: locationFilter == 'All'
                        ? Colors.blue
                        : Colors.grey.shade300,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: isLoadingLocation ? null : _getCurrentLocation,
                icon: isLoadingLocation
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            locationFilter == 'NearMe'
                                ? Colors.white
                                : Colors.blue,
                          ),
                        ),
                      )
                    : const Icon(Icons.location_on),
                label: Text(
                  locationFilter == 'NearMe' ? 'Near Me ✓' : 'Near Me',
                  style: const TextStyle(fontSize: 11),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: locationFilter == 'NearMe'
                      ? Colors.green
                      : Colors.white,
                  foregroundColor: locationFilter == 'NearMe'
                      ? Colors.white
                      : Colors.blue,
                  side: BorderSide(
                    color: locationFilter == 'NearMe'
                        ? Colors.green
                        : Colors.blue,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],
        ),
        if (locationFilter == 'NearMe' && userLatitude != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Showing medicines within 5 km',
              style: TextStyle(
                fontSize: 10,
                color: Colors.green.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
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
          crossAxisAlignment:
              CrossAxisAlignment.stretch, // Ensures children take full width
          children: [
            // Medicine Image Header
            ClipRRect(
              // Added to ensure the image corners match the card corners
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: SizedBox(
                height: 140,
                width: double.infinity, // Forces width to fill card
                child: _buildMedicineImage(donation.photoUrl),
              ),
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
