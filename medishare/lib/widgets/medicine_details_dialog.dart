import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'dart:convert';
import '../models/donation.dart';
import '../models/user.dart';
import '../services/user_service.dart';

class MedicineDetailsDialog extends StatefulWidget {
  final Donation donation;

  const MedicineDetailsDialog({super.key, required this.donation});

  @override
  State<MedicineDetailsDialog> createState() => _MedicineDetailsDialogState();
}

class _MedicineDetailsDialogState extends State<MedicineDetailsDialog> {
  final UserService _userService = UserService();
  late Future<UserModel?> _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = _userService.getUserById(widget.donation.donorId);
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getRemainingDays(DateTime expiryDate) {
    final remaining = expiryDate.difference(DateTime.now()).inDays;
    if (remaining < 0) return 'Expired';
    if (remaining == 0) return 'Expires today';
    if (remaining == 1) return 'Expires tomorrow';
    return 'Expires in $remaining days';
  }

  /// Build image widget - handles both base64 and network URLs
  Widget _buildImageWidget(String photoUrl) {
    try {
      // Check if it's base64 encoded data
      if (photoUrl.startsWith('iVBO') ||
          photoUrl.startsWith('/9j/') ||
          photoUrl.contains('base64') ||
          !photoUrl.startsWith('http')) {
        // It's base64 or file path
        try {
          final decodedBytes = base64Decode(photoUrl);
          return Image.memory(
            decodedBytes,
            height: 250,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
          );
        } catch (e) {
          return _buildPlaceholder();
        }
      } else {
        // It's a network URL
        return Image.network(
          photoUrl,
          height: 250,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
        );
      }
    } catch (e) {
      return _buildPlaceholder();
    }
  }

  Widget _buildPlaceholder() {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.image_not_supported,
        size: 64,
        color: Colors.grey,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 800, maxWidth: 600),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Close Button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 4, 113, 78),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        widget.donation.medicineName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Medicine Image
                    if (widget.donation.photoUrl != null &&
                        widget.donation.photoUrl!.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _buildImageWidget(widget.donation.photoUrl!),
                      )
                    else
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.image,
                            size: 64,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),

                    // Medicine Details Section
                    Text(
                      'Medicine Details',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow('Type:', widget.donation.medicineType),
                    _buildDetailRow('Quantity:', '${widget.donation.quantity}'),
                    _buildDetailRow(
                      'Expiry Date:',
                      _formatDate(widget.donation.expiryDate),
                    ),
                    _buildDetailRow(
                      'Status:',
                      _getRemainingDays(widget.donation.expiryDate),
                      isHighlight: widget.donation.isExpired,
                    ),
                    if (widget.donation.description != null &&
                        widget.donation.description!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        'Description:',
                        widget.donation.description ?? '',
                      ),
                    ],
                    const SizedBox(height: 20),

                    // User/Donor Details Section
                    FutureBuilder<UserModel?>(
                      future: _userFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        }

                        final user = snapshot.data;
                        if (user == null) {
                          return const SizedBox.shrink();
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Donor Information',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildDetailRow('Name:', user.name),
                            _buildDetailRow('Email:', user.email),
                            _buildDetailRow('Phone:', user.phone),
                            _buildDetailRow('Location:', user.location),
                            const SizedBox(height: 20),
                          ],
                        );
                      },
                    ),

                    // Map Section
                    Text(
                      'Location Map',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        height: 300,
                        child: FlutterMap(
                          options: MapOptions(
                            center: latlng.LatLng(
                              widget.donation.latitude,
                              widget.donation.longitude,
                            ),
                            zoom: 15,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                              subdomains: const ['a', 'b', 'c'],
                              userAgentPackageName: 'com.medishare.app',
                              tms: false,
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  width: 80.0,
                                  height: 80.0,
                                  point: latlng.LatLng(
                                    widget.donation.latitude,
                                    widget.donation.longitude,
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.blue,
                                      borderRadius: BorderRadius.circular(50),
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 3,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.location_on,
                                      color: Colors.white,
                                      size: 40,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Action Buttons (for Admin)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Opening navigation in map app...',
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.directions),
                            label: const Text('Navigate'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(
                                255,
                                4,
                                113,
                                78,
                              ),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // Copy location info
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Location copied!'),
                                ),
                              );
                            },
                            icon: const Icon(Icons.copy),
                            label: const Text('Copy Location'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade600,
                              foregroundColor: Colors.white,
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
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isHighlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isHighlight ? Colors.red : Colors.black54,
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
