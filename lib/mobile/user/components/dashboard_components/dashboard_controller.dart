import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:capstone_app/data/models/clinic_settings_model.dart';
import 'package:capstone_app/data/models/ratings_and_review_model.dart';
import 'package:capstone_app/data/provider/appwrite_provider.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/utils/appwrite_constant.dart';
import 'package:get/get.dart';

class DashboardController extends GetxController {
  final AppWriteProvider appwrite = AppWriteProvider();
  final AuthRepository authRepository = Get.find<AuthRepository>();

  var allClinics = <Clinic>[].obs;
  var filteredClinics = <Clinic>[].obs;
  var clinicSettingsMap = <String, ClinicSettings?>{}.obs;
  var ratingStatsCache = <String, ClinicRatingStats>{}.obs;
  var isLoading = true.obs;
  var searchQuery = ''.obs;
  var selectedFilter = 'All'.obs;

  @override
  void onInit() {
    super.onInit();
    fetchClinics();
  }

  Future<void> fetchClinics() async {
    try {
      isLoading.value = true;

      final result = await appwrite.databases!.listDocuments(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.clinicsCollectionID,
      );

      // Create clinic objects
      final clinics = result.documents.map((doc) {
        final clinic = Clinic.fromMap(doc.data);
        clinic.documentId = doc.$id;
        return clinic;
      }).toList();

      // Load clinic settings and rating stats for each clinic
      final settingsMap = <String, ClinicSettings?>{};
      final statsCache = <String, ClinicRatingStats>{};

      for (final clinic in clinics) {
        try {
          // Load settings
          final settings = await authRepository
              .getClinicSettingsByClinicId(clinic.documentId ?? '');
          settingsMap[clinic.documentId ?? ''] = settings;

          // Load rating stats
          try {
            final stats = await authRepository
                .getClinicRatingStats(clinic.documentId ?? '');
            statsCache[clinic.documentId ?? ''] = stats;
          } catch (e) {
            // Create empty stats if none found
            statsCache[clinic.documentId ?? ''] = ClinicRatingStats(
              averageRating: 0.0,
              totalReviews: 0,
              ratingDistribution: {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
              reviewsWithText: 0,
              reviewsWithImages: 0,
            );
          }
        } catch (e) {
          print("Error loading data for clinic ${clinic.clinicName}: $e");
          settingsMap[clinic.documentId ?? ''] = null;
        }
      }

      allClinics.assignAll(clinics);
      clinicSettingsMap.assignAll(settingsMap);
      ratingStatsCache.assignAll(statsCache);
      applyFilters();
    } catch (e) {
      print("Error fetching clinics: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void applyFilters() {
    var filtered = allClinics.toList();

    // Apply search filter
    if (searchQuery.value.isNotEmpty) {
      filtered = filtered.where((clinic) {
        final settings = clinicSettingsMap[clinic.documentId ?? ''];
        final services = settings?.services.join(' ') ?? clinic.services;

        return clinic.clinicName
                .toLowerCase()
                .contains(searchQuery.value.toLowerCase()) ||
            clinic.address
                .toLowerCase()
                .contains(searchQuery.value.toLowerCase()) ||
            services.toLowerCase().contains(searchQuery.value.toLowerCase());
      }).toList();
    }

    // Apply status filter with closed dates support
    switch (selectedFilter.value) {
      case 'Open':
        filtered = filtered.where((clinic) {
          final settings = clinicSettingsMap[clinic.documentId ?? ''];
          if (settings == null) return false;

          final today = DateTime.now();
          final todayStr =
              '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
          final isTodayClosedDate = settings.closedDates.contains(todayStr);

          return settings.isOpen && settings.isOpenNow() && !isTodayClosedDate;
        }).toList();
        break;

      case 'Available Today':
        filtered = filtered.where((clinic) {
          final settings = clinicSettingsMap[clinic.documentId ?? ''];
          if (settings == null) return false;

          final today = DateTime.now();
          final todayStr =
              '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
          final isTodayClosedDate = settings.closedDates.contains(todayStr);

          return settings.isOpen &&
              settings.isOpenToday() &&
              !isTodayClosedDate;
        }).toList();
        break;

      case 'Closed':
        filtered = filtered.where((clinic) {
          final settings = clinicSettingsMap[clinic.documentId ?? ''];
          if (settings == null) return false;

          final today = DateTime.now();
          final todayStr =
              '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
          final isTodayClosedDate = settings.closedDates.contains(todayStr);

          return !settings.isOpen || !settings.isOpenNow() || isTodayClosedDate;
        }).toList();
        break;

      case 'Popular':
        // Sort by review count and rating
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

        // Only show clinics with at least 1 review
        filtered = filtered.where((clinic) {
          final stats = ratingStatsCache[clinic.documentId ?? ''];
          return (stats?.totalReviews ?? 0) > 0;
        }).toList();
        break;

      case 'All':
      default:
        // Sort open clinics first
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

    filteredClinics.assignAll(filtered);
  }

  void updateSearchQuery(String query) {
    searchQuery.value = query;
    applyFilters();
  }

  void setFilter(String filter) {
    selectedFilter.value = filter;
    applyFilters();
  }

  int getFilterCount(String filter) {
    switch (filter) {
      case 'All':
        return allClinics.length;

      case 'Open':
        return allClinics.where((clinic) {
          final settings = clinicSettingsMap[clinic.documentId ?? ''];
          if (settings == null) return false;

          final today = DateTime.now();
          final todayStr =
              '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
          final isTodayClosedDate = settings.closedDates.contains(todayStr);

          return settings.isOpen && settings.isOpenNow() && !isTodayClosedDate;
        }).length;

      case 'Available Today':
        return allClinics.where((clinic) {
          final settings = clinicSettingsMap[clinic.documentId ?? ''];
          if (settings == null) return false;

          final today = DateTime.now();
          final todayStr =
              '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
          final isTodayClosedDate = settings.closedDates.contains(todayStr);

          return settings.isOpen &&
              settings.isOpenToday() &&
              !isTodayClosedDate;
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
          final stats = ratingStatsCache[clinic.documentId ?? ''];
          return (stats?.totalReviews ?? 0) > 0;
        }).length;

      default:
        return 0;
    }
  }
}
