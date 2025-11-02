import 'dart:math' as math;

import 'package:capstone_app/utils/user_session_service.dart';
import 'package:get/get.dart';
import 'package:capstone_app/data/models/pet_model.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/web/user_web/services/web_snack_bar_service.dart';
import 'package:capstone_app/data/models/medical_record_model.dart';
import 'package:capstone_app/data/models/vaccination_model.dart';

class WebPetsController extends GetxController {
  final AuthRepository authRepository;
  final UserSessionService session;

  WebPetsController({required this.authRepository, required this.session});

  RxList<Pet> pets = <Pet>[].obs;
  RxBool isLoading = false.obs;
  RxString searchQuery = ''.obs;
  Rx<Pet?> selectedPet = Rx<Pet?>(null);

  RxList<MedicalRecord> medicalRecords = <MedicalRecord>[].obs;
  RxList<Vaccination> vaccinations = <Vaccination>[].obs;
  RxBool isLoadingMedical = false.obs;
  RxBool isLoadingVaccinations = false.obs;

  // NEW: Medical appointments across all clinics
  final RxList<Map<String, dynamic>> medicalAppointments =
      <Map<String, dynamic>>[].obs;
  final RxBool isLoadingMedicalAppointments = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchUserPets();
  }

  // Filtered pets based on search query
  List<Pet> get filteredPets {
    if (searchQuery.value.isEmpty) {
      return pets;
    }
    return pets
        .where((pet) =>
            pet.name.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
            pet.type.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
            pet.breed.toLowerCase().contains(searchQuery.value.toLowerCase()))
        .toList();
  }

  Future<void> fetchUserPets() async {
    isLoading.value = true;
    try {
      final userId = session.userId;
      if (userId.isEmpty) {
        WebSnackBarService.showError(
          title: "Error",
          message: "User not logged in. Please log in to view your pets.",
        );
        return;
      }
      final petDocs = await authRepository.getUserPets(userId);
      pets.value = petDocs.map((doc) => Pet.fromMap(doc.data)).toList();
    } catch (e) {
      WebSnackBarService.showError(
        title: "Error",
        message: "Failed to fetch pets: $e",
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchPetMedicalHistory(String petId) async {
    isLoadingMedical.value = true;
    try {
      final records = await authRepository.getPetMedicalRecords(petId);
      medicalRecords.value = records;
    } catch (e) {
      WebSnackBarService.showError(
        title: "Error",
        message: "Failed to fetch medical history: $e",
      );
    } finally {
      isLoadingMedical.value = false;
    }
  }

  Future<void> fetchPetVaccinationHistory(String petId) async {
    isLoadingVaccinations.value = true;
    try {
      print('>>> CONTROLLER: Fetching vaccinations for pet: $petId');

      final vaccins = await authRepository.getPetVaccinations(petId);

      vaccinations.value = vaccins;

      print('>>> CONTROLLER: ✅ Loaded ${vaccins.length} vaccinations');

      // Debug info
      if (vaccins.isNotEmpty) {
        print('>>> First vaccination: ${vaccins.first.vaccineName}');
        print('>>> Date given: ${vaccins.first.dateGiven}');
      }
    } catch (e) {
      print('>>> CONTROLLER: ❌ Error fetching vaccinations: $e');
      WebSnackBarService.showError(
        title: "Error",
        message: "Failed to fetch vaccination history: $e",
      );
      vaccinations.clear();
    } finally {
      isLoadingVaccinations.value = false;
    }
  }

  Future<void> debugVaccinations(String petId) async {
    await authRepository.appWriteProvider.debugPetVaccinations(petId);
  }

  // NEW: Fetch medical appointments across all clinics
  Future<void> fetchPetMedicalAppointmentsAllClinics(String petId) async {
    try {
      isLoadingMedicalAppointments.value = true;
      print('>>> CONTROLLER: Fetching medical appointments for pet: $petId');

      // ✅ CRITICAL FIX 6: Call the corrected method
      final appointments =
          await authRepository.getPetMedicalAppointmentsAllClinics(petId);

      medicalAppointments.value = appointments;

      print(
          '>>> CONTROLLER: ✅ Loaded ${appointments.length} medical appointments');

      // ✅ Additional debug info
      if (appointments.isNotEmpty) {
        print(
            '>>> First appointment service: ${appointments.first['service']}');
        print('>>> First appointment petId: ${appointments.first['petId']}');
      }
    } catch (e) {
      print('>>> CONTROLLER: ❌ Error fetching medical appointments: $e');
      WebSnackBarService.showError(
        title: "Error",
        message: "Failed to fetch medical appointments: $e",
      );
      medicalAppointments.clear();
    } finally {
      isLoadingMedicalAppointments.value = false;
    }
  }

  // Clear histories when pet selection changes
  void clearHistories() {
    medicalRecords.clear();
    vaccinations.clear();
    medicalAppointments.clear(); // NEW: Clear medical appointments too
  }

  void selectPet(Pet pet) {
    selectedPet.value = pet;
  }

  void clearSelection() {
    selectedPet.value = null;
  }

  void updateSearchQuery(String query) {
    searchQuery.value = query;
  }

  /// Extract file ID from image URL or return null if invalid
  String? _extractFileId(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return null;
    }

    try {
      // Check if it's already a file ID (no URL structure)
      if (!imageUrl.contains('/') && !imageUrl.contains('http')) {
        return imageUrl;
      }

      // Try to extract from URL format: .../files/{fileId}/...
      if (imageUrl.contains('/files/')) {
        final parts = imageUrl.split('/files/');
        if (parts.length > 1) {
          final fileIdPart = parts[1].split('/')[0];
          if (fileIdPart.isNotEmpty) {
            return fileIdPart;
          }
        }
      }

      // Try alternative format: .../{fileId}/view or .../{fileId}/preview
      final urlParts = imageUrl.split('/');
      if (urlParts.length > 1) {
        // Look for a segment that looks like a file ID (alphanumeric, no dots)
        for (int i = 0; i < urlParts.length - 1; i++) {
          final part = urlParts[i];
          if (part.isNotEmpty &&
              part.length > 10 &&
              !part.contains('.') &&
              !part.contains('http') &&
              !part.contains('preview') &&
              !part.contains('view')) {
            return part;
          }
        }
      }

      print('⚠️ Could not extract file ID from: $imageUrl');
      return null;
    } catch (e) {
      print('⚠️ Error extracting file ID from $imageUrl: $e');
      return null;
    }
  }

  // Update the fetchPetMedicalRecordsForAppointments method
  Future<void> fetchPetMedicalRecordsForAppointments(String petId) async {
    isLoadingMedical.value = true;
    try {
      print('>>> ============================================');
      print('>>> CONTROLLER: Fetching medical records for pet: $petId');
      print('>>> ============================================');

      final records = await authRepository.getPetMedicalRecords(petId);

      medicalRecords.value = records;

      print('>>> CONTROLLER: ✅ Loaded ${records.length} medical records');

      // Debug info - print each record
      if (records.isNotEmpty) {
        for (var record in records) {
          print('>>> Medical Record:');
          print('>>>   Record ID: ${record.id}');
          print('>>>   Appointment ID: ${record.appointmentId}');
          print('>>>   Service: ${record.service}');
          print('>>>   Pet ID: ${record.petId}');
          print('>>>   Visit Date: ${record.visitDate}');
          print(
              '>>>   Diagnosis: ${record.diagnosis.substring(0, math.min(30, record.diagnosis.length))}...');
          print('>>> ---');
        }
      }
      print('>>> ============================================');
    } catch (e, stackTrace) {
      print('>>> CONTROLLER: ❌ Error fetching medical records: $e');
      print('>>> Stack trace: $stackTrace');
      WebSnackBarService.showError(
        title: "Error",
        message: "Failed to fetch medical records: $e",
      );
      medicalRecords.clear();
    } finally {
      isLoadingMedical.value = false;
    }
  }

  Future<void> deletePet(Pet pet) async {
    bool imageDeleted = false;

    try {
      // Attempt to delete image if it exists
      if (pet.image != null && pet.image!.isNotEmpty) {
        final imageId = _extractFileId(pet.image);

        if (imageId != null) {
          try {
            print('🗑️ Attempting to delete image: $imageId');
            await authRepository.deleteImage(imageId);
            imageDeleted = true;
            print('✅ Image deleted successfully');
          } catch (imageError) {
            // Log the error but don't fail the entire operation
            print('⚠️ Failed to delete image (continuing anyway): $imageError');

            // Only show warning if it's not a "file not found" error
            if (!imageError.toString().contains('storage_file_not_found') &&
                !imageError.toString().contains('404')) {
              WebSnackBarService.showWarning(
                title: "Warning",
                message:
                    "Pet image could not be deleted, but pet record will be removed.",
              );
            }
          }
        } else {
          print('⚠️ Could not extract valid file ID from image URL');
        }
      }

      // Delete the pet document (this should always succeed)
      print('🗑️ Deleting pet document: ${pet.documentId}');
      await authRepository.deletePet(pet.documentId!);

      // Remove from local list
      pets.removeWhere((p) => p.documentId == pet.documentId);

      // Clear selection if deleted pet was selected
      if (selectedPet.value?.documentId == pet.documentId) {
        clearSelection();
      }

      // Show success message
      final message = imageDeleted
          ? "${pet.name} has been deleted successfully"
          : "${pet.name} has been deleted (image was already removed)";

      WebSnackBarService.showSuccess(
        title: "Success",
        message: message,
      );
    } catch (e) {
      print('❌ Error deleting pet: $e');
      WebSnackBarService.showError(
        title: "Error",
        message:
            "Failed to delete pet: ${e.toString().replaceAll('AppwriteException: ', '')}",
      );
    }
  }

  void refreshPets() {
    fetchUserPets();
  }

  // In web_pets_controller.dart, add this temporarily
  Future<void> debugAppointments(String petId) async {
    await authRepository.appWriteProvider.debugPetAppointments(petId);
  }

  Future<String> getVeterinarianName(String vetId) async {
    try {
      print('>>> CONTROLLER: Fetching veterinarian name for vetId: $vetId');

      // Check if this is a clinic admin (by user ID)
      final clinicDoc = await authRepository.getClinicByAdminId(vetId);
      if (clinicDoc != null) {
        print('>>> User is CLINIC ADMIN - returning "Admin"');
        return 'Admin';
      }

      // Try to get staff by USER ID (most common case)
      try {
        final staffDoc = await authRepository.getStaffByUserId(vetId);
        if (staffDoc != null) {
          final staffName = staffDoc.name;
          final isDoctor = staffDoc.isDoctor;

          print('>>> Staff found by USER ID!');
          print('>>>   Name: $staffName');
          print('>>>   Is Doctor: $isDoctor');

          // Return "Dr. [Name]" if doctor, otherwise just name
          final displayName = isDoctor ? 'Dr. $staffName' : staffName;
          print('>>> Returning staff name: $displayName');
          return displayName;
        }
      } catch (e) {
        print('>>> Not a staff user ID, trying staff document ID...');
      }

      // Try to get staff by DOCUMENT ID (fallback)
      try {
        final staffDoc = await authRepository.getStaffByDocumentId(vetId);
        if (staffDoc != null) {
          final staffName = staffDoc.name;
          final isDoctor = staffDoc.isDoctor;

          print('>>> Staff found by DOCUMENT ID!');
          print('>>>   Name: $staffName');
          print('>>>   Is Doctor: $isDoctor');

          final displayName = isDoctor ? 'Dr. $staffName' : staffName;
          print('>>> Returning staff name: $displayName');
          return displayName;
        }
      } catch (e) {
        print('>>> Not a staff document ID either...');
      }

      // Get the user document as last resort
      print('>>> Fetching user document as fallback...');
      final userDoc = await authRepository.getUserById(vetId);

      if (userDoc == null) {
        print('>>> User document not found for vetId: $vetId');
        return 'Unknown';
      }

      final userName = userDoc.data['name'] ?? 'Unknown';
      print('>>> Returning user name: $userName');
      return userName;
    } catch (e, stackTrace) {
      print('>>> ERROR fetching veterinarian name: $e');
      print('>>> Stack trace: $stackTrace');
      return 'Unknown';
    }
  }
}
