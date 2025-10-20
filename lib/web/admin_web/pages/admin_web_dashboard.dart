import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/utils/user_session_service.dart';
import 'package:capstone_app/data/models/appointment_model.dart';
import 'package:capstone_app/web/admin_web/components/dashboard/admin_dashboard_controller.dart';
import 'package:capstone_app/web/pages/web_admin_home/web_admin_home_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class AdminWebDashboard extends StatefulWidget {
  const AdminWebDashboard({super.key});

  @override
  State<AdminWebDashboard> createState() => _AdminWebDashboardState();
}

class _AdminWebDashboardState extends State<AdminWebDashboard> {
  late AdminDashboardController controller;
  late WebAdminHomeController permissionController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  @override
  void dispose() {
    if (Get.isRegistered<AdminDashboardController>()) {
      Get.delete<AdminDashboardController>(force: true);
      print('>>> Dashboard disposed - controller deleted');
    }
    super.dispose();
  }

  void _initializeController() {
    permissionController = Get.find<WebAdminHomeController>();

    if (Get.isRegistered<AdminDashboardController>()) {
      Get.delete<AdminDashboardController>(force: true);
      print('>>> Deleted existing AdminDashboardController');
    }

    controller = Get.put(
      AdminDashboardController(
        authRepository: Get.find<AuthRepository>(),
        session: Get.find<UserSessionService>(),
      ),
      permanent: false,
    );

    print('>>> Created new AdminDashboardController');

    _runMigrationOnce();

    setState(() {
      _isInitialized = true;
    });
  }

  Future<void> _runMigrationOnce() async {
    final storage = GetStorage();
    final migrationRun = storage.read('staff_migration_completed') ?? false;

    if (!migrationRun) {
      try {
        print('>>> Running staff migration...');
        final authRepo = Get.find<AuthRepository>();
        await authRepo.migrateExistingStaffRecords();

        storage.write('staff_migration_completed', true);
        print('>>> Staff migration completed successfully');
      } catch (e) {
        print('>>> Migration error: $e');
      }
    }
  }

  bool _canAccessFeature(String featureName) {
    return permissionController.canAccessFeature(featureName);
  }

  // NEW: Check if staff has NO permissions at all
  bool _hasNoPermissions() {
    if (permissionController.isAdmin) return false;
    if (permissionController.isStaff) {
      return permissionController.userAuthorities.isEmpty;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // NEW: Check if staff has no permissions
    if (_hasNoPermissions()) {
      return _buildNoPermissionsView(context);
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final isTablet = screenWidth < 1200 && screenWidth >= 768;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: () => controller.refreshDashboard(),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(controller, isMobile),
                const SizedBox(height: 24),
                _buildQuickStats(controller, isMobile, isTablet),
                const SizedBox(height: 32),
                if (isMobile)
                  _buildMobileLayout(controller)
                else if (isTablet)
                  _buildTabletLayout(controller)
                else
                  _buildDesktopLayout(controller),
              ],
            ),
          ),
        );
      }),
    );
  }

  // NEW: Build no permissions view
  Widget _buildNoPermissionsView(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 24 : 48),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: EdgeInsets.all(isMobile ? 32 : 48),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Lock Icon
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.lock_outline,
                        size: 60,
                        color: Colors.orange.shade700,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Title
                    Text(
                      'No Permissions Assigned',
                      style: TextStyle(
                        fontSize: isMobile ? 24 : 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    // Subtitle
                    Text(
                      'You currently don\'t have any permissions to access the dashboard features.',
                      style: TextStyle(
                        fontSize: isMobile ? 16 : 18,
                        color: Colors.grey.shade600,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // Info Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.blue.shade200,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.blue.shade700,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'What can you do?',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildInfoItem(
                            icon: Icons.contact_mail,
                            text:
                                'Contact your administrator to request access',
                            color: Colors.blue,
                          ),
                          const SizedBox(height: 12),
                          _buildInfoItem(
                            icon: Icons.schedule,
                            text:
                                'Check back later after permissions are granted',
                            color: Colors.blue,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String text,
    required MaterialColor color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: color.shade700,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: color.shade900,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  void _showContactAdminDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.help_outline, color: Colors.blue.shade700),
            const SizedBox(width: 12),
            const Text('Contact Administrator'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'To get access to dashboard features, please contact your clinic administrator.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'What to request:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildPermissionOption(
                      'Appointments', 'Manage and view appointments'),
                  const SizedBox(height: 8),
                  _buildPermissionOption('Messages', 'Chat with pet owners'),
                  const SizedBox(height: 8),
                  _buildPermissionOption('Clinic', 'Update clinic information'),
                ],
              ),
            ),
          ],
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

  Widget _buildPermissionOption(String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.check_circle_outline,
          size: 18,
          color: Colors.green.shade600,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(AdminDashboardController controller, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color.fromARGB(255, 81, 115, 153),
            Colors.blue.shade400,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.dashboard_rounded,
                    color: Colors.white, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      controller.clinicData.value?.clinicName ??
                          'Admin Dashboard',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isMobile ? 20 : 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      DateFormat('EEEE, MMMM dd, yyyy').format(DateTime.now()),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: isMobile ? 14 : 16,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isMobile && _canAccessFeature('appointments')) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.pets, color: Colors.white, size: 24),
                      const SizedBox(height: 8),
                      Text(
                        '${controller.todayAppointments.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Today's Patients",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(
      AdminDashboardController controller, bool isMobile, bool isTablet) {
    final stats = [
      {
        'title': 'Today\'s Appointments',
        'value': controller.todayAppointments.length.toString(),
        'subtitle': 'Scheduled today',
        'icon': Icons.event_available,
        'color': Colors.blue,
        'permission': 'appointments',
        'onTap': () => _handleNavigateToAppointments('today'),
      },
      {
        'title': 'Pending Appointments',
        'value': controller.pendingCount.toString(),
        'subtitle': 'Need approval',
        'icon': Icons.pending_actions,
        'color': Colors.orange,
        'permission': 'appointments',
        'onTap': () => _handleNavigateToAppointments('pending'),
      },
      {
        'title': 'Today\'s In Progress',
        'value': controller.todayAppointments
            .where((a) => a.status == 'in_progress')
            .length
            .toString(),
        'subtitle': 'Currently being treated',
        'icon': Icons.medical_services,
        'color': Colors.purple,
        'permission': 'appointments',
        'onTap': () => _handleNavigateToAppointments('in_progress'),
      },
      {
        'title': 'Today\'s Completed',
        'value': controller.todayAppointments
            .where((a) => a.status == 'completed')
            .length
            .toString(),
        'subtitle': 'Finished appointments today',
        'icon': Icons.check_circle,
        'color': Colors.green,
        'permission': 'appointments',
        'onTap': () => _handleNavigateToAppointments('completed'),
      },
    ];

    final visibleStats = stats
        .where((s) => _canAccessFeature(s['permission'] as String))
        .toList();

    if (visibleStats.isEmpty) {
      return const SizedBox.shrink();
    }

    if (isMobile) {
      return Column(
        children: [
          Row(
            children: [
              if (visibleStats.isNotEmpty)
                Expanded(child: _buildStatCard(visibleStats[0])),
              const SizedBox(width: 12),
              if (visibleStats.length > 1)
                Expanded(child: _buildStatCard(visibleStats[1]))
              else
                Expanded(child: Container()),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (visibleStats.length > 2)
                Expanded(child: _buildStatCard(visibleStats[2])),
              const SizedBox(width: 12),
              if (visibleStats.length > 3)
                Expanded(child: _buildStatCard(visibleStats[3]))
              else
                Expanded(child: Container()),
            ],
          ),
        ],
      );
    } else if (isTablet) {
      return Column(
        children: [
          Row(
            children: [
              if (visibleStats.isNotEmpty)
                Expanded(child: _buildStatCard(visibleStats[0])),
              const SizedBox(width: 16),
              if (visibleStats.length > 1)
                Expanded(child: _buildStatCard(visibleStats[1]))
              else
                Expanded(child: Container()),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (visibleStats.length > 2)
                Expanded(child: _buildStatCard(visibleStats[2])),
              const SizedBox(width: 16),
              if (visibleStats.length > 3)
                Expanded(child: _buildStatCard(visibleStats[3]))
              else
                Expanded(child: Container()),
            ],
          ),
        ],
      );
    } else {
      return Row(
        children: visibleStats.map((stat) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: _buildStatCard(stat),
            ),
          );
        }).toList(),
      );
    }
  }

  void _handleNavigateToAppointments(String filter) {
    if (!permissionController.canAccessFeature('appointments')) {
      permissionController.showPermissionDeniedDialog('Appointments');
      return;
    }

    final appointmentsIndex =
        permissionController.navigationLabels.indexOf('Appointments');

    if (appointmentsIndex == -1) {
      print('>>> ERROR: Appointments page not found in navigation');
      return;
    }

    print(
        '>>> Navigating to Appointments at index $appointmentsIndex with filter: $filter');

    permissionController.setSelectedIndex(appointmentsIndex);
    controller.navigateToAppointments(filter);
  }

  void _handleNavigateToMessages() {
    if (!permissionController.canAccessFeature('messages')) {
      permissionController.showPermissionDeniedDialog('Messages');
      return;
    }

    final messagesIndex =
        permissionController.navigationLabels.indexOf('Messages');

    if (messagesIndex == -1) {
      print('>>> ERROR: Messages page not found in navigation');
      return;
    }

    print('>>> Navigating to Messages at index $messagesIndex');
    permissionController.setSelectedIndex(messagesIndex);
  }

  Widget _buildStatCard(Map<String, dynamic> stat) {
    return InkWell(
      onTap: stat['onTap'],
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: stat['color'].withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: stat['color'].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(stat['icon'], color: stat['color'], size: 20),
                ),
                const Spacer(),
                Icon(Icons.arrow_forward_ios,
                    size: 16, color: Colors.grey[400]),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              stat['value'],
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: stat['color'],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              stat['title'],
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            Text(
              stat['subtitle'],
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout(AdminDashboardController controller) {
    final children = <Widget>[];

    if (_canAccessFeature('appointments')) {
      children.add(_buildTodaySchedule(controller, true));
      children.add(const SizedBox(height: 24));
    }

    if (_canAccessFeature('messages')) {
      children.add(_buildRecentMessages(controller, true));
      children.add(const SizedBox(height: 24));
    }

    if (_canAccessFeature('appointments')) {
      children.add(_buildUpcomingAppointments(controller, true));
    }

    return Column(children: children);
  }

  Widget _buildTabletLayout(AdminDashboardController controller) {
    final hasAppointments = _canAccessFeature('appointments');
    final hasMessages = _canAccessFeature('messages');
    final children = <Widget>[];

    if (hasAppointments) {
      children.add(_buildTodaySchedule(controller, false));
      children.add(const SizedBox(height: 24));
    }

    final rowChildren = <Widget>[];
    if (hasMessages) {
      rowChildren.add(Expanded(child: _buildRecentMessages(controller, false)));
      if (hasAppointments) {
        rowChildren.add(const SizedBox(width: 24));
        rowChildren.add(
            Expanded(child: _buildUpcomingAppointments(controller, false)));
      }
    } else if (hasAppointments) {
      rowChildren
          .add(Expanded(child: _buildUpcomingAppointments(controller, false)));
    }

    if (rowChildren.isNotEmpty) {
      children.add(Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: rowChildren,
      ));
    }

    return Column(children: children);
  }

  Widget _buildDesktopLayout(AdminDashboardController controller) {
    final hasAppointments = _canAccessFeature('appointments');
    final hasMessages = _canAccessFeature('messages');
    final children = <Widget>[];

    if (hasAppointments) {
      children.add(Expanded(
        flex: 2,
        child: Column(
          children: [
            _buildTodaySchedule(controller, false),
            const SizedBox(height: 24),
            _buildUpcomingAppointments(controller, false),
          ],
        ),
      ));
      children.add(const SizedBox(width: 24));
    }

    if (hasAppointments || hasMessages) {
      final rightChildren = <Widget>[];

      if (hasAppointments) {
        rightChildren.add(_buildAppointmentCalendar(controller));
        rightChildren.add(const SizedBox(height: 24));
      }

      if (hasMessages) {
        rightChildren.add(_buildRecentMessages(controller, false));
      }

      if (rightChildren.isNotEmpty) {
        children.add(Expanded(
          flex: 1,
          child: Column(children: rightChildren),
        ));
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  // Rest of the widget methods remain the same...
  // (Include all other methods from your original code)

  Widget _buildTodaySchedule(
      AdminDashboardController controller, bool isMobile) {
    return _buildDashboardCard(
      title: 'Today\'s Schedule',
      subtitle: '${controller.todayAppointments.length} appointments',
      icon: Icons.today,
      child: controller.todayAppointments.isEmpty
          ? _buildEmptyState(
              'No appointments scheduled for today', Icons.event_available)
          : Column(
              children: controller.todayAppointments.take(5).map((appointment) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child:
                      _buildAppointmentItem(controller, appointment, isMobile),
                );
              }).toList(),
            ),
      actionLabel: 'View All',
      onAction: () => _handleNavigateToAppointments('today'),
    );
  }

  Widget _buildAppointmentItem(AdminDashboardController controller,
      Appointment appointment, bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getStatusColor(appointment.status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: _getStatusColor(appointment.status).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _getStatusColor(appointment.status),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Icon(Icons.pets, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      controller.getPetName(appointment.petId),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      controller.getOwnerName(appointment.userId),
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    Text(
                      appointment.service,
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    DateFormat('hh:mm a').format(appointment.dateTime),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getStatusColor(appointment.status),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _getStatusDisplayText(appointment.status),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Show action buttons only for pending appointments
          if (appointment.status == 'pending') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        controller.confirmQuickDeclineAppointment(appointment),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Decline'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        controller.confirmQuickAcceptAppointment(appointment),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Accept'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // Replace these methods in admin_web_dashboard.dart

  Widget _buildRecentMessages(
      AdminDashboardController controller, bool isMobile) {
    return _buildDashboardCard(
      title: 'Recent Messages',
      subtitle:
          '${controller.recentMessages.where((m) => m['unreadCount'] > 0).length} unread',
      icon: Icons.message,
      child: Obx(() {
        if (controller.recentMessages.isEmpty) {
          return _buildEmptyState('No recent messages', Icons.message);
        }

        return Column(
          children: controller.recentMessages.take(3).map((message) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildMessageItem(message, isMobile),
            );
          }).toList(),
        );
      }),
      actionLabel: 'View All',
      onAction: _handleNavigateToMessages,
    );
  }

  Widget _buildMessageItem(Map<String, dynamic> message, bool isMobile) {
    final isUnread = (message['unreadCount'] ?? 0) > 0;

    // Format the time - EXACTLY THE SAME LOGIC AS CONVERSATION_MODEL
    final messageTime = message['time'] as DateTime;
    final now = DateTime.now();

    // Check if message is from today
    final isToday = messageTime.year == now.year &&
        messageTime.month == now.month &&
        messageTime.day == now.day;

    String timeDisplay;

    if (isToday) {
      // If today, show time in 12-hour format with AM/PM
      final hour = messageTime.hour == 0
          ? 12
          : messageTime.hour > 12
              ? messageTime.hour - 12
              : messageTime.hour;
      final minute = messageTime.minute.toString().padLeft(2, '0');
      final period = messageTime.hour >= 12 ? 'PM' : 'AM';
      timeDisplay = '$hour:$minute $period';
    } else {
      // If yesterday, show "Yesterday"
      final yesterday = now.subtract(const Duration(days: 1));
      if (messageTime.year == yesterday.year &&
          messageTime.month == yesterday.month &&
          messageTime.day == yesterday.day) {
        timeDisplay = 'Yesterday';
      } else {
        // If within this week (last 7 days), show day name
        final difference = now.difference(messageTime);
        if (difference.inDays < 7) {
          final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
          timeDisplay = days[messageTime.weekday - 1];
        } else {
          // If older, show date (M/D/YY format)
          timeDisplay =
              '${messageTime.month}/${messageTime.day}/${messageTime.year.toString().substring(2)}';
        }
      }
    }

    return InkWell(
      onTap: () {
        _handleNavigateToMessagesWithConversation(
          message['conversationId'] as String?,
          message['senderId'] as String,
          message['senderName'] as String,
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUnread
              ? Colors.blue.withOpacity(0.1)
              : Colors.grey.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isUnread
                ? Colors.blue.withOpacity(0.3)
                : Colors.grey.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            // Profile Picture Avatar
            _buildMessageUserAvatar(message),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          message['senderName'] ?? 'Unknown User',
                          style: TextStyle(
                            fontWeight:
                                isUnread ? FontWeight.bold : FontWeight.w600,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        timeDisplay, // ✅ NOW MATCHES MESSAGES PAGE FORMAT
                        style: TextStyle(
                          color: isUnread ? Colors.blue[700] : Colors.grey[500],
                          fontSize: 12,
                          fontWeight:
                              isUnread ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message['message'] ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isUnread ? Colors.black87 : Colors.grey[700],
                      fontSize: 13,
                      fontWeight:
                          isUnread ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            if (isUnread)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                margin: const EdgeInsets.only(left: 8),
              ),
          ],
        ),
      ),
    );
  }

  /// Build user avatar with profile picture support
  Widget _buildMessageUserAvatar(Map<String, dynamic> messageData) {
    final hasProfilePicture = messageData['hasProfilePicture'] ?? false;
    final profilePictureUrl = messageData['profilePictureUrl'] ?? '';
    final userName = messageData['senderName'] ?? 'U';

    return Stack(
      children: [
        if (hasProfilePicture && profilePictureUrl.isNotEmpty)
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.grey.shade200,
                width: 2,
              ),
            ),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey[200],
              backgroundImage: NetworkImage(profilePictureUrl),
              onBackgroundImageError: (exception, stackTrace) {
                print(
                    'Error loading profile picture for ${messageData['senderId']}: $exception');
              },
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withOpacity(0.0),
                ),
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.grey.shade200,
                width: 2,
              ),
            ),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: const Color.fromARGB(255, 81, 115, 153),
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        // Online status indicator (currently showing offline/grey)
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.grey[400], // Could be made dynamic with user status
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
      ],
    );
  }

// Add this new helper method to handle navigation with conversation opening
  void _handleNavigateToMessagesWithConversation(
    String? conversationId,
    String userId,
    String userName,
  ) {
    if (!permissionController.canAccessFeature('messages')) {
      permissionController.showPermissionDeniedDialog('Messages');
      return;
    }

    final messagesIndex =
        permissionController.navigationLabels.indexOf('Messages');

    if (messagesIndex == -1) {
      print('>>> ERROR: Messages page not found in navigation');
      return;
    }

    print('>>> Navigating to Messages at index $messagesIndex');
    print('>>> Will open conversation for user: $userName ($userId)');

    // Navigate to messages page
    permissionController.setSelectedIndex(messagesIndex);

    // The messages controller will handle opening the specific conversation
    // based on the conversation data passed
  }

  Widget _buildUpcomingAppointments(
      AdminDashboardController controller, bool isMobile) {
    return _buildDashboardCard(
      title: 'Upcoming Appointments',
      subtitle: 'Next ${controller.upcomingAppointments.length} scheduled',
      icon: Icons.schedule,
      child: controller.upcomingAppointments.isEmpty
          ? _buildEmptyState('No upcoming appointments', Icons.event_available)
          : Column(
              children: controller.upcomingAppointments.map((appointment) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildUpcomingAppointmentItem(
                      controller, appointment, isMobile),
                );
              }).toList(),
            ),
      actionLabel: 'View All',
      onAction: () => _handleNavigateToAppointments('all'),
    );
  }

  Widget _buildUpcomingAppointmentItem(AdminDashboardController controller,
      Appointment appointment, bool isMobile) {
    final daysDifference =
        appointment.dateTime.difference(DateTime.now()).inDays;
    final isToday = daysDifference == 0;
    final isTomorrow = daysDifference == 1;

    String dateLabel;
    if (isToday) {
      dateLabel = 'Today';
    } else if (isTomorrow) {
      dateLabel = 'Tomorrow';
    } else {
      dateLabel = DateFormat('MMM dd').format(appointment.dateTime);
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isToday ? Colors.orange : Colors.green,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  dateLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  DateFormat('hh:mm a').format(appointment.dateTime),
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.getPetName(appointment.petId),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  controller.getOwnerName(appointment.userId),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    appointment.service,
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCalendar(AdminDashboardController controller) {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    return _buildDashboardCard(
      title: 'Appointment Calendar',
      subtitle: 'Monthly overview',
      icon: Icons.calendar_month,
      child: TableCalendar<Appointment>(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: controller.selectedDate.value,
        calendarFormat: CalendarFormat.month,
        eventLoader: (day) {
          return controller.calendarAppointments[
                  DateTime(day.year, day.month, day.day)] ??
              [];
        },
        startingDayOfWeek: StartingDayOfWeek.monday,
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          weekendTextStyle: const TextStyle(color: Colors.red),
          todayDecoration: const BoxDecoration(
            color: Color.fromARGB(255, 81, 115, 153),
            shape: BoxShape.circle,
          ),
          selectedDecoration: BoxDecoration(
            color: Colors.blue.shade600,
            shape: BoxShape.circle,
          ),
          markerDecoration: BoxDecoration(
            color: Colors.green.shade400,
            shape: BoxShape.circle,
          ),
        ),
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
        ),
        onDaySelected: (selectedDay, focusedDay) {
          final selectedDate =
              DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
          if (!selectedDate.isBefore(todayDate)) {
            controller.setSelectedDate(selectedDay);
          }
        },
        selectedDayPredicate: (day) {
          return isSameDay(controller.selectedDate.value, day);
        },
      ),
    );
  }

  Widget _buildDashboardCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:
                      const Color.fromARGB(255, 81, 115, 153).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: const Color.fromARGB(255, 81, 115, 153),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (actionLabel != null && onAction != null)
                TextButton(
                  onPressed: onAction,
                  child: Text(actionLabel),
                ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            icon,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'in_progress':
        return Colors.purple;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.grey;
      case 'declined':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusDisplayText(String status) {
    switch (status) {
      case 'pending':
        return 'PENDING';
      case 'accepted':
        return 'SCHEDULED';
      case 'in_progress':
        return 'IN PROGRESS';
      case 'completed':
        return 'COMPLETED';
      case 'cancelled':
        return 'CANCELLED';
      case 'declined':
        return 'DECLINED';
      default:
        return status.toUpperCase();
    }
  }
}
