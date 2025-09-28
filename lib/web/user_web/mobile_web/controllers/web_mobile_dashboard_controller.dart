// import 'package:capstone_app/data/models/clinic_model.dart';
// import 'package:capstone_app/data/models/clinic_settings_model.dart';
// import 'package:capstone_app/data/provider/appwrite_provider.dart';
// import 'package:capstone_app/data/repository/auth.repository.dart';
// import 'package:capstone_app/utils/appwrite_constant.dart';
// import 'package:get/get.dart';

// class WebMobileDashboardController extends GetxController {
//   final AppWriteProvider appwrite = AppWriteProvider();
//   final AuthRepository authRepository = Get.find<AuthRepository>();

//   var allClinics = <Clinic>[].obs;
//   var filteredClinics = <Clinic>[].obs;
//   var clinicSettingsMap = <String, ClinicSettings?>{}.obs;
//   var isLoading = true.obs;
//   var searchQuery = ''.obs;
//   var selectedFilter = 'All'.obs;

//   @override
//   void onInit() {
//     super.onInit();
//     fetchClinics();
//   }

//   Future<void> fetchClinics() async {
//     try {
//       isLoading.value = true;
      
//       final result = await appwrite.databases!.listDocuments(
//         databaseId: AppwriteConstants.dbID,
//         collectionId: AppwriteConstants.clinicsCollectionID,
//       );

//       // Create clinic objects
//       final clinics = result.documents.map((doc) {
//         final clinic = Clinic.fromMap(doc.data);
//         clinic.documentId = doc.$id;
//         return clinic;
//       }).toList();

//       // Load clinic settings for each clinic
//       final settingsMap = <String, ClinicSettings?>{};
      
//       for (final clinic in clinics) {
//         try {
//           final settings = await authRepository.getClinicSettingsByClinicId(clinic.documentId ?? '');
//           settingsMap[clinic.documentId ?? ''] = settings;
//         } catch (e) {
//           print("Error loading settings for clinic ${clinic.clinicName}: $e");
//           settingsMap[clinic.documentId ?? ''] = null;
//         }
//       }

//       allClinics.assignAll(clinics);
//       clinicSettingsMap.assignAll(settingsMap);
//       applyFilters();
      
//     } catch (e) {
//       print("Error fetching clinics: $e");
//     } finally {
//       isLoading.value = false;
//     }
//   }

//   void applyFilters() {
//     var filtered = allClinics.toList();

//     // Apply search filter
//     if (searchQuery.value.isNotEmpty) {
//       filtered = filtered.where((clinic) {
//         final settings = clinicSettingsMap[clinic.documentId ?? ''];
//         final services = settings?.services.join(' ') ?? clinic.services;
        
//         return clinic.clinicName.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
//                clinic.address.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
//                services.toLowerCase().contains(searchQuery.value.toLowerCase());
//       }).toList();
//     }

//     // Apply status filter
//     switch (selectedFilter.value) {
//       case 'Open':
//         filtered = filtered.where((clinic) {
//           final settings = clinicSettingsMap[clinic.documentId ?? ''];
//           return settings?.isOpen ?? true;
//         }).toList();
//         break;
//       case 'Available Today':
//         filtered = filtered.where((clinic) {
//           final settings = clinicSettingsMap[clinic.documentId ?? ''];
//           return (settings?.isOpen ?? true) && (settings?.isOpenToday() ?? true);
//         }).toList();
//         break;
//       case 'Closed':
//         filtered = filtered.where((clinic) {
//           final settings = clinicSettingsMap[clinic.documentId ?? ''];
//           return !(settings?.isOpen ?? true);
//         }).toList();
//         break;
//     }

//     // Sort by status (open clinics first)
//     filtered.sort((a, b) {
//       final aSettings = clinicSettingsMap[a.documentId ?? ''];
//       final bSettings = clinicSettingsMap[b.documentId ?? ''];
      
//       final aIsOpen = aSettings?.isOpen ?? true;
//       final bIsOpen = bSettings?.isOpen ?? true;
      
//       if (aIsOpen && !bIsOpen) return -1;
//       if (!aIsOpen && bIsOpen) return 1;
      
//       return a.clinicName.compareTo(b.clinicName);
//     });

//     filteredClinics.assignAll(filtered);
//   }

//   void updateSearchQuery(String query) {
//     searchQuery.value = query;
//     applyFilters();
//   }

//   void setFilter(String filter) {
//     selectedFilter.value = filter;
//     applyFilters();
//   }

//   int getFilterCount(String filter) {
//     switch (filter) {
//       case 'All':
//         return allClinics.length;
//       case 'Open':
//         return allClinics.where((clinic) {
//           final settings = clinicSettingsMap[clinic.documentId ?? ''];
//           return settings?.isOpen ?? true;
//         }).length;
//       case 'Available Today':
//         return allClinics.where((clinic) {
//           final settings = clinicSettingsMap[clinic.documentId ?? ''];
//           return (settings?.isOpen ?? true) && (settings?.isOpenToday() ?? true);
//         }).length;
//       case 'Closed':
//         return allClinics.where((clinic) {
//           final settings = clinicSettingsMap[clinic.documentId ?? ''];
//           return !(settings?.isOpen ?? true);
//         }).length;
//       default:
//         return 0;
//     }
//   }
// }