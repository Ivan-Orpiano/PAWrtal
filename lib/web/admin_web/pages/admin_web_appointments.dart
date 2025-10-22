import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/utils/user_session_service.dart';
import 'package:capstone_app/web/admin_web/components/appointments/appointment_view_mode.dart';
import 'package:capstone_app/web/admin_web/components/appointments/admin_web_appointment_controller.dart';
import 'package:capstone_app/web/admin_web/components/appointments/web_appointment_stats.dart';
import 'package:capstone_app/web/admin_web/components/appointments/web_appointment_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class AdminWebAppointments extends StatefulWidget {
  const AdminWebAppointments({super.key});

  @override
  State<AdminWebAppointments> createState() => _AdminWebAppointmentsState();
}

class _AdminWebAppointmentsState extends State<AdminWebAppointments>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late TabController _mobileTabController;
  late TextEditingController _searchController;
  late ScrollController _statsScrollController;

  bool _controllersInitialized = false;
  bool _isDisposed = false;

  final List<Tab> _tabs = const [
    Tab(text: 'Today'),
    Tab(text: 'Pending'),
    Tab(text: 'Scheduled'),
    Tab(text: 'In Progress'),
    Tab(text: 'Completed'),
    Tab(text: 'Cancelled'),
    Tab(text: 'Declined'),
  ];

  final List<String> _tabValues = [
    'today',
    'pending',
    'scheduled',
    'in_progress',
    'completed',
    'cancelled',
    'declined',
  ];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    if (_isDisposed) return;

    _tabController = TabController(length: _tabs.length, vsync: this);
    _mobileTabController = TabController(length: _tabs.length, vsync: this);
    _searchController = TextEditingController();
    _statsScrollController = ScrollController();

    if (!Get.isRegistered<WebAppointmentController>()) {
      Get.put(WebAppointmentController(
        authRepository: Get.find<AuthRepository>(),
        session: Get.find<UserSessionService>(),
      ));
    }

    _tabController.addListener(_onTabControllerChanged);
    _mobileTabController.addListener(_onMobileTabControllerChanged);

    _controllersInitialized = true;
  }

  void _onTabControllerChanged() {
    if (_isDisposed || _tabController.indexIsChanging) return;

    if (Get.isRegistered<WebAppointmentController>()) {
      final controller = Get.find<WebAppointmentController>();
      controller.setSelectedTab(_tabValues[_tabController.index]);
    }
  }

  void _onMobileTabControllerChanged() {
    if (_isDisposed || _mobileTabController.indexIsChanging) return;

    if (Get.isRegistered<WebAppointmentController>()) {
      final controller = Get.find<WebAppointmentController>();
      controller.setSelectedTab(_tabValues[_mobileTabController.index]);
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _tabController.removeListener(_onTabControllerChanged);
    _mobileTabController.removeListener(_onMobileTabControllerChanged);
    _tabController.dispose();
    _mobileTabController.dispose();
    _searchController.dispose();
    _statsScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ADD THIS CHECK
    if (!_controllersInitialized) {
      return const Scaffold(
        backgroundColor: Color.fromARGB(255, 245, 245, 245),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Check if controller exists and is ready
    if (!Get.isRegistered<WebAppointmentController>()) {
      return const Scaffold(
        backgroundColor: Color.fromARGB(255, 245, 245, 245),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final isTablet = screenWidth < 1200 && screenWidth >= 768;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 245, 245, 245),
      body: Column(
        children: [
          if (!isMobile) const WebAppointmentStats(),
          if (isMobile) _buildMobileStats(),
          _buildSearchAndFilterBar(isMobile, isTablet),
          _buildTabBar(isMobile, isTablet),
          Expanded(
            child: _buildTabContent(isMobile),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileStats() {
    final controller = Get.find<WebAppointmentController>();

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(() => Container(
                padding: const EdgeInsets.only(
                    left: 24, right: 24, top: 10, bottom: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color.fromARGB(255, 81, 115, 153),
                      Colors.blue.shade400,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.15),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                DateFormat('EEEE, MMMM dd, yyyy')
                                    .format(DateTime.now()),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                "Appointments",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                controller.selectedCalendarDate.value != null
                                    ? "Showing: ${DateFormat('MMM dd, yyyy').format(controller.selectedCalendarDate.value!)}"
                                    : "${controller.appointmentStats['today']} today",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${controller.appointmentStats['total']}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                controller.viewMode.value.label,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: AppointmentViewMode.values.map((mode) {
                          final isSelected = controller.viewMode.value == mode;
                          return Padding(
                            padding: const EdgeInsets.only(right: 2),
                            child: InkWell(
                              onTap: () => controller.setViewMode(mode),
                              borderRadius: BorderRadius.circular(4),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  mode.label,
                                  style: TextStyle(
                                    color: isSelected
                                        ? const Color.fromARGB(
                                            255, 81, 115, 153)
                                        : Colors.white,
                                    fontSize: 10,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    if (controller.selectedCalendarDate.value != null) ...[
                      const SizedBox(height: 6),
                      TextButton.icon(
                        onPressed: () => controller.setCalendarDate(null),
                        icon: const Icon(Icons.clear,
                            color: Colors.white, size: 12),
                        label: const Text(
                          'Clear date filter',
                          style: TextStyle(color: Colors.white, fontSize: 9),
                        ),
                      ),
                    ],
                  ],
                ),
              )),
          const SizedBox(height: 16),
          SizedBox(
            height: 80,
            child: Obx(() {
              final stats = controller.appointmentStats;
              return ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(
                  dragDevices: {
                    PointerDeviceKind.touch,
                    PointerDeviceKind.mouse,
                  },
                ),
                child: ListView(
                  controller: _statsScrollController,
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildMobileStatCard('Total', stats['total'] ?? 0,
                        Icons.calendar_today, Colors.blue),
                    const SizedBox(width: 12),
                    _buildMobileStatCard('Pending', stats['pending'] ?? 0,
                        Icons.pending, Colors.orange),
                    const SizedBox(width: 12),
                    _buildMobileStatCard('Scheduled', stats['scheduled'] ?? 0,
                        Icons.schedule, Colors.green),
                    const SizedBox(width: 12),
                    _buildMobileStatCard(
                        'In Progress',
                        stats['in_progress'] ?? 0,
                        Icons.medical_services,
                        Colors.purple),
                    const SizedBox(width: 12),
                    _buildMobileStatCard('Completed', stats['completed'] ?? 0,
                        Icons.check_circle, Colors.teal),
                    const SizedBox(width: 12),
                    _buildMobileStatCard('Cancelled', stats['cancelled'] ?? 0,
                        Icons.cancel, Colors.grey),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileStatCard(
      String title, int value, IconData icon, Color color) {
    return Container(
      width: 110,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                value.toString(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterBar(bool isMobile, bool isTablet) {
    final controller = Get.find<WebAppointmentController>();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: isMobile
          ? _buildMobileSearchBar(controller)
          : _buildDesktopSearchBar(controller),
    );
  }

  Widget _buildMobileSearchBar(WebAppointmentController controller) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search...',
              prefixIcon: const Icon(Icons.search, size: 18),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        controller.setSearchQuery('');
                      },
                      iconSize: 18,
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey[100],
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              hintStyle: const TextStyle(fontSize: 12),
              isDense: true,
            ),
            style: const TextStyle(fontSize: 12),
            onChanged: (value) => controller.setSearchQuery(value),
          ),
        ),
        const SizedBox(width: 6),
        InkWell(
          onTap: () => _showDatePicker(controller),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.date_range, size: 18, color: Colors.grey),
          ),
        ),
        const SizedBox(width: 6),
        InkWell(
          onTap: () => controller.refreshAppointments(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.refresh, size: 18, color: Colors.grey),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopSearchBar(WebAppointmentController controller) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by pet name, owner, or service...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        controller.setSearchQuery('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey[100],
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              isDense: true,
            ),
            onChanged: (value) => controller.setSearchQuery(value),
          ),
        ),
        const SizedBox(width: 10),
        OutlinedButton.icon(
          onPressed: () => _showCalendarPicker(controller),
          icon: const Icon(Icons.calendar_today, size: 14),
          label: Obx(() => Text(
                controller.selectedCalendarDate.value != null
                    ? DateFormat('MMM dd, yyyy')
                        .format(controller.selectedCalendarDate.value!)
                    : 'Select Date',
                style: const TextStyle(fontSize: 10),
              )),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            minimumSize: const Size(0, 32),
          ),
        ),
        const SizedBox(width: 10),
        OutlinedButton.icon(
          onPressed: () => controller.refreshAppointments(),
          icon: const Icon(Icons.refresh, size: 14),
          label: const Text('Refresh', style: TextStyle(fontSize: 10)),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            minimumSize: const Size(0, 32),
          ),
        ),
        const SizedBox(width: 10),
        Obx(() => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 81, 115, 153).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${controller.filteredAppointments.length} results',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                  color: Color.fromARGB(255, 81, 115, 153),
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildTabBar(bool isMobile, bool isTablet) {
    final controller = Get.find<WebAppointmentController>();

    if (isMobile) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
        child: Obx(() {
          final stats = controller.appointmentStats;
          return ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              dragDevices: {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
              },
              scrollbars: false,
            ),
            child: TabBar(
              controller: _mobileTabController,
              isScrollable: true,
              labelColor: Colors.white,
              unselectedLabelColor: const Color.fromARGB(255, 81, 115, 153),
              indicatorColor: Colors.transparent,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: const Color.fromARGB(255, 81, 115, 153),
                borderRadius: BorderRadius.circular(8),
              ),
              tabs: [
                _buildMobileTab('Today', stats['today'] ?? 0, Icons.today),
                _buildMobileTab(
                    'Pending', stats['pending'] ?? 0, Icons.pending),
                _buildMobileTab(
                    'Scheduled', stats['scheduled'] ?? 0, Icons.schedule),
                _buildMobileTab('In Progress', stats['in_progress'] ?? 0,
                    Icons.medical_services),
                _buildMobileTab(
                    'Completed', stats['completed'] ?? 0, Icons.check_circle),
                _buildMobileTab(
                    'Cancelled', stats['cancelled'] ?? 0, Icons.cancel),
                _buildMobileTab(
                    'Declined', stats['declined'] ?? 0, Icons.cancel_outlined),
              ],
            ),
          );
        }),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
      child: Obx(() {
        final stats = controller.appointmentStats;
        return LayoutBuilder(
          builder: (context, constraints) {
            // Determine if we need scrollable tabs based on available width
            final needsScroll = constraints.maxWidth < 1100;

            return ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                dragDevices: {
                  PointerDeviceKind.touch,
                  PointerDeviceKind.mouse,
                },
                scrollbars: false,
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: needsScroll || isTablet,
                tabAlignment:
                    (needsScroll || isTablet) ? TabAlignment.center : null,
                labelColor: Colors.white,
                unselectedLabelColor: const Color.fromARGB(255, 81, 115, 153),
                indicatorColor: Colors.transparent,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  color: const Color.fromARGB(255, 81, 115, 153),
                  borderRadius: BorderRadius.circular(8),
                ),
                tabs: [
                  _buildTab('Today', stats['today'] ?? 0, Icons.today),
                  _buildTab('Pending', stats['pending'] ?? 0, Icons.pending),
                  _buildTab(
                      'Scheduled', stats['scheduled'] ?? 0, Icons.schedule),
                  _buildTab('In Progress', stats['in_progress'] ?? 0,
                      Icons.medical_services),
                  _buildTab(
                      'Completed', stats['completed'] ?? 0, Icons.check_circle),
                  _buildTab('Cancelled', stats['cancelled'] ?? 0, Icons.cancel),
                  _buildTab('Declined', stats['declined'] ?? 0,
                      Icons.cancel_outlined),
                ],
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildMobileTab(String text, int count, IconData icon) {
    return Tab(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14),
            const SizedBox(width: 4),
            Text(text, style: const TextStyle(fontSize: 11)),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: _getTabCountColor(text),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String text, int count, IconData icon) {
    return Tab(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 6),
            Text(text, style: const TextStyle(fontSize: 13)),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getTabCountColor(text),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(bool isMobile) {
    final controller = Get.find<WebAppointmentController>();
    final tabCtrl = isMobile ? _mobileTabController : _tabController;

    return TabBarView(
      controller: tabCtrl,
      children: _tabValues.map((tabValue) {
        return _buildAppointmentsList(controller, tabValue, isMobile);
      }).toList(),
    );
  }

  Widget _buildAppointmentsList(
      WebAppointmentController controller, String tabValue, bool isMobile) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final appointments = controller.filteredAppointments;

      if (appointments.isEmpty) {
        return _buildEmptyState(tabValue);
      }

      return RefreshIndicator(
        onRefresh: () => controller.refreshAppointments(),
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: appointments.length,
          itemBuilder: (context, index) {
            final appointment = appointments[index];
            return WebAppointmentTile(
              appointment: appointment,
              isSelected: false,
            );
          },
        ),
      );
    });
  }

  Widget _buildEmptyState(String tabValue) {
    IconData icon;
    String title;
    String subtitle;

    switch (tabValue) {
      case 'today':
        icon = Icons.event_available;
        title = 'No Appointments Today';
        subtitle = 'Your schedule is clear for today!';
        break;
      case 'pending':
        icon = Icons.pending_actions;
        title = 'No Pending Appointments';
        subtitle = 'All caught up! No pending appointments to review.';
        break;
      case 'scheduled':
        icon = Icons.schedule;
        title = 'No Scheduled Appointments';
        subtitle = 'Accepted appointments for future dates will appear here.';
        break;
      case 'in_progress':
        icon = Icons.medical_services_outlined;
        title = 'No Active Treatments';
        subtitle = 'Patients currently receiving treatment will appear here.';
        break;
      case 'completed':
        icon = Icons.check_circle_outline;
        title = 'No Completed Services';
        subtitle = 'Completed treatments will appear here.';
        break;
      case 'cancelled':
        icon = Icons.event_busy;
        title = 'No Cancelled Appointments';
        subtitle = 'User-cancelled appointments will appear here.';
        break;
      case 'declined':
        icon = Icons.cancel_outlined;
        title = 'No Declined Appointments';
        subtitle = 'Appointments you declined will appear here.';
        break;
      default:
        icon = Icons.help_outline;
        title = 'No Data';
        subtitle = 'No appointments found.';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  void _showDatePicker(WebAppointmentController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: controller.selectedDateFilter.value,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      controller.setDateFilter(picked);
    }
  }

  void _showCalendarPicker(WebAppointmentController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: controller.selectedCalendarDate.value ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      controller.setCalendarDate(picked);
    }
  }

  Color _getTabCountColor(String tabName) {
    switch (tabName) {
      case 'Today':
        return Colors.blue;
      case 'Pending':
        return Colors.orange;
      case 'Scheduled':
        return Colors.green;
      case 'In Progress':
        return Colors.purple;
      case 'Completed':
        return Colors.teal;
      case 'Cancelled':
        return Colors.grey;
      case 'Declined':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
