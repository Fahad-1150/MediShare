import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/auth_state.dart';
import '../services/donation_service.dart';
import '../services/request_service.dart';
import '../models/donation.dart';
import '../models/request.dart';

class UserPanel extends StatefulWidget {
  const UserPanel({super.key});

  @override
  State<UserPanel> createState() => _UserPanelState();
}

class _UserPanelState extends State<UserPanel> {
  final DonationService _donationService = DonationService();
  final RequestService _requestService = RequestService();

  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();

    if (!auth.isLoggedIn) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outlined, size: 64, color: Colors.red.shade300),
              const SizedBox(height: 24),
              const Text(
                'Please Log In',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'You need to log in to access your profile',
                style: TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.black),
          title: const Text(
            'My Profile',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          bottom: TabBar(
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color.fromARGB(255, 4, 113, 78),
            tabs: const [
              Tab(text: 'Profile'),
              Tab(text: 'Search'),
              Tab(text: 'My Donations'),
              Tab(text: 'Received'),
              Tab(text: 'Pending Donations'),
              Tab(text: 'Pending Requests'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildProfileTab(auth),
            _buildSearchTab(),
            _buildMyDonationsTab(auth),
            _buildReceivedDonationsTab(auth),
            _buildPendingDonationsTab(auth),
            _buildPendingRequestsTab(auth),
          ],
        ),
      ),
    );
  }

  // Profile Tab
  Widget _buildProfileTab(AuthState auth) {
    final user = auth.user;
    if (user == null) {
      return const Center(child: Text('User not found'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Icon(
                    Icons.person,
                    size: 50,
                    color: Colors.blue.shade600,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  user.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Edit Profile',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              labelText: 'Full Name',
              hintText: user.name,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.person),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              labelText: 'Email',
              hintText: user.email,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.email),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              labelText: 'Phone',
              hintText: user.phone,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.phone),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              labelText: 'Location',
              hintText: user.location,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.location_on),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Profile updated successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text(
                'Save Changes',
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
    );
  }

  // Search Tab
  Widget _buildSearchTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              labelText: 'Search medicines',
              hintText: 'Enter medicine name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _searchQuery = ''),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 24),
          FutureBuilder<List<Donation>>(
            future: _donationService.getAllDonations(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Text(
                    _searchQuery.isEmpty
                        ? 'Enter a search term'
                        : 'No medicines found',
                    style: const TextStyle(color: Colors.black54),
                  ),
                );
              }

              final filtered = snapshot.data!
                  .where(
                    (d) =>
                        d.medicineName.toLowerCase().contains(
                          _searchQuery.toLowerCase(),
                        ) ||
                        d.medicineType.toLowerCase().contains(
                          _searchQuery.toLowerCase(),
                        ),
                  )
                  .toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Text(
                    _searchQuery.isEmpty
                        ? 'Enter a search term'
                        : 'No medicines found',
                    style: const TextStyle(color: Colors.black54),
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final med = filtered[index];
                  return _buildMedicineCard(med);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // My Donations Tab
  Widget _buildMyDonationsTab(AuthState auth) {
    final user = auth.user;
    if (user == null) {
      return const Center(child: Text('User not found'));
    }

    return FutureBuilder<List<Donation>>(
      future: _donationService.getAllDonations(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No donations added yet'));
        }

        final myDonations = snapshot.data!
            .where((d) => d.donorId == user.userId)
            .toList();

        return _buildDonationList(myDonations, 'No donations added yet');
      },
    );
  }

  // Received Donations Tab
  Widget _buildReceivedDonationsTab(AuthState auth) {
    final user = auth.user;
    if (user == null) {
      return const Center(child: Text('User not found'));
    }

    return FutureBuilder<List<Donation>>(
      future: _donationService.getAllDonations(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No medicines received yet'));
        }

        final receivedDonations = snapshot.data!
            .where(
              (d) =>
                  d.status == DonationStatus.approved &&
                  d.donorId != user.userId,
            )
            .toList();

        return _buildDonationList(
          receivedDonations,
          'No medicines received yet',
        );
      },
    );
  }

  // Pending Donations Tab
  Widget _buildPendingDonationsTab(AuthState auth) {
    final user = auth.user;
    if (user == null) {
      return const Center(child: Text('User not found'));
    }

    return FutureBuilder<List<Donation>>(
      future: _donationService.getAllDonations(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No pending donations'));
        }

        final pendingDonations = snapshot.data!
            .where(
              (d) =>
                  d.status == DonationStatus.pending &&
                  d.donorId == user.userId,
            )
            .toList();

        return _buildDonationList(pendingDonations, 'No pending donations');
      },
    );
  }

  // Pending Requests Tab
  Widget _buildPendingRequestsTab(AuthState auth) {
    final user = auth.user;
    if (user == null) {
      return const Center(child: Text('User not found'));
    }

    return FutureBuilder<List<MedicineRequest>>(
      future: _requestService.getAllRequests(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No pending requests'));
        }

        final pendingRequests = snapshot.data!
            .where(
              (r) =>
                  r.status == RequestStatus.pending &&
                  r.requesterId == user.userId,
            )
            .toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: pendingRequests.isEmpty
                ? [
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 48),
                        child: Text(
                          'No pending requests',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ),
                    ),
                  ]
                : pendingRequests.map((req) => _buildRequestCard(req)).toList(),
          ),
        );
      },
    );
  }

  Widget _buildDonationList(List<Donation> donations, String emptyMessage) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: donations.isEmpty
            ? [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Text(
                      emptyMessage,
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  ),
                ),
              ]
            : donations.map((d) => _buildMedicineCard(d)).toList(),
      ),
    );
  }

  Widget _buildMedicineCard(Donation donation) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      donation.medicineName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      donation.medicineType,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: donation.status == DonationStatus.pending
                      ? Colors.orange.shade100
                      : donation.status == DonationStatus.approved
                      ? Colors.green.shade100
                      : Colors.red.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  donation.status.toString().split('.').last.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: donation.status == DonationStatus.pending
                        ? Colors.orange.shade700
                        : donation.status == DonationStatus.approved
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Qty: ${donation.quantity}',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              Text(
                'Expires: ${donation.expiryDate.year}-${donation.expiryDate.month.toString().padLeft(2, '0')}-${donation.expiryDate.day.toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Location: ${donation.donorLocation}',
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(MedicineRequest request) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.medicineName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      request.medicineType,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.yellow.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  request.status.toString().split('.').last.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.yellow.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Quantity needed: ${request.quantity}',
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 8),
          Text(
            'Location: ${request.requesterLocation}',
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
