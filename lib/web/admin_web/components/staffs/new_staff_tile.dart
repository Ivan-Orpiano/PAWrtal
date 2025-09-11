import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';

class NewStaffTile extends StatelessWidget {
  final void Function(String name, String email, List<String> authorities,
      Uint8List? imageBytes) onStaffCreated;
  const NewStaffTile({super.key, required this.onStaffCreated});

  // Updated color palette to match the interface
  static const Color primaryBlue = Color(0xFF4A6FA5);
  static const Color primaryTeal = Color(0xFF5B9BD5);
  static const Color lightTeal = Color(0xFF9FC5E8);
  static const Color deepBlue = Color(0xFF2F4F7F);
  static const Color softBlue = Color(0xFF6FA8DC);
  static const Color lightGray = Color(0xFFF3F4F6);
  static const Color mediumGray = Color(0xFF9CA3AF);
  static const Color darkText = Color(0xFF374151);
  static const Color vetGreen = Color(0xFF34D399);
  static const Color vetOrange = Color(0xFFF59E0B);
  static const Color vetPurple = Color(0xFF6A1B9A);
  static const Color lightVetGreen = Color(0xFFE5F7E5);

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width <= 600;

    return Material(
      elevation: 3.0,
      borderRadius: BorderRadius.circular(20),
      shadowColor: primaryTeal.withOpacity(0.2),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _showStaffForm(context),
        hoverColor: primaryTeal.withOpacity(0.04),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: primaryTeal.withOpacity(0.3),
              width: 2.5,
            ),
          ),
          padding: EdgeInsets.all(isSmall ? 14 : 20),
          child: isSmall ? _buildMobileLayout() : _buildDesktopLayout(),
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: lightVetGreen.withOpacity(0.3),
            shape: BoxShape.circle,
            border: Border.all(color: primaryTeal.withOpacity(0.3), width: 2),
          ),
          child: Icon(Icons.person_add_alt_1_rounded,
              color: primaryTeal, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Add New Staff',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: darkText,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: primaryTeal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Create account',
                  style: TextStyle(
                    color: primaryTeal,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        Icon(Icons.add, color: primaryTeal, size: 20),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: lightVetGreen.withOpacity(0.3),
            shape: BoxShape.circle,
            border: Border.all(color: primaryTeal.withOpacity(0.3), width: 2),
          ),
          child: Icon(Icons.person_add_alt_1_rounded,
              color: primaryTeal, size: 40),
        ),
        const SizedBox(height: 16),
        Text(
          'Add New Staff',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: darkText,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: primaryTeal.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Text(
            'Create account',
            style: TextStyle(
              color: primaryTeal,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  void _showStaffForm(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        // Move all state variables to the StatefulBuilder scope
        final firstNameController = TextEditingController();
        final surnameController = TextEditingController();
        final emailController = TextEditingController();
        final phoneController = TextEditingController();

        return StatefulBuilder(
          builder: (context, setState) {
            // State variables that need to be reactive
            bool clinicAuth = false;
            bool appointmentAuth = false;
            bool staffAuth = false;
            bool messagesAuth = false;
            Uint8List? selectedImageBytes;

            final screenWidth = MediaQuery.of(context).size.width;
            final screenHeight = MediaQuery.of(context).size.height;
            final isDesktop = screenWidth > 768;
            final dialogWidth = isDesktop ? 520.0 : screenWidth * 0.9;

            return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
              child: Container(
                width: dialogWidth,
                constraints: BoxConstraints(
                  maxHeight: screenHeight * 0.9,
                  maxWidth: screenWidth * 0.95,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      lightVetGreen.withOpacity(0.1),
                      Colors.white,
                      lightVetGreen.withOpacity(0.05),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primaryTeal.withOpacity(0.15),
                      blurRadius: 25,
                      offset: const Offset(0, 10),
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: EdgeInsets.all(isDesktop ? 24 : 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [primaryBlue, primaryTeal, softBlue],
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: primaryTeal.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.medical_services_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'Create New Staff Account',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isDesktop ? 22 : 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Content
                    Flexible(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(isDesktop ? 28 : 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Profile Photo
                            Center(
                              child: _buildProfilePhotoSection(
                                selectedImageBytes: selectedImageBytes,
                                onChange: (bytes) => setState(() {
                                  selectedImageBytes = bytes;
                                }),
                              ),
                            ),
                            const SizedBox(height: 28),

                            // Personal Info
                            _buildSectionHeader(
                              'Personal Information',
                              Icons.person_outline,
                              primaryBlue,
                            ),
                            const SizedBox(height: 20),

                            _buildPersonalInfoFields(
                              isDesktop,
                              firstNameController,
                              surnameController,
                              emailController,
                              phoneController,
                            ),
                            const SizedBox(height: 28),

                            // Authorities
                            _buildSectionHeader(
                              'Access Permissions',
                              Icons.security_rounded,
                              vetGreen,
                              subtitle:
                                  'Select which sections this staff member can access',
                            ),
                            const SizedBox(height: 20),

                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(
                                    color: primaryTeal.withOpacity(0.3),
                                    width: 2),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryTeal.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  CheckboxListTile(
                                    title: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: primaryTeal.withOpacity(0.2),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                              Icons.local_hospital_rounded,
                                              size: 18,
                                              color: primaryTeal),
                                        ),
                                        const SizedBox(width: 16),
                                        const Expanded(
                                          child: Text(
                                            'Clinic Page',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 15),
                                          ),
                                        ),
                                      ],
                                    ),
                                    subtitle: const Padding(
                                      padding:
                                          EdgeInsets.only(left: 40, top: 4),
                                      child: Text(
                                        'Access to clinic information and settings',
                                        style: TextStyle(fontSize: 13),
                                      ),
                                    ),
                                    value: clinicAuth,
                                    onChanged: (val) => setState(
                                        () => clinicAuth = val ?? false),
                                    activeColor: primaryTeal,
                                    checkColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                  ),
                                  Divider(height: 1, color: Colors.grey[300]),
                                  CheckboxListTile(
                                    title: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: primaryBlue.withOpacity(0.2),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                              Icons.calendar_month_rounded,
                                              size: 18,
                                              color: primaryBlue),
                                        ),
                                        const SizedBox(width: 16),
                                        const Expanded(
                                          child: Text(
                                            'Appointments',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 15),
                                          ),
                                        ),
                                      ],
                                    ),
                                    subtitle: const Padding(
                                      padding:
                                          EdgeInsets.only(left: 40, top: 4),
                                      child: Text(
                                        'Manage and view appointments',
                                        style: TextStyle(fontSize: 13),
                                      ),
                                    ),
                                    value: appointmentAuth,
                                    onChanged: (val) => setState(
                                        () => appointmentAuth = val ?? false),
                                    activeColor: primaryBlue,
                                    checkColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                  ),
                                  Divider(height: 1, color: Colors.grey[300]),
                                  CheckboxListTile(
                                    title: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: vetPurple.withOpacity(0.2),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Icon(Icons.group_rounded,
                                              size: 18, color: vetPurple),
                                        ),
                                        const SizedBox(width: 16),
                                        const Expanded(
                                          child: Text(
                                            'Staff Management',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 15),
                                          ),
                                        ),
                                      ],
                                    ),
                                    subtitle: const Padding(
                                      padding:
                                          EdgeInsets.only(left: 40, top: 4),
                                      child: Text(
                                        'Add, edit, and remove staff accounts',
                                        style: TextStyle(fontSize: 13),
                                      ),
                                    ),
                                    value: staffAuth,
                                    onChanged: (val) => setState(
                                        () => staffAuth = val ?? false),
                                    activeColor: vetPurple,
                                    checkColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                  ),
                                  Divider(height: 1, color: Colors.grey[300]),
                                  CheckboxListTile(
                                    title: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: vetOrange.withOpacity(0.2),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Icon(Icons.message_rounded,
                                              size: 18, color: vetOrange),
                                        ),
                                        const SizedBox(width: 16),
                                        const Expanded(
                                          child: Text(
                                            'Messages',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 15),
                                          ),
                                        ),
                                      ],
                                    ),
                                    subtitle: const Padding(
                                      padding:
                                          EdgeInsets.only(left: 40, top: 4),
                                      child: Text(
                                        'Access to messaging system',
                                        style: TextStyle(fontSize: 13),
                                      ),
                                    ),
                                    value: messagesAuth,
                                    onChanged: (val) => setState(
                                        () => messagesAuth = val ?? false),
                                    activeColor: vetOrange,
                                    checkColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Actions
                    Container(
                      padding: EdgeInsets.all(isDesktop ? 24 : 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [lightGray, lightVetGreen.withOpacity(0.3)],
                        ),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(24),
                          bottomRight: Radius.circular(24),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: mediumGray,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                  colors: [primaryTeal, primaryBlue]),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryTeal.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              onPressed: () {
                                if (firstNameController.text.isEmpty ||
                                    surnameController.text.isEmpty ||
                                    emailController.text.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text(
                                          'Please fill in all required fields'),
                                      backgroundColor: Colors.red[600],
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                final fullName =
                                    '${firstNameController.text.trim()} ${surnameController.text.trim()}';

                                final authorities = <String>[];
                                if (clinicAuth) authorities.add('Clinic');
                                if (appointmentAuth)
                                  authorities.add('Appointments');
                                if (staffAuth) authorities.add('Staffs');
                                if (messagesAuth) authorities.add('Messages');

                                Navigator.of(context).pop();
                                onStaffCreated(
                                    fullName,
                                    emailController.text.trim(),
                                    authorities,
                                    selectedImageBytes);
                              },
                              icon: const Icon(Icons.check_circle_outline,
                                  color: Colors.white),
                              label: const Text('Create Account',
                                  style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 28, vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
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
          },
        );
      },
    );
  }

  Widget _buildProfilePhotoSection({
    required Uint8List? selectedImageBytes,
    required ValueChanged<Uint8List?> onChange,
  }) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            InkWell(
              onTap: () async {
                try {
                  final result = await FilePicker.platform.pickFiles(
                    type: FileType.image,
                    withData: true,
                  );

                  if (result != null && result.files.single.bytes != null) {
                    final bytes = result.files.single.bytes!;
                    final size = result.files.single.size;

                    // 5MB limit
                    if (size > 5 * 1024 * 1024) {
                      return;
                    }
                    onChange(bytes);
                  }
                } catch (_) {
                  // Handle error
                }
              },
              borderRadius: BorderRadius.circular(70),
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selectedImageBytes != null
                      ? null
                      : lightVetGreen.withOpacity(0.3),
                  border: Border.all(color: primaryTeal, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: primaryTeal.withOpacity(0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                  image: selectedImageBytes != null
                      ? DecorationImage(
                          image: MemoryImage(selectedImageBytes),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: selectedImageBytes == null
                    ? Icon(Icons.camera_alt_rounded,
                        size: 36, color: primaryTeal)
                    : null,
              ),
            ),
            if (selectedImageBytes != null)
              Positioned(
                top: -4,
                right: -4,
                child: InkWell(
                  onTap: () => onChange(null),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child:
                        const Icon(Icons.close, color: Colors.white, size: 16),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: primaryTeal.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: primaryTeal.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selectedImageBytes != null
                    ? Icons.edit_rounded
                    : Icons.add_photo_alternate_rounded,
                size: 14,
                color: primaryTeal,
              ),
              const SizedBox(width: 6),
              Text(
                selectedImageBytes != null
                    ? 'Click to change photo'
                    : 'Click to upload photo',
                style: TextStyle(
                  color: primaryTeal,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color,
      {String? subtitle}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: darkText,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: TextStyle(color: mediumGray, fontSize: 13),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoFields(
    bool isDesktop,
    TextEditingController firstNameController,
    TextEditingController surnameController,
    TextEditingController emailController,
    TextEditingController phoneController,
  ) {
    return Column(
      children: [
        if (isDesktop)
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: firstNameController,
                  label: 'First Name',
                  icon: Icons.badge_outlined,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: surnameController,
                  label: 'Surname',
                  icon: Icons.badge_outlined,
                ),
              ),
            ],
          )
        else
          Column(
            children: [
              _buildTextField(
                controller: firstNameController,
                label: 'First Name',
                icon: Icons.badge_outlined,
              ),
              const SizedBox(height: 18),
              _buildTextField(
                controller: surnameController,
                label: 'Surname',
                icon: Icons.badge_outlined,
              ),
            ],
          ),
        const SizedBox(height: 18),
        _buildTextField(
          controller: emailController,
          label: 'Email Address',
          icon: Icons.email_outlined,
        ),
        const SizedBox(height: 18),
        _buildTextField(
          controller: phoneController,
          label: 'Phone Number',
          icon: Icons.phone_outlined,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: primaryTeal.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: mediumGray, fontWeight: FontWeight.w500),
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryTeal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: primaryTeal, size: 20),
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryTeal.withOpacity(0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryTeal.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryTeal, width: 2.5),
          ),
        ),
      ),
    );
  }
}
