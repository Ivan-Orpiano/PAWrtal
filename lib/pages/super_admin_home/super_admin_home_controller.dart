import 'package:appwrite/appwrite.dart';
import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:capstone_app/data/models/clinic_settings_model.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/utils/appwrite_constant.dart';
import 'package:get/get.dart';
import 'dart:async';

class SuperAdminHomeController extends GetxController {
  final AuthRepository authRepository;

  SuperAdminHomeController(this.authRepository);

  // Observable lists
  final RxList<Map<String, dynamic>> clinicsWithSettings =
      <Map<String, dynamic>>[].obs;
  final RxBool isLoading = true.obs;
  final RxString errorMessage = ''.obs;
  final RxString searchQuery = ''.obs;
  final RxString sortBy = 'name'.obs; // 'name', 'date', 'status'

  StreamSubscription<RealtimeMessage>? _clinicSubscription;
  StreamSubscription<RealtimeMessage>? _settingsSubscription;

  @override
  void onInit() {
    super.onInit();
    fetchAllClinics();
    setupRealtimeListeners();
  }

  @override
  void onClose() {
    _clinicSubscription?.cancel();
    _settingsSubscription?.cancel();
    super.onClose();
  }

  // Fetch all clinics with their settings
  Future<void> fetchAllClinics() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final clinicsData = await authRepository.getClinicsWithSettings();
      clinicsWithSettings.value = clinicsData;

      sortClinics();
    } catch (e) {
      errorMessage.value = 'Error fetching clinics: ${e.toString()}';
      print('Error in fetchAllClinics: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Setup real-time listeners for clinics and settings
  // Setup real-time listeners for clinics and settings
// Setup real-time listeners for clinics and settings
  void setupRealtimeListeners() {
    try {
      final realtime = Realtime(authRepository.client);

      // Listen to clinic changes
      final clinicChannel =
          'databases.${AppwriteConstants.dbID}.collections.${AppwriteConstants.clinicsCollectionID}.documents';

      final clinicSubscription = realtime.subscribe([clinicChannel]);
      _clinicSubscription = clinicSubscription.stream.listen(
        (response) {
          print('Clinic realtime event: ${response.events}');

          // Check if it's a clinic-related event
          if (response.events.any((event) =>
              event.contains('databases') &&
              event.contains(AppwriteConstants.clinicsCollectionID))) {
            print('Clinic update detected, refreshing...');
            fetchAllClinics();
          }
        },
        onError: (error) {
          print('Clinic subscription error: $error');
        },
      );

      // Listen to settings changes
      final settingsChannel =
          'databases.${AppwriteConstants.dbID}.collections.${AppwriteConstants.clinicSettingsCollectionID}.documents';

      final settingsSubscription = realtime.subscribe([settingsChannel]);
      _settingsSubscription = settingsSubscription.stream.listen(
        (response) {
          print('Settings realtime event: ${response.events}');

          // Check if it's a settings-related event
          if (response.events.any((event) =>
              event.contains('databases') &&
              event.contains(AppwriteConstants.clinicSettingsCollectionID))) {
            print('Settings update detected, refreshing...');
            fetchAllClinics();
          }
        },
        onError: (error) {
          print('Settings subscription error: $error');
        },
      );

      print('Realtime listeners setup successfully');
    } catch (e) {
      print('Error setting up realtime listeners: $e');
    }
  }

  // Search functionality
  void updateSearchQuery(String query) {
    searchQuery.value = query.toLowerCase();
  }

  // Get filtered clinics based on search
  List<Map<String, dynamic>> get filteredClinics {
    if (searchQuery.value.isEmpty) {
      return clinicsWithSettings;
    }

    return clinicsWithSettings.where((clinicData) {
      final clinic = clinicData['clinic'] as Clinic;
      return clinic.clinicName.toLowerCase().contains(searchQuery.value) ||
          clinic.address.toLowerCase().contains(searchQuery.value) ||
          clinic.services.toLowerCase().contains(searchQuery.value) ||
          clinic.email.toLowerCase().contains(searchQuery.value);
    }).toList();
  }

  // Sort clinics
  void updateSortBy(String sortOption) {
    sortBy.value = sortOption;
    sortClinics();
  }

  void sortClinics() {
    switch (sortBy.value) {
      case 'name':
        clinicsWithSettings.sort((a, b) {
          final clinicA = a['clinic'] as Clinic;
          final clinicB = b['clinic'] as Clinic;
          return clinicA.clinicName.compareTo(clinicB.clinicName);
        });
        break;
      case 'date':
        clinicsWithSettings.sort((a, b) {
          final clinicA = a['clinic'] as Clinic;
          final clinicB = b['clinic'] as Clinic;
          try {
            return DateTime.parse(clinicB.createdAt)
                .compareTo(DateTime.parse(clinicA.createdAt));
          } catch (e) {
            return 0;
          }
        });
        break;
      case 'status':
        clinicsWithSettings.sort((a, b) {
          final settingsA = a['settings'] as ClinicSettings?;
          final settingsB = b['settings'] as ClinicSettings?;
          final isOpenA = settingsA?.isOpen ?? false;
          final isOpenB = settingsB?.isOpen ?? false;

          // Open clinics first
          if (isOpenA && !isOpenB) return -1;
          if (!isOpenA && isOpenB) return 1;
          return 0;
        });
        break;
    }

    // Trigger UI update
    clinicsWithSettings.refresh();
  }

  // Get clinic statistics
  Map<String, int> get clinicStats {
    int totalClinics = clinicsWithSettings.length;
    int openClinics = 0;
    int closedClinics = 0;

    for (var clinicData in clinicsWithSettings) {
      final settings = clinicData['settings'] as ClinicSettings?;
      if (settings?.isOpen == true) {
        openClinics++;
      } else {
        closedClinics++;
      }
    }

    return {
      'total': totalClinics,
      'open': openClinics,
      'closed': closedClinics,
    };
  }
}
