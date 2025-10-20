import 'package:capstone_app/data/models/feedback_deletion_request_model.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/utils/logout_helper.dart';
import 'package:capstone_app/web/super_admin/WebVersion/pet_owners_pages/user_page.dart';
import 'package:capstone_app/web/super_admin/WebVersion/vet_clinic_pages/veterinary_clinics/super_ad_vet_clinic_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:capstone_app/web/super_admin/WebVersion/view_report/user_app_feedback/app_feedback.dart';
import 'package:get/get.dart';
import 'vet_deletion_request_controller.dart';

class VeterinaryReport extends StatefulWidget {
  const VeterinaryReport({super.key});
  
  @override
  State<VeterinaryReport> createState() => _VeterinaryReportState();
}

class _VeterinaryReportState extends State<VeterinaryReport> {
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isLoggingOut = false;

  // Initialize controller
  late final VetDeletionRequestController _controller;

  @override
  void initState() {
    super.initState();
    
    // Initialize GetX controller
    _controller = Get.put(
      VetDeletionRequestController(
        authRepository: Get.find<AuthRepository>(),
      ),
    );

    // Listen to search controller changes
    _searchController.addListener(() {
      _controller.updateSearchQuery(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    Get.delete<VetDeletionRequestController>();
    super.dispose();
  }

  /// Show request details dialog
  void _showRequestDetails(FeedbackDeletionRequest request) async {
    // Get clinic name
    final clinicName = await _controller.getClinicName(request.clinicId);
    
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => RequestDetailDialog(
        request: request,
        clinicName: clinicName,
      ),
    );
  }

  /// Handle deletion request (Approve/Reject)
  void _handleDeletionRequest(FeedbackDeletionRequest request) async {
    // Get clinic name
    final clinicName = await _controller.getClinicName(request.clinicId);
    
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => DeleteRequestActionDialog(
        request: request,
        clinicName: clinicName,
        onApprove: (reviewNotes) => _controller.approveDeletionRequest(
          request,
          'Super Admin', // You can get this from GetStorage
          reviewNotes,
        ),
        onDeny: (reviewNotes) => _controller.rejectDeletionRequest(
          request,
          'Super Admin',
          reviewNotes,
        ),
      ),
    );
  }

  /// Delete a processed request
  void _deleteRequest(FeedbackDeletionRequest request) async {
    final clinicName = await _controller.getClinicName(request.clinicId);
    
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: const Color.fromRGBO(248, 253, 255, 1),
        title: const Row(
          children: [
            Icon(Icons.delete_forever, color: Color(0xFFE74C3C)),
            SizedBox(width: 8),
            Text('Confirm Deletion'),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete the ${request.status} request for "$clinicName"?\n\nThis action cannot be undone.',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF95A5A6),
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _controller.deleteProcessedRequest(request);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE74C3C),
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardStats() {
    return Obx(() {
      final stats = _controller.stats;
      
      return Container(
        color: const Color.fromRGBO(248, 253, 255, 1),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _buildStatCard(
              'Total Requests',
              stats['total'].toString(),
              Icons.delete_forever,
              const Color(0xFF4A90E2),
            ),
            const SizedBox(width: 12),
            _buildStatCard(
              'Pending',
              stats['pending'].toString(),
              Icons.pending,
              const Color(0xFFF39C12),
            ),
            const SizedBox(width: 12),
            _buildStatCard(
              'Approved',
              stats['approved'].toString(),
              Icons.check_circle,
              const Color(0xFF2ECC71),
            ),
            const SizedBox(width: 12),
            _buildStatCard(
              'Rejected',
              stats['rejected'].toString(),
              Icons.cancel,
              const Color(0xFFE74C3C),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      color: const Color.fromRGBO(248, 253, 255, 1),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by clinic, requester, or reason...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: Obx(() {
                return _controller.searchQuery.value.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _controller.updateSearchQuery('');
                        },
                      )
                    : const SizedBox.shrink();
              }),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color.fromRGBO(81, 115, 153, 1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color.fromRGBO(81, 115, 153, 1),
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildStatusDropdown()),
              const SizedBox(width: 12),
              Expanded(child: _buildReasonDropdown()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDropdown() {
    return Obx(() {
      return DropdownButtonFormField<String>(
        dropdownColor: const Color.fromRGBO(248, 253, 255, 1),
        value: _controller.selectedStatus.value,
        decoration: InputDecoration(
          labelText: 'Status',
          labelStyle: const TextStyle(color: Colors.black),
          floatingLabelStyle: const TextStyle(color: Color(0xFF517399)),
          border: OutlineInputBorder(
            borderSide: const BorderSide(color: Color(0xFF517399)),
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        items: ['All', 'pending', 'approved', 'rejected']
            .map((status) => DropdownMenuItem(
                  value: status,
                  child: Text(status == 'All' ? 'All' : status.capitalize!),
                ))
            .toList(),
        onChanged: (value) {
          if (value != null) {
            _controller.updateStatusFilter(value);
          }
        },
      );
    });
  }

  Widget _buildReasonDropdown() {
    return Obx(() {
      // Get unique reasons from all requests
      final reasons = ['All', ..._controller.allRequests.map((r) => r.reason).toSet()];

      return DropdownButtonFormField<String>(
        dropdownColor: const Color.fromRGBO(248, 253, 255, 1),
        value: _controller.selectedReason.value,
        decoration: InputDecoration(
          labelText: 'Reason',
          labelStyle: const TextStyle(color: Colors.black),
          floatingLabelStyle: const TextStyle(color: Color(0xFF517399)),
          border: OutlineInputBorder(
            borderSide: const BorderSide(color: Color(0xFF517399)),
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        items: reasons
            .map((reason) => DropdownMenuItem(value: reason, child: Text(reason)))
            .toList(),
        onChanged: (value) {
          if (value != null) {
            _controller.updateReasonFilter(value);
          }
        },
      );
    });
  }

  Widget _buildRequestList() {
    return Obx(() {
      if (_controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (_controller.filteredRequests.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No deletion requests found',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _controller.filteredRequests.length,
        itemBuilder: (context, index) {
          final request = _controller.filteredRequests[index];
          return _buildRequestCard(request);
        },
      );
    });
  }

  Widget _buildRequestCard(FeedbackDeletionRequest request) {
    return FutureBuilder<String>(
      future: _controller.getClinicName(request.clinicId),
      builder: (context, snapshot) {
        final clinicName = snapshot.data ?? 'Loading...';

        return Card(
          color: const Color.fromRGBO(242, 250, 252, 1),
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _showRequestDetails(request),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.business, size: 20, color: Colors.grey[600]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                clinicName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildStatusChip(request.status),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.report_problem, size: 14, color: Colors.orange[700]),
                        const SizedBox(width: 4),
                        Text(
                          request.reason,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (request.additionalDetails != null &&
                      request.additionalDetails!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      request.additionalDetails!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.person, size: 16, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        'Requested by admin',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.access_time, size: 16, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        '${request.requestedAt.day}/${request.requestedAt.month}/${request.requestedAt.year}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  if (request.hasAttachments) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.attach_file, size: 16, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          '${request.attachments.length} attachment(s)',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                  if (request.reviewNotes != null && request.reviewNotes!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: request.status == 'rejected'
                            ? Colors.red[50]
                            : Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: request.status == 'rejected'
                              ? Colors.red[200]!
                              : Colors.green[200]!,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                request.status == 'rejected'
                                    ? Icons.error_outline
                                    : Icons.check_circle_outline,
                                size: 16,
                                color: request.status == 'rejected'
                                    ? Colors.red[600]
                                    : Colors.green[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Review Notes',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: request.status == 'rejected'
                                      ? Colors.red[600]
                                      : Colors.green[600],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            request.reviewNotes!,
                            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          if (request.isPending) ...[
                            ElevatedButton.icon(
                              onPressed: _controller.isProcessing.value
                                  ? null
                                  : () => _handleDeletionRequest(request),
                              icon: const Icon(Icons.gavel, size: 16, color: Colors.white),
                              label: const Text('Process'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(255, 81, 115, 153),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                              ),
                            ),
                          ],
                          if (request.isApproved || request.isRejected) ...[
                            ElevatedButton.icon(
                              onPressed: _controller.isProcessing.value
                                  ? null
                                  : () => _deleteRequest(request),
                              icon: const Icon(
                                Icons.delete_forever,
                                size: 16,
                                color: Colors.white,
                              ),
                              label: const Text('Delete Record'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE74C3C),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'approved':
        color = const Color(0xFF2ECC71);
        break;
      case 'pending':
        color = const Color(0xFFF39C12);
        break;
      case 'rejected':
        color = const Color(0xFFE74C3C);
        break;
      default:
        color = const Color(0xFF95A5A6);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status.capitalize!,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(context),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, color: Color.fromRGBO(81, 115, 153, 1)),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
          tooltip: 'Menu',
        ),
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: const Row(
          children: [
            Icon(Icons.delete_forever, color: Color.fromARGB(255, 81, 115, 153)),
            SizedBox(width: 8),
            Text(
              'Vet Reports',
              style: TextStyle(
                color: Color.fromARGB(255, 81, 115, 153),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: const Color.fromARGB(255, 248, 253, 255),
        elevation: 0,
        actions: [
          Obx(() {
            if (_controller.isLoading.value) {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            }
            return IconButton(
              icon: const Icon(Icons.refresh, color: Color.fromRGBO(81, 115, 153, 1)),
              onPressed: () => _controller.loadAllDeletionRequests(),
              tooltip: 'Refresh',
            );
          }),
        ],
      ),
      backgroundColor: const Color.fromRGBO(248, 253, 255, 1),
      body: Column(
        children: [
          _buildDashboardStats(),
          _buildSearchAndFilters(),
          Expanded(child: _buildRequestList()),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: const Color.fromRGBO(248, 253, 255, 1),
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.fromRGBO(81, 115, 153, 1),
                  Color.fromRGBO(81, 115, 153, 0.8),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Developer',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Management Panel',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildDrawerItem(
                  context,
                  icon: Icons.local_hospital_rounded,
                  title: 'Veterinary Clinics',
                  subtitle: 'Manage vet clinics',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SuperAdminVetClinicDashboard(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.people_rounded,
                  title: 'Pet Owner Management',
                  subtitle: 'Manage user accounts',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SuperAdminUserManagementScreen(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.feedback_rounded,
                  title: 'System Reports',
                  subtitle: 'User feedback & reports',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminFeedbackManagement(),
                      ),
                    );
                  },
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Divider(),
                ),
              ],
            ),
          ),

          // Logout Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: _isLoggingOut
                  ? Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color.fromRGBO(81, 115, 153, 0.7),
                            Color.fromRGBO(81, 115, 153, 0.5),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Logging Out...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : InkWell(
                      onTap: () async {
                        setState(() => _isLoggingOut = true);
                        try {
                          await LogoutHelper.logout();
                        } catch (e) {
                          if (mounted) {
                            setState(() => _isLoggingOut = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Logout failed: ${e.toString()}'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color.fromRGBO(220, 53, 69, 1),
                              Color.fromRGBO(200, 35, 51, 1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.logout_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Log Out',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color.fromRGBO(81, 115, 153, 0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color.fromRGBO(81, 115, 153, 0.2),
                      Color.fromRGBO(81, 115, 153, 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: const Color.fromRGBO(81, 115, 153, 1),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color.fromRGBO(81, 115, 153, 1),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Color.fromRGBO(81, 115, 153, 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============= DIALOG WIDGETS =============

class RequestDetailDialog extends StatelessWidget {
  final FeedbackDeletionRequest request;
  final String clinicName;

  const RequestDetailDialog({
    super.key,
    required this.request,
    required this.clinicName,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color.fromRGBO(248, 253, 255, 1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.delete_forever, color: Color(0xFF517399), size: 24),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Deletion Request Details',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 16),
              _buildDetailRow('Vet Clinic:', clinicName),
              _buildDetailRow('Reason:', request.reason),
              _buildDetailRow('Status:', request.status.capitalize!),
              _buildDetailRow(
                'Date Requested:',
                '${request.requestedAt.day}/${request.requestedAt.month}/${request.requestedAt.year} ${request.requestedAt.hour}:${request.requestedAt.minute.toString().padLeft(2, '0')}',
              ),
              if (request.reviewedAt != null)
                _buildDetailRow(
                  'Date Processed:',
                  '${request.reviewedAt!.day}/${request.reviewedAt!.month}/${request.reviewedAt!.year} ${request.reviewedAt!.hour}:${request.reviewedAt!.minute.toString().padLeft(2, '0')}',
                ),
              if (request.reviewedBy != null)
                _buildDetailRow('Reviewed By:', request.reviewedBy!),
              const SizedBox(height: 16),
              if (request.additionalDetails != null && request.additionalDetails!.isNotEmpty) ...[
                const Text(
                  'Additional Details:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FDFF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE0E6ED)),
                  ),
                  child: Text(
                    request.additionalDetails!,
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),
                ),
              ],
              if (request.reviewNotes != null && request.reviewNotes!.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Review Notes:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: request.status == 'rejected' ? Colors.red[50] : Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: request.status == 'rejected'
                          ? Colors.red[200]!
                          : Colors.green[200]!,
                    ),
                  ),
                  child: Text(
                    request.reviewNotes!,
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),
                ),
              ],
              if (request.hasAttachments) ...[
                const SizedBox(height: 16),
                Text(
                  'Attachments (${request.attachments.length}):',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                ...request.attachments.map((attachmentId) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.attach_file, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Attachment ID: $attachmentId',
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFF517399),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Color(0xFF7F8C8D),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class DeleteRequestActionDialog extends StatefulWidget {
  final FeedbackDeletionRequest request;
  final String clinicName;
  final Function(String?) onApprove;
  final Function(String?) onDeny;

  const DeleteRequestActionDialog({
    super.key,
    required this.request,
    required this.clinicName,
    required this.onApprove,
    required this.onDeny,
  });

  @override
  State<DeleteRequestActionDialog> createState() => _DeleteRequestActionDialogState();
}

class _DeleteRequestActionDialogState extends State<DeleteRequestActionDialog> {
  final TextEditingController _reviewNotesController = TextEditingController();
  bool _showReviewForm = false;
  bool _isApproving = true;

  @override
  void dispose() {
    _reviewNotesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.gavel, color: Color(0xFF517399)),
          SizedBox(width: 8),
          Text('Process Deletion Request'),
        ],
      ),
      backgroundColor: const Color.fromRGBO(248, 253, 255, 1),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Review the deletion request for "${widget.clinicName}":',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FDFF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE0E6ED)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reason: ${widget.request.reason}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (widget.request.additionalDetails != null &&
                      widget.request.additionalDetails!.isNotEmpty) ...[
                    const Text('Details:', style: TextStyle(fontWeight: FontWeight.w600)),
                    Text(
                      widget.request.additionalDetails!,
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (!_showReviewForm) ...[
              const Text(
                'What would you like to do with this request?',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ] else ...[
              Text(
                _isApproving
                    ? 'Add review notes (optional):'
                    : 'Please provide a reason for rejection:',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _reviewNotesController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: _isApproving
                      ? 'Enter optional notes...'
                      : 'Enter rejection reason...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF517399), width: 2),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (!_showReviewForm) ...[
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFF95A5A6)),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _showReviewForm = true;
                _isApproving = false;
              });
            },
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFE74C3C)),
            child: const Text('Reject Request'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _showReviewForm = true;
                _isApproving = true;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2ECC71),
              foregroundColor: Colors.white,
            ),
            child: const Text('Approve Deletion'),
          ),
        ] else ...[
          TextButton(
            onPressed: () {
              setState(() {
                _showReviewForm = false;
                _reviewNotesController.clear();
              });
            },
            style: TextButton.styleFrom(foregroundColor: const Color(0xFF95A5A6)),
            child: const Text('Back'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (_isApproving) {
                widget.onApprove(_reviewNotesController.text.trim().isEmpty
                    ? null
                    : _reviewNotesController.text.trim());
              } else {
                if (_reviewNotesController.text.trim().isNotEmpty) {
                  widget.onDeny(_reviewNotesController.text.trim());
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please provide a rejection reason'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _isApproving ? const Color(0xFF2ECC71) : const Color(0xFFE74C3C),
              foregroundColor: Colors.white,
            ),
            child: Text(_isApproving ? 'Confirm Approval' : 'Confirm Rejection'),
          ),
        ],
      ],
    );
  }
}