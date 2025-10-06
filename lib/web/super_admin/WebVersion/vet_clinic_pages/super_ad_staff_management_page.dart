import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:capstone_app/data/models/staff_model.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/utils/image_helper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SuperAdminStaffManagementPage extends StatefulWidget {
  final Clinic clinic;

  const SuperAdminStaffManagementPage({
    super.key,
    required this.clinic,
  });

  @override
  State<SuperAdminStaffManagementPage> createState() =>
      _SuperAdminStaffManagementPageState();
}

class _SuperAdminStaffManagementPageState
    extends State<SuperAdminStaffManagementPage> {
  final AuthRepository authRepository = Get.find<AuthRepository>();
  List<Staff> staffList = [];
  bool isLoading = true;
  String errorMessage = '';
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadStaff();
  }

  Future<void> _loadStaff() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });

      final staff =
          await authRepository.getClinicStaff(widget.clinic.documentId ?? '');

      setState(() {
        staffList = staff;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading staff: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  List<Staff> get filteredStaff {
    if (searchQuery.isEmpty) return staffList;

    return staffList.where((staff) {
      return staff.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          staff.email.toLowerCase().contains(searchQuery.toLowerCase()) ||
          staff.department.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1000;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 248, 253, 255),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 248, 253, 255),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back,
              color: Color.fromARGB(255, 81, 115, 153)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Staff Management',
              style: TextStyle(
                color: Color.fromARGB(255, 81, 115, 153),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              widget.clinic.clinicName,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh,
                color: Color.fromARGB(255, 81, 115, 153)),
            onPressed: _loadStaff,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.05,
              vertical: 16,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search staff...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color.fromARGB(255, 81, 115, 153),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color.fromARGB(255, 81, 115, 153),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 81, 115, 153),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.filter_list, color: Colors.white),
                    onPressed: () {
                      // Implement filter functionality
                    },
                    tooltip: 'Filter',
                  ),
                ),
              ],
            ),
          ),

          // Staff Count
          Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${filteredStaff.length} Staff Members',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    // Navigate to add staff page or show dialog
                    _showAddStaffInfo();
                  },
                  icon: const Icon(Icons.info_outline, size: 16),
                  label: const Text('Add Staff Info'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color.fromARGB(255, 81, 115, 153),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Staff List
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color.fromARGB(255, 81, 115, 153),
                    ),
                  )
                : errorMessage.isNotEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline,
                                size: 64, color: Colors.red),
                            const SizedBox(height: 16),
                            Text(
                              errorMessage,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadStaff,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color.fromARGB(255, 81, 115, 153),
                              ),
                              child: const Text('Retry',
                                  style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      )
                    : filteredStaff.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.people_outline,
                                    size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text(
                                  searchQuery.isEmpty
                                      ? 'No staff members yet'
                                      : 'No staff found',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadStaff,
                            color: const Color.fromARGB(255, 81, 115, 153),
                            child: ListView.builder(
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.05,
                                vertical: 16,
                              ),
                              itemCount: filteredStaff.length,
                              itemBuilder: (context, index) {
                                final staff = filteredStaff[index];
                                return _buildStaffCard(staff, isMobile);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffCard(Staff staff, bool isMobile) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showStaffDetails(staff),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: isMobile
              ? _buildMobileLayout(staff)
              : _buildDesktopLayout(staff),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(Staff staff) {
    return Column(
      children: [
        Row(
          children: [
            _buildStaffAvatar(staff),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    staff.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 81, 115, 153),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    staff.email,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            _buildStatusBadge(staff),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildInfoChip(Icons.work_outline, staff.department),
            _buildInfoChip(Icons.badge, staff.role),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showStaffDetails(staff),
                icon: const Icon(Icons.visibility, size: 16),
                label: const Text('View'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color.fromARGB(255, 81, 115, 153),
                  side: const BorderSide(
                    color: Color.fromARGB(255, 81, 115, 153),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _confirmDeleteStaff(staff),
                icon: const Icon(Icons.delete, size: 16),
                label: const Text('Delete'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(Staff staff) {
    return Row(
      children: [
        _buildStaffAvatar(staff),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                staff.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 81, 115, 153),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                staff.email,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _buildInfoChip(Icons.work_outline, staff.department),
        ),
        Expanded(
          child: _buildInfoChip(Icons.badge, staff.role),
        ),
        _buildStatusBadge(staff),
        const SizedBox(width: 12),
        IconButton(
          onPressed: () => _showStaffDetails(staff),
          icon: const Icon(Icons.visibility),
          color: const Color.fromARGB(255, 81, 115, 153),
          tooltip: 'View Details',
        ),
        IconButton(
          onPressed: () => _confirmDeleteStaff(staff),
          icon: const Icon(Icons.delete),
          color: Colors.red,
          tooltip: 'Delete Staff',
        ),
      ],
    );
  }

  Widget _buildStaffAvatar(Staff staff) {
    return CircleAvatar(
      radius: 30,
      backgroundColor: const Color.fromARGB(255, 81, 115, 153).withOpacity(0.1),
      backgroundImage: staff.image.isNotEmpty
          ? NetworkImage(getPetImageUrl(staff.image))
          : null,
      child: staff.image.isEmpty
          ? Text(
              staff.name.isNotEmpty ? staff.name[0].toUpperCase() : 'S',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 81, 115, 153),
              ),
            )
          : null,
    );
  }

  Widget _buildStatusBadge(Staff staff) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: staff.isActive ? Colors.green[100] : Colors.red[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        staff.isActive ? 'Active' : 'Inactive',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: staff.isActive ? Colors.green[800] : Colors.red[800],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _showStaffDetails(Staff staff) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      _buildStaffAvatar(staff),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              staff.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color.fromARGB(255, 81, 115, 153),
                              ),
                            ),
                            const SizedBox(height: 4),
                            _buildStatusBadge(staff),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  _buildDetailRow('Email', staff.email, Icons.email),
                  _buildDetailRow('Phone', staff.phone ?? 'N/A', Icons.phone),
                  _buildDetailRow('Department', staff.department, Icons.work),
                  _buildDetailRow('Role', staff.role, Icons.badge),
                  _buildDetailRow('User ID', staff.userId, Icons.fingerprint),
                  const SizedBox(height: 16),
                  const Text(
                    'Authorities',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 81, 115, 153),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: staff.authorities.map((authority) {
                      return Chip(
                        label: Text(authority),
                        backgroundColor: const Color.fromARGB(255, 81, 115, 153)
                            .withOpacity(0.1),
                        labelStyle: const TextStyle(
                          fontSize: 12,
                          color: Color.fromARGB(255, 81, 115, 153),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    'Created',
                    _formatDate(staff.createdAt),
                    Icons.calendar_today,
                  ),
                  _buildDetailRow(
                    'Last Updated',
                    _formatDate(staff.updatedAt),
                    Icons.update,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _confirmDeleteStaff(staff);
                          },
                          icon: const Icon(Icons.delete),
                          label: const Text('Delete Staff'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteStaff(Staff staff) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Staff Member'),
        content: Text(
          'Are you sure you want to delete ${staff.name}?\n\n'
          'This action cannot be undone. The staff member will be permanently removed from the system.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteStaff(staff);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteStaff(Staff staff) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            color: Color.fromARGB(255, 81, 115, 153),
          ),
        ),
      );

      await authRepository.deleteStaffAccountPermanently(staff.documentId!);

      // Close loading indicator
      if (mounted) Navigator.pop(context);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${staff.name} has been deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );

      // Reload staff list
      await _loadStaff();
    } catch (e) {
      // Close loading indicator
      if (mounted) Navigator.pop(context);

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting staff: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAddStaffInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Staff Member'),
        content: const Text(
          'To add new staff members, administrators should use the clinic admin panel.\n\n'
          'Staff creation requires:\n'
          '• Name and email\n'
          '• Password for login\n'
          '• Department and role\n'
          '• Assigned authorities/permissions\n\n'
          'Super admin can view and manage existing staff but should not create staff accounts directly.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return isoDate;
    }
  }
}