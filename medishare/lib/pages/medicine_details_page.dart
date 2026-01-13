import 'package:flutter/material.dart';
import 'package:medishare/models/donation.dart';
import 'package:medishare/services/request_service.dart';

class MedicineDetailsPage extends StatefulWidget {
  final Donation donation;

  const MedicineDetailsPage({super.key, required this.donation});

  @override
  State<MedicineDetailsPage> createState() => _MedicineDetailsPageState();
}

class _MedicineDetailsPageState extends State<MedicineDetailsPage> {
  final _requestService = RequestService();
  bool _isRequesting = false;

  Future<void> _requestMedicine() async {
    try {
      setState(() => _isRequesting = true);

      // Create a request for this medicine
      await _requestService.createRequest(
        requesterId: 'USER_ID_HERE', // Get from auth context
        medicineName: widget.donation.medicineName,
        medicineType: widget.donation.medicineType,
        quantity: widget.donation.quantity,
        requesterLocation: 'USER_LOCATION', // Get from user profile
        latitude: 0.0, // Get from user location
        longitude: 0.0, // Get from user location
        reason: 'Need this medicine',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Medicine requested successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Medicine Image
            if (donation.photoUrl != null && donation.photoUrl!.isNotEmpty)
              Container(
                width: double.infinity,
                height: 300,
                color: Colors.grey.shade100,
                child: Image.network(
                  donation.photoUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Icon(
                        Icons.medication,
                        size: 100,
                        color: Colors.grey.shade400,
                      ),
                    );
                  },
                ),
              )
            else
              Container(
                width: double.infinity,
                height: 300,
                color: Colors.grey.shade100,
                child: Icon(
                  Icons.medication,
                  size: 100,
                  color: Colors.grey.shade400,
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Medicine Name
                  Text(
                    donation.medicineName,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Medicine Type & Quantity
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(
                            255,
                            4,
                            113,
                            78,
                          ).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          donation.medicineType,
                          style: const TextStyle(
                            color: Color.fromARGB(255, 4, 113, 78),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${donation.quantity} Units',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Donor Information
                  _buildInfoSection(
                    icon: Icons.person,
                    title: 'Donor',
                    content: donation.donorId.toString(),
                  ),

                  const SizedBox(height: 16),

                  // Location
                  _buildInfoSection(
                    icon: Icons.location_on,
                    title: 'Location',
                    content: donation.donorLocation,
                  ),

                  const SizedBox(height: 16),

                  // Expiry Date
                  _buildInfoSection(
                    icon: Icons.calendar_today,
                    title: 'Expiry Date',
                    content:
                        '${donation.expiryDate.day}/${donation.expiryDate.month}/${donation.expiryDate.year}',
                    color: donation.isExpired
                        ? Colors.red
                        : donation.isExpiringsoon
                        ? Colors.orange
                        : Colors.green,
                  ),

                  const SizedBox(height: 16),

                  // Status
                  _buildInfoSection(
                    icon: Icons.info,
                    title: 'Status',
                    content: donation.status.toString().split('.').last,
                  ),

                  if (donation.description != null &&
                      donation.description!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      donation.description!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        height: 1.5,
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Request Button (for normal users)
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isRequesting ? null : _requestMedicine,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 4, 113, 78),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isRequesting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Request This Medicine',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Back Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: Color.fromARGB(255, 4, 113, 78),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Back',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 4, 113, 78),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection({
    required IconData icon,
    required String title,
    required String content,
    Color? color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: color ?? const Color.fromARGB(255, 4, 113, 78),
          size: 24,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade400,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                content,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color ?? Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
