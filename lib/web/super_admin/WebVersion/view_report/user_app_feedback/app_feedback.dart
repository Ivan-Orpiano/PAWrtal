import 'package:capstone_app/web/super_admin/WebVersion/services/attachment_viewer_widget.dart';
import 'package:capstone_app/web/user_web/controllers/web_feedback_controller.dart';
import 'package:capstone_app/web/responsive_layout.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:capstone_app/data/models/feedback_and_report_model.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/utils/user_session_service.dart';
import 'package:capstone_app/web/super_admin/WebVersion/vet_clinic_pages/veterinary_clinics/super_ad_vet_clinic_dashboard.dart';
import 'package:capstone_app/web/super_admin/WebVersion/pet_owners_pages/user_page.dart';
import 'package:capstone_app/web/super_admin/WebVersion/view_report/user_vet_feedback/vet_deletion_reports.dart';
import 'package:capstone_app/utils/logout_helper.dart';
import 'dart:async';
import 'package:capstone_app/web/super_admin/WebVersion/view_report/user_app_feedback/pinned_feedback_app.dart';

class AdminFeedbackManagement extends StatefulWidget {
  const AdminFeedbackManagement({super.key});

  @override
  State<AdminFeedbackManagement> createState() =>
      _AdminFeedbackManagementState();
}

class _AdminFeedbackManagementState extends State<AdminFeedbackManagement> {
  late WebFeedbackController controller;
  final TextEditingController searchController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isLoggingOut = false;
  Timer? _timeUpdateTimer;

  final Set<String> _selectedFeedbackIds = <String>{};
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    _timeUpdateTimer?.cancel();
    controller = Get.put(WebFeedbackController(
      authRepository: Get.find<AuthRepository>(),
      session: Get.find<UserSessionService>(),
    ));
    controller.loadAllFeedback();
    _timeUpdateTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timeUpdateTimer?.cancel();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobileBody: () => _buildMobileLayout(),
      tabletBody: () => _buildTabletLayout(),
      desktopBody: () => _buildDesktopLayout(),
    );
  }

  // ==================== MOBILE LAYOUT ====================
  Widget _buildMobileLayout() {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, color: Color(0xFF517399)),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          tooltip: 'Menu',
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'System Reports',
              style: TextStyle(
                color: Color(0xFF517399),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        backgroundColor: const Color.fromRGBO(248, 253, 255, 1),
        actions: [
          // Auto-Clean Spam Button
          Obx(() => controller.isCleaningSpam.value
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF517399)),
                    ),
                  ),
                )
              : Tooltip(
                  message: 'Auto-clean spam feedback',
                  child: TextButton.icon(
                    onPressed: () => controller.autoCleanSpamFeedback(),
                    icon: const Icon(Icons.cleaning_services, size: 18),
                    label: const Text('Clean Spam'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFE65100),
                      backgroundColor: Colors.orange[50],
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                  ),
                )),
          const SizedBox(width: 8),

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
          const SizedBox(width: 12),
        ],
      ),
      drawer: _buildDrawer(context),
      backgroundColor: const Color.fromRGBO(248, 253, 255, 1),
      body: Column(
        children: [
          _buildMobileStatsCards(),
          _buildMobileFiltersSection(),
          Expanded(child: _buildFeedbackList(isMobile: true)),
        ],
      ),
      floatingActionButton: _buildPinnedFAB(),
    );
  }

  Widget _buildMobileStatsCards() {
  return Obx(() {
    final visibleFeedback = controller.allFeedback
        .where((f) => !f.isArchived) // Only exclude archived
        .toList();

    final stats = {
      'total': visibleFeedback.length,
      'pending': visibleFeedback.where((f) => f.status == FeedbackStatus.pending).length,
      'inProgress': visibleFeedback.where((f) => f.status == FeedbackStatus.inProgress).length,
      'completed': visibleFeedback.where((f) => f.status == FeedbackStatus.completed).length,
      'critical': visibleFeedback.where((f) => f.priority == Priority.critical).length,
    };

    return Container(
      color: const Color.fromRGBO(248, 253, 255, 1),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildCompactStatCard(
                  'Total',
                  stats['total']?.toString() ?? '0',
                  Colors.blue,
                  Icons.feedback,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCompactStatCard(
                  'Pending',
                  stats['pending']?.toString() ?? '0',
                  Colors.orange,
                  Icons.schedule,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCompactStatCard(
                  'Progress',
                  stats['inProgress']?.toString() ?? '0',
                  Colors.blue,
                  Icons.autorenew,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildCompactStatCard(
                  'Completed',
                  stats['completed']?.toString() ?? '0',
                  Colors.green,
                  Icons.check_circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCompactStatCard(
                  'Critical',
                  stats['critical']?.toString() ?? '0',
                  Colors.red,
                  Icons.warning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  });
}

  Widget _buildCompactStatCard(
      String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMobileFiltersSection() {
    return Container(
      color: const Color.fromRGBO(248, 253, 255, 1),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: [
          TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'Search feedback...',
              hintStyle: const TextStyle(fontSize: 14),
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: Obx(() => controller.searchQuery.value.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
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
                borderSide:
                    const BorderSide(color: Color(0xFF517399), width: 2),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            onChanged: (value) => controller.updateSearchQuery(value),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Obx(() => _buildCompactFilterChip<FeedbackStatus>(
                      'Status',
                      controller.statusFilter.value,
                      FeedbackStatus.values,
                      (value) {
                        if (value == null) {
                          controller.updateFilters(clearStatus: true);
                        } else {
                          controller.updateFilters(status: value);
                        }
                      },
                      (status) => status.displayName,
                    )),
                const SizedBox(width: 8),
                Obx(() => _buildCompactFilterChip<FeedbackType>(
                      'Type',
                      controller.typeFilter.value,
                      FeedbackType.values,
                      (value) {
                        if (value == null) {
                          controller.updateFilters(clearType: true);
                        } else {
                          controller.updateFilters(type: value);
                        }
                      },
                      (type) => type.displayName,
                    )),
                const SizedBox(width: 8),
                Obx(() => _buildCompactFilterChip<FeedbackCategory>(
                      'Category',
                      controller.categoryFilter.value,
                      FeedbackCategory.values,
                      (value) {
                        if (value == null) {
                          controller.updateFilters(clearCategory: true);
                        } else {
                          controller.updateFilters(category: value);
                        }
                      },
                      (category) => category.displayName,
                    )),
                const SizedBox(width: 8),
                Obx(() => _buildCompactFilterChip<Priority>(
                      'Priority',
                      controller.priorityFilter.value,
                      Priority.values,
                      (value) {
                        if (value == null) {
                          controller.updateFilters(clearPriority: true);
                        } else {
                          controller.updateFilters(priority: value);
                        }
                      },
                      (priority) => priority.displayName,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactFilterChip<T>(
    String label,
    T? selectedValue,
    List<T> items,
    Function(T?) onChanged,
    String Function(T) getText,
  ) {
    return PopupMenuButton<T>(
      color: const Color.fromRGBO(248, 253, 255, 1),
      offset: const Offset(0, 40),
      onSelected: onChanged,
      itemBuilder: (context) => [
        PopupMenuItem<T>(
          value: null,
          child: Text('All $label', style: const TextStyle(fontSize: 13)),
        ),
        ...items.map((item) => PopupMenuItem<T>(
              value: item,
              child: Text(getText(item), style: const TextStyle(fontSize: 13)),
            )),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selectedValue != null ? const Color(0xFF517399) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selectedValue != null
                ? const Color(0xFF517399)
                : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              selectedValue != null ? getText(selectedValue) : label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selectedValue != null ? Colors.white : Colors.grey[700],
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 16,
              color: selectedValue != null ? Colors.white : Colors.grey[700],
            ),
          ],
        ),
      ),
    );
  }

  // ==================== TABLET LAYOUT ====================
  Widget _buildTabletLayout() {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, color: Color(0xFF517399)),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          tooltip: 'Menu',
        ),
        title: const Row(
          children: [
            Icon(Icons.feedback, color: Color(0xFF517399)),
            SizedBox(width: 8),
            Text(
              'System Reports',
              style: TextStyle(
                color: Color(0xFF517399),
                fontWeight: FontWeight.bold,
                fontSize: 18,
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
          const SizedBox(width: 12),
        ],
      ),
      drawer: _buildDrawer(context),
      backgroundColor: const Color.fromRGBO(248, 253, 255, 1),
      body: Column(
        children: [
          _buildTabletStatsCards(),
          _buildTabletFiltersSection(),
          Expanded(child: _buildFeedbackList(isTablet: true)),
        ],
      ),
      floatingActionButton: _buildPinnedFAB(),
    );
  }
    Widget _buildTabletStatsCards() {
  return Obx(() {
   
    final visibleFeedback = controller.allFeedback
        .where((f) => !f.isArchived)
        .toList();

    final stats = {
      'total': visibleFeedback.length,
      'pending': visibleFeedback.where((f) => f.status == FeedbackStatus.pending).length,
      'inProgress': visibleFeedback.where((f) => f.status == FeedbackStatus.inProgress).length,
      'completed': visibleFeedback.where((f) => f.status == FeedbackStatus.completed).length,
      'critical': visibleFeedback.where((f) => f.priority == Priority.critical).length,
    };

    return Container(
      color: const Color.fromRGBO(248, 253, 255, 1),
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            children: [
              _buildStatCard(
                'Total',
                stats['total']?.toString() ?? '0',
                Colors.blue,
                Icons.feedback,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                'Pending',
                stats['pending']?.toString() ?? '0',
                Colors.orange,
                Icons.schedule,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                'In Progress',
                stats['inProgress']?.toString() ?? '0',
                Colors.blue,
                Icons.autorenew,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Completed',
                  stats['completed']?.toString() ?? '0',
                  Colors.green,
                  Icons.check_circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatCard(
                  'Critical',
                  stats['critical']?.toString() ?? '0',
                  Colors.red,
                  Icons.warning,
                ),
              ),
              const Expanded(child: SizedBox()),
              Expanded(
                child: _buildStatCard(
                  'Spam Blocked',
                  controller.autoArchivedCount.value.toString(),
                  Colors.orange,
                  Icons.block,
                ),
              ),
              const SizedBox(width: 10),
            ],
          ),
        ],
      ),
    );
  });
}

  Widget _buildTabletFiltersSection() {
    return Container(
      color: const Color.fromRGBO(248, 253, 255, 1),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Column(
        children: [
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
                borderSide:
                    const BorderSide(color: Color(0xFF517399), width: 2),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            onChanged: (value) => controller.updateSearchQuery(value),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Obx(() => _buildFilterDropdown<FeedbackStatus>(
                      'Status',
                      controller.statusFilter.value,
                      FeedbackStatus.values,
                      (value) {
                        if (value == null) {
                          controller.updateFilters(clearStatus: true);
                        } else {
                          controller.updateFilters(status: value);
                        }
                      },
                      (status) => status.displayName,
                    )),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Obx(() => _buildFilterDropdown<FeedbackType>(
                      'Type',
                      controller.typeFilter.value,
                      FeedbackType.values,
                      (value) {
                        if (value == null) {
                          controller.updateFilters(clearType: true);
                        } else {
                          controller.updateFilters(type: value);
                        }
                      },
                      (type) => type.displayName,
                    )),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Obx(() => _buildFilterDropdown<FeedbackCategory>(
                      'Category',
                      controller.categoryFilter.value,
                      FeedbackCategory.values,
                      (value) {
                        if (value == null) {
                          controller.updateFilters(clearCategory: true);
                        } else {
                          controller.updateFilters(category: value);
                        }
                      },
                      (category) => category.displayName,
                    )),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Obx(() => _buildFilterDropdown<Priority>(
                      'Priority',
                      controller.priorityFilter.value,
                      Priority.values,
                      (value) {
                        if (value == null) {
                          controller.updateFilters(clearPriority: true);
                        } else {
                          controller.updateFilters(priority: value);
                        }
                      },
                      (priority) => priority.displayName,
                    )),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== DESKTOP LAYOUT ====================
  Widget _buildDesktopLayout() {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, color: Color(0xFF517399)),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          tooltip: 'Menu',
        ),
        title: const Row(
          children: [
            Icon(Icons.feedback, color: Color(0xFF517399)),
            SizedBox(width: 8),
            Text(
              'System Reports',
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
      floatingActionButton: _buildPinnedFAB(),
    );
  }

    Widget _buildStatsCards() {
      return Obx(() {
        final activeUnpinnedFeedback = controller.allFeedback
            .where((f) => !f.isArchived) 
            .toList();

        final stats = {
          'total': activeUnpinnedFeedback.length,
          'pending': activeUnpinnedFeedback.where((f) => f.status == FeedbackStatus.pending).length,
          'inProgress': activeUnpinnedFeedback.where((f) => f.status == FeedbackStatus.inProgress).length,
          'completed': activeUnpinnedFeedback.where((f) => f.status == FeedbackStatus.completed).length,
          'critical': activeUnpinnedFeedback.where((f) => f.priority == Priority.critical).length,
        };

        return Container(
          color: const Color.fromRGBO(248, 253, 255, 1),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _buildStatCard(
                'Total',
                stats['total']?.toString() ?? '0',
                Colors.blue,
                Icons.feedback,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                'Pending',
                stats['pending']?.toString() ?? '0',
                Colors.orange,
                Icons.schedule,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                'In Progress',
                stats['inProgress']?.toString() ?? '0',
                Colors.blue,
                Icons.autorenew,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                'Completed',
                stats['completed']?.toString() ?? '0',
                Colors.green,
                Icons.check_circle,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                'Critical',
                stats['critical']?.toString() ?? '0',
                Colors.red,
                Icons.warning,
              ),
            ],
          ),
        );
      });
    }

  Widget _buildStatCard(
      String title, String value, Color color, IconData icon) {
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
                borderSide:
                    const BorderSide(color: Color(0xFF517399), width: 2),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (value) => controller.updateSearchQuery(value),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Obx(() => _buildFilterDropdown<FeedbackStatus>(
                      'Status',
                      controller.statusFilter.value,
                      FeedbackStatus.values,
                      (value) {
                        if (value == null) {
                          controller.updateFilters(clearStatus: true);
                        } else {
                          controller.updateFilters(status: value);
                        }
                      },
                      (status) => status.displayName,
                    )),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Obx(() => _buildFilterDropdown<FeedbackType>(
                      'Type',
                      controller.typeFilter.value,
                      FeedbackType.values,
                      (value) {
                        if (value == null) {
                          controller.updateFilters(clearType: true);
                        } else {
                          controller.updateFilters(type: value);
                        }
                      },
                      (type) => type.displayName,
                    )),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Obx(() => _buildFilterDropdown<FeedbackCategory>(
                      'Category',
                      controller.categoryFilter.value,
                      FeedbackCategory.values,
                      (value) {
                        if (value == null) {
                          controller.updateFilters(clearCategory: true);
                        } else {
                          controller.updateFilters(category: value);
                        }
                      },
                      (category) => category.displayName,
                    )),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Obx(() => _buildFilterDropdown<Priority>(
                      'Priority',
                      controller.priorityFilter.value,
                      Priority.values,
                      (value) {
                        if (value == null) {
                          controller.updateFilters(clearPriority: true);
                        } else {
                          controller.updateFilters(priority: value);
                        }
                      },
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
          child: Text('All $label'),
        ),
        ...items.map((item) => DropdownMenuItem<T>(
              value: item,
              child: Text(getText(item)),
            )),
      ],
      onChanged: onChanged,
    );
  }

  IconData _getStatusIcon(FeedbackStatus status) {
    switch (status) {
      case FeedbackStatus.pending:
        return Icons.schedule;
      case FeedbackStatus.inProgress:
        return Icons.autorenew;
      case FeedbackStatus.completed:
        return Icons.check_circle;
      case FeedbackStatus.closed:
        return Icons.lock;
    }
  }

    Widget _buildFeedbackList({bool isMobile = false, bool isTablet = false}) {
      return Obx(() {
        if (controller.isLoadingFeedback.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final visibleFeedback = controller.filteredFeedback
            .where((feedback) => !feedback.isPinned && !feedback.isArchived) 
            .toList();

        if (visibleFeedback.isEmpty) {
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
                const SizedBox(height: 8),
                Text(
                  controller.filteredFeedback.isEmpty
                      ? 'No feedback items to display'
                      : 'All feedback items are ${controller.filteredFeedback.every((f) => f.isPinned) ? "pinned" : "archived"}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          itemCount: visibleFeedback.length,
          itemBuilder: (context, index) {
            final feedback = visibleFeedback[index];
            if (isMobile) {
              return _buildMobileFeedbackCard(feedback);
            } else if (isTablet) {
              return _buildTabletFeedbackCard(feedback);
            }
            return _buildFeedbackCard(feedback);
          },
        );
      });
    }
  // ==================== MOBILE FEEDBACK CARD ====================
  Widget _buildMobileFeedbackCard(FeedbackAndReport feedback) {
    return Obx(() {
      final feedbackItem = controller.allFeedback.firstWhere(
        (f) => f.documentId == feedback.documentId,
        orElse: () => feedback,
      );
      final isPinned = feedbackItem.isPinned;

      return Card(
        color: isPinned
            ? const Color.fromRGBO(255, 248, 225, 1)
            : const Color.fromRGBO(242, 250, 252, 1),
        margin: const EdgeInsets.only(bottom: 10),
        elevation: isPinned ? 6 : 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isPinned
              ? const BorderSide(color: Colors.amber, width: 2)
              : BorderSide.none,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showFeedbackDetails(feedback),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    InkWell(
                      onTap: () => controller.togglePin(feedback.documentId!),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isPinned
                              ? Colors.amber.withOpacity(0.2)
                              : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                          size: 14,
                          color:
                              isPinned ? Colors.amber[800] : Colors.grey[600],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    _buildClickablePriorityBadge(feedback),
                    const Spacer(),
                    _buildStatusBadge(feedback.status),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  feedback.subject,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  feedback.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildTypeBadge(feedback.feedbackType),
                    _buildCategoryBadge(feedback.category),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.person, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        feedback.userName,
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      _formatDateTime(feedback.submittedAt),
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ],
                ),
                // Display attachments with video support
                if (feedback.attachments.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Attachments (${feedback.attachments.length})',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: feedback.attachments.map((fileId) {
                      final url = controller.getAttachmentUrl(fileId);
                      final isVideo = _isVideoAttachment(fileId, url);

                      return GestureDetector(
                        onTap: () =>
                            _showAttachmentDialog(context, url, isVideo),
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: AttachmentViewerWidget(
                            attachmentUrl: url,
                            fileId: fileId,
                            isVideo: isVideo,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
                // Status-based action buttons
                // Archive button for completed/closed status
                if (feedback.status == FeedbackStatus.completed ||
                    feedback.status == FeedbackStatus.closed) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: () => _archiveFeedback(feedback),
                      icon: const Icon(Icons.archive, size: 14, color: Colors.white),
                      label: const Text('Archive', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    });
  }

  // ==================== TABLET FEEDBACK CARD ====================
  Widget _buildTabletFeedbackCard(FeedbackAndReport feedback) {
    return Obx(() {
      final feedbackItem = controller.allFeedback.firstWhere(
        (f) => f.documentId == feedback.documentId,
        orElse: () => feedback,
      );
      final isPinned = feedbackItem.isPinned;

      return Card(
        color: isPinned
            ? const Color.fromRGBO(255, 248, 225, 1)
            : const Color.fromRGBO(242, 250, 252, 1),
        margin: const EdgeInsets.only(bottom: 12),
        elevation: isPinned ? 7 : 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isPinned
              ? const BorderSide(color: Colors.amber, width: 2)
              : BorderSide.none,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showFeedbackDetails(feedback),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    InkWell(
                      onTap: () => controller.togglePin(feedback.documentId!),
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: isPinned
                              ? Colors.amber.withOpacity(0.2)
                              : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(
                          isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                          size: 16,
                          color:
                              isPinned ? Colors.amber[800] : Colors.grey[600],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildClickablePriorityBadge(feedback),
                    const SizedBox(width: 8),
                    _buildTypeBadge(feedback.feedbackType),
                    const SizedBox(width: 8),
                    _buildCategoryBadge(feedback.category),
                    const Spacer(),
                    _buildStatusBadge(feedback.status),
                  ],
                ),
                if (isPinned) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.push_pin, size: 12, color: Colors.amber[800]),
                      const SizedBox(width: 4),
                      Text(
                        'Pinned',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.amber[800],
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  feedback.subject,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  feedback.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.person, size: 15, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      feedback.userName,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.access_time, size: 15, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      _formatDateTime(feedback.submittedAt),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    if (feedback.attachments.isNotEmpty) ...[
                      const SizedBox(width: 16),
                      Icon(Icons.attachment, size: 15, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        '${feedback.attachments.length}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ],
                ),
               if (feedback.status == FeedbackStatus.completed ||
                    feedback.status == FeedbackStatus.closed) ...[
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => _archiveFeedback(feedback),
                    icon: const Icon(Icons.archive, size: 16, color: Colors.white),
                    label: const Text('Archive'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    });
  }

  // ==================== DESKTOP FEEDBACK CARD ====================
  Widget _buildFeedbackCard(FeedbackAndReport feedback) {
    final isSelected = _selectedFeedbackIds.contains(feedback.documentId);
    return Obx(() {
      final feedbackItem = controller.allFeedback.firstWhere(
        (f) => f.documentId == feedback.documentId,
        orElse: () => feedback,
      );
      final isPinned = feedbackItem.isPinned;

      return Card(
        color: isPinned
            ? const Color.fromRGBO(255, 248, 225, 1)
            : const Color.fromRGBO(242, 250, 252, 1),
        margin: const EdgeInsets.only(bottom: 12),
        elevation: isPinned ? 8 : 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isPinned
              ? const BorderSide(color: Colors.amber, width: 2)
              : BorderSide.none,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showFeedbackDetails(feedback),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: isSelected,
                      onChanged: (bool? value) {
                        _toggleSelection(feedback.documentId!);
                      },
                      activeColor: const Color(0xFF517399),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => controller.togglePin(feedback.documentId!),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isPinned
                              ? Colors.amber.withOpacity(0.2)
                              : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                          size: 18,
                          color:
                              isPinned ? Colors.amber[800] : Colors.grey[600],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FutureBuilder<Map<String, bool>>(
                      future: Future.wait([
                        controller.checkIfSpam(feedback),
                        controller.checkUserRedundancy(feedback),
                      ]).then((results) => {
                            'isSpam': results[0],
                            'isRedundant': results[1],
                          }),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const SizedBox.shrink();

                        final isSpam = snapshot.data!['isSpam'] ?? false;
                        final isRedundant =
                            snapshot.data!['isRedundant'] ?? false;

                        if (!isSpam && !isRedundant)
                          return const SizedBox.shrink();

                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isSpam) ...[
                              Tooltip(
                                message: 'Gibberish/Scrambled content detected',
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.red[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.red[300]!),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.report_problem,
                                          size: 14, color: Colors.red[700]),
                                      const SizedBox(width: 4),
                                      Text(
                                        'SPAM',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            if (isRedundant) ...[
                              Tooltip(
                                message: 'Duplicate submission from this user',
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.orange[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border:
                                        Border.all(color: Colors.orange[300]!),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.content_copy,
                                          size: 14, color: Colors.orange[700]),
                                      const SizedBox(width: 4),
                                      Text(
                                        'DUPLICATE',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildClickablePriorityBadge(feedback),
                    const SizedBox(width: 8),
                    _buildTypeBadge(feedback.feedbackType),
                    const SizedBox(width: 8),
                    _buildCategoryBadge(feedback.category),
                    const Spacer(),
                    _buildStatusBadge(feedback.status),
                  ],
                ),
                if (isPinned) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.push_pin, size: 12, color: Colors.amber[800]),
                      const SizedBox(width: 4),
                      Text(
                        'Pinned',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.amber[800],
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  feedback.subject,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
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
                // Status-based action buttons
                // Archive button for completed/closed status
                if (feedback.status == FeedbackStatus.completed ||
                    feedback.status == FeedbackStatus.closed) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (feedback.status == FeedbackStatus.completed)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green[300]!),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle, size: 20, color: Colors.green[700]),
                              const SizedBox(width: 10),
                              Text(
                                'Issue Resolved',
                                style: TextStyle(
                                  color: Colors.green[700],
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (feedback.status == FeedbackStatus.completed)
                        const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: () => _archiveFeedback(feedback),
                        icon: const Icon(Icons.archive, size: 18, color: Colors.white),
                        label: const Text('Archive', style: TextStyle(fontSize: 14)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
    });
  }

  Widget _buildClickablePriorityBadge(FeedbackAndReport feedback) {
    Color color = _getPriorityColor(feedback.priority);
    IconData icon = _getPriorityIcon(feedback.priority);

    return PopupMenuButton<Priority>(
      color: const Color.fromRGBO(248, 253, 255, 1),
      tooltip: 'Change Priority',
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[300]!),
      ),
      onSelected: (Priority newPriority) {
        if (newPriority != feedback.priority) {
          controller.updatePriority(feedback.documentId!, newPriority);
        }
      },
      itemBuilder: (BuildContext context) {
        return Priority.values.map((Priority priority) {
          final isSelected = priority == feedback.priority;
          final priorityColor = _getPriorityColor(priority);
          final priorityIcon = _getPriorityIcon(priority);

          return PopupMenuItem<Priority>(
            value: priority,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: priorityColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    priorityIcon,
                    size: 16,
                    color: priorityColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    priority.displayName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? priorityColor : Colors.grey[800],
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check, size: 18, color: priorityColor),
              ],
            ),
          );
        }).toList();
      },
      child: Container(
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
              feedback.priority.displayName,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, size: 16, color: color),
          ],
        ),
      ),
    );
  }

  Widget _buildClickableStatusBadge(FeedbackAndReport feedback) {
    Color color = _getStatusColor(feedback.status);

    return PopupMenuButton<FeedbackStatus>(
      color: const Color.fromRGBO(248, 253, 255, 1),
      tooltip: 'Change Status',
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[300]!),
      ),
      onSelected: (FeedbackStatus newStatus) {
        if (newStatus != feedback.status) {
          controller.updateStatus(feedback.documentId!, newStatus);
        }
      },
      itemBuilder: (BuildContext context) {
        return FeedbackStatus.values.map((FeedbackStatus status) {
          final isSelected = status == feedback.status;
          final statusColor = _getStatusColor(status);
          final statusIcon = _getStatusIcon(status);

          return PopupMenuItem<FeedbackStatus>(
            value: status,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    statusIcon,
                    size: 16,
                    color: statusColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    status.displayName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? statusColor : Colors.grey[800],
                    ),
                  ),
                ),
                if (isSelected) Icon(Icons.check, size: 18, color: statusColor),
              ],
            ),
          );
        }).toList();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              feedback.status.displayName,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, size: 16, color: color),
          ],
        ),
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
      case FeedbackStatus.completed:
        return Colors.green;
      case FeedbackStatus.closed:
        return Colors.grey;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      if (difference.inDays == 1) {
        return '1 day ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else if (difference.inDays < 30) {
        final weeks = (difference.inDays / 7).floor();
        return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
      } else if (difference.inDays < 365) {
        final months = (difference.inDays / 30).floor();
        return months == 1 ? '1 month ago' : '$months months ago';
      } else {
        final years = (difference.inDays / 365).floor();
        return years == 1 ? '1 year ago' : '$years years ago';
      }
    } else if (difference.inHours > 0) {
      return difference.inHours == 1
          ? '1 hour ago'
          : '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return difference.inMinutes == 1
          ? '1 minute ago'
          : '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

   void _toggleSelection(String feedbackId) {
    setState(() {
      if (_selectedFeedbackIds.contains(feedbackId)) {
        _selectedFeedbackIds.remove(feedbackId);
        if (_selectedFeedbackIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedFeedbackIds.add(feedbackId);
        _isSelectionMode = true;
      }
    });
  }

  void _selectAll(List<FeedbackAndReport> feedbackList) {
    setState(() {
      if (_selectedFeedbackIds.length == feedbackList.length) {
        _selectedFeedbackIds.clear();
        _isSelectionMode = false;
      } else {
        _selectedFeedbackIds.clear();
        _selectedFeedbackIds.addAll(
          feedbackList.map((f) => f.documentId!).where((id) => id.isNotEmpty)
        );
        _isSelectionMode = true;
      }
    });
  }

  void _cancelSelection() {
    setState(() {
      _selectedFeedbackIds.clear();
      _isSelectionMode = false;
    });
  }

  Future<void> _archiveSelectedFeedback() async {
    if (_selectedFeedbackIds.isEmpty) return;

    final count = _selectedFeedbackIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color.fromRGBO(248, 253, 255, 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.archive, color: Colors.orange[700], size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Archive Selected'),
          ],
        ),
        content: Text(
          'Archive $count selected feedback item${count > 1 ? 's' : ''}?',
          style: TextStyle(fontSize: 15, color: Colors.grey[700]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.archive, size: 18),
            label: const Text('Archive'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[600],
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final ids = List<String>.from(_selectedFeedbackIds);
      for (final id in ids) {
        await controller.archiveFeedback(id);
      }
      setState(() {
        _selectedFeedbackIds.clear();
        _isSelectionMode = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Archived $count feedback item${count > 1 ? 's' : ''}'),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

    void _archiveFeedback(FeedbackAndReport feedback) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.transparent,
          child: Container(
            width: 450,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.orange[50]!,
                  Colors.deepOrange[50]!,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 🎨 Animated Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange[700]!, Colors.orange[500]!],
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 600),
                        tween: Tween(begin: 0.0, end: 1.0),
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.archive_rounded,
                                color: Colors.white,
                                size: 48,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Archive Feedback',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Remove from active view',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                // 📋 Content Section
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Feedback Preview Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.orange[200]!, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withOpacity(0.1),
                              blurRadius: 10,
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
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.orange[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.feedback,
                                    color: Colors.orange[700],
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        feedback.subject,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.grey[800],
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(Icons.person_outline,
                                              size: 14, color: Colors.grey[600]),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              feedback.userName,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Divider(color: Colors.grey[300], height: 1),
                            const SizedBox(height: 12),
                            // Status and Priority badges
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _buildMiniStatusBadge(feedback.status),
                                _buildMiniPriorityBadge(feedback.priority),
                                _buildMiniTypeBadge(feedback.feedbackType),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Warning Box
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange[300]!),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.orange[100],
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.info_outline,
                                color: Colors.orange[800],
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'What happens next?',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.orange[900],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'This feedback will be moved to archive. It can be permanently deleted after review.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.orange[800],
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // 🎯 Action Buttons
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, size: 18),
                          label: const Text('Cancel'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey[700],
                            side: BorderSide(color: Colors.grey[300]!),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                        onPressed: () async {
                          // Close the dialog first
                          Navigator.pop(context);
                          
                          // Archive the feedback
                          await controller.archiveFeedback(feedback.documentId!);
                          
                          // Show success message (already handled in controller)
                        },
                        icon: const Icon(Icons.archive, size: 20),
                        label: const Text(
                          'Archive Now',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                          shadowColor: Colors.orange.withOpacity(0.5),
                        ),
                      ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

// 🎨 Helper methods for mini badges (add these after _archiveFeedback method)
Widget _buildMiniStatusBadge(FeedbackStatus status) {
  Color color = _getStatusColor(status);
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(_getStatusIcon(status), size: 12, color: color),
        const SizedBox(width: 4),
        Text(
          status.displayName,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    ),
  );
}

Widget _buildMiniPriorityBadge(Priority priority) {
  Color color = _getPriorityColor(priority);
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(_getPriorityIcon(priority), size: 12, color: color),
        const SizedBox(width: 4),
        Text(
          priority.displayName,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    ),
  );
}

Widget _buildMiniTypeBadge(FeedbackType type) {
  Color color = _getTypeColor(type);
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Text(
      type.displayName,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: color,
      ),
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
                        builder: (context) =>
                            const SuperAdminVetClinicDashboard(),
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
                        builder: (context) =>
                            const SuperAdminUserManagementScreen(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.delete_forever_rounded,
                  title: 'Deletion Reports',
                  subtitle: 'Feedback deletion requests',
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
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
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

  bool _isVideoAttachment(String fileId, String url) {
    // Check URL extension
    final videoExtensions = ['mp4', 'mov', 'avi', 'mkv', 'webm'];
    final urlLower = url.toLowerCase();

    return videoExtensions.any((ext) => urlLower.contains('.$ext'));
  }

  void _showAttachmentDialog(BuildContext context, String url, bool isVideo) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: 800,
            maxHeight: 600,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Row(
                  children: [
                    Icon(
                      isVideo ? Icons.videocam_rounded : Icons.image_rounded,
                      color: Colors.grey[700],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isVideo ? 'Video Attachment' : 'Image Attachment',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: AttachmentViewerWidget(
                    attachmentUrl: url,
                    fileId: url,
                    isVideo: isVideo,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== PINNED FEEDBACK FAB ====================
  Widget _buildPinnedFAB() {
    return Obx(() {
      final pinnedCount = controller.pinnedFeedbackIds.length;
        if (_isSelectionMode && _selectedFeedbackIds.isNotEmpty) {
        return FloatingActionButton.extended(
          onPressed: _archiveSelectedFeedback,
          backgroundColor: Colors.orange[700],
          icon: const Icon(Icons.archive, color: Colors.white),
          label: Text(
            'Archive (${_selectedFeedbackIds.length})',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          elevation: 6,
        );
      }
      return pinnedCount > 0
          ? Stack(
              alignment: Alignment.center,
              children: [
                FloatingActionButton.extended(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PinnedFeedbackPage(),
                      ),
                    );
                  },
                  backgroundColor: Colors.amber[700],
                  icon: const Icon(Icons.push_pin, color: Colors.white),
                  label: Text(
                    'Pinned ($pinnedCount)',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  elevation: 6,
                ),
                if (pinnedCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.red[600],
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 24,
                        minHeight: 24,
                      ),
                      child: Text(
                        '$pinnedCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            )
          : const SizedBox.shrink(); // Hide FAB when no pinned items
    });
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
                widget.controller
                    .updateStatus(widget.feedback.documentId!, status);
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
                widget.controller
                    .updatePriority(widget.feedback.documentId!, priority);
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
              backgroundColor: Colors.orange[600],
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
