import 'package:flutter/material.dart';
import 'dart:typed_data';

class StaffFullDetails extends StatefulWidget {
  final String staffName;
  final String email;
  final String? phone;
  final Function(List<String>) onAuthoritiesUpdated;
  final List<String> initialAuthorities;
  final VoidCallback onRemove;
  final Uint8List? imageBytes;

  const StaffFullDetails({
    required this.staffName,
    required this.email,
    this.phone,
    required this.onAuthoritiesUpdated,
    required this.initialAuthorities,
    required this.onRemove,
    this.imageBytes,
    super.key,
  });

  @override
  State<StaffFullDetails> createState() => _StaffFullDetailsState();
}

class _StaffFullDetailsState extends State<StaffFullDetails> {
  late bool hasClinicAuthority;
  late bool hasAppointmentsAuthority;
  late bool hasMessagesAuthority;
  bool showDeleteConfirm = false;

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
  static const Color vetPurple = Color(0x00a855f7);
  static const Color lightVetGreen = Color(0xFFE5F7E5);

  @override
  void initState() {
    super.initState();
    hasClinicAuthority = widget.initialAuthorities.contains('Clinic');
    hasAppointmentsAuthority =
        widget.initialAuthorities.contains('Appointments');
    hasMessagesAuthority = widget.initialAuthorities.contains('Messages');
  }

  void _handleUpdate() {
    List<String> updatedAuthorities = [];
    if (hasClinicAuthority) updatedAuthorities.add('Clinic');
    if (hasAppointmentsAuthority) updatedAuthorities.add('Appointments');
    if (hasMessagesAuthority) updatedAuthorities.add('Messages');
    widget.onAuthoritiesUpdated(updatedAuthorities);
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
                child: Text(
                    '${widget.staffName}\'s permissions updated successfully')),
          ],
        ),
        backgroundColor: vetGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _handleRemove() {
    if (showDeleteConfirm) {
      widget.onRemove();
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('${widget.staffName} has been removed')),
            ],
          ),
          backgroundColor: vetOrange,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else {
      setState(() {
        showDeleteConfirm = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isDesktop = screenWidth > 768;
    final dialogWidth = isDesktop ? 480.0 : screenWidth * 0.9;

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
          color: Colors.white,
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
            // Header with gradient
            Container(
              padding: EdgeInsets.all(isDesktop ? 28 : 24),
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
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: _buildHeader(),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isDesktop ? 28 : 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Contact Information
                    _buildSectionHeader(
                      'Contact Information',
                      Icons.contact_mail_outlined,
                      primaryBlue,
                    ),
                    const SizedBox(height: 20),
                    _buildContactInfoSection(),
                    const SizedBox(height: 28),

                    // Permissions Section
                    _buildSectionHeader(
                      'Access Permissions',
                      Icons.security_rounded,
                      vetGreen,
                      subtitle: 'Manage what this staff member can access',
                    ),
                    const SizedBox(height: 20),
                    _buildPermissionsSection(),

                    if (showDeleteConfirm) ...[
                      const SizedBox(height: 20),
                      _buildDeleteConfirmation(),
                    ],
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
              child: _buildActionButtons(screenWidth > 500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: widget.imageBytes != null
              ? ClipOval(
                  child: Image.memory(
                    widget.imageBytes!,
                    fit: BoxFit.cover,
                    width: 92,
                    height: 92,
                  ),
                )
              : Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: lightVetGreen.withOpacity(0.3),
                  ),
                  child: const Icon(Icons.person, size: 45, color: primaryTeal),
                ),
        ),
        const SizedBox(height: 16),
        Text(
          widget.staffName,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.25),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: const Text(
            'Staff Member',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
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
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: darkText,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: const TextStyle(color: mediumGray, fontSize: 13),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: lightGray,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryTeal.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: primaryTeal.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoRow(Icons.email_outlined, 'Email', widget.email),
          const SizedBox(height: 16),
          _buildInfoRow(
              Icons.phone_outlined, 'Phone', widget.phone ?? 'Not provided'),
          const SizedBox(height: 16),
          _buildInfoRow(
              Icons.location_on_outlined, 'Location', 'Veterinary Clinic'),
        ],
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
          _buildAuthTile(
            'Clinic Page',
            'Access to clinic information',
            Icons.local_hospital_rounded,
            [primaryTeal, primaryBlue],
            hasClinicAuthority,
            (val) => setState(() => hasClinicAuthority = val!),
          ),
          Divider(height: 1, color: Colors.grey[300]),
          _buildAuthTile(
            'Appointments',
            'Manage appointments',
            Icons.calendar_month_rounded,
            [primaryBlue, softBlue],
            hasAppointmentsAuthority,
            (val) => setState(() => hasAppointmentsAuthority = val!),
          ),
          Divider(height: 1, color: Colors.grey[300]),
          _buildAuthTile(
            'Messages',
            'Access messaging system',
            Icons.message_rounded,
            [vetOrange, primaryTeal],
            hasMessagesAuthority,
            (val) => setState(() => hasMessagesAuthority = val!),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteConfirmation() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[300]!, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.warning_amber_rounded,
                color: Colors.red[700], size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Are you sure you want to remove ${widget.staffName}? This action cannot be undone.',
              style: TextStyle(
                color: Colors.red[700],
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool isWide) {
    if (isWide) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (!showDeleteConfirm)
            TextButton.icon(
              onPressed: _handleRemove,
              icon: const Icon(Icons.delete_outline, size: 20),
              label: const Text('Remove'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            )
          else
            Row(
              children: [
                TextButton(
                  onPressed: () => setState(() => showDeleteConfirm = false),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: mediumGray,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _handleRemove,
                  icon: const Icon(Icons.delete_forever, size: 18),
                  label: const Text('Confirm Remove'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          if (!showDeleteConfirm)
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Close',
                    style: TextStyle(
                      color: mediumGray,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [primaryTeal, primaryBlue]),
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
                    onPressed: _handleUpdate,
                    icon: const Icon(Icons.save_outlined,
                        size: 18, color: Colors.white),
                    label: const Text('Save Changes',
                        style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
        ],
      );
    } else {
      return Column(
        children: [
          if (showDeleteConfirm) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => setState(() => showDeleteConfirm = false),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: mediumGray,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _handleRemove,
                    icon: const Icon(Icons.delete_forever, size: 18),
                    label: const Text('Confirm'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: _handleRemove,
                    icon: const Icon(Icons.delete_outline, size: 20),
                    label: const Text('Remove'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Close',
                      style: TextStyle(
                        color: mediumGray,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: Container(
                decoration: BoxDecoration(
                  gradient:
                      const LinearGradient(colors: [primaryTeal, primaryBlue]),
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
                  onPressed: _handleUpdate,
                  icon: const Icon(Icons.save_outlined,
                      size: 18, color: Colors.white),
                  label: const Text('Save Changes',
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ),
          ],
        ],
      );
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primaryTeal.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: primaryTeal),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: mediumGray,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: darkText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAuthTile(
    String title,
    String subtitle,
    IconData icon,
    List<Color> colors,
    bool value,
    Function(bool?) onChanged,
  ) {
    return SwitchListTile(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: colors.first.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: colors.first),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(left: 40, top: 6),
        child: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: mediumGray),
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: colors.first,
      activeTrackColor: colors.first.withOpacity(0.3),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }
}
