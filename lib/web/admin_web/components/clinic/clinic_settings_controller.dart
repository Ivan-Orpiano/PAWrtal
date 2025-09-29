import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:capstone_app/data/models/clinic_settings_model.dart';
import 'package:capstone_app/utils/user_session_service.dart';

class ClinicSettingsController extends GetxController {
  final AuthRepository authRepository;
  final UserSessionService session;

  ClinicSettingsController({
    required this.authRepository,
    required this.session,
  });

  // Reactive variables
  final isLoading = false.obs;
  final isSaving = false.obs;
  final clinic = Rxn<Clinic>();
  final clinicSettings = Rxn<ClinicSettings>();

  // Basic Info Controllers
  final clinicNameController = TextEditingController();
  final emailController = TextEditingController();
  final addressController = TextEditingController();
  final contactController = TextEditingController();
  final descriptionController = TextEditingController();

  // Services
  final selectedServices = <String>[].obs;
  final availableServices = [
    'General Checkup',
    'Vaccinations',
    'Surgery',
    'Dental Care',
    'Grooming',
    'Emergency Care',
    'Laboratory Services',
    'X-Ray',
    'Ultrasound',
    'Microchipping',
    'Spay/Neuter',
    'Boarding',
  ];

  // Gallery
  final galleryImages = <String>[].obs;

  // Operating Hours
  final operatingHours = <String, Map<String, dynamic>>{}.obs;

  // Settings
  final isClinicOpen = true.obs;
  final appointmentDuration = 30.obs;
  final maxAdvanceBooking = 30.obs;
  final autoAcceptAppointments = false.obs;
  final emergencyContactController = TextEditingController();
  final specialInstructionsController = TextEditingController();

  // Location - NEW
  final selectedLocation = Rxn<Map<String, double>>();

  @override
  void onInit() {
    super.onInit();
    loadClinicData();
  }

  @override
  void onClose() {
    clinicNameController.dispose();
    emailController.dispose();
    addressController.dispose();
    contactController.dispose();
    descriptionController.dispose();
    emergencyContactController.dispose();
    specialInstructionsController.dispose();
    super.onClose();
  }

  // Getters
  String get clinicStatusText => isClinicOpen.value ? "OPEN" : "CLOSED";
  Color get clinicStatusColor => isClinicOpen.value ? Colors.green : Colors.red;

  Future<void> loadClinicData() async {
    try {
      isLoading.value = true;

      final user = await authRepository.getUser();
      if (user == null) return;

      final clinicDoc = await authRepository.getClinicByAdminId(user.$id);
      if (clinicDoc != null) {
        final clinicData = Clinic.fromMap(clinicDoc.data);
        clinicData.documentId = clinicDoc.$id;
        clinic.value = clinicData;

        // Load clinic settings
        final settingsData = await authRepository
            .getClinicSettingsByClinicId(clinicData.documentId!);
        if (settingsData != null) {
          clinicSettings.value = settingsData;
          _populateFieldsFromSettings(settingsData);
        } else {
          // Initialize default settings if none exist
          final defaultSettings = await authRepository
              .initializeClinicSettings(clinicData.documentId!);
          clinicSettings.value = defaultSettings;
          _populateFieldsFromSettings(defaultSettings);
        }

        _populateFieldsFromClinic(clinicData);
      }
    } catch (e) {
      print("Error loading clinic data: $e");
      Get.snackbar("Error", "Failed to load clinic data");
    } finally {
      isLoading.value = false;
    }
  }

  void _populateFieldsFromClinic(Clinic clinicData) {
    clinicNameController.text = clinicData.clinicName;
    emailController.text = clinicData.email;
    addressController.text = clinicData.address;
    contactController.text = clinicData.contact;
    descriptionController.text = clinicData.description;
  }

  void _populateFieldsFromSettings(ClinicSettings settings) {
    isClinicOpen.value = settings.isOpen;
    selectedServices.value = List<String>.from(settings.services);
    galleryImages.value = List<String>.from(
        settings.gallery.map((fileId) => authRepository.getImageUrl(fileId)));
    operatingHours.value =
        Map<String, Map<String, dynamic>>.from(settings.operatingHours);
    appointmentDuration.value = settings.appointmentDuration;
    maxAdvanceBooking.value = settings.maxAdvanceBooking;
    autoAcceptAppointments.value = settings.autoAcceptAppointments;
    emergencyContactController.text = settings.emergencyContact;
    specialInstructionsController.text = settings.specialInstructions;

    // Set location
    if (settings.location != null) {
      selectedLocation.value = Map<String, double>.from(settings.location!);
    }
  }

  // Basic Info Methods
  Future<void> saveClinicBasicInfo() async {
    if (clinic.value?.documentId == null) return;

    try {
      isSaving.value = true;

      final updateData = {
        'clinicName': clinicNameController.text.trim(),
        'email': emailController.text.trim(),
        'address': addressController.text.trim(),
        'contact': contactController.text.trim(),
        'description': descriptionController.text.trim(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      await authRepository.updateClinic(clinic.value!.documentId!, updateData);

      // Update local clinic data
      clinic.value!.clinicName = clinicNameController.text.trim();
      clinic.value!.email = emailController.text.trim();
      clinic.value!.address = addressController.text.trim();
      clinic.value!.contact = contactController.text.trim();
      clinic.value!.description = descriptionController.text.trim();

      clinic.refresh();

      Get.snackbar(
        "Success",
        "Clinic information updated successfully",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      print("Error saving clinic basic info: $e");
      Get.snackbar("Error", "Failed to update clinic information");
    } finally {
      isSaving.value = false;
    }
  }

  // Services Methods
  void toggleService(String service) {
    if (selectedServices.contains(service)) {
      selectedServices.remove(service);
    } else {
      selectedServices.add(service);
    }
  }

  void addCustomService(String service) {
    if (service.trim().isNotEmpty &&
        !selectedServices.contains(service.trim())) {
      selectedServices.add(service.trim());
    }
  }

  void removeService(String service) {
    selectedServices.remove(service);
  }

  // Gallery Methods
  Future<void> addGalleryImages() async {
    try {
      isSaving.value = true;

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        allowedExtensions: ['jpg', 'jpeg', 'png'],
      );

      if (result != null) {
        final uploadedFiles =
            await authRepository.uploadClinicGalleryImages(result.files);
        final newImageUrls = uploadedFiles
            .map((file) => authRepository.getImageUrl(file.$id))
            .toList();

        galleryImages.addAll(newImageUrls);

        // Update gallery in settings
        if (clinicSettings.value != null) {
          final currentGallery = clinicSettings.value!.gallery;
          final newFileIds = uploadedFiles.map((file) => file.$id).toList();
          currentGallery.addAll(newFileIds);

          final updatedSettings =
              clinicSettings.value!.copyWith(gallery: currentGallery);
          await authRepository.updateClinicSettings(updatedSettings);
          clinicSettings.value = updatedSettings;
        }

        Get.snackbar(
          "Success",
          "Images uploaded successfully",
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      print("Error uploading images: $e");
      Get.snackbar("Error", "Failed to upload images");
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> removeGalleryImage(int index) async {
    try {
      if (clinicSettings.value != null) {
        final fileId = clinicSettings.value!.gallery[index];
        await authRepository.deleteClinicGalleryImages([fileId]);

        galleryImages.removeAt(index);
        clinicSettings.value!.gallery.removeAt(index);

        final updatedSettings = clinicSettings.value!
            .copyWith(gallery: clinicSettings.value!.gallery);
        await authRepository.updateClinicSettings(updatedSettings);
        clinicSettings.value = updatedSettings;

        Get.snackbar(
          "Success",
          "Image removed successfully",
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      print("Error removing image: $e");
      Get.snackbar("Error", "Failed to remove image");
    }
  }

  // Operating Hours Methods
  void updateOperatingHours(String day, Map<String, dynamic> dayData) {
    operatingHours[day] = dayData;
  }

  // Status Methods
  Future<void> toggleClinicStatus() async {
    try {
      isClinicOpen.value = !isClinicOpen.value;
      await saveClinicSettings();
    } catch (e) {
      print("Error toggling clinic status: $e");
      isClinicOpen.value = !isClinicOpen.value; // Revert on error
      Get.snackbar("Error", "Failed to update clinic status");
    }
  }

  // Location Methods - NEW
  void updateSelectedLocation(Map<String, double> location) {
    if (location.isEmpty) {
      selectedLocation.value = null;
    } else {
      selectedLocation.value = location;
    }
  }

  void clearLocation() {
    selectedLocation.value = null;
  }

  // Save Methods
  Future<void> saveClinicSettings() async {
    if (clinicSettings.value == null) return;

    try {
      isSaving.value = true;

      final updatedSettings = clinicSettings.value!.copyWith(
        isOpen: isClinicOpen.value,
        services: selectedServices.toList(),
        operatingHours: Map<String, Map<String, dynamic>>.from(operatingHours),
        appointmentDuration: appointmentDuration.value,
        maxAdvanceBooking: maxAdvanceBooking.value,
        autoAcceptAppointments: autoAcceptAppointments.value,
        emergencyContact: emergencyContactController.text.trim(),
        specialInstructions: specialInstructionsController.text.trim(),
        location: selectedLocation.value, // NEW - Include location
      );

      await authRepository.updateClinicSettings(updatedSettings);
      clinicSettings.value = updatedSettings;

      Get.snackbar(
        "Success",
        "Settings saved successfully",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      print("Error saving clinic settings: $e");
      Get.snackbar("Error", "Failed to save settings");
    } finally {
      isSaving.value = false;
    }
  }
}
