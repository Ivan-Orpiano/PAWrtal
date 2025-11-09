import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:capstone_app/data/models/clinic_settings_model.dart';
import 'package:capstone_app/data/models/ratings_and_review_model.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:get/get.dart';

class LandingController extends GetxController {
  final AuthRepository _authRepository;

  LandingController(this._authRepository);

  final isLoading = true.obs;
  final searchQuery = ''.obs;
  final selectedFilter = 'All'.obs;

  final allClinics = <Clinic>[].obs;
  final filteredClinics = <Clinic>[].obs;
  final clinicSettingsMap = <String, ClinicSettings?>{}.obs;
  final ratingStatsCache = <String, ClinicRatingStats>{}.obs;

  @override
  void onInit() {
    super.onInit();
    fetchClinics();
  }

  Future<void> fetchClinics() async {
    try {
      isLoading.value = true;


      final clinicsWithSettings = await _authRepository.getClinicsWithSettings();

      final clinics = <Clinic>[];
      final settingsMap = <String, ClinicSettings?>{};
      final statsCache = <String, ClinicRatingStats>{};

      for (final data in clinicsWithSettings) {
        final clinic = data['clinic'] as Clinic;
        final settings = data['settings'] as ClinicSettings?;
        final clinicDocId = clinic.documentId ?? '';

        clinics.add(clinic);
        settingsMap[clinicDocId] = settings;

        // Load rating stats
        try {
          final stats = await _authRepository.getClinicRatingStats(clinicDocId);
          statsCache[clinicDocId] = stats;
        } catch (e) {
          statsCache[clinicDocId] = ClinicRatingStats(
            averageRating: 0.0,
            totalReviews: 0,
            ratingDistribution: {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
            reviewsWithText: 0,
            reviewsWithImages: 0,
          );
        }
      }

      allClinics.value = clinics;
      clinicSettingsMap.value = settingsMap;
      ratingStatsCache.value = statsCache;
      applyFilters();

    } catch (e) {
    } finally {
      isLoading.value = false;
    }
  }

  void updateSearchQuery(String query) {
    searchQuery.value = query;
    applyFilters();
  }

  void setFilter(String filter) {
    selectedFilter.value = filter;
    applyFilters();
  }

  void applyFilters() {
    var filtered = allClinics.toList();

    // Apply search filter
    if (searchQuery.value.isNotEmpty) {
      filtered = filtered.where((clinic) {
        final settings = clinicSettingsMap[clinic.documentId ?? ''];
        final services = settings?.services.join(' ') ?? clinic.services;

        return clinic.clinicName.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
            clinic.address.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
            services.toLowerCase().contains(searchQuery.value.toLowerCase());
      }).toList();
    }

    // Apply tag filter
    switch (selectedFilter.value) {
      case 'Open':
        filtered = filtered.where((clinic) {
          final settings = clinicSettingsMap[clinic.documentId ?? ''];
          if (settings == null) return true;

          final today = DateTime.now();
          final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
          final isTodayClosedDate = settings.closedDates.contains(todayStr);

          return settings.isOpen && settings.isOpenNow() && !isTodayClosedDate;
        }).toList();
        break;

      // case 'Available Today':
      //   filtered = filtered.where((clinic) {
      //     final settings = clinicSettingsMap[clinic.documentId ?? ''];
      //     if (settings == null) return true;

      //     final today = DateTime.now();
      //     final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      //     final isTodayClosedDate = settings.closedDates.contains(todayStr);

      //     return settings.isOpen && settings.isOpenToday() && !isTodayClosedDate;
      //   }).toList();
      //   break;

      case 'Closed':
        filtered = filtered.where((clinic) {
          final settings = clinicSettingsMap[clinic.documentId ?? ''];
          if (settings == null) return false;

          final today = DateTime.now();
          final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
          final isTodayClosedDate = settings.closedDates.contains(todayStr);

          return !settings.isOpen || !settings.isOpenNow() || isTodayClosedDate;
        }).toList();
        break;

      case 'Popular':
        filtered.sort((a, b) {
          final aStats = ratingStatsCache[a.documentId ?? ''];
          final bStats = ratingStatsCache[b.documentId ?? ''];

          final aReviews = aStats?.totalReviews ?? 0;
          final bReviews = bStats?.totalReviews ?? 0;

          if (aReviews != bReviews) {
            return bReviews.compareTo(aReviews);
          }

          final aRating = aStats?.averageRating ?? 0.0;
          final bRating = bStats?.averageRating ?? 0.0;
          return bRating.compareTo(aRating);
        });

        filtered = filtered.where((clinic) {
          final stats = ratingStatsCache[clinic.documentId ?? ''];
          return (stats?.totalReviews ?? 0) > 0;
        }).toList();
        break;

      case 'All':
      default:
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

    filteredClinics.value = filtered;
  }

  int getFilterCount(String filter) {
    switch (filter) {
      case 'All':
        return allClinics.length;

      case 'Open':
        return allClinics.where((clinic) {
          final settings = clinicSettingsMap[clinic.documentId ?? ''];
          if (settings == null) return true;

          final today = DateTime.now();
          final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
          final isTodayClosedDate = settings.closedDates.contains(todayStr);

          return settings.isOpen && settings.isOpenNow() && !isTodayClosedDate;
        }).length;

      // case 'Available Today':
      //   return allClinics.where((clinic) {
      //     final settings = clinicSettingsMap[clinic.documentId ?? ''];
      //     if (settings == null) return true;

      //     final today = DateTime.now();
      //     final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      //     final isTodayClosedDate = settings.closedDates.contains(todayStr);

      //     return settings.isOpen && settings.isOpenToday() && !isTodayClosedDate;
      //   }).length;

      case 'Closed':
        return allClinics.where((clinic) {
          final settings = clinicSettingsMap[clinic.documentId ?? ''];
          if (settings == null) return false;

          final today = DateTime.now();
          final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
          final isTodayClosedDate = settings.closedDates.contains(todayStr);

          return !settings.isOpen || !settings.isOpenNow() || isTodayClosedDate;
        }).length;

      case 'Popular':
        return allClinics.where((clinic) {
          final stats = ratingStatsCache[clinic.documentId ?? ''];
          return (stats?.totalReviews ?? 0) > 0;
        }).length;

      default:
        return 0;
    }
  }
}