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

  // Cache for vet/staff names
  final RxMap<String, String> vetNamesCache = <String, String>{}.obs;

  Future<void> loadPetData(Pet pet, String clinicId) async {
    currentPet.value = pet;
    currentClinicId.value = clinicId;

    print('>>> ============================================');
    print('>>> ADMIN CARD CONTROLLER: Loading pet data');
    print('>>> Pet ID: ${pet.petId}');
    print('>>> Clinic ID: $clinicId');
    print('>>> ============================================');

    // Fetch ALL data immediately in parallel
    await Future.wait([
      fetchPetMedicalRecords(pet.petId),
      fetchPetVaccinations(pet.petId),
      fetchPetMedicalAppointmentsByClinic(pet.petId, clinicId),
    ]);

    print('>>> ✅ All pet data loaded successfully');
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

  Future<void> fetchPetMedicalRecords(String petId) async {
    isLoadingMedicalRecords.value = true;
    try {
      print('>>> ADMIN CARD: Fetching medical records for pet: $petId');

      final records = await authRepository.getPetMedicalRecords(petId);
      medicalRecords.value = records;

      print('>>> ADMIN CARD: ✅ Loaded ${records.length} medical records');

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

  /// MODIFIED: Get veterinarian/staff name with doctor/admin distinction
  Future<String> getVeterinarianName(String vetId) async {
    // Check cache first
    if (vetNamesCache.containsKey(vetId)) {
      return vetNamesCache[vetId]!;
    }

    try {
      print('>>> ============================================');
      print('>>> Fetching veterinarian name for vetId: $vetId');
      print('>>> ============================================');

      // STEP 1: Try to get staff by document ID first (most common case)
      print('>>> Step 1: Checking if vetId is a staff document ID...');
      try {
        final staffDoc = await authRepository.getStaffByDocumentId(vetId);
        if (staffDoc != null) {
          final staffName = staffDoc.name;
          final isDoctor = staffDoc.isDoctor;

          print('>>> ✅ Staff found by document ID!');
          print('>>>   Name: $staffName');
          print('>>>   Is Doctor: $isDoctor');

          // CRITICAL: Return "Dr. [Name]" if doctor, otherwise just name
          final displayName = isDoctor ? 'Dr. $staffName' : staffName;
          vetNamesCache[vetId] = displayName;
          print('>>> ✅ Returning staff name: $displayName');
          print('>>> ============================================');
          return displayName;
        }
      } catch (e) {
        print('>>> Not a staff document ID, continuing...');
      }

      // STEP 2: Check if this user is a clinic admin (by user ID)
      print('>>> Step 2: Checking if vetId is a clinic admin...');
      final clinicDoc = await authRepository.getClinicByAdminId(vetId);

      if (clinicDoc != null) {
        vetNamesCache[vetId] = 'Admin';
        print('>>> ✅ User is CLINIC ADMIN - returning "Admin"');
        print('>>> ============================================');
        return 'Admin';
      }

      // STEP 3: Get the user document to check role (by user ID)
      print('>>> Step 3: Fetching user document...');
      final userDoc = await authRepository.getUserById(vetId);

      if (userDoc == null) {
        print('>>> ❌ User document not found for vetId: $vetId');
        vetNamesCache[vetId] = 'Unknown';
        print('>>> ============================================');
        return 'Unknown';
      }

      final userRole = userDoc.data['role'] ?? '';
      final userName = userDoc.data['name'] ?? 'Unknown';

      print('>>> User found:');
      print('>>>   Name: $userName');
      print('>>>   Role: $userRole');

      // STEP 4: Check if user is staff (by user ID)
      if (userRole == 'staff') {
        print('>>> User is staff, fetching staff details by user ID...');

        try {
          final staffDoc = await authRepository.getStaffByUserId(vetId);
          if (staffDoc != null) {
            final staffName = staffDoc.name;
            final isDoctor = staffDoc.isDoctor;

            print('>>> Staff found:');
            print('>>>   Name: $staffName');
            print('>>>   Is Doctor: $isDoctor');

            // CRITICAL: Return "Dr. [Name]" if doctor, otherwise just name
            final displayName = isDoctor ? 'Dr. $staffName' : staffName;
            vetNamesCache[vetId] = displayName;
            print('>>> ✅ Returning staff name: $displayName');
            print('>>> ============================================');
            return displayName;
          } else {
            print('>>> ⚠️ Staff document not found, using user name');
            vetNamesCache[vetId] = userName;
            print('>>> ============================================');
            return userName;
          }
        } catch (e) {
          print('>>> ⚠️ Error fetching staff document: $e');
          vetNamesCache[vetId] = userName;
          print('>>> ============================================');
          return userName;
        }
      }

      // STEP 5: For any other role, return the user's name
      print('>>> User has role: $userRole, returning user name');
      vetNamesCache[vetId] = userName;
      print('>>> ============================================');
      return userName;
    } catch (e, stackTrace) {
      print('>>> ============================================');
      print('>>> ❌ ERROR fetching veterinarian name: $e');
      print('>>> Stack trace: $stackTrace');
      print('>>> ============================================');
      vetNamesCache[vetId] = 'Unknown';
      return 'Unknown';
    }
  }

  /// Get veterinarian role (for display)
  Future<String> getVeterinarianRole(String vetId) async {
    try {
      // Check if admin
      final clinicDoc = await authRepository.getClinicByAdminId(vetId);
      if (clinicDoc != null) {
        return 'Admin';
      }

      // Check if staff
      final userDoc = await authRepository.getUserById(vetId);
      if (userDoc != null && userDoc.data['role'] == 'staff') {
        final staffDoc = await authRepository.getStaffByUserId(vetId);
        if (staffDoc != null && staffDoc.isDoctor) {
          return 'Doctor';
        }
        return 'Staff';
      }

      return 'Unknown';
    } catch (e) {
      print('>>> Error getting veterinarian role: $e');
      return 'Unknown';
    }
  }

  void clearData() {
    currentPet.value = null;
    medicalRecords.clear();
    vaccinations.clear();
    medicalAppointments.clear();
    vetNamesCache.clear();
  }

  int get vaccinationCount => vaccinations.length;
  int get medicalAppointmentsCount => medicalAppointments.length;

  @override
  void onClose() {
    clearData();
    super.onClose();
  }

  Future<void> debugVetIdIssue(String vetId, String appointmentId) async {
    try {
      print('>>> ============================================');
      print('>>> DEBUGGING VET ID ISSUE');
      print('>>> VetId from medical record: $vetId');
      print('>>> Appointment ID: $appointmentId');
      print('>>> ============================================');

      // Step 1: Find the medical record
      print('>>> Step 1: Finding medical record...');
      final medicalRecord = medicalRecords.firstWhere(
        (record) => record.appointmentId == appointmentId,
        orElse: () => throw Exception('Medical record not found'),
      );

      print('>>> Medical Record Found:');
      print('>>>   Document ID: ${medicalRecord.id}');
      print('>>>   VetId stored: ${medicalRecord.vetId}');
      print('>>>   Service: ${medicalRecord.service}');
      print('>>>   Diagnosis: ${medicalRecord.diagnosis}');

      // Step 2: Get all staff in the clinic
      print('>>> ');
      print('>>> Step 2: Fetching all staff in clinic...');
      final allStaff =
          await authRepository.getClinicStaff(currentClinicId.value);

      print('>>> Found ${allStaff.length} staff members in clinic:');
      for (var staff in allStaff) {
        print('>>> ---');
        print('>>>   Staff Name: ${staff.name}');
        print('>>>   Staff Document ID: ${staff.documentId}');
        print('>>>   Staff User ID: ${staff.userId}');
        print('>>>   Is Doctor: ${staff.isDoctor}');
        print('>>>   Is Active: ${staff.isActive}');
        print(
            '>>>   Match with vetId? Document: ${staff.documentId == vetId}, User: ${staff.userId == vetId}');
      }

      // Step 3: Check if it's the admin
      print('>>> ');
      print('>>> Step 3: Checking if vetId is clinic admin...');
      final clinicDoc = await authRepository.getClinicByAdminId(vetId);
      if (clinicDoc != null) {
        print('>>> ✅ VetId IS the clinic admin!');
        print('>>>   Clinic: ${clinicDoc.data['clinicName']}');
        print('>>>   Admin ID: ${clinicDoc.data['adminId']}');
      } else {
        print('>>> ❌ VetId is NOT the clinic admin');
      }

      // Step 4: Try direct user lookup
      print('>>> ');
      print('>>> Step 4: Trying direct user lookup...');
      final userDoc = await authRepository.getUserById(vetId);
      if (userDoc != null) {
        print('>>> ✅ User document found!');
        print('>>>   Name: ${userDoc.data['name']}');
        print('>>>   Email: ${userDoc.data['email']}');
        print('>>>   Role: ${userDoc.data['role']}');
      } else {
        print('>>> ❌ No user document found with this ID');
      }

      print('>>> ============================================');
      print('>>> DEBUG COMPLETE');
      print('>>> ============================================');
    } catch (e, stackTrace) {
      print('>>> ============================================');
      print('>>> ERROR IN DEBUG: $e');
      print('>>> Stack trace: $stackTrace');
      print('>>> ============================================');
    }
  }
}
