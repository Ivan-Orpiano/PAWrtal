import 'dart:async';
import 'package:appwrite/appwrite.dart';
import 'package:capstone_app/utils/logout_helper.dart';
import 'package:capstone_app/web/super_admin/WebVersion/pet_owners_pages/user_page.dart';
import 'package:capstone_app/web/super_admin/WebVersion/services/attachment_viewer_widget.dart';
import 'package:capstone_app/web/super_admin/WebVersion/vet_clinic_pages/veterinary_clinics/super_ad_vet_clinic_dashboard.dart';
import 'package:capstone_app/web/super_admin/WebVersion/view_report/user_app_feedback/app_feedback.dart';
import 'package:capstone_app/web/super_admin/WebVersion/view_report/user_vet_feedback/vet_deletion_reports.dart';
import 'package:capstone_app/web/user_web/controllers/web_feedback_controller.dart';
import 'package:capstone_app/web/responsive_layout.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:capstone_app/data/models/feedback_and_report_model.dart';

class PinnedFeedbackPage extends StatefulWidget {
  const PinnedFeedbackPage({super.key});

  @override
  State<PinnedFeedbackPage> createState() => _PinnedFeedbackPageState();
}

class _PinnedFeedbackPageState extends State<PinnedFeedbackPage> {
  late WebFeedbackController controller;
  final TextEditingController searchController = TextEditingController();

  StreamSubscription<RealtimeMessage>? _feedbackSubscription;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    controller = Get.find<WebFeedbackController>();
    _setupRealtimeUpdates();
    ever(controller.pinnedFeedbackIds, (pinnedIds) {
    
    // Force UI update when pinned IDs change
    if (mounted) {
      setState(() {});
    }
  });
  }

  @override
  void dispose() {
    searchController.dispose();
    _feedbackSubscription?.cancel();
    super.dispose();
  }

        /// Setup real-time updates for pinned feedback page
      void _setupRealtimeUpdates() {
        try {
          _feedbackSubscription = controller.authRepository.appWriteProvider
              .subscribeToFeedbackChanges()
              .listen((event) {
            if (!mounted) return;
            // Trigger UI refresh when any feedback changes
            if (mounted) {
              setState(() {
                // This will cause pinnedFeedback getter to recalculate
              });
            }  
          }, onError: (error) {
            });
            } catch (e) {
        }
      }

        // Get only pinned AND non-archived feedback
        List<FeedbackAndReport> get pinnedFeedback {
          // ✅ CRITICAL: Filter out archived items
          final pinned = controller.filteredFeedback
              .where((f) => f.isPinned && !f.isArchived) 
              .toList();
          pinned.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));                  
          return pinned;
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
            drawer: _buildDrawer(context), 
            appBar: AppBar(
              surfaceTintColor: Colors.transparent,
              leading: IconButton(
                icon: const Icon(
                  Icons.menu_rounded,
                  color:  Color.fromRGBO(81, 115, 153, 1),
                  size: 22,
                ),
                onPressed: () {
                  _scaffoldKey.currentState?.openDrawer();
                },
                tooltip: 'Menu',
              ),
              title: Row(
                children: [
                  Icon(Icons.push_pin, color: Colors.amber[800], size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Pinned Reports',
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
                  Obx(() {
              if (controller.isLoadingFeedback.value) {
                  return const Padding(
                    padding:  EdgeInsets.all(12.0),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child:  CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF517399), size: 22),
                onPressed: () => Navigator.pop(context),
                tooltip: 'Back to All Reports',
              ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Color(0xFF517399)),
                  onPressed: () => controller.loadAllFeedback(),
                  tooltip: 'Refresh',
                ),
                const SizedBox(width: 12),
              ],
            ),
            backgroundColor: const Color.fromRGBO(248, 253, 255, 1),
            body: Column(
              children: [
                _buildPinnedStatsCard(),
                _buildMobileSearchBar(),
                Expanded(child: _buildPinnedFeedbackList(isMobile: true)),
              ],
            ),
          );
        }

        // ==================== TABLET LAYOUT ====================
        Widget _buildTabletLayout() {
          return Scaffold(
          key: _scaffoldKey,
          drawer: _buildDrawer(context),
            appBar: AppBar(
              surfaceTintColor: Colors.transparent,
                leading: IconButton(
                icon: const Icon(Icons.menu_rounded, color: Color(0xFF517399)),
                onPressed: () {
                  _scaffoldKey.currentState?.openDrawer();
                },
                tooltip: 'Menu',
              ),
              title: Row(
                children: [
                  Icon(Icons.push_pin, color: Colors.amber[800]),
                  const SizedBox(width: 8),
                  const Text(
                    'Pinned Reports',
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
                Obx(() {
                if (controller.isLoadingFeedback.value) {
                  return Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),

                IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF517399)),
                onPressed: () => Navigator.pop(context),
                tooltip: 'Back to All Reports',
              ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Color(0xFF517399)),
                  onPressed: () => controller.loadAllFeedback(),
                  tooltip: 'Refresh',
                ),
                const SizedBox(width: 12),
              ],
            ),
            backgroundColor: const Color.fromRGBO(248, 253, 255, 1),
            body: Column(
              children: [
                _buildPinnedStatsCard(),
                _buildTabletSearchBar(),
                Expanded(child: _buildPinnedFeedbackList(isTablet: true)),
              ],
            ),
          );
        }

        // ==================== DESKTOP LAYOUT ====================
        Widget _buildDesktopLayout() {
          return Scaffold(
            key: _scaffoldKey,
            drawer: _buildDrawer(context),
            appBar: AppBar(
              surfaceTintColor: Colors.transparent,
                leading: IconButton(
                  icon: const Icon(Icons.menu_rounded, color: Color(0xFF517399)),
                  onPressed: () {
                    _scaffoldKey.currentState?.openDrawer();
                  },
                  tooltip: 'Menu',
                ),
              title: Row(
                children: [
                  Icon(Icons.push_pin, color: Colors.amber[800]),
                  const SizedBox(width: 8),
                  const Text(
                    'Pinned Reports',
                    style: TextStyle(
                      color: Color(0xFF517399),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color.fromRGBO(248, 253, 255, 1),
              actions: [
                Obx(() {
                if (controller.isLoadingFeedback.value) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF517399)),
                onPressed: () => Navigator.pop(context),
                tooltip: 'Back to All Reports',
              ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Color(0xFF517399)),
                  onPressed: () => controller.loadAllFeedback(),
                  tooltip: 'Refresh',
                ),
                const SizedBox(width: 16),
              ],
            ),
            backgroundColor: const Color.fromRGBO(248, 253, 255, 1),
            body: Column(
              children: [
                _buildPinnedStatsCard(),
                _buildDesktopSearchBar(),
                Expanded(child: _buildPinnedFeedbackList()),
              ],
            ),
          );
        }


            Widget _buildPinnedStatsCard() {
              return Obx(() {
            
                final pinnedCount = pinnedFeedback.length;
                final criticalCount = pinnedFeedback
                    .where((f) => f.priority == Priority.critical)
                    .length;
                final pendingCount = pinnedFeedback
                    .where((f) => f.status == FeedbackStatus.pending)
                    .length;
                final completedCount = pinnedFeedback
                    .where((f) => f.status == FeedbackStatus.completed)
                    .length;

                return Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.amber[700]!, Colors.amber[500]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // 📌 Icon Container
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.push_pin,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 20),
                      
                      // 📊 Stats Column
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Main Title
                            Text(
                              '$pinnedCount Pinned Report${pinnedCount != 1 ? 's' : ''}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            
                            // Filter Chips Row
                            Wrap(
                              spacing: 12,
                              runSpacing: 8,
                              children: [
                                _buildClickablePriorityFilter(
                                  Icons.warning,
                                  '$criticalCount Critical',
                                  Priority.critical,
                                ),
                                _buildClickableStatusFilter(
                                  Icons.schedule,
                                  '$pendingCount Pending',
                                  FeedbackStatus.pending,
                                ),
                                _buildClickableStatusFilter(
                                  Icons.check_circle,
                                  '$completedCount Completed',
                                  FeedbackStatus.completed,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              });
            }

          // 🎯 NEW: Clickable Priority Filter Chip
          Widget _buildClickablePriorityFilter(
            IconData icon,
            String label,
            Priority priority,
          ) {
            return Obx(() {
              final isActive = controller.priorityFilter.value == priority;

              return PopupMenuButton<Priority>(
                color: const Color.fromRGBO(248, 253, 255, 1),
                tooltip: 'Filter by Priority',
                offset: const Offset(0, 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey[300]!),
                ),
                onSelected: (Priority? selectedPriority) {
                  if (selectedPriority == null) {
                    controller.updateFilters(clearPriority: true);
                  } else {
                    controller.updateFilters(priority: selectedPriority);
                  }
                },
                itemBuilder: (BuildContext context) {
                  return [
                    PopupMenuItem<Priority>(
                      value: null,
                      child: Row(
                        children: [
                          Icon(Icons.clear_all, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 12),
                          const Text(
                            'Show All',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    ...Priority.values.map((Priority p) {
                      final isSelected = p == controller.priorityFilter.value;
                      final priorityColor = _getPriorityColor(p);
                      final priorityIcon = _getPriorityIcon(p);

                      return PopupMenuItem<Priority>(
                        value: p,
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
                                p.displayName,
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
                    }),
                  ];
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.white.withOpacity(0.3)
                        : Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isActive
                          ? Colors.white.withOpacity(0.6)
                          : Colors.white.withOpacity(0.3),
                      width: isActive ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, color: Colors.white, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        label,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_drop_down,
                        color: Colors.white,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              );
            });
          }

          // 🎯 NEW: Clickable Status Filter Chip
          Widget _buildClickableStatusFilter(
            IconData icon,
            String label,
            FeedbackStatus status,
          ) {
            return Obx(() {
              final isActive = controller.statusFilter.value == status;

              return PopupMenuButton<FeedbackStatus>(
                color: const Color.fromRGBO(248, 253, 255, 1),
                tooltip: 'Filter by Status',
                offset: const Offset(0, 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey[300]!),
                ),
                onSelected: (FeedbackStatus? selectedStatus) {
                  if (selectedStatus == null) {
                    controller.updateFilters(clearStatus: true);
                  } else {
                    controller.updateFilters(status: selectedStatus);
                  }
                },
                itemBuilder: (BuildContext context) {
                  return [
                    PopupMenuItem<FeedbackStatus>(
                      value: null,
                      child: Row(
                        children: [
                          Icon(Icons.clear_all, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 12),
                          const Text(
                            'Show All',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    ...FeedbackStatus.values.map((FeedbackStatus s) {
                      final isSelected = s == controller.statusFilter.value;
                      final statusColor = _getStatusColor(s);
                      final statusIcon = _getStatusIcon(s);

                      return PopupMenuItem<FeedbackStatus>(
                        value: s,
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
                                s.displayName,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight:
                                      isSelected ? FontWeight.w600 : FontWeight.w500,
                                  color: isSelected ? statusColor : Colors.grey[800],
                                ),
                              ),
                            ),
                            if (isSelected)
                              Icon(Icons.check, size: 18, color: statusColor),
                          ],
                        ),
                      );
                    }),
                  ];
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.white.withOpacity(0.3)
                        : Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isActive
                          ? Colors.white.withOpacity(0.6)
                          : Colors.white.withOpacity(0.3),
                      width: isActive ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, color: Colors.white, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        label,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_drop_down,
                        color: Colors.white,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              );
            });
          }

            Widget _buildPinnedStatChip(IconData icon, String label, Color color) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: Colors.white, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }

            // ==================== SEARCH BARS ====================
            Widget _buildMobileSearchBar() {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                color: const Color.fromRGBO(248, 253, 255, 1),
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: 'Search pinned feedback...',
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
                      borderSide: const BorderSide(color: Color(0xFF517399), width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  onChanged: (value) => controller.updateSearchQuery(value),
                ),
              );
            }

            Widget _buildTabletSearchBar() {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                color: const Color.fromRGBO(248, 253, 255, 1),
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: 'Search pinned feedback...',
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  onChanged: (value) => controller.updateSearchQuery(value),
                ),
              );
            }

            Widget _buildDesktopSearchBar() {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: const Color.fromRGBO(248, 253, 255, 1),
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: 'Search pinned feedback...',
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
              );
            }

          // ✅ OPTIMIZED VERSION with explicit reactivity
              Widget _buildPinnedFeedbackList({bool isMobile = false, bool isTablet = false}) {
                return Obx(() {
                  // 🔥 CRITICAL: Explicitly access reactive variables to register dependencies
                  // This ensures GetX rebuilds this widget when these values change
                  final isLoading = controller.isLoadingFeedback.value; // Explicit access
                  final allFeedbackCount = controller.allFeedback.length; // Trigger dependency
                  final pinnedCount = controller.pinnedFeedbackIds.length; // Trigger dependency
                  
                  
                  if (isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // Get pinned feedback using our reactive getter
                  final pinnedItems = pinnedFeedback; // Calls the reactive getter
                  
                  if (pinnedItems.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.push_pin_outlined, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No pinned feedback',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Pin important reports to view them here',
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
                    itemCount: pinnedItems.length,
                    itemBuilder: (context, index) {
                      final feedback = pinnedItems[index];
                      
                      // Log each item being displayed
                      
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

            // ==================== REUSE CARD BUILDERS FROM ORIGINAL PAGE ====================
            // Copy the exact same card builders from app_feedback.dart
            Widget _buildMobileFeedbackCard(FeedbackAndReport feedback) {
              // Exact copy from AdminFeedbackManagement._buildMobileFeedbackCard
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
                                    color: isPinned ? Colors.amber[800] : Colors.grey[600],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              _buildClickablePriorityBadge(feedback),
                              const Spacer(),
                              _buildClickableStatusBadge(feedback),
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
             
                     const SizedBox(height: 8),
                      Row(
                        children: [
                          if (feedback.status == FeedbackStatus.pending ||
                              feedback.status == FeedbackStatus.inProgress)
                            InkWell(
                              onTap: () => _markAsCompleted(feedback),
                              borderRadius: BorderRadius.circular(4),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green[50],
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.green[300]!),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check_box_outline_blank,
                                      size: 16,
                                      color: Colors.green[700],
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Mark Complete',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.green[700],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          if (feedback.status == FeedbackStatus.completed ||
                              feedback.status == FeedbackStatus.closed) ...[
                            const Spacer(),
                            ElevatedButton.icon(
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
                          ],
                        ],
                      ),
                          
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
                    // Header Row with Pin, Priority, Type, Category, Status
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
                              color: isPinned ? Colors.amber[800] : Colors.grey[600],
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
                        _buildClickableStatusBadge(feedback),
                      ],
                    ),
                    
                    // Pinned Indicator
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
                    
                    // Subject
                    Text(
                      feedback.subject,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Description
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
                    
                    // User Info and Time
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
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (feedback.status == FeedbackStatus.pending ||
                        feedback.status == FeedbackStatus.inProgress)
                      InkWell(
                        onTap: () => _markAsCompleted(feedback),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.green[300]!),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_box_outline_blank,
                                size: 18,
                                color: Colors.green[700],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Mark Complete',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (feedback.status == FeedbackStatus.completed) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green[300]!),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle, size: 18, color: Colors.green[700]),
                            const SizedBox(width: 8),
                            Text(
                              'Issue Resolved',
                              style: TextStyle(
                                color: Colors.green[700],
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    const Spacer(),
                    if (feedback.status == FeedbackStatus.completed ||
                        feedback.status == FeedbackStatus.closed)
                      ElevatedButton.icon(
                        onPressed: () => _archiveFeedback(feedback),
                        icon: const Icon(Icons.archive, size: 16, color: Colors.white),
                        label: const Text(
                          'Archive',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 2,
                        ),
                      ),
                  ],
                ),
                  ],
                ),
              ),
            ),
          );
        });
      }
    // ==================== DESKTOP FEEDBACK CARD ====================
    Widget _buildFeedbackCard(FeedbackAndReport feedback) {
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
                  // Header Row with Pin Button, Priority Badge, Type, Category, Status
                  Row(
                    children: [
                      // Pin Button
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
                            color: isPinned ? Colors.amber[800] : Colors.grey[600],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      
                      // Priority Badge
                      _buildClickablePriorityBadge(feedback),
                      const SizedBox(width: 8),
                      _buildTypeBadge(feedback.feedbackType),
                      const SizedBox(width: 8),
                      _buildCategoryBadge(feedback.category),
                      const Spacer(),
                      
                      // Status Badge
                      _buildClickableStatusBadge(feedback),
                    ],
                  ),
                  
                  // Pinned Indicator
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
                  
                  // User Info and Time
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
                  
                  // Status-based
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (feedback.status == FeedbackStatus.pending ||
                        feedback.status == FeedbackStatus.inProgress)
                      InkWell(
                        onTap: () => _markAsCompleted(feedback),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green[300]!, width: 1.5),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_box_outline_blank,
                                size: 20,
                                color: Colors.green[700],
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Mark as Complete',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (feedback.status == FeedbackStatus.completed) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green[300]!),
                        ),
                        child: Row(
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
                      const SizedBox(width: 16),
                    ],
                    const Spacer(),
                    if (feedback.status == FeedbackStatus.completed ||
                        feedback.status == FeedbackStatus.closed)
                      ElevatedButton.icon(
                        onPressed: () => _archiveFeedback(feedback),
                        icon: const Icon(Icons.archive, size: 18, color: Colors.white),
                        label: const Text(
                          'Archive',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 2,
                        ),
                      ),
                  ],
                ),
                ],
              ),
            ),
          ),
        );
      });
    }

            // Copy helper methods from original file
            Widget _buildClickablePriorityBadge(FeedbackAndReport feedback) {
              Color color = _getPriorityColor(feedback.priority);
              IconData icon = _getPriorityIcon(feedback.priority);

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
                      feedback.priority.displayName,
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

            Widget _buildClickableStatusBadge(FeedbackAndReport feedback) {
              Color color = _getStatusColor(feedback.status);

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Text(
                  feedback.status.displayName,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color,
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

          void _showFeedbackDetails(FeedbackAndReport feedback) {
            showDialog(
              context: context,
              builder: (context) => Dialog(
                backgroundColor: Colors.transparent,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  height: MediaQuery.of(context).size.height * 0.85,
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(248, 253, 255, 1),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // 🎨 Creative Header with Gradient
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.amber[700]!, Colors.amber[500]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(24),
                          ),
                        ),
                        padding: const EdgeInsets.all(20),
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
                                  child: const Icon(
                                    Icons.push_pin,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Pinned Feedback Details',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'ID: ${feedback.documentId?.substring(0, 8)}...',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.9),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => Navigator.pop(context),
                                  icon: const Icon(Icons.close, color: Colors.white),
                                  tooltip: 'Close',
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Status badges
                            Wrap(
                              spacing: 8,
                              children: [
                                _buildStatusChip(feedback.status),
                                _buildPriorityChip(feedback.priority),
                                _buildTypeChip(feedback.feedbackType),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // 📄 Content Area
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Subject
                              _buildDetailCard(
                                icon: Icons.subject,
                                title: 'Subject',
                                content: feedback.subject,
                                color: Colors.blue,
                              ),
                              const SizedBox(height: 12),

                              // Description
                              _buildDetailCard(
                                icon: Icons.description,
                                title: 'Description',
                                content: feedback.description,
                                color: Colors.green,
                              ),
                              const SizedBox(height: 12),

                              // User Info
                              _buildDetailCard(
                                icon: Icons.person,
                                title: 'Submitted by',
                                content: '${feedback.userName}\n${feedback.userEmail}',
                                color: Colors.purple,
                              ),
                              const SizedBox(height: 12),

                              // Technical Info
                              _buildDetailCard(
                                icon: Icons.info_outline,
                                title: 'Technical Information',
                                content:
                                    'App Version: ${feedback.appVersion}\nDevice: ${feedback.deviceInfo}\nPlatform: ${feedback.platform}',
                                color: Colors.orange,
                              ),
                              const SizedBox(height: 12),

                              // Timestamps
                              _buildDetailCard(
                                icon: Icons.access_time,
                                title: 'Timeline',
                                content:
                                    'Submitted: ${_formatFullDateTime(feedback.submittedAt)}\nPinned: ${feedback.pinnedAt != null ? _formatFullDateTime(feedback.pinnedAt!) : 'N/A'}\nPinned by: ${feedback.pinnedBy ?? 'N/A'}',
                                color: Colors.teal,
                              ),

                              // Attachments
                              if (feedback.attachments.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                _buildAttachmentsCard(feedback),
                              ],
                            ],
                          ),
                        ),
                      ),

                      // 🎯 Action Buttons
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, -5),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Unpin Button
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  controller.togglePin(feedback.documentId!);
                                  Navigator.pop(context);
                                },
                                icon: const Icon(Icons.push_pin_outlined, size: 18),
                                label: const Text('Unpin'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey[600],
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Archive Button (Creative Style)
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _showArchiveConfirmation(context, feedback),
                                icon: const Icon(Icons.archive, size: 18),
                                label: const Text('Archive'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange[600],
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 4,
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

          // 🎨 Helper method for status chip
          Widget _buildStatusChip(FeedbackStatus status) {
            final color = _getStatusColor(status);
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_getStatusIcon(status), color: Colors.white, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    status.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }

          Widget _buildPriorityChip(Priority priority) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_getPriorityIcon(priority), color: Colors.white, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    priority.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }

          Widget _buildTypeChip(FeedbackType type) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Text(
                type.displayName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
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

          Widget _buildDetailCard({
            required IconData icon,
            required String title,
            required String content,
            required Color color,
          }) {
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(icon, color: color, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    content,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            );
          }

          Widget _buildAttachmentsCard(FeedbackAndReport feedback) {
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.attach_file, color: Colors.blue[700], size: 18),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Attachments (${feedback.attachments.length})',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: feedback.attachments.map((attachmentId) {
                      final url = controller.getAttachmentUrl(attachmentId);
                      final isVideo = _isVideoAttachment(attachmentId, url);
                      
                      return GestureDetector(
                        onTap: () => _showAttachmentDialog(context, url, isVideo),
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue[300]!),
                          ),
                          child: AttachmentViewerWidget(
                            attachmentUrl: url,
                            fileId: attachmentId,
                            isVideo: isVideo,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          }

          String _formatFullDateTime(DateTime dateTime) {
            return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
          }

          bool _isVideoAttachment(String fileId, String url) {
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
                  constraints: const BoxConstraints(
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
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
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

          // 🎯 CREATIVE ARCHIVE CONFIRMATION DIALOG
          void _showArchiveConfirmation(BuildContext context, FeedbackAndReport feedback) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => Dialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                backgroundColor: Colors.transparent,
                child: Container(
                  width: 400,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.orange[50]!,
                        Colors.orange[100]!,
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
                      // 🎨 Creative Header
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.orange[600]!, Colors.orange[400]!],
                          ),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.archive,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Archive This Feedback?',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),

                      // 📝 Content
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.orange[200]!),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          feedback.subject,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey[800],
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Submitted by: ${feedback.userName}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.orange[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.orange[300]!),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.warning_amber_rounded,
                                      color: Colors.orange[800], size: 24),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'This action will remove the feedback from active view. It can be permanently deleted later.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.orange[900],
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 🎯 Action Buttons
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () => Navigator.pop(context),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'Cancel',
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  Navigator.pop(context); // Close confirmation
                                  Navigator.pop(context); // Close details
                                  
                                  // Archive the feedback
                                  await controller.archiveFeedback(feedback.documentId!);
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
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 4,
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

          // 🆕 ADD THESE COMPLETE METHODS

        bool _isMobile(BuildContext context) =>
            MediaQuery.of(context).size.width < 600;

        Widget _buildDrawer(BuildContext context) {
          final isMobile = _isMobile(context);

          return Drawer(
            backgroundColor: const Color.fromRGBO(248, 253, 255, 1),
            child: Column(
              children: [
                // 🎨 Creative Gradient Header
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(
                    isMobile ? 16 : 24,
                    isMobile ? 48 : 60,
                    isMobile ? 16 : 24,
                    isMobile ? 16 : 24,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.amber[700]!,
                        Colors.amber[500]!,
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Animated Icon Container
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 600),
                        tween: Tween(begin: 0.0, end: 1.0),
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: Container(
                              padding: EdgeInsets.all(isMobile ? 10 : 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.push_pin,
                                color: Colors.white,
                                size: isMobile ? 28 : 32,
                              ),
                            ),
                          );
                        },
                      ),
                      SizedBox(height: isMobile ? 12 : 16),
                      Text(
                        'Developer',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isMobile ? 20 : 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Pinned Reports Panel',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: isMobile ? 12 : 14,
                        ),
                      ),
                    ],
                  ),
                ),

                // 📋 Menu Items
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.symmetric(vertical: isMobile ? 4 : 8),
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
                        icon: Icons.feedback_rounded,
                        title: 'System Reports',
                        subtitle: 'All feedback & reports',
                        gradient: LinearGradient(
                          colors: [
                            Colors.blue[100]!,
                            Colors.blue[50]!,
                          ],
                        ),
                        iconGradient: LinearGradient(
                          colors: [
                            Colors.blue[200]!,
                            Colors.blue[100]!,
                          ],
                        ),
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
                      _buildDrawerItem(
                        context,
                        icon: Icons.delete_forever_rounded,
                        title: 'Deletion Reports',
                        subtitle: 'Review deletion requests',
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
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 12 : 16,
                          vertical: isMobile ? 4 : 8,
                        ),
                        child: const Divider(),
                      ),
                    ],
                  ),
                ),

                // 🚪 Creative Logout Button
                Container(
                  padding: EdgeInsets.all(isMobile ? 12 : 16),
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
                            padding: EdgeInsets.symmetric(
                              vertical: isMobile ? 14 : 16,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.red[400]!.withOpacity(0.7),
                                  Colors.red[300]!.withOpacity(0.5),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: isMobile ? 18 : 20,
                                  height: isMobile ? 18 : 20,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Logging Out...',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: isMobile ? 14 : 16,
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
                              padding: EdgeInsets.symmetric(
                                vertical: isMobile ? 14 : 16,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.red[600]!,
                                    Colors.red[400]!,
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
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.logout_rounded,
                                    color: Colors.white,
                                size: isMobile ? 18 : 20,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Log Out',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isMobile ? 14 : 16,
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
      Gradient? gradient,
      Gradient? iconGradient,
    }) {
      final isMobile = _isMobile(context);

      return Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 6 : 8,
          vertical: isMobile ? 2 : 4,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            decoration: BoxDecoration(
              gradient: gradient,
              color: gradient == null ? Colors.white : null,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: gradient == null
                    ? const Color.fromRGBO(81, 115, 153, 0.2)
                    : Colors.transparent,
              ),
              boxShadow: gradient != null
                  ? [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isMobile ? 8 : 10),
                  decoration: BoxDecoration(
                    gradient: iconGradient ??
                        const LinearGradient(
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
                    size: isMobile ? 20 : 24,
                  ),
                ),
                SizedBox(width: isMobile ? 12 : 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: isMobile ? 13 : 15,
                          fontWeight: FontWeight.w600,
                          color: const Color.fromRGBO(81, 115, 153, 1),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: isMobile ? 11 : 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: isMobile ? 14 : 16,
                  color: const Color.fromRGBO(81, 115, 153, 0.5),
                ),
              ],
            ),
          ),
        ),
      );
    }

  

void _markAsCompleted(FeedbackAndReport feedback) {
  final TextEditingController resolutionController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color.fromRGBO(248, 253, 255, 1),
      title: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green[700], size: 24),
          const SizedBox(width: 12),
          const Text(
            'Mark as Completed',
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
            'Confirm that this issue has been resolved:',
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
          TextField(
            controller: resolutionController,
            decoration: InputDecoration(
              labelText: 'Resolution Notes (Optional)',
              hintText: 'Describe how the issue was fixed...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF517399), width: 2),
              ),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.green[700], size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Once marked as completed, this feedback can be archived.',
                    style: TextStyle(
                      color: Colors.green[900],
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
          onPressed: () {
            resolutionController.dispose();
            Navigator.pop(context);
          },
          child: Text(
            'Cancel',
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        ElevatedButton.icon(
          onPressed: () async {
            await controller.updateStatus(
              feedback.documentId!,
              FeedbackStatus.completed,
            );

            if (resolutionController.text.trim().isNotEmpty) {
              await controller.addReply(
                feedback.documentId!,
                'Resolution: ${resolutionController.text.trim()}',
              );
            }

            resolutionController.dispose();
            Navigator.pop(context);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 12),
                    const Text('Feedback marked as completed!'),
                  ],
                ),
                backgroundColor: Colors.green[600],
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 3),
              ),
            );
          },
          icon: const Icon(Icons.check_circle, size: 18),
          label: const Text('Mark as Completed'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[600],
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

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.orange[200]!, width: 2),
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
                              child: Text(
                                feedback.subject,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey[800],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
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
                          child: Text(
                            'This feedback will be moved to archive.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange[800],
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

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
                        Navigator.pop(context);
                        await controller.archiveFeedback(feedback.documentId!);
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
    


}