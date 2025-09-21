import 'dart:io';
import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:capstone_app/data/models/clinic_settings_model.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/utils/appwrite_constant.dart';
import 'package:capstone_app/utils/user_session_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ClinicSettingsController extends GetxController {
  final AuthRepository authRepository;
  final UserSessionService session;

  ClinicSettingsController({
    required this.authRepository,
    required this.session,
  });

  // Observable variables
  var isLoading = false.obs;
  var isSaving = false.obs;
  var clinic = Rxn<Clinic>();
  var clinicSettings = Rxn<ClinicSettings>();

  // Form controllers
  final clinicNameController = TextEditingController();
  final addressController = TextEditingController();
  final contactController = TextEditingController();
  final emailController = TextEditingController();
  final descriptionController = TextEditingController();
  final emergencyContactController = TextEditingController();
  final specialInstructionsController = TextEditingController();

  // Settings observables
  var isClinicOpen = true.obs;
  var autoAcceptAppointments = false.obs;
  var appointmentDuration = 30.obs;
  var maxAdvanceBooking = 30.obs;
  var selectedServices = <String>[].obs;
  var galleryImages = <String>[].obs;
  var operatingHours = <String, Map<String, dynamic>>{}.obs;
  var selectedLocation = Rxn<Map<String, double>>();

  // Available services list
  final List<String> availableServices = [
    'General Checkup',
    'Vaccination',
    'Surgery',
    'Dental Care',
    'Emergency Care',
    'Laboratory Tests',
    'Pet Grooming',
    'Microchipping',
    'Spay/Neuter',
    'X-Ray Imaging',
    'Ultrasound',
    'Blood Work',
    'Behavioral Consultation',
    'Nutritional Counseling',
    'Pet Boarding',
    'Parasite Treatment',
    'Wound Care',
    'Prescription Medications',
    'Health Certificates',
    'Euthanasia Services',
  ];

  @override
  void onInit() {
    super.onInit();
    initializeData();
  }

  @override
  void onClose() {
    // Dispose controllers
    clinicNameController.dispose();
    addressController.dispose();
    contactController.dispose();
    emailController.dispose();
    descriptionController.dispose();
    emergencyContactController.dispose();
    specialInstructionsController.dispose();
    super.onClose();
  }

  Future<void> initializeData() async {
    try {
      isLoading.value = true;
      await fetchClinicData();
      await fetchClinicSettings();
    } catch (e) {
      _showSnackBar("Failed to load clinic data: $e", isError: true);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchClinicData() async {
    final user = await authRepository.getUser();
    if (user == null) return;

    final clinicDoc = await authRepository.getClinicByAdminId(user.$id);
    if (clinicDoc != null) {
      clinic.value = Clinic.fromMap(clinicDoc.data);
      clinic.value!.documentId = clinicDoc.$id;
      _populateClinicFields();
    }
  }

  Future<void> fetchClinicSettings() async {
    if (clinic.value?.documentId == null) return;

    final settings = await authRepository.getClinicSettingsByClinicId(clinic.value!.documentId!);
    if (settings != null) {
      clinicSettings.value = settings;
      _populateSettingsFields();
    } else {
      // Create default settings if none exist
      await createDefaultSettings();
    }
  }

  Future<void> createDefaultSettings() async {
    if (clinic.value?.documentId == null) return;

    final defaultSettings = ClinicSettings(clinicId: clinic.value!.documentId!);
    final createdSettings = await authRepository.initializeClinicSettings(clinic.value!.documentId!);
    clinicSettings.value = createdSettings;
    _populateSettingsFields();
  }

  void _populateClinicFields() {
    if (clinic.value == null) return;

    clinicNameController.text = clinic.value!.clinicName;
    addressController.text = clinic.value!.address;
    contactController.text = clinic.value!.contact;
    emailController.text = clinic.value!.email;
    descriptionController.text = clinic.value!.description;
  }

  void _populateSettingsFields() {
    if (clinicSettings.value == null) return;

    final settings = clinicSettings.value!;
    isClinicOpen.value = settings.isOpen;
    autoAcceptAppointments.value = settings.autoAcceptAppointments;
    appointmentDuration.value = settings.appointmentDuration;
    maxAdvanceBooking.value = settings.maxAdvanceBooking;
    selectedServices.assignAll(settings.services);
    galleryImages.assignAll(settings.gallery);
    operatingHours.assignAll(settings.operatingHours);
    selectedLocation.value = settings.location;
    emergencyContactController.text = settings.emergencyContact;
    specialInstructionsController.text = settings.specialInstructions;
  }

  // Save clinic basic information
  Future<void> saveClinicBasicInfo() async {
    if (clinic.value == null) return;

    try {
      isSaving.value = true;

      final updatedData = {
        'clinicName': clinicNameController.text.trim(),
        'address': addressController.text.trim(),
        'contact': contactController.text.trim(),
        'email': emailController.text.trim(),
        'description': descriptionController.text.trim(),
      };

      await authRepository.updateClinic(clinic.value!.documentId!, updatedData);
      
      // Update local clinic object
      clinic.value = clinic.value!..clinicName = clinicNameController.text.trim()
        ..address = addressController.text.trim()
        ..contact = contactController.text.trim()
        ..email = emailController.text.trim()
        ..description = descriptionController.text.trim();

      _showSnackBar("Clinic information updated successfully!");
    } catch (e) {
      _showSnackBar("Failed to update clinic information: $e", isError: true);
    } finally {
      isSaving.value = false;
    }
  }

  // Save clinic settings
  Future<void> saveClinicSettings() async {
    if (clinicSettings.value == null) return;

    try {
      isSaving.value = true;

      final updatedSettings = clinicSettings.value!.copyWith(
        isOpen: isClinicOpen.value,
        autoAcceptAppointments: autoAcceptAppointments.value,
        appointmentDuration: appointmentDuration.value,
        maxAdvanceBooking: maxAdvanceBooking.value,
        services: selectedServices.toList(),
        gallery: galleryImages.toList(),
        operatingHours: Map<String, Map<String, dynamic>>.from(operatingHours),
        location: selectedLocation.value,
        emergencyContact: emergencyContactController.text.trim(),
        specialInstructions: specialInstructionsController.text.trim(),
      );

      await authRepository.updateClinicSettings(updatedSettings);
      clinicSettings.value = updatedSettings;

      _showSnackBar("Clinic settings updated successfully!");
    } catch (e) {
      _showSnackBar("Failed to update clinic settings: $e", isError: true);
    } finally {
      isSaving.value = false;
    }
  }

  // Toggle clinic status
  Future<void> toggleClinicStatus() async {
    isClinicOpen.value = !isClinicOpen.value;
    await saveClinicSettings();
  }

  // Update operating hours
  void updateOperatingHours(String day, Map<String, dynamic> hours) {
    operatingHours[day] = hours;
    operatingHours.refresh();
  }

  // Add/remove services
  void toggleService(String service) {
    if (selectedServices.contains(service)) {
      selectedServices.remove(service);
    } else {
      selectedServices.add(service);
    }
  }

  void addCustomService(String service) {
    if (service.trim().isNotEmpty && !selectedServices.contains(service.trim())) {
      selectedServices.add(service.trim());
    }
  }

  void removeService(String service) {
    selectedServices.remove(service);
  }

  // Gallery management - using same approach as pet creation
  Future<void> addGalleryImages() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        isSaving.value = true;
        
        final newImageUrls = <String>[];
        
        // Process each file individually, similar to pet creation
        for (int i = 0; i < result.files.length; i++) {
          final file = result.files[i];
          
          try {
            // For web: use bytes, for mobile: use path (same logic as pet creation)
            String? imagePath;
            if (file.bytes != null) {
              // Handle web platform - we need to create a temporary approach
              // For now, let's use the uploadClinicGalleryImages method but simplified
              final uploadedFiles = await authRepository.uploadClinicGalleryImages([file]);
              if (uploadedFiles.isNotEmpty) {
                final imageId = uploadedFiles.first.$id;
                // Use exact same URL construction as pet creation
                final imageUrl = '${AppwriteConstants.endPoint}/storage/buckets/${AppwriteConstants.imageBucketID}/files/$imageId/view?project=${AppwriteConstants.projectID}';
                newImageUrls.add(imageUrl);
                print("Added image URL: $imageUrl"); // Debug log
              }
            } else if (file.path != null) {
              // Handle mobile platform - use existing uploadImage method like pet creation
              final imageResponse = await authRepository.uploadImage(file.path!);
              final imageId = imageResponse.$id;
              // Use exact same URL construction as pet creation  
              final imageUrl = '${AppwriteConstants.endPoint}/storage/buckets/${AppwriteConstants.imageBucketID}/files/$imageId/view?project=${AppwriteConstants.projectID}';
              newImageUrls.add(imageUrl);
              print("Added image URL: $imageUrl"); // Debug log
            }
          } catch (e) {
            print("Error uploading image ${file.name}: $e");
            // Continue with other images
          }
        }
        
        if (newImageUrls.isNotEmpty) {
          galleryImages.addAll(newImageUrls);
          await saveClinicSettings();
          _showSnackBar("${newImageUrls.length} image(s) uploaded successfully!");
        } else {
          _showSnackBar("No images were uploaded successfully", isError: true);
        }
      }
    } catch (e) {
      print("Error in addGalleryImages: $e");
      _showSnackBar("Failed to upload images: $e", isError: true);
    } finally {
      isSaving.value = false;
    }
  }

  void removeGalleryImage(int index) {
    if (index >= 0 && index < galleryImages.length) {
      galleryImages.removeAt(index);
    }
  }

  // Location management
  void updateLocation(double lat, double lng) {
    selectedLocation.value = {'lat': lat, 'lng': lng};
  }

  void clearLocation() {
    selectedLocation.value = null;
  }

  // Validation
  bool get isValidBasicInfo {
    return clinicNameController.text.trim().isNotEmpty &&
           addressController.text.trim().isNotEmpty &&
           contactController.text.trim().isNotEmpty &&
           emailController.text.trim().isNotEmpty;
  }

  bool get hasUnsavedChanges {
    if (clinic.value == null || clinicSettings.value == null) return false;
    
    return clinicNameController.text.trim() != clinic.value!.clinicName ||
           addressController.text.trim() != clinic.value!.address ||
           contactController.text.trim() != clinic.value!.contact ||
           emailController.text.trim() != clinic.value!.email ||
           descriptionController.text.trim() != clinic.value!.description ||
           isClinicOpen.value != clinicSettings.value!.isOpen ||
           autoAcceptAppointments.value != clinicSettings.value!.autoAcceptAppointments;
  }

  // Utility methods
  String get clinicStatusText => isClinicOpen.value ? "Open" : "Closed";
  Color get clinicStatusColor => isClinicOpen.value ? Colors.green : Colors.red;

  void _showSnackBar(String message, {bool isError = false}) {
    Get.snackbar(
      isError ? "Error" : "Success",
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: isError ? Colors.red[600] : Colors.green[600],
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
    );
  }
}