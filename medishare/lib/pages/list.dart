import 'package:flutter/material.dart';
import '../models/medicine.dart';
import '../widgets/medicine_card.dart';

// EXAMPLEDATA
final List<Medicine> mockMedicines = [
  Medicine(
    name: 'Napa',
    type: 'Tablet',
    quantity: 10,
    expiryDate: DateTime(2025, 1),
    location: 'Dhaka',
    photoUrl:
        'https://chaldn.com/_mpimage/napa-pediatric-drop-15ml-1-pc?src=https%3A%2F%2Feggyolk.chaldal.com%2Fapi%2FPicture%2FRaw%3FpictureId%3D106697&q=low&v=1&m=400&webp=1',
  ),
  Medicine(
    name: 'Ace Paracetamol',
    type: 'Tablet',
    quantity: 10,
    expiryDate: DateTime(2025, 1),
    location: 'Dhaka',
    photoUrl:
        'https://chaldn.com/_mpimage/ace-tablet-500mg-10-tablets?src=https%3A%2F%2Feggyolk.chaldal.com%2Fapi%2FPicture%2FRaw%3FpictureId%3D105213&q=low&v=1&m=400&webp=1',
  ),
  Medicine(
    name: 'Azithromycin',
    type: 'Capsule',
    quantity: 10,
    expiryDate: DateTime(2025, 8),
    location: 'Chittagong',
    photoUrl:
        'https://www.biofieldpharma.com/wp-content/uploads/2023/06/BIOFIELD-OZISET-250-TAB-1-scaled.jpg',
  ),
  Medicine(
    name: 'Insulin',
    type: 'Injection',
    quantity: 5,
    expiryDate: DateTime(2025, 5),
    location: 'Sylhet',
    photoUrl:
        'https://img.lb.wbmdstatic.com/vim/live/webmd/consumer_assets/site_images/article_thumbnails/BigBead/how_insulin_works_bigbead/1800x1200_how_insulin_works_bigbead.jpg?resize=750px:*&output-quality=75',
  ),
];

class MedicineListPage extends StatefulWidget {
  const MedicineListPage({super.key});

  @override
  State<MedicineListPage> createState() => _MedicineListPageState();
}

class _MedicineListPageState extends State<MedicineListPage> {
  String searchTerm = '';
  String filterType = 'All';

  List<String> get medicineTypes {
    final types = mockMedicines.map((m) => m.type).toSet().toList();
    return ['All', ...types];
  }

  List<Medicine> get filteredMedicines {
    return mockMedicines.where((medicine) {
      final matchesSearch =
          medicine.name.toLowerCase().contains(searchTerm.toLowerCase()) ||
          medicine.type.toLowerCase().contains(searchTerm.toLowerCase());

      final matchesType = filterType == 'All' || medicine.type == filterType;

      return matchesSearch && matchesType;
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
            filteredMedicines.isNotEmpty
                ? GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredMedicines.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.7,
                    ),
                    itemBuilder: (_, index) {
                      return MedicineCard(medicine: filteredMedicines[index]);
                    },
                  )
                : _emptyState(),
          ],
        ),
      ),
    );
  }

  Widget _searchBar() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Search medicine name or type',
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
}
