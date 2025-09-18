import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/utils/user_session_service.dart';
import 'package:capstone_app/web/admin_web/components/appointments/web_appointment_controller.dart';
import 'package:capstone_app/web/admin_web/components/appointments/web_appointment_stats.dart';
import 'package:capstone_app/web/admin_web/components/appointments/web_appointment_tile.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AdminWebAppointments extends StatefulWidget {
  const AdminWebAppointments({super.key});

  @override
  State<AdminWebAppointments> createState() => _AdminWebAppointmentsState();
}

class _AdminWebAppointmentsState extends State<AdminWebAppointments> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _searchController;

  final List<Tab> _tabs = const [
    Tab(text: 'Today'),
    Tab(text: 'Pending'),
    Tab(text: 'Scheduled'),
    Tab(text: 'In Progress'),
    Tab(text: 'Completed'),
    Tab(text: 'Declined'),
  ];

  final List<String> _tabValues = [
    'today',
    'pending',
    'scheduled',
    'in_progress',
    'completed',
    'declined',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _searchController = TextEditingController();

    // Initialize controller
    if (!Get.isRegistered<WebAppointmentController>()) {
      Get.put(WebAppointmentController(
        authRepository: Get.find<AuthRepository>(),
        session: Get.find<UserSessionService>(),
      ));
    }

    // Listen to tab changes
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final controller = Get.find<WebAppointmentController>();
        controller.setSelectedTab(_tabValues[_tabController.index]);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final isTablet = screenWidth < 1200 && screenWidth >= 768;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 245, 245, 245),
      body: Column(
        children: [
          // Header and Stats
          const WebAppointmentStats(),
          
          // Quick Actions (only on desktop)
          if (!isMobile) ...[
            // const WebAppointmentQuickActions(),
            const SizedBox(height: 20),
          ],
          
          // Search and Filter Bar
          _buildSearchAndFilterBar(isMobile),
          
          // Tab Bar
          _buildTabBar(isMobile, isTablet),
          
          // Content Area
          Expanded(
            child: _buildTabContent(isMobile),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterBar(bool isMobile) {
    final controller = Get.find<WebAppointmentController>();
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
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
      child: isMobile ? _buildMobileSearchBar(controller) : _buildDesktopSearchBar(controller),
    );
  }

  Widget _buildMobileSearchBar(WebAppointmentController controller) {
    return Column(
      children: [
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search by pet name, owner, or service...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
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
          ),
          onChanged: (value) => controller.setSearchQuery(value),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showDatePicker(controller),
                icon: const Icon(Icons.date_range, size: 18),
                label: Obx(() => Text(
                  'Filter by Date',
                  style: const TextStyle(fontSize: 12),
                )),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => controller.refreshAppointments(),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Refresh', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopSearchBar(WebAppointmentController controller) {
    return Row(
      children: [
        // Search field
        Expanded(
          flex: 3,
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by pet name, owner, or service...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
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
            ),
            onChanged: (value) => controller.setSearchQuery(value),
          ),
        ),
        const SizedBox(width: 16),
        
        // Date filter
        OutlinedButton.icon(
          onPressed: () => _showDatePicker(controller),
          icon: const Icon(Icons.date_range),
          label: Obx(() => Text(
            controller.selectedDateFilter.value.day == DateTime.now().day
                ? 'Today'
                : 'Custom Date',
          )),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        const SizedBox(width: 16),
        
        // Refresh button
        OutlinedButton.icon(
          onPressed: () => controller.refreshAppointments(),
          icon: const Icon(Icons.refresh),
          label: const Text('Refresh'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        const SizedBox(width: 16),
        
        // Results count
        Obx(() => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 81, 115, 153).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${controller.filteredAppointments.length} results',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color.fromARGB(255, 81, 115, 153),
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildTabBar(bool isMobile, bool isTablet) {
    final controller = Get.find<WebAppointmentController>();
    
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
        return TabBar(
          controller: _tabController,
          isScrollable: isMobile || isTablet,
          labelColor: Colors.white,
          unselectedLabelColor: const Color.fromARGB(255, 81, 115, 153),
          indicatorColor: Colors.transparent,
          dividerColor: Colors.transparent,
          indicator: BoxDecoration(
            color: const Color.fromARGB(255, 81, 115, 153),
            borderRadius: BorderRadius.circular(8),
          ),
          tabs: [
            _buildTab('Today', stats['today']!, Icons.today),
            _buildTab('Pending', stats['pending']!, Icons.pending),
            _buildTab('Scheduled', stats['scheduled']!, Icons.schedule),
            _buildTab('In Progress', stats['in_progress']!, Icons.medical_services),
            _buildTab('Completed', stats['completed']!, Icons.check_circle),
            _buildTab('Declined', stats['declined']!, Icons.cancel),
          ],
        );
      }),
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
    
    return TabBarView(
      controller: _tabController,
      children: _tabValues.map((tabValue) => _buildAppointmentsList(controller, tabValue, isMobile)).toList(),
    );
  }

  Widget _buildAppointmentsList(WebAppointmentController controller, String tabValue, bool isMobile) {
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
              isSelected: false, // You can implement selection logic here
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
        subtitle = 'Accepted appointments will appear here.';
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
      case 'declined':
        icon = Icons.cancel_outlined;
        title = 'No Declined Appointments';
        subtitle = 'Declined appointments will appear here.';
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
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
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
      case 'Declined':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}