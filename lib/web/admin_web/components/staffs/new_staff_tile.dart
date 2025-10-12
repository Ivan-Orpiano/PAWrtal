import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:capstone_app/data/models/clinic_settings_model.dart';

class NewStaffTile extends StatelessWidget {
  final ClinicSettings clinicSettings;
  final void Function(
      String name,
      String email,
      String phone,
      List<String> authorities,
      Uint8List? imageBytes,
      String password) onStaffCreated;

  const NewStaffTile({
    super.key,
    required this.clinicSettings,
    required this.onStaffCreated,
  });

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
  static const Color vetPurple = Color(0xFFA855F7);
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
            border: Border.all(color: primaryTeal.withOpacity(0.3), width: 2.5),
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
          child: const Icon(Icons.person_add_alt_1_rounded,
              color: primaryTeal, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Add New Staff',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold, color: darkText),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: primaryTeal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Create account',
                  style: TextStyle(
                      color: primaryTeal,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        const Icon(Icons.add, color: primaryTeal, size: 20),
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
          child: const Icon(Icons.person_add_alt_1_rounded,
              color: primaryTeal, size: 40),
        ),
        const SizedBox(height: 16),
        const Text(
          'Add New Staff',
          style: TextStyle(
              fontSize: 17, fontWeight: FontWeight.bold, color: darkText),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: primaryTeal.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Text(
            'Create account',
            style: TextStyle(
                color: primaryTeal, fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  void _showStaffForm(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final firstNameController = TextEditingController();
        final surnameController = TextEditingController();
        final phoneController = TextEditingController();

        return _StaffFormDialog(
          clinicSettings: clinicSettings,
          firstNameController: firstNameController,
          surnameController: surnameController,
          phoneController: phoneController,
          onStaffCreated: onStaffCreated,
        );
      },
    );
  }
}

class _StaffFormDialog extends StatefulWidget {
  final ClinicSettings clinicSettings;
  final TextEditingController firstNameController;
  final TextEditingController surnameController;
  final TextEditingController phoneController;
  final void Function(
      String name,
      String email,
      String phone,
      List<String> authorities,
      Uint8List? imageBytes,
      String password) onStaffCreated;

  const _StaffFormDialog({
    required this.clinicSettings,
    required this.firstNameController,
    required this.surnameController,
    required this.phoneController,
    required this.onStaffCreated,
  });

  @override
  State<_StaffFormDialog> createState() => _StaffFormDialogState();
}

class _StaffFormDialogState extends State<_StaffFormDialog> {
  bool clinicAuth = false;
  bool appointmentAuth = false;
  bool messagesAuth = false;
  Uint8List? selectedImageBytes;
  String generatedEmail = '';

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
  static const Color vetPurple = Color(0xFFA855F7);
  static const Color lightVetGreen = Color(0xFFE5F7E5);

  @override
  void initState() {
    super.initState();
    widget.firstNameController.addListener(_updateEmail);
    widget.surnameController.addListener(_updateEmail);
    _updateEmail();
  }

  @override
  void dispose() {
    widget.firstNameController.removeListener(_updateEmail);
    widget.surnameController.removeListener(_updateEmail);
    super.dispose();
  }

  void _updateEmail() {
    final firstName = widget.firstNameController.text.trim();
    final surname = widget.surnameController.text.trim();

    setState(() {
      if (firstName.isNotEmpty || surname.isNotEmpty) {
        final fullName = '$firstName $surname'.trim();
        generatedEmail = widget.clinicSettings.generateStaffEmail(fullName);
      } else {
        generatedEmail =
            widget.clinicSettings.staffEmailTemplate.startsWith('@')
                ? 'staff${widget.clinicSettings.staffEmailTemplate}'
                : widget.clinicSettings.staffEmailTemplate
                    .replaceAll('{name}', 'staff');
      }
    });
  }

  String _getFullPhoneNumber() {
    final phoneDigits = widget.phoneController.text.trim();
    if (phoneDigits.isEmpty) return '';
    return '09$phoneDigits';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isDesktop = screenWidth > 768;
    final dialogWidth = isDesktop ? 520.0 : screenWidth * 0.9;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
                gradient: const LinearGradient(
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
                      child: _buildProfilePhotoSection(),
                    ),
                    const SizedBox(height: 28),

                    // Personal Info
                    _buildSectionHeader('Personal Information',
                        Icons.person_outline, primaryBlue),
                    const SizedBox(height: 20),

                    _buildPersonalInfoFields(isDesktop),
                    const SizedBox(height: 16),

                    // Generated Email Display
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            primaryTeal.withOpacity(0.1),
                            lightVetGreen.withOpacity(0.3),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: primaryTeal.withOpacity(0.3), width: 2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: primaryTeal.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.email,
                                    color: primaryTeal, size: 16),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Generated Email Address',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: darkText,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            generatedEmail,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: primaryBlue,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Based on template: ${widget.clinicSettings.staffEmailTemplate}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: mediumGray,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
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

                    _buildPermissionsSection(),
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
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                          color: mediumGray, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
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
                      onPressed: _handleCreateStaff,
                      icon: const Icon(Icons.check_circle_outline,
                          color: Colors.white),
                      label: const Text('Next: Set Password',
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
  }

  void _handleCreateStaff() {
    if (widget.firstNameController.text.isEmpty ||
        widget.surnameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please fill in all required fields'),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    // Validate image is required
    if (selectedImageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profile photo is required'),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    // Validate phone if provided
    final phoneDigits = widget.phoneController.text.trim();
    if (phoneDigits.isNotEmpty && phoneDigits.length != 9) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Phone number must be exactly 9 digits after 09'),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    final fullName =
        '${widget.firstNameController.text.trim()} ${widget.surnameController.text.trim()}';
    final phone = _getFullPhoneNumber();

    final authorities = <String>[];
    if (clinicAuth) authorities.add('Clinic');
    if (appointmentAuth) authorities.add('Appointments');
    if (messagesAuth) authorities.add('Messages');

    // Show password dialog
    _showPasswordDialog(fullName, generatedEmail, phone, authorities);
  }

  Future<void> _showPasswordDialog(
    String fullName,
    String email,
    String phone,
    List<String> authorities,
  ) async {
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscurePassword = true;
    bool obscureConfirm = true;
    String? errorMessage;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 480),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    lightVetGreen.withOpacity(0.2),
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [primaryTeal, primaryBlue],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.lock_outline,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Set Staff Password',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: darkText,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Create a secure password',
                              style: TextStyle(
                                fontSize: 13,
                                color: mediumGray,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Info Box
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: primaryBlue.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Password Field
                  TextField(
                    controller: passwordController,
                    obscureText: obscurePassword,
                    onChanged: (_) => setDialogState(() => errorMessage = null),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: 'Minimum 8 characters',
                      prefixIcon: Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primaryTeal.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.lock,
                            color: primaryTeal, size: 20),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: mediumGray,
                          size: 20,
                        ),
                        onPressed: () => setDialogState(
                            () => obscurePassword = !obscurePassword),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: primaryTeal.withOpacity(0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: primaryTeal.withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: primaryTeal, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Confirm Password Field
                  TextField(
                    controller: confirmPasswordController,
                    obscureText: obscureConfirm,
                    onChanged: (_) => setDialogState(() => errorMessage = null),
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      hintText: 'Re-enter password',
                      prefixIcon: Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: vetGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.check_circle_outline,
                            color: vetGreen, size: 20),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureConfirm
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: mediumGray,
                          size: 20,
                        ),
                        onPressed: () => setDialogState(
                            () => obscureConfirm = !obscureConfirm),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: vetGreen.withOpacity(0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: vetGreen.withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: vetGreen, width: 2),
                      ),
                    ),
                  ),

                  if (errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: Colors.red, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              errorMessage!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: mediumGray,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [primaryTeal, primaryBlue],
                          ),
                          borderRadius: BorderRadius.circular(10),
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
                            final password = passwordController.text;
                            final confirmPassword =
                                confirmPasswordController.text;

                            if (password.length < 8) {
                              setDialogState(() => errorMessage =
                                  'Password must be at least 8 characters');
                              return;
                            }

                            if (password != confirmPassword) {
                              setDialogState(() =>
                                  errorMessage = 'Passwords do not match');
                              return;
                            }

                            // Show confirmation dialog
                            Navigator.pop(dialogContext);
                            _showConfirmationDialog(
                              fullName,
                              email,
                              password,
                              phone,
                              authorities,
                            );
                          },
                          icon: const Icon(Icons.arrow_forward,
                              color: Colors.white, size: 18),
                          label: const Text(
                            'Continue',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showConfirmationDialog(
    String fullName,
    String email,
    String password,
    String phone,
    List<String> authorities,
  ) async {
    bool showPassword = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    vetGreen.withOpacity(0.1),
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [vetGreen, primaryTeal],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.check_circle_outline,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Review & Confirm',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: darkText,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Verify account details',
                              style: TextStyle(
                                fontSize: 13,
                                color: mediumGray,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Account Details Box
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: lightVetGreen.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: vetGreen.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name
                        _buildDetailRow(
                          Icons.person,
                          'Staff Name',
                          fullName,
                          primaryBlue,
                        ),
                        const SizedBox(height: 14),

                        // Email
                        _buildDetailRow(
                          Icons.email,
                          'Email / Username',
                          email,
                          primaryTeal,
                        ),
                        const SizedBox(height: 14),

                        // Phone (if provided)
                        if (phone.isNotEmpty) ...[
                          _buildDetailRow(
                            Icons.phone,
                            'Phone Number',
                            phone,
                            vetOrange,
                          ),
                          const SizedBox(height: 14),
                        ],

                        // Password
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: vetOrange.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.lock,
                                color: vetOrange,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Password',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: mediumGray,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          showPassword
                                              ? password
                                              : '•' * password.length,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: darkText,
                                          ),
                                        ),
                                      ),
                                      InkWell(
                                        onTap: () => setDialogState(
                                            () => showPassword = !showPassword),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: vetOrange.withOpacity(0.15),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                showPassword
                                                    ? Icons.visibility_off
                                                    : Icons.visibility,
                                                size: 14,
                                                color: vetOrange,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                showPassword ? 'Hide' : 'Show',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: vetOrange,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        if (authorities.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          // Permissions
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: vetGreen.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.security,
                                  color: vetGreen,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Permissions',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: mediumGray,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: authorities.map((auth) {
                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: vetGreen.withOpacity(0.2),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                              color: vetGreen.withOpacity(0.4),
                                            ),
                                          ),
                                          child: Text(
                                            auth,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: vetGreen,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Warning Box
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: vetOrange.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: vetOrange, size: 20),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Staff should change this password after first login',
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.3,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: mediumGray,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [vetGreen, primaryTeal],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: vetGreen.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(dialogContext);
                            Navigator.of(this.context).pop();
                            widget.onStaffCreated(
                              fullName,
                              email,
                              phone,
                              authorities,
                              selectedImageBytes,
                              password,
                            );
                          },
                          icon: const Icon(Icons.check_circle,
                              color: Colors.white, size: 20),
                          label: const Text(
                            'Confirm & Create',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 28,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(
      IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: mediumGray,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: darkText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfilePhotoSection() {
    final ImagePicker picker = ImagePicker();

    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            InkWell(
              onTap: () async {
                try {
                  final XFile? result = await picker.pickImage(
                    source: ImageSource.gallery,
                    maxWidth: 1920,
                    maxHeight: 1080,
                  );

                  if (result != null) {
                    final bytes = await result.readAsBytes();
                    if (bytes.length > 5 * 1024 * 1024) return;
                    setState(() {
                      selectedImageBytes = bytes;
                    });
                  }
                } catch (_) {}
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
                          image: MemoryImage(selectedImageBytes!),
                          fit: BoxFit.cover)
                      : null,
                ),
                child: selectedImageBytes == null
                    ? const Icon(Icons.camera_alt_rounded,
                        size: 36, color: primaryTeal)
                    : null,
              ),
            ),
            if (selectedImageBytes != null)
              Positioned(
                top: -4,
                right: -4,
                child: InkWell(
                  onTap: () => setState(() {
                    selectedImageBytes = null;
                  }),
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
                style: const TextStyle(
                    color: primaryTeal,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
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
                Text(title,
                    style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: darkText)),
                if (subtitle != null)
                  Text(subtitle,
                      style: const TextStyle(color: mediumGray, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoFields(bool isDesktop) {
    return Column(
      children: [
        if (isDesktop)
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: widget.firstNameController,
                  label: 'First Name',
                  icon: Icons.badge_outlined,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: widget.surnameController,
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
                controller: widget.firstNameController,
                label: 'First Name',
                icon: Icons.badge_outlined,
              ),
              const SizedBox(height: 18),
              _buildTextField(
                controller: widget.surnameController,
                label: 'Surname',
                icon: Icons.badge_outlined,
              ),
            ],
          ),
        const SizedBox(height: 18),
        _buildPhoneTextField(),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
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
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          labelStyle:
              const TextStyle(color: mediumGray, fontWeight: FontWeight.w500),
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

  Widget _buildPhoneTextField() {
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
        controller: widget.phoneController,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(9),
        ],
        decoration: InputDecoration(
          labelText: 'Phone Number (Optional)',
          labelStyle:
              const TextStyle(color: mediumGray, fontWeight: FontWeight.w500),
          hintText: '123456789',
          helperText: 'Format: 09XXXXXXXXX (9 digits after 09)',
          helperMaxLines: 2,
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryTeal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child:
                const Icon(Icons.phone_outlined, color: primaryTeal, size: 20),
          ),
          prefix: Container(
            padding: const EdgeInsets.only(right: 4),
            child: const Text(
              '09',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: primaryBlue,
              ),
            ),
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

  Widget _buildPermissionsSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: primaryTeal.withOpacity(0.3), width: 2),
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
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.local_hospital_rounded,
                    size: 18,
                    color: primaryTeal,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Clinic Page',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ),
              ],
            ),
            subtitle: const Padding(
              padding: EdgeInsets.only(left: 40, top: 4),
              child: Text(
                'Access to clinic information and settings',
                style: TextStyle(fontSize: 13),
              ),
            ),
            value: clinicAuth,
            onChanged: (val) => setState(() => clinicAuth = val ?? false),
            activeColor: primaryTeal,
            checkColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          Divider(height: 1, color: Colors.grey[300]),
          CheckboxListTile(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: primaryBlue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.calendar_month_rounded,
                    size: 18,
                    color: primaryBlue,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Appointments',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ),
              ],
            ),
            subtitle: const Padding(
              padding: EdgeInsets.only(left: 40, top: 4),
              child: Text(
                'Manage and view appointments',
                style: TextStyle(fontSize: 13),
              ),
            ),
            value: appointmentAuth,
            onChanged: (val) => setState(() => appointmentAuth = val ?? false),
            activeColor: primaryBlue,
            checkColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          Divider(height: 1, color: Colors.grey[300]),
          CheckboxListTile(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: vetOrange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.message_rounded,
                      size: 18, color: vetOrange),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Messages',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ),
              ],
            ),
            subtitle: const Padding(
              padding: EdgeInsets.only(left: 40, top: 4),
              child: Text(
                'Access to messaging system',
                style: TextStyle(fontSize: 13),
              ),
            ),
            value: messagesAuth,
            onChanged: (val) => setState(() => messagesAuth = val ?? false),
            activeColor: vetOrange,
            checkColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ],
      ),
    );
  }
}
