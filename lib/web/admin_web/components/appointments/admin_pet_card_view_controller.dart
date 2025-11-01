// admin_pet_card_view_controller.dart
import 'dart:math' as math;
import 'package:capstone_app/data/models/pet_model.dart';
import 'package:capstone_app/data/models/medical_record_model.dart';
import 'package:capstone_app/data/models/vaccination_model.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:get/get.dart';

class AdminPetCardViewController extends GetxController {
  final AuthRepository authRepository;

  AdminPetCardViewController({required this.authRepository});

  // Observable data
  final Rx<Pet?> currentPet = Rx<Pet?>(null);
  final RxList<MedicalRecord> medicalRecords = <MedicalRecord>[].obs;
  final RxList<Vaccination> vaccinations = <Vaccination>[].obs;
  final RxList<Map<String, dynamic>> medicalAppointments =
      <Map<String, dynamic>>[].obs;

  // Loading states
  final RxBool isLoadingMedicalRecords = false.obs;
  final RxBool isLoadingVaccinations = false.obs;
  final RxBool isLoadingMedicalAppointments = false.obs;

  final RxString currentClinicId = ''.obs;

  Future<void> loadPetData(Pet pet, String clinicId) async {
    currentPet.value = pet;
    currentClinicId.value = clinicId;

    print('>>> ============================================');
    print('>>> ADMIN CARD CONTROLLER: Loading pet data');
    print('>>> Pet ID: ${pet.petId}');
    print('>>> Clinic ID: $clinicId');
    print('>>> ============================================');

    // âœ… CRITICAL: Fetch ALL data immediately in parallel
    await Future.wait([
      fetchPetMedicalRecords(pet.petId),
      fetchPetVaccinations(pet.petId),
      fetchPetMedicalAppointmentsByClinic(pet.petId, clinicId),
    ]);

    print('>>> âœ… All pet data loaded successfully');
    print('>>> Medical Records: ${medicalRecords.length}');
    print('>>> Vaccinations: ${vaccinations.length}');
    print('>>> Medical Appointments: ${medicalAppointments.length}');
    print('>>> ============================================');
  }

  Future<void> fetchPetMedicalAppointmentsByClinic(
    String petId,
    String clinicId,
  ) async {
    isLoadingMedicalAppointments.value = true;
    try {
      print('>>> ADMIN CARD: Fetching medical appointments');
      print('>>> Pet ID: $petId');
      print('>>> Clinic ID: $clinicId');
      print('>>> ============================================');

      // Use the new clinic-specific method
      final appointments = await authRepository
          .getPetMedicalAppointmentsByClinic(petId, clinicId);

      medicalAppointments.value = appointments;

      print(
          '>>> ADMIN CARD: ✅ Loaded ${appointments.length} medical appointments');
      print('>>> (Only from THIS clinic)');

      if (appointments.isNotEmpty) {
        print('>>> First appointment:');
        print('>>>   Service: ${appointments.first['service']}');
        print('>>>   Clinic: ${appointments.first['clinicName']}');
        print('>>>   Date: ${appointments.first['dateTime']}');
      }
    } catch (e) {
      print('>>> ADMIN CARD: ❌ Error fetching medical appointments: $e');
      medicalAppointments.clear();
    } finally {
      isLoadingMedicalAppointments.value = false;
    }
  }

  /// Fetch medical records for the pet
  Future<void> fetchPetMedicalRecords(String petId) async {
    isLoadingMedicalRecords.value = true;
    try {
      print('>>> ADMIN CARD: Fetching medical records for pet: $petId');

      final records = await authRepository.getPetMedicalRecords(petId);
      medicalRecords.value = records;

      print('>>> ADMIN CARD: ✅ Loaded ${records.length} medical records');

      // Debug info
      if (records.isNotEmpty) {
        for (var record in records) {
          print('>>> Medical Record:');
          print('>>>   Record ID: ${record.id}');
          print('>>>   Appointment ID: ${record.appointmentId}');
          print('>>>   Service: ${record.service}');
          print('>>>   Visit Date: ${record.visitDate}');
          print('>>> ---');
        }
      }
    } catch (e, stackTrace) {
      print('>>> ADMIN CARD: ❌ Error fetching medical records: $e');
      print('>>> Stack trace: $stackTrace');
      medicalRecords.clear();
    } finally {
      isLoadingMedicalRecords.value = false;
    }
  }

  /// Fetch vaccinations for the pet
  Future<void> fetchPetVaccinations(String petId) async {
    isLoadingVaccinations.value = true;
    try {
      print('>>> ADMIN CARD: Fetching vaccinations for pet: $petId');
      print('>>> (Visible across ALL clinics)');

      final vaccins = await authRepository.getPetVaccinations(petId);
      vaccinations.value = vaccins;

      print('>>> ADMIN CARD: ✅ Loaded ${vaccins.length} vaccinations');

      if (vaccins.isNotEmpty) {
        print('>>> First vaccination: ${vaccins.first.vaccineName}');
        print('>>> Date given: ${vaccins.first.dateGiven}');
      }
    } catch (e) {
      print('>>> ADMIN CARD: ❌ Error fetching vaccinations: $e');
      vaccinations.clear();
    } finally {
      isLoadingVaccinations.value = false;
    }
  }

  /// Fetch medical appointments across all clinics
  Future<void> fetchPetMedicalAppointments(String petId) async {
    isLoadingMedicalAppointments.value = true;
    try {
      print('>>> ADMIN CARD: Fetching medical appointments for pet: $petId');

      final appointments =
          await authRepository.getPetMedicalAppointmentsAllClinics(petId);
      medicalAppointments.value = appointments;

      print(
          '>>> ADMIN CARD: ✅ Loaded ${appointments.length} medical appointments');

      if (appointments.isNotEmpty) {
        print(
            '>>> First appointment service: ${appointments.first['service']}');
        print('>>> First appointment petId: ${appointments.first['petId']}');
      }
    } catch (e) {
      print('>>> ADMIN CARD: ❌ Error fetching medical appointments: $e');
      medicalAppointments.clear();
    } finally {
      isLoadingMedicalAppointments.value = false;
    }
  }

  /// Get counts for display
  int get vaccinationCount => vaccinations.length;
  int get medicalAppointmentsCount => medicalAppointments.length;

  /// Clear all data when closing
  void clearData() {
    currentPet.value = null;
    medicalRecords.clear();
    vaccinations.clear();
    medicalAppointments.clear();
  }

  @override
  void onClose() {
    clearData();
    super.onClose();
  }
}
