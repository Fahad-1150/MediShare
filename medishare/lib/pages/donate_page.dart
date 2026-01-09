import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/auth_state.dart';
import '../services/donation_service.dart';
import '../services/user_service.dart';

class DonatePage extends StatefulWidget {
  const DonatePage({super.key});

  @override
  State<DonatePage> createState() => _DonatePageState();
}

class _DonatePageState extends State<DonatePage> {
  final DonationService _donationService = DonationService();
  final UserService _userService = UserService();

  final _nameController = TextEditingController();
  final _typeController = TextEditingController();
  final _quantityController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime? _selectedExpiryDate;
  bool _isLoading = false;

  String _selectedType = 'Tablet';
  final List<String> _medicineTypes = [
    'Tablet',
    'Capsule',
    'Injection',
    'Syrup',
    'Cream',
    'Other',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
    _quantityController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 1000)),
    );

    if (picked != null) {
      setState(() => _selectedExpiryDate = picked);
    }
  }

  Future<void> _submitDonation() async {
    final auth = context.read<AuthState>();

    if (!auth.isLoggedIn) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please login first')));
      return;
    }

    if (_nameController.text.isEmpty ||
        _quantityController.text.isEmpty ||
        _selectedExpiryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final donationId = await _donationService.createDonation(
        donorId: auth.user!.userId,
        medicineName: _nameController.text,
        medicineType: _selectedType,
        quantity: int.parse(_quantityController.text),
        expiryDate: _selectedExpiryDate!,
        donorLocation: _locationController.text.isNotEmpty
            ? _locationController.text
            : auth.user!.location,
        latitude: auth.user!.latitude,
        longitude: auth.user!.longitude,
        description: _descriptionController.text,
      );

      // Add donation to user's list
      await _userService.addDonation(auth.user!.userId, donationId);

      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Medicine donated successfully! Pending admin approval.',
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Clear form
        _nameController.clear();
        _quantityController.clear();
        _locationController.clear();
        _descriptionController.clear();
        setState(() => _selectedExpiryDate = null);
      }
    } catch (e) {
      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();

    if (!auth.isLoggedIn) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline, size: 64, color: Colors.blue),
                const SizedBox(height: 24),
                const Text(
                  'Sign In Required',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  'You must be logged in to donate medicine',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/login'),
                  icon: const Icon(Icons.login),
                  label: const Text('Sign In'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Donate Medicine',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            const Text(
              'Share unused medicine with those in need',
              style: TextStyle(color: Colors.black54, fontSize: 14),
            ),
            const SizedBox(height: 32),
            // Medicine name
            _buildLabel('Medicine Name *'),
            TextField(
              controller: _nameController,
              decoration: _buildInputDecoration('e.g., Paracetamol'),
            ),
            const SizedBox(height: 20),
            // Medicine type
            _buildLabel('Medicine Type *'),
            DropdownMenu<String>(
              width: MediaQuery.of(context).size.width - 40,
              initialSelection: _selectedType,
              onSelected: (String? value) {
                if (value != null) {
                  setState(() => _selectedType = value);
                }
              },
              dropdownMenuEntries: _medicineTypes
                  .map(
                    (String type) =>
                        DropdownMenuEntry<String>(value: type, label: type),
                  )
                  .toList(),
            ),
            const SizedBox(height: 20),
            // Quantity
            _buildLabel('Quantity *'),
            TextField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: _buildInputDecoration('Number of units'),
            ),
            const SizedBox(height: 20),
            // Expiry date
            _buildLabel('Expiry Date *'),
            ElevatedButton.icon(
              onPressed: _selectExpiryDate,
              icon: const Icon(Icons.calendar_today),
              label: Text(
                _selectedExpiryDate == null
                    ? 'Select Date'
                    : '${_selectedExpiryDate!.day}/${_selectedExpiryDate!.month}/${_selectedExpiryDate!.year}',
              ),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(MediaQuery.of(context).size.width - 40, 56),
              ),
            ),
            const SizedBox(height: 20),
            // Location
            _buildLabel('Location'),
            TextField(
              controller: _locationController,
              decoration: _buildInputDecoration(
                auth.user!.location.isNotEmpty
                    ? 'Default: ${auth.user!.location}'
                    : 'Your location',
              ),
            ),
            const SizedBox(height: 20),
            // Description
            _buildLabel('Description (optional)'),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: _buildInputDecoration('Additional notes'),
            ),
            const SizedBox(height: 32),
            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitDonation,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text(
                        'Donate Medicine',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.blue, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }
}
