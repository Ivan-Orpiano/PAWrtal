import 'package:capstone_app/web/user_web/controllers/web_feedback_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:capstone_app/data/models/feedback_and_report_model.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/utils/user_session_service.dart';
import 'package:capstone_app/web/super_admin/WebVersion/vet_clinic_pages/veterinary_clinics/super_ad_vet_clinic_dashboard.dart';
import 'package:capstone_app/web/super_admin/WebVersion/pet_owners_pages/user_page.dart';
import 'package:capstone_app/web/super_admin/WebVersion/view_report/user_vet_feedback/super_admin_feedback_manager.dart';
import 'package:capstone_app/utils/logout_helper.dart';

class AdminFeedbackManagement extends StatefulWidget {
  const AdminFeedbackManagement({super.key});

  @override
  State<AdminFeedbackManagement> createState() => _AdminFeedbackManagementState();
}

class _AdminFeedbackManagementState extends State<AdminFeedbackManagement> {
  late WebFeedbackController controller;
  final TextEditingController searchController = TextEditingController();

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    controller = Get.put(WebFeedbackController(
      authRepository: Get.find<AuthRepository>(),
      session: Get.find<UserSessionService>(),
    ));
    controller.loadAllFeedback();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey,
      appBar: AppBar(
              surfaceTintColor: Colors.transparent,
            leading: IconButton(
        icon: const Icon(Icons.menu_rounded, color: Color(0xFF517399)),
        onPressed: () {
          _scaffoldKey.currentState?.openDrawer();
        },
        tooltip: 'Menu',
      ),
        title: const Row(
          children: [
            Icon(Icons.feedback, color: Color(0xFF517399)),
            SizedBox(width: 8),
            Text(
              'Feedback Management',
              style: TextStyle(
                color: Color(0xFF517399),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: const Color.fromRGBO(248, 253, 255, 1),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF517399)),
            onPressed: () => controller.loadAllFeedback(),
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.filter_list_off, color: Color(0xFF517399)),
            onPressed: () => controller.clearFilters(),
            tooltip: 'Clear Filters',
          ),
          const SizedBox(width: 16),
        ],
      ),
      drawer: _buildDrawer(context),
      backgroundColor: const Color.fromRGBO(248, 253, 255, 1),
      body: Column(
        children: [
          _buildStatsCards(),
          _buildFiltersSection(),
          Expanded(child: _buildFeedbackList()),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return Obx(() => Container(
      color: const Color.fromRGBO(248, 253, 255, 1),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildStatCard(
            'Total',
            controller.feedbackStats['total']?.toString() ?? '0',
            Colors.blue,
            Icons.feedback,
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            'Pending',
            controller.feedbackStats['pending']?.toString() ?? '0',
            Colors.orange,
            Icons.pending,
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            'In Progress',
            controller.feedbackStats['inProgress']?.toString() ?? '0',
            Colors.blue,
            Icons.work,
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            'Resolved',
            controller.feedbackStats['resolved']?.toString() ?? '0',
            Colors.green,
            Icons.check_circle,
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            'Critical',
            controller.feedbackStats['critical']?.toString() ?? '0',
            Colors.red,
            Icons.warning,
          ),
        ],
      ),
    ));
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
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

  Widget _buildFiltersSection() {
    return Container(
      color: const Color.fromRGBO(248, 253, 255, 1),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Search Bar
          TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'Search feedback...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: Obx(() => controller.searchQuery.value.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      searchController.clear();
                      controller.updateSearchQuery('');
                    },
                  )
                : const SizedBox()),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF517399)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF517399), width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (value) => controller.updateSearchQuery(value),
          ),
          const SizedBox(height: 12),
          
          // Filter Dropdowns
         // Filter Dropdowns
          Row(
            children: [
              Expanded(
                child: Obx(() => _buildFilterDropdown<FeedbackStatus>(
                  'Status',
                  controller.statusFilter.value,
                  FeedbackStatus.values,
                  (value) => controller.updateFilters(status: value),
                  (status) => status.displayName,
                )),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Obx(() => _buildFilterDropdown<FeedbackType>(
                  'Type',
                  controller.typeFilter.value,
                  FeedbackType.values,
                  (value) => controller.updateFilters(type: value),
                  (type) => type.displayName,
                )),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Obx(() => _buildFilterDropdown<FeedbackCategory>(
                  'Category',
                  controller.categoryFilter.value,
                  FeedbackCategory.values,
                  (value) => controller.updateFilters(category: value),
                  (category) => category.displayName,
                )),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Obx(() => _buildFilterDropdown<Priority>(
                  'Priority',
                  controller.priorityFilter.value,
                  Priority.values,
                  (value) => controller.updateFilters(priority: value),
                  (priority) => priority.displayName,
                )),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown<T>(
    String label,
    T? selectedValue,
    List<T> items,
    Function(T?) onChanged,
    String Function(T) getText,
  ) {
    return DropdownButtonFormField<T>(
      dropdownColor: const Color.fromRGBO(248, 253, 255, 1),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black),
        floatingLabelStyle: const TextStyle(color: Color(0xFF517399)),
        border: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFF517399)),
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      value: selectedValue,
      items: [
        DropdownMenuItem<T>(
          value: null,
          child: Text('All'),
        ),
        ...items.map((item) => DropdownMenuItem<T>(
          value: item,
          child: Text(getText(item)),
        )),
      ],
      onChanged: onChanged,
    );
  }

  Widget _buildFeedbackList() {
    return Obx(() {
      if (controller.isLoadingFeedback.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.filteredFeedback.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.feedback_outlined, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No feedback found',
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
        itemCount: controller.filteredFeedback.length,
        itemBuilder: (context, index) {
          final feedback = controller.filteredFeedback[index];
          return _buildFeedbackCard(feedback);
        },
      );
    });
  }

  Widget _buildFeedbackCard(FeedbackAndReport feedback) {
    return Card(
      color: const Color.fromRGBO(242, 250, 252, 1),
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showFeedbackDetails(feedback),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badges Row
              Row(
                children: [
                  _buildPriorityBadge(feedback.priority),
                  const SizedBox(width: 8),
                  _buildTypeBadge(feedback.feedbackType),
                  const SizedBox(width: 8),
                  _buildCategoryBadge(feedback.category),
                  const Spacer(),
                  _buildStatusBadge(feedback.status),
                ],
              ),
              const SizedBox(height: 12),
              
              // Subject
              Text(
                feedback.subject,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              
              // Description
              Text(
                feedback.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              
              // Meta Information
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    feedback.userName,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.access_time, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    _formatDateTime(feedback.submittedAt),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  if (feedback.attachments.isNotEmpty) ...[
                    const SizedBox(width: 16),
                    Icon(Icons.attachment, size: 16, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      '${feedback.attachments.length}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ],
              ),
              
              // Quick Actions for Closed/Resolved
              if (feedback.status == FeedbackStatus.closed ||
                feedback.status == FeedbackStatus.resolved) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (feedback.status == FeedbackStatus.closed)
                    ElevatedButton.icon(
                      onPressed: () => _archiveFeedback(feedback), // Now with confirmation
                      icon: const Icon(Icons.archive, size: 16, color: Colors.white),
                      label: const Text('Archive'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[600], // Changed color for better visibility
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                ],
              ),
            ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityBadge(Priority priority) {
    Color color = _getPriorityColor(priority);
    IconData icon = _getPriorityIcon(priority);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            priority.displayName,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeBadge(FeedbackType type) {
    Color color = _getTypeColor(type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        type.displayName,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildCategoryBadge(FeedbackCategory category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        category.displayName,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(FeedbackStatus status) {
    Color color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Color _getPriorityColor(Priority priority) {
    switch (priority) {
      case Priority.critical:
        return Colors.red;
      case Priority.high:
        return Colors.orange;
      case Priority.medium:
        return Colors.yellow[700]!;
      case Priority.low:
        return Colors.grey;
    }
  }

  IconData _getPriorityIcon(Priority priority) {
    switch (priority) {
      case Priority.critical:
        return Icons.error;
      case Priority.high:
        return Icons.warning;
      case Priority.medium:
        return Icons.info;
      case Priority.low:
        return Icons.low_priority;
    }
  }

  Color _getTypeColor(FeedbackType type) {
    switch (type) {
      case FeedbackType.bug:
        return Colors.red;
      case FeedbackType.feature:
        return Colors.green;
      case FeedbackType.complaint:
        return Colors.orange;
      case FeedbackType.question:
        return Colors.purple;
      case FeedbackType.compliment:
        return Colors.teal;
      case FeedbackType.systemIssue:
        return Colors.deepOrange;
    }
  }

  Color _getStatusColor(FeedbackStatus status) {
    switch (status) {
      case FeedbackStatus.pending:
        return Colors.orange;
      case FeedbackStatus.inProgress:
        return Colors.blue;
      case FeedbackStatus.resolved:
        return Colors.green;
      case FeedbackStatus.closed:
        return Colors.grey;
      case FeedbackStatus.archived:
        return Colors.blueGrey;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _archiveFeedback(FeedbackAndReport feedback) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color.fromRGBO(248, 253, 255, 1),
      title: Row(
        children: [
          Icon(Icons.archive, color: Colors.orange[700], size: 24),
          const SizedBox(width: 12),
          const Text(
            'Archive Feedback',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Are you sure you want to archive this feedback?',
            style: TextStyle(
              color: Colors.grey[800],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.subject, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        feedback.subject,
                        style: TextStyle(
                          color: Colors.grey[800],
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.person, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      feedback.userName,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange[700], size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Archived feedback can be permanently deleted later.',
                    style: TextStyle(
                      color: Colors.orange[900],
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        ElevatedButton.icon(
          onPressed: () {
            controller.archiveFeedback(feedback.documentId!);
            Navigator.pop(context);
          },
          icon: const Icon(Icons.archive, size: 18),
          label: const Text('Archive'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange[600],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    ),
  );
}
  void _showFeedbackDetails(FeedbackAndReport feedback) {
    showDialog(
      context: context,
      builder: (context) => FeedbackDetailsDialog(
        feedback: feedback,
        controller: controller,
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
                'Super Admin',
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
                icon: Icons.delete_forever_rounded,
                title: 'Vet Reports',
                subtitle: 'Deletion requests',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const VeterinaryReport(),
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

// Feedback Details Dialog
class FeedbackDetailsDialog extends StatefulWidget {
  final FeedbackAndReport feedback;
  final WebFeedbackController controller;

  const FeedbackDetailsDialog({
    super.key,
    required this.feedback,
    required this.controller,
  });

  @override
  State<FeedbackDetailsDialog> createState() => _FeedbackDetailsDialogState();
}

class _FeedbackDetailsDialogState extends State<FeedbackDetailsDialog> {
  final TextEditingController _replyController = TextEditingController();
  bool _isReplying = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color.fromRGBO(248, 253, 255, 1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Feedback Details',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailSection('User Information', [
                      'Name: ${widget.feedback.userName}',
                      'Email: ${widget.feedback.userEmail}',
                      'User ID: ${widget.feedback.userId}',
                    ]),
                    const SizedBox(height: 16),
                    
                    _buildDetailSection('Feedback Information', [
                      'ID: ${widget.feedback.documentId}',
                      'Subject: ${widget.feedback.subject}',
                      'Type: ${widget.feedback.feedbackType.displayName}',
                      'Category: ${widget.feedback.category.displayName}',
                      'Priority: ${widget.feedback.priority.displayName}',
                      'Status: ${widget.feedback.status.displayName}',
                      'Submitted: ${_formatFullDateTime(widget.feedback.submittedAt)}',
                    ]),
                    const SizedBox(height: 16),
                    
                    _buildDetailSection('Technical Information', [
                      'App Version: ${widget.feedback.appVersion}',
                      'Device Info: ${widget.feedback.deviceInfo}',
                      'Platform: ${widget.feedback.platform}',
                    ]),
                    const SizedBox(height: 16),
                    
                    _buildDescriptionSection(),
                    
                    if (widget.feedback.attachments.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildAttachmentsSection(),
                    ],
                    
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<String> items) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  item,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Description',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.blue[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.feedback.description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Attachments (${widget.feedback.attachments.length})',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.orange[800],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.feedback.attachments.map((attachmentId) {
              return GestureDetector(
                onTap: () => _viewAttachment(attachmentId),
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                    color: Colors.grey[100],
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(7),
                        child: Image.network(
                          widget.controller.getAttachmentUrl(attachmentId),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.image,
                              size: 40,
                              color: Colors.grey[400],
                            );
                          },
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(
                            Icons.zoom_in,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }


  Widget _buildActionButtons() {
    return Row(
      children: [
        // Status Dropdown
        Expanded(
          child: DropdownButtonFormField<FeedbackStatus>(
            dropdownColor: const Color.fromRGBO(248, 253, 255, 1),
            value: widget.feedback.status,
            decoration: InputDecoration(
              labelText: 'Update Status',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            items: FeedbackStatus.values
                .map(
                  (status) => DropdownMenuItem(
                    value: status,
                    child: Text(status.displayName),
                  ),
                )
                .toList(),
            onChanged: (status) {
              if (status != null && status != widget.feedback.status) {
                widget.controller.updateStatus(widget.feedback.documentId!, status);
                Navigator.pop(context);
              }
            },
          ),
        ),
        const SizedBox(width: 16),
        
        // Priority Dropdown
        Expanded(
          child: DropdownButtonFormField<Priority>(
            dropdownColor: const Color.fromRGBO(248, 253, 255, 1),
            value: widget.feedback.priority,
            decoration: InputDecoration(
              labelText: 'Update Priority',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            items: Priority.values
                .map(
                  (priority) => DropdownMenuItem(
                    value: priority,
                    child: Text(priority.displayName),
                  ),
                )
                .toList(),
            onChanged: (priority) {
              if (priority != null && priority != widget.feedback.priority) {
                widget.controller.updatePriority(widget.feedback.documentId!, priority);
                Navigator.pop(context);
              }
            },
          ),
        ),
        const SizedBox(width: 16),
        
        // Archive Button (only for closed)
        if (widget.feedback.status == FeedbackStatus.closed)
          ElevatedButton.icon(
            onPressed: () {
              widget.controller.archiveFeedback(widget.feedback.documentId!);
              Navigator.pop(context);
            },
            icon: const Icon(Icons.archive, color: Colors.white),
            label: const Text('Archive'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF517399),
              foregroundColor: Colors.white,
            ),
          ),
        
        // Delete Button (only for archived)
        if (widget.feedback.status == FeedbackStatus.archived)
          ElevatedButton.icon(
            onPressed: () => _deleteFeedback(),
            icon: const Icon(Icons.delete_forever, color: Colors.white),
            label: const Text('Delete'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
            ),
          ),
      ],
    );
  }

  void _sendReply() {
    if (_replyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a reply message'),
          backgroundColor: Colors.red[600],
        ),
      );
      return;
    }

    widget.controller.addReply(
      widget.feedback.documentId!,
      _replyController.text.trim(),
    );
    
    setState(() {
      _isReplying = false;
    });

    Navigator.pop(context);
  }

  void _deleteFeedback() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color.fromRGBO(248, 253, 255, 1),
        title: Text(
          'Delete Feedback',
          style: TextStyle(
            color: Colors.red[700],
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to permanently delete this feedback? This action cannot be undone.',
          style: TextStyle(color: Colors.grey[700]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              widget.controller.deleteFeedback(
                widget.feedback.documentId!,
                widget.feedback.attachments,
              );
              Navigator.pop(context); // Close confirmation
              Navigator.pop(context); // Close details
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _viewAttachment(String attachmentId) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.9),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Stack(
          children: [
            Center(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    widget.controller.getAttachmentUrl(attachmentId),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Text('Failed to load image'),
                      );
                    },
                  ),
                ),
              ),
            ),
            Positioned(
              top: 30,
              right: 30,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white, size: 24),
                  tooltip: 'Close',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatFullDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}