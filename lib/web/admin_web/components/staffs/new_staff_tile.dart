import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';

class NewStaffTile extends StatelessWidget {
  final void Function(String name, String role, Uint8List? imageBytes)
      onStaffCreated;
  const NewStaffTile({super.key, required this.onStaffCreated});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showStaffForm(context),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(
            color: Colors.white,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, color: Colors.white, size: 40),
                    SizedBox(height: 10),
                    Text(
                      'Add Staff',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStaffForm(BuildContext context) {
    final firstNameController = TextEditingController();
    final surnameController = TextEditingController();
    final emailController = TextEditingController();
    bool clinicAuth = false;
    bool appointmentAuth = false;
    bool staffAuth = false;
    bool messagesAuth = false;
    Uint8List? selectedImageBytes;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('New Staff Account'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () async {
                      final result = await FilePicker.platform.pickFiles(
                        type: FileType.image,
                        withData: true,
                      );
                      if (result != null && result.files.single.bytes != null) {
                        setState(() {
                          selectedImageBytes = result.files.single.bytes;
                        });
                      }
                    },
                    child: CircleAvatar(
                      radius: 40,
                      backgroundImage: selectedImageBytes != null
                          ? MemoryImage(selectedImageBytes!)
                          : null,
                      child: selectedImageBytes == null
                          ? const Icon(Icons.camera_alt, size: 30)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: firstNameController,
                          decoration:
                              const InputDecoration(labelText: 'First Name'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: surnameController,
                          decoration:
                              const InputDecoration(labelText: 'Surname'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: 20),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Authorities'),
                  ),
                  SwitchListTile(
                    title: const Text('Clinic'),
                    value: clinicAuth,
                    onChanged: (val) => setState(() => clinicAuth = val),
                  ),
                  SwitchListTile(
                    title: const Text('Appointments'),
                    value: appointmentAuth,
                    onChanged: (val) => setState(() => appointmentAuth = val),
                  ),
                  SwitchListTile(
                    title: const Text('Staffs'),
                    value: staffAuth,
                    onChanged: (val) => setState(() => staffAuth = val),
                  ),
                  SwitchListTile(
                    title: const Text('Messages'),
                    value: messagesAuth,
                    onChanged: (val) => setState(() => messagesAuth = val),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  final fullName =
                      '${firstNameController.text} ${surnameController.text}';
                  final role = 'Email: ${emailController.text}\nAuthorities: '
                      '${clinicAuth ? '- Clinic Page\n- Clinic\n' : ''}'
                      '${appointmentAuth ? '- Appointments\n' : ''}'
                      '${staffAuth ? '- Staffs\n' : ''}'
                      '${messagesAuth ? '- Messages' : ''}';
                  onStaffCreated(fullName, role, selectedImageBytes);
                },
                child: const Text('Create'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class StaffInfoTile extends StatelessWidget {
  final String name;
  final String role;
  final Uint8List? image;
  const StaffInfoTile(
      {super.key, required this.name, required this.role, this.image});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage: image != null ? MemoryImage(image!) : null,
            child: image == null ? const Icon(Icons.person, size: 30) : null,
          ),
          const SizedBox(height: 8),
          Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(role, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
