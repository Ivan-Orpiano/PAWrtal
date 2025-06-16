import 'package:capstone_app/web/admin_web/components/staffs/new_staff_tile.dart';
import 'package:capstone_app/web/admin_web/components/staffs/staff_tile.dart';
import 'package:flutter/material.dart';

class AdminWebStaffs extends StatefulWidget {
  const AdminWebStaffs({super.key});

  @override
  State<AdminWebStaffs> createState() => _AdminWebStaffsState();
}

class _AdminWebStaffsState extends State<AdminWebStaffs> {
  final TextEditingController _searchController = TextEditingController();
  String? selectedTag;

  final List<String> tags = ['Clinic', 'Appointments', 'Staffs'];

  final List<String> allStaffs = [
    'Staff 1',
    'Staff 2',
    'Staff 3',
    'Staff 4',
    'Staff 5',
    'Staff 6',
    'Staff 7'
  ];

  final Map<String, List<String>> authorityMap = {
    'Staff 1': ['Clinic', 'Appointments'],
    'Staff 2': ['Appointments'],
    'Staff 3': ['Appointments'],
    'Staff 4': ['Staffs'],
    'Staff 5': ['Clinic'],
    'Staff 6': ['Staffs'],
    'Staff 7': ['Clinic', 'Appointments', 'Staffs'],
  };

  final Map<String, String> staffImages = {
    'Staff 1': 'lib/images/user_profile.png',
    'Staff 2': 'lib/images/user_profile.png',
    'Staff 3': 'lib/images/user_profile.png',
    'Staff 4': 'lib/images/user_profile.png',
    'Staff 5': 'lib/images/user_profile.png',
    'Staff 6': 'lib/images/user_profile.png',
    'Staff 7': 'lib/images/user_profile.png',
  };

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.toLowerCase();
    final filteredStaffs = allStaffs
        .where((staff) =>
            (selectedTag == null ||
                (authorityMap[staff] ?? []).contains(selectedTag)) &&
            staff.toLowerCase().contains(query))
        .toList();

    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: tags.map((tag) {
                    final bool isSelected = tag == selectedTag;
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: ChoiceChip(
                        label: Text(tag),
                        selected: isSelected,
                        onSelected: (_) {
                          setState(() {
                            selectedTag = isSelected ? null : tag;
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(
                  height: 40,
                  width: 220,
                  child: TextField(
                    onChanged: (_) => setState(() {}),
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search Staff',
                      hintStyle: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      suffixIcon: const Icon(
                        Icons.search,
                        size: 20,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 200,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                  childAspectRatio: 3 / 4.4,
                ),
                itemCount: filteredStaffs.length + 1,
                itemBuilder: (context, index) {
                  if (index == filteredStaffs.length) {
                    return const NewStaffTile();
                  }
                  final staffName = filteredStaffs[index];
                  final imagePath =
                      staffImages[staffName] ?? 'lib/images/kapitankalbo.png';
                  return StaffTile(
                    name: staffName,
                    imagePath: imagePath,
                    authorities: authorityMap[staffName] ?? [],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
