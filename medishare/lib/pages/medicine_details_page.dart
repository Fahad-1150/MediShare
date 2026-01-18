import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:medishare/models/donation.dart';
import 'package:medishare/services/request_service.dart';
import 'package:medishare/services/user_service.dart';
import 'package:medishare/models/user.dart';
import 'package:provider/provider.dart';
import 'package:medishare/state/auth_state.dart';
import 'chat_page.dart';

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
      if (mounted) {
        setState(() => _donor = donor);
      }
    } catch (e) {
      // Handle error silently - donor info is optional
    }
  }

  Future<void> _requestMedicine() async {
    final auth = context.read<AuthState>();
    final user = auth.user;
    if (user == null) {
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
        requesterId: user.userId,
        donorId: widget.donation.donorId,
        medicineName: widget.donation.medicineName,
        medicineType: widget.donation.medicineType,
        quantity: requestedQuantity,
        requesterLocation: user.location,
        latitude: user.latitude,
        longitude: user.longitude,
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
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
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
              _buildDonorDetailsSection(),
              const SizedBox(height: 16),
              _buildMedicineDetailsSection(),
              const SizedBox(height: 16),
              _buildLocationSection(),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isRequesting ? null : _requestMedicine,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(
                            255,
                            4,
                            113,
                            78,
                          ),
                        ),
                        child: _isRequesting
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                'Request This Medicine',
                                style: TextStyle(color: Colors.white),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: OutlinedButton(
                        onPressed: _donor != null
                            ? () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatPage(
                                      requestId:
                                          'inquiry_${widget.donation.donationId}',
                                      otherUserId: widget.donation.donorId,
                                      otherUserName: _donor!.name,
                                    ),
                                  ),
                                );
                              }
                            : null,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color.fromARGB(
                            255,
                            4,
                            113,
                            78,
                          ),
                          side: const BorderSide(
                            color: Color.fromARGB(255, 4, 113, 78),
                          ),
                        ),
                        child: const Icon(Icons.chat_outlined),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🔹 ONLY MAP SECTION CHANGED (OpenStreetMap)
  Widget _buildDonorDetailsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Donor Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 4, 113, 78),
            ),
          ),
          const SizedBox(height: 12),
          if (_donor == null)
            const Center(child: CircularProgressIndicator())
          else ...[
            _buildDetailRow(Icons.person, 'Name', _donor!.name),
            _buildDetailRow(Icons.email, 'Email', _donor!.email),
            _buildDetailRow(Icons.phone, 'Phone', _donor!.phone),
            _buildDetailRow(Icons.location_on, 'Location', _donor!.location),
            _buildDetailRow(
              Icons.verified,
              'Verified',
              _donor!.isVerified ? 'Yes' : 'No',
            ),
            _buildDetailRow(
              Icons.admin_panel_settings,
              'Role',
              _donor!.role == UserRole.admin ? 'Admin' : 'User',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMedicineDetailsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Medicine Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 4, 113, 78),
            ),
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            Icons.medication,
            'Medicine',
            widget.donation.medicineName,
          ),
          _buildDetailRow(Icons.category, 'Type', widget.donation.medicineType),
          _buildDetailRow(
            Icons.inventory,
            'Available Quantity',
            '${widget.donation.quantity} units',
          ),
          _buildDetailRow(
            Icons.calendar_today,
            'Expiry Date',
            '${widget.donation.expiryDate.day}/${widget.donation.expiryDate.month}/${widget.donation.expiryDate.year}',
          ),
          if (widget.donation.description != null &&
              widget.donation.description!.isNotEmpty)
            _buildDetailRow(
              Icons.description,
              'Description',
              widget.donation.description!,
            ),
          if (widget.donation.photoUrl != null &&
              widget.donation.photoUrl!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Photo',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  _buildPhotoWidget(widget.donation.photoUrl!),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Location', style: TextStyle(fontWeight: FontWeight.bold)),
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
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoWidget(String photoUrl) {
    try {
      // Check if it's a valid base64 string
      if (!_isValidBase64(photoUrl)) {
        return Container(
          height: 150,
          color: Colors.grey.shade200,
          child: const Icon(Icons.broken_image, size: 50),
        );
      }

      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(
          base64Decode(photoUrl),
          height: 150,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('Error decoding image: $error');
            return Container(
              height: 150,
              color: Colors.grey.shade200,
              child: const Icon(Icons.broken_image, size: 50),
            );
          },
        ),
      );
    } catch (e) {
      print('Exception in _buildPhotoWidget: $e');
      return Container(
        height: 150,
        color: Colors.grey.shade200,
        child: const Icon(Icons.broken_image, size: 50),
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
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Available: ${widget.maxQuantity} units'),
          const SizedBox(height: 16),
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
                  border: Border.all(color: Colors.grey.shade300),
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
            'Requesting $_selectedQuantity unit${_selectedQuantity == 1 ? '' : 's'}',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed:
              _selectedQuantity > 0 && _selectedQuantity <= widget.maxQuantity
              ? () => Navigator.pop(context, _selectedQuantity)
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 4, 113, 78),
          ),
          child: const Text('Request', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
