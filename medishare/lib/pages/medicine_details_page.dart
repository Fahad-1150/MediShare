import 'package:flutter/material.dart';
import 'package:medishare/models/donation.dart';
import 'package:medishare/services/request_service.dart';
import 'package:medishare/services/user_service.dart';
import 'package:medishare/models/user.dart';
import 'package:provider/provider.dart';
import 'package:medishare/state/auth_state.dart';

// OpenStreetMap imports (NO API)
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlng;

class MedicineDetailsPage extends StatefulWidget {
  final Donation donation;

  const MedicineDetailsPage({super.key, required this.donation});

  @override
  State<MedicineDetailsPage> createState() => _MedicineDetailsPageState();
}

class _MedicineDetailsPageState extends State<MedicineDetailsPage> {
  final _requestService = RequestService();
  final _userService = UserService();
  bool _isRequesting = false;
  UserModel? _donor;

  @override
  void initState() {
    super.initState();
    _loadDonorInfo();
  }

  Future<void> _loadDonorInfo() async {
    try {
      final donor = await _userService.getUserById(widget.donation.donorId);
      setState(() => _donor = donor);
    } catch (e) {}
  }

  Future<void> _requestMedicine() async {
    final auth = context.read<AuthState>();
    if (auth.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to request medicine')),
      );
      return;
    }

    final requestedQuantity = await showDialog<int>(
      context: context,
      builder: (context) => _QuantitySelectionDialog(
        maxQuantity: widget.donation.quantity,
        medicineName: widget.donation.medicineName,
      ),
    );

    if (requestedQuantity == null || requestedQuantity <= 0) return;

    try {
      setState(() => _isRequesting = true);

      await _requestService.createRequest(
        requesterId: auth.user!.userId,
        donorId: widget.donation.donorId,
        medicineName: widget.donation.medicineName,
        medicineType: widget.donation.medicineType,
        quantity: requestedQuantity,
        requesterLocation: auth.user!.location,
        latitude: auth.user!.latitude,
        longitude: auth.user!.longitude,
        reason:
            'Requesting $requestedQuantity units of ${widget.donation.medicineName}',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Request for $requestedQuantity units submitted successfully!',
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isRequesting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final donation = widget.donation;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 4, 113, 78),
        title: const Text('Medicine Details'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                donation.medicineName,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              _buildInfoSection(
                icon: Icons.person,
                title: 'Donor',
                content: _donor?.name ?? 'Loading...',
              ),
              const SizedBox(height: 16),
              _buildLocationSection(),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isRequesting ? null : _requestMedicine,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color.fromARGB(255, 4, 113, 78),
                  ),
                  child: _isRequesting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Request This Medicine',
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🔹 ONLY MAP SECTION CHANGED (OpenStreetMap)
  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Location',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: FlutterMap(
              options: MapOptions(
                initialCenter: latlng.LatLng(
                  widget.donation.latitude,
                  widget.donation.longitude,
                ),
                initialZoom: 15,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.medishare',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: latlng.LatLng(
                        widget.donation.latitude,
                        widget.donation.longitude,
                      ),
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Row(
      children: [
        Icon(icon, size: 24),
        const SizedBox(width: 12),
        Text(content),
      ],
    );
  }
}

/// Quantity dialog (unchanged)
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
  int _selectedQuantity = 1;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Request ${widget.medicineName}'),
      content: Text('Available: ${widget.maxQuantity} units'),
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
