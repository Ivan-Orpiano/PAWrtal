import 'package:capstone_app/web/admin_web/components/staffs/new_staff_tile.dart';
import 'package:capstone_app/web/admin_web/components/staffs/staff_tile.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';

class AdminWebStaffs extends StatefulWidget {
  const AdminWebStaffs({super.key});

  @override
  State<AdminWebStaffs> createState() => _AdminWebStaffsState();
}

class _AdminWebStaffsState extends State<AdminWebStaffs> {
  final TextEditingController _searchController = TextEditingController();
  String? selectedTag;

  final List<String> tags = ['Clinic', 'Appointments', 'Staffs', 'Messages'];

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

  void _addNewStaff(String name, String role, Uint8List? imageBytes) {
    setState(() {
      allStaffs.add(name);
      authorityMap[name] = _parseAuthorities(role);
      staffImages[name] =
          imageBytes != null ? 'memory' : 'lib/images/user_profile.png';
    });
  }

  List<String> _parseAuthorities(String roleText) {
    final lines = roleText.split('\n');
    return lines
        .where((line) => line.startsWith('-'))
        .map((line) => line.replaceFirst('- ', '').trim())
        .toList();
  }

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
                      hintStyle: const TextStyle(
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
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 200,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                  childAspectRatio: 3 / 4.5,
                ),
                itemCount: filteredStaffs.length + 1,
                itemBuilder: (context, index) {
                  if (index == filteredStaffs.length) {
                    return NewStaffTile(onStaffCreated: _addNewStaff);
                  }
                  final staffName = filteredStaffs[index];
                  final imagePath =
                      staffImages[staffName] ?? 'lib/images/kapitankalbo1.png';
                  final authorities = authorityMap[staffName] ?? [];

                  return StaffTile(
                    staff: Staff(
                      name: staffName,
                      authorities: authorities,
                      imagePath: imagePath,
                    ),
                    onUpdate: (updatedAuthorities) {
                      setState(() {
                        authorityMap[staffName] = updatedAuthorities;
                      });
                    },
                    onRemove: () {
                      setState(() {
                        allStaffs.remove(staffName);
                        authorityMap.remove(staffName);
                        staffImages.remove(staffName);
                      });
                    },
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
