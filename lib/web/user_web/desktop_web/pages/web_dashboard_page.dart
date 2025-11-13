import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:capstone_app/data/models/clinic_settings_model.dart';
import 'package:capstone_app/data/models/ratings_and_review_model.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/web/user_web/desktop_web/components/dashboard_components/web_dashboard_grid_tile.dart';
import 'package:capstone_app/web/user_web/desktop_web/components/dashboard_components/web_search_bar.dart';
import 'package:capstone_app/web/user_web/desktop_web/pages/web_maps.dart';
import 'package:capstone_app/web/pages/web_user_home/web_user_home_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'package:appwrite/appwrite.dart';

class WebDashboardPage extends StatefulWidget {
  const WebDashboardPage({super.key});

  @override
  State<WebDashboardPage> createState() => _WebDashboardPageState();
}

class _WebDashboardPageState extends State<WebDashboardPage> {
  List<Clinic> allClinics = [];
  List<Clinic> filteredClinics = [];
  Map<String, ClinicSettings?> clinicSettingsMap = {};
  bool isLoading = true;
  String? error;
  String searchQuery = '';
  String selectedFilter = 'All';

  // Real-time subscriptions
  StreamSubscription? _clinicSubscription;
  StreamSubscription? _settingsSubscription;

  Map<String, ClinicRatingStats> _ratingStatsCache = {};

  // ✨ NEW: Cache management
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheValidity = Duration(minutes: 5);

  @override
  void initState() {
    super.initState();
    _fetchClinicsData();
    _setupRealtimeListeners();
  }

  @override
  void dispose() {
    _clinicSubscription?.cancel();
    _settingsSubscription?.cancel();
    super.dispose();
  }

  bool _isCacheValid(String key) {
    final timestamp = _cacheTimestamps[key];
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < _cacheValidity;
  }

  void _setupRealtimeListeners() {
    final authRepository = Get.find<AuthRepository>();

    _clinicSubscription = authRepository.subscribeToClinicChanges().listen(
        (RealtimeMessage event) {
      final eventType = event.events.first;

      if (eventType.contains('.create')) {
        _showRealTimeNotification(
          'New clinic added to the network',
          Icons.add_business_rounded,
          Colors.green,
        );
        _fetchClinicsData(forceRefresh: true);
      } else if (eventType.contains('.update')) {
        final clinicName = event.payload['clinicName'] as String?;
        _showRealTimeNotification(
          'Clinic "${clinicName ?? 'Unknown'}" information updated',
          Icons.sync_rounded,
          Colors.blue,
        );
        _fetchClinicsData(forceRefresh: true);
      } else if (eventType.contains('.delete')) {
        _showRealTimeNotification(
          'A clinic has been removed',
          Icons.delete_rounded,
          Colors.red,
        );
        _fetchClinicsData(forceRefresh: true);
      }
    }, onError: (error) {
    });

    _settingsSubscription = authRepository
        .subscribeToClinicSettingsChanges()
        .listen((RealtimeMessage event) {
      final eventType = event.events.first;

      if (eventType.contains('.update') || eventType.contains('.create')) {
        _fetchClinicsData(forceRefresh: true);
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
                child: Icon(icon, color: color, size: 22),
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

  // ✨ OPTIMIZED: Parallel data loading with caching
  Future<void> _fetchClinicsData({bool forceRefresh = false}) async {
    try {
      // Check cache validity
      if (!forceRefresh &&
          _isCacheValid('dashboard') &&
          allClinics.isNotEmpty) {
        return;
      }

      if (allClinics.isEmpty) {
        setState(() {
          isLoading = true;
          error = null;
        });
      }

      final authRepository = Get.find<AuthRepository>();

      // Fetch clinics with settings (already optimized in your repo)
      final clinicsWithSettings = await authRepository.getClinicsWithSettings();

      final clinics = <Clinic>[];
      final settingsMap = <String, ClinicSettings?>{};
      final statsCache = <String, ClinicRatingStats>{};

      // Collect clinic IDs
      final clinicIds = <String>[];
      for (final data in clinicsWithSettings) {
        final clinic = data['clinic'] as Clinic;
        final settings = data['settings'] as ClinicSettings?;
        final clinicDocId = clinic.documentId ?? '';

        if (clinicDocId.isNotEmpty) {
          clinics.add(clinic);
          settingsMap[clinicDocId] = settings;
          clinicIds.add(clinicDocId);
        }
      }

      // ✨ OPTIMIZATION: Batch load rating stats in parallel
      await _batchLoadRatingStats(clinicIds, statsCache);

      if (mounted) {
        setState(() {
          allClinics = clinics;
          clinicSettingsMap = settingsMap;
          _ratingStatsCache = statsCache;
          filteredClinics = _applyFilters(clinics);
          isLoading = false;
          _cacheTimestamps['dashboard'] = DateTime.now();
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

  // ✨ NEW: Batch load rating stats with parallel execution
  Future<void> _batchLoadRatingStats(
    List<String> clinicIds,
    Map<String, ClinicRatingStats> statsCache,
  ) async {
    final authRepository = Get.find<AuthRepository>();

    // Create futures for all requests
    final futures = clinicIds.map((clinicId) async {
      try {
        final stats = await authRepository.getClinicRatingStats(clinicId);
        return MapEntry(clinicId, stats);
      } catch (e) {
        // Return empty stats on error
        return MapEntry(
          clinicId,
          ClinicRatingStats(
            averageRating: 0.0,
            totalReviews: 0,
            ratingDistribution: {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
            reviewsWithText: 0,
            reviewsWithImages: 0,
          ),
        );
      }
    });

    // Execute all requests in parallel
    final results = await Future.wait(futures);

    // Populate cache
    for (final entry in results) {
      statsCache[entry.key] = entry.value;
    }
  }

  List<Clinic> _applyFilters(List<Clinic> clinics) {
    var filtered = clinics;

    // Apply search query filter
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      filtered = filtered.where((clinic) {
        final settings = clinicSettingsMap[clinic.documentId ?? ''];
        final services = settings?.services.join(' ') ?? clinic.services;

        return clinic.clinicName.toLowerCase().contains(query) ||
            clinic.address.toLowerCase().contains(query) ||
            services.toLowerCase().contains(query);
      }).toList();
    }

    // Apply tag filter
    switch (selectedFilter) {
      case 'Open':
        filtered = _filterOpenClinics(filtered);
        break;

      case 'Closed':
        filtered = _filterClosedClinics(filtered);
        break;

      case 'Popular':
        filtered = _filterPopularClinics(filtered);
        break;

      case 'All':
      default:
        filtered = _sortAllClinics(filtered);
        break;
    }

    return filtered;
  }

  List<Clinic> _filterOpenClinics(List<Clinic> clinics) {
    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    return clinics.where((clinic) {
      final settings = clinicSettingsMap[clinic.documentId ?? ''];
      if (settings == null) return true;

      final isTodayClosedDate = settings.closedDates.contains(todayStr);
      return settings.isOpen && settings.isOpenNow() && !isTodayClosedDate;
    }).toList();
  }

  List<Clinic> _filterClosedClinics(List<Clinic> clinics) {
    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    return clinics.where((clinic) {
      final settings = clinicSettingsMap[clinic.documentId ?? ''];
      if (settings == null) return false;

      final isTodayClosedDate = settings.closedDates.contains(todayStr);
      return !settings.isOpen || !settings.isOpenNow() || isTodayClosedDate;
    }).toList();
  }

  List<Clinic> _filterPopularClinics(List<Clinic> clinics) {
    final popular = clinics.where((clinic) {
      final stats = _ratingStatsCache[clinic.documentId ?? ''];
      return (stats?.totalReviews ?? 0) > 0;
    }).toList();

    popular.sort((a, b) {
      final aStats = _ratingStatsCache[a.documentId ?? ''];
      final bStats = _ratingStatsCache[b.documentId ?? ''];

      final aReviews = aStats?.totalReviews ?? 0;
      final bReviews = bStats?.totalReviews ?? 0;

      if (aReviews != bReviews) {
        return bReviews.compareTo(aReviews);
      }

      final aRating = aStats?.averageRating ?? 0.0;
      final bRating = bStats?.averageRating ?? 0.0;
      return bRating.compareTo(aRating);
    });

    return popular;
  }

  List<Clinic> _sortAllClinics(List<Clinic> clinics) {
    clinics.sort((a, b) {
      final aSettings = clinicSettingsMap[a.documentId ?? ''];
      final bSettings = clinicSettingsMap[b.documentId ?? ''];

      final aIsOpen = aSettings?.isOpen ?? true;
      final bIsOpen = bSettings?.isOpen ?? true;

      if (aIsOpen && !bIsOpen) return -1;
      if (!aIsOpen && bIsOpen) return 1;

      return a.clinicName.compareTo(b.clinicName);
    });

    return clinics;
  }

  // ✨ OPTIMIZATION: Debounced search
  Timer? _searchDebounce;
  void _filterClinics(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        searchQuery = query;
        filteredClinics = _applyFilters(allClinics);
      });
    });
  }

  void _setFilter(String filter) {
    setState(() {
      selectedFilter = filter;
      filteredClinics = _applyFilters(allClinics);
    });
  }

  Widget _buildWebTagsStyleFilter() {
    final filters = [
      'All',
      'Open',
      'Closed',
      'Popular',
    ];

    return Expanded(
      child: SizedBox(
        height: 50,
        child: Stack(
          children: [
            Positioned.fill(
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: filters.length,
                itemBuilder: (context, index) {
                  final filter = filters[index];
                  final isSelected = selectedFilter == filter;
                  final count = _getFilterCount(filter);

                  return GestureDetector(
                    onTap: () => _setFilter(filter),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      child: Column(
                        children: [
                          Text(
                            count > 0 && filter != 'All'
                                ? '$filter ($count)'
                                : filter,
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
                              width: _getTextWidth(count > 0 && filter != 'All'
                                  ? '$filter ($count)'
                                  : filter),
                              color: Colors.black,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _getTextWidth(String text) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
          text: text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

  Widget _buildMapView() {
    return SizedBox(
      height: 770,
      child: WebMaps(
        selectedFilter: selectedFilter,
        searchQuery: searchQuery,
        onFilterChanged: _setFilter,
        ratingStatsCache: _ratingStatsCache, // CRITICAL: Pass the rating stats
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

    return WebDashboardGridTile(
      clinics: filteredClinics,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<WebUserHomeController>();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: RefreshIndicator(
        onRefresh: () => _fetchClinicsData(forceRefresh: true),
        child: ListView(
          padding: const EdgeInsets.only(left: 65, right: 65, top: 16),
          children: [
            Row(
              children: [
                _buildWebTagsStyleFilter(),
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
                    ? const Text("Show List",
                        style: TextStyle(color: Colors.black))
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
