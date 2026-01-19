import 'package:flutter/material.dart';
import '../models/medicine.dart';
import 'dart:convert';

class MedicineCard extends StatelessWidget {
  final Medicine medicine;
  const MedicineCard({super.key, required this.medicine});

  bool get isExpiringSoon =>
      medicine.expiryDate.difference(DateTime.now()).inDays < 90;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image covering full width
          SizedBox(
            width: double.infinity,
            height: 200,
            child: _buildImageWidget(medicine.photoUrl),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medicine.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  medicine.location,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${medicine.quantity} units'),
                    Text(
                      '${medicine.expiryDate.month}/${medicine.expiryDate.year}',
                      style: TextStyle(
                        color: isExpiringSoon ? Colors.orange : Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Request Medicine'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
      color: Colors.grey.shade200,
      child: const Center(
        child: Icon(Icons.image_not_supported, size: 64, color: Colors.grey),
      ),
    );
  }
}
