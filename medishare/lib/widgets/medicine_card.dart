import 'package:flutter/material.dart';
import '../models/medicine.dart';

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Image.network(
              medicine.photoUrl,
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(medicine.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(medicine.location, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${medicine.quantity} units'),
                    Text(
                      '${medicine.expiryDate.month}/${medicine.expiryDate.year}',
                      style: TextStyle(color: isExpiringSoon ? Colors.orange : Colors.black),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Request Medicine'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
