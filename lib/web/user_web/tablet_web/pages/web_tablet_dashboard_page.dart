import 'package:capstone_app/web/user_web/desktop_web/components/dashboard_components/web_dashboard_grid_tile.dart';
import 'package:capstone_app/web/user_web/desktop_web/components/dashboard_components/web_search_bar.dart';
import 'package:capstone_app/web/user_web/desktop_web/pages/web_maps.dart';
import 'package:capstone_app/web/pages/web_user_home/web_user_home_controller.dart';
import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:capstone_app/data/models/clinic_settings_model.dart';
import 'package:capstone_app/data/models/ratings_and_review_model.dart'; // ADD THIS
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'package:appwrite/appwrite.dart';

class WebTabletDashboardPageUpdated extends StatefulWidget {
  const WebTabletDashboardPageUpdated({super.key});

  @override
  State<WebTabletDashboardPageUpdated> createState() =>
      _WebTabletDashboardPageUpdatedState();
}

class _WebTabletDashboardPageUpdatedState
    extends State<WebTabletDashboardPageUpdated> {
  List<Clinic> allClinics = [];
  List<Clinic> filteredClinics = [];
  Map<String, ClinicSettings?> clinicSettingsMap = {};
  Map<String, ClinicRatingStats> _ratingStatsCache = {}; // ADD THIS
  bool isLoading = true;
  String? error;
  String searchQuery = '';
  String selectedFilter = 'All';

  // Real-time subscriptions
  StreamSubscription? _clinicSubscription;
  StreamSubscription? _settingsSubscription;

  final ScrollController _scrollController = ScrollController();
  bool _showLeft = false;
  bool _showRight = true;
  bool _isHoveredLeft = false;
  bool _isHoveredRight = false;

  final List<String> tags = [
    'All',
    'Open',
    'Closed',
    'Popular', // Keep this one
  ];

  @override
  void initState() {
    super.initState();
    _fetchClinicsData();
    _setupRealtimeListeners();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _clinicSubscription?.cancel();
    _settingsSubscription?.cancel();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    final max = _scrollController.position.maxScrollExtent;
    final offset = _scrollController.offset;

    setState(() {
      _showLeft = offset > 0;
      _showRight = offset < max;
    });
  }

  void _scrollLeft() {
    _scrollController.animateTo(
      _scrollController.offset - 250,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _scrollRight() {
    _scrollController.animateTo(
      _scrollController.offset + 250,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _setupRealtimeListeners() {

    final authRepository = Get.find<AuthRepository>();

    _clinicSubscription = authRepository
        .subscribeToClinicChanges()
        .listen((RealtimeMessage event) {

      final eventType = event.events.first;

      if (eventType.contains('.create')) {
        _showRealTimeNotification(
          'New clinic added to the network',
          Icons.add_business_rounded,
          Colors.green,
        );
        _fetchClinicsData();
      } else if (eventType.contains('.update')) {
        final clinicName = event.payload['clinicName'] as String?;
        _showRealTimeNotification(
          'Clinic "${clinicName ?? 'Unknown'}" information updated',
          Icons.sync_rounded,
          Colors.blue,
        );
        _fetchClinicsData();
      } else if (eventType.contains('.delete')) {
        _showRealTimeNotification(
          'A clinic has been removed',
          Icons.delete_rounded,
          Colors.red,
        );
        _fetchClinicsData();
      }
    }, onError: (error) {
    });

    _settingsSubscription = authRepository
        .subscribeToClinicSettingsChanges()
        .listen((RealtimeMessage event) {

      final eventType = event.events.first;

      if (eventType.contains('.update') || eventType.contains('.create')) {
        _fetchClinicsData();
      }
    }, onError: (error) {
    });

  }

  void _showRealTimeNotification(String message, IconData icon, Color color) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Real-Time Update',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      message,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.wifi_tethering_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
        elevation: 8,
      ),
    );
  }

  Future<void> _fetchClinicsData() async {
    try {
      if (allClinics.isEmpty) {
        setState(() {
          isLoading = true;
          error = null;
        });
      }

      final authRepository = Get.find<AuthRepository>();
      final clinicsWithSettings = await authRepository.getClinicsWithSettings();

      final clinics = <Clinic>[];
      final settingsMap = <String, ClinicSettings?>{};
      final statsCache = <String, ClinicRatingStats>{}; // ADD THIS


      for (final data in clinicsWithSettings) {
        final clinic = data['clinic'] as Clinic;
        final settings = data['settings'] as ClinicSettings?;

        final clinicDocId = clinic.documentId ?? '';


        clinics.add(clinic);
        settingsMap[clinicDocId] = settings;

        // Load rating stats for each clinic
        try {
          final stats = await authRepository.getClinicRatingStats(clinicDocId);
          statsCache[clinicDocId] = stats;

        } catch (e) {
          // Create empty stats for clinics without ratings
          statsCache[clinicDocId] = ClinicRatingStats(
            averageRating: 0.0,
            totalReviews: 0,
            ratingDistribution: {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
            reviewsWithText: 0,
            reviewsWithImages: 0,
          );
        }

      }

      if (mounted) {
        setState(() {
          allClinics = clinics;
          clinicSettingsMap = settingsMap;
          _ratingStatsCache = statsCache; // ADD THIS
          filteredClinics = _applyFilters(clinics);
          isLoading = false;
        });

      }
    } catch (e, stackTrace) {

      if (mounted) {
        setState(() {
          error = "Failed to load clinics data";
          isLoading = false;
        });
      }
    }
  }

  List<Clinic> _applyFilters(List<Clinic> clinics) {
    var filtered = clinics;

    // Apply search query filter
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((clinic) {
        final settings = clinicSettingsMap[clinic.documentId ?? ''];
        final services = settings?.services.join(' ') ?? clinic.services;

        return clinic.clinicName
                .toLowerCase()
                .contains(searchQuery.toLowerCase()) ||
            clinic.address.toLowerCase().contains(searchQuery.toLowerCase()) ||
            services.toLowerCase().contains(searchQuery.toLowerCase());
      }).toList();
    }

    // Apply tag filter
    switch (selectedFilter) {
      case 'Open':
        filtered = filtered.where((clinic) {
          final settings = clinicSettingsMap[clinic.documentId ?? ''];
          if (settings == null) return true;

          // Check if today is a closed date
          final today = DateTime.now();
          final todayStr =
              '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
          final isTodayClosedDate = settings.closedDates.contains(todayStr);

          // Clinic is open if: isOpen flag is true, open now, and NOT a closed date
          return settings.isOpen && settings.isOpenNow() && !isTodayClosedDate;
        }).toList();
        break;

      case 'Closed':
        filtered = filtered.where((clinic) {
          final settings = clinicSettingsMap[clinic.documentId ?? ''];
          if (settings == null) return false;

          // Check if today is a closed date
          final today = DateTime.now();
          final todayStr =
              '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
          final isTodayClosedDate = settings.closedDates.contains(todayStr);

          // Clinic is closed if: NOT open, NOT open now, OR is a closed date
          return !settings.isOpen || !settings.isOpenNow() || isTodayClosedDate;
        }).toList();
        break;

      case 'Popular':
        // Sort by review count (descending) and rating (descending)
        filtered.sort((a, b) {
          final aStats = _ratingStatsCache[a.documentId ?? ''];
          final bStats = _ratingStatsCache[b.documentId ?? ''];

          final aReviews = aStats?.totalReviews ?? 0;
          final bReviews = bStats?.totalReviews ?? 0;

          // First sort by review count
          if (aReviews != bReviews) {
            return bReviews.compareTo(aReviews);
          }

          // If same review count, sort by rating
          final aRating = aStats?.averageRating ?? 0.0;
          final bRating = bStats?.averageRating ?? 0.0;
          return bRating.compareTo(aRating);
        });

        // Only show clinics with at least 1 review for "Popular"
        filtered = filtered.where((clinic) {
          final stats = _ratingStatsCache[clinic.documentId ?? ''];
          return (stats?.totalReviews ?? 0) > 0;
        }).toList();
        break;

      case 'All':
      default:
        // Keep all clinics, but sort open ones first
        filtered.sort((a, b) {
          final aSettings = clinicSettingsMap[a.documentId ?? ''];
          final bSettings = clinicSettingsMap[b.documentId ?? ''];

          final aIsOpen = aSettings?.isOpen ?? true;
          final bIsOpen = bSettings?.isOpen ?? true;

          if (aIsOpen && !bIsOpen) return -1;
          if (!aIsOpen && bIsOpen) return 1;

          return a.clinicName.compareTo(b.clinicName);
        });
        break;
    }

    return filtered;
  }

  void _filterClinics(String query) {
    setState(() {
      searchQuery = query;
      filteredClinics = _applyFilters(allClinics);
    });
  }

  void _setFilter(String filter) {
    setState(() {
      selectedFilter = filter;
      filteredClinics = _applyFilters(allClinics);
    });
  }

  double _getTextWidth(String text) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();
    return textPainter.width;
  }

  int _getFilterCount(String filter) {
    switch (filter) {
      case 'All':
        return allClinics.length;

      case 'Open':
        return allClinics.where((clinic) {
          final settings = clinicSettingsMap[clinic.documentId ?? ''];
          if (settings == null) return true;

          final today = DateTime.now();
          final todayStr =
              '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
          final isTodayClosedDate = settings.closedDates.contains(todayStr);

          return settings.isOpen && settings.isOpenNow() && !isTodayClosedDate;
        }).length;

      case 'Closed':
        return allClinics.where((clinic) {
          final settings = clinicSettingsMap[clinic.documentId ?? ''];
          if (settings == null) return false;

          final today = DateTime.now();
          final todayStr =
              '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
          final isTodayClosedDate = settings.closedDates.contains(todayStr);

          return !settings.isOpen || !settings.isOpenNow() || isTodayClosedDate;
        }).length;

      case 'Popular':
        return allClinics.where((clinic) {
          final stats = _ratingStatsCache[clinic.documentId ?? ''];
          return (stats?.totalReviews ?? 0) > 0;
        }).length;

      default:
        return 0;
    }
  }

  Widget _buildFilterTags() {
    return Expanded(
      child: SizedBox(
        height: 50,
        child: Stack(
          children: [
            Positioned.fill(
              child: ListView.builder(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                itemCount: tags.length,
                itemBuilder: (context, index) {
                  final tag = tags[index];
                  final isSelected = selectedFilter == tag;
                  final count = _getFilterCount(tag);

                  return GestureDetector(
                    onTap: () => _setFilter(tag),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Column(
                        children: [
                          Text(
                            count > 0 && tag != 'All'
                                ? '$tag ($count)'
                                : tag,
                            style: TextStyle(
                              fontSize: 16,
                              color: isSelected ? Colors.black : Colors.grey,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          if (isSelected)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              height: 2,
                              width: _getTextWidth(
                                count > 0 && tag != 'All'
                                    ? '$tag ($count)'
                                    : tag,
                              ),
                              color: Colors.black,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_showLeft)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.white, Colors.white.withOpacity(0)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                  child: MouseRegion(
                    onEnter: (_) {
                      if (!_isHoveredLeft) {
                        setState(() {
                          _isHoveredLeft = true;
                        });
                      }
                    },
                    onExit: (_) {
                      if (_isHoveredLeft) {
                        setState(() {
                          _isHoveredLeft = false;
                        });
                      }
                    },
                    child: AnimatedContainer(
                      height: 35,
                      width: 35,
                      duration: const Duration(milliseconds: 0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color.fromARGB(255, 121, 116, 126),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _isHoveredLeft
                                ? Colors.grey.shade300
                                : Colors.transparent,
                            blurRadius: _isHoveredLeft ? 1 : 0,
                            spreadRadius: _isHoveredLeft ? 1 : 0,
                            offset: _isHoveredLeft
                                ? const Offset(0, 2)
                                : Offset.zero,
                          )
                        ],
                      ),
                      child: IconButton(
                        hoverColor: Colors.transparent,
                        onPressed: _scrollLeft,
                        icon: const Icon(
                          Icons.arrow_back_ios_rounded,
                          size: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (_showRight)
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerRight,
                      end: Alignment.centerLeft,
                      colors: [Colors.white, Colors.white.withOpacity(0)],
                    ),
                  ),
                  child: MouseRegion(
                    onEnter: (_) {
                      if (!_isHoveredRight) {
                        setState(() {
                          _isHoveredRight = true;
                        });
                      }
                    },
                    onExit: (_) {
                      if (_isHoveredRight) {
                        setState(() {
                          _isHoveredRight = false;
                        });
                      }
                    },
                    child: AnimatedContainer(
                      height: 35,
                      width: 35,
                      duration: const Duration(microseconds: 0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color.fromARGB(255, 121, 116, 126),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _isHoveredRight
                                ? Colors.grey.shade300
                                : Colors.transparent,
                            blurRadius: _isHoveredRight ? 1 : 0,
                            spreadRadius: _isHoveredRight ? 1 : 0,
                            offset: _isHoveredRight
                                ? const Offset(0, 2)
                                : Offset.zero,
                          )
                        ],
                      ),
                      child: IconButton(
                        hoverColor: Colors.transparent,
                        onPressed: _scrollRight,
                        icon: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapView() {
    return SizedBox(
      height: 770,
      child: WebMaps(
        selectedFilter: selectedFilter,
        searchQuery: searchQuery,
        onFilterChanged: _setFilter,
        ratingStatsCache: _ratingStatsCache, // ADD THIS - Pass rating stats to map
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.only(top: 200),
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text("Loading clinics..."),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 200),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              error ?? "Failed to load clinics",
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchClinicsData,
              child: const Text("Retry"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 200),
        child: Column(
          children: [
            Icon(
              Icons.local_hospital_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              searchQuery.isEmpty
                  ? "No clinics match the selected filter"
                  : "No clinics found for '$searchQuery'",
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            if (searchQuery.isNotEmpty || selectedFilter != 'All') ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  setState(() {
                    searchQuery = '';
                    selectedFilter = 'All';
                    filteredClinics = _applyFilters(allClinics);
                  });
                },
                child: const Text("Clear filters"),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildClinicList() {
    if (isLoading) {
      return _buildLoadingState();
    }

    if (error != null) {
      return _buildErrorState();
    }

    if (filteredClinics.isEmpty) {
      return _buildEmptyState();
    }

    return WebDashboardGridTile(clinics: filteredClinics);
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<WebUserHomeController>();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: RefreshIndicator(
        onRefresh: _fetchClinicsData,
        child: ListView(
          padding: const EdgeInsets.only(left: 65, right: 65, top: 16),
          children: [
            Row(
              children: [
                _buildFilterTags(),
                const SizedBox(width: 12),
                WebSearchBar(
                  onSearchChanged: _filterClinics,
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Obx(() => controller.showMapView.value 
                  ? _buildMapView() 
                  : _buildClinicList()),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: SizedBox(
          height: 50,
          width: 120,
          child: Obx(() => FloatingActionButton.extended(
            backgroundColor: Colors.white,
            label: controller.showMapView.value
                ? const Text("Show List", style: TextStyle(color: Colors.black))
                : const Text("Show Maps",
                    style: TextStyle(color: Colors.black)),
            icon: controller.showMapView.value
                ? const Icon(Icons.list_rounded, color: Colors.black)
                : const Icon(Icons.map_rounded, color: Colors.black),
            onPressed: () {
              controller.toggleMapView();
            },
          )),
        ),
      ),
    );
  }
}