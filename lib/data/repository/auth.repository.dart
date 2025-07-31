import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:capstone_app/data/models/pet_model.dart';
import 'package:capstone_app/data/provider/appwrite_provider.dart';
import 'package:appwrite/models.dart' as models;

import '../models/appointment_model.dart';

class AuthRepository {
  final AppWriteProvider appWriteProvider;
  AuthRepository(this.appWriteProvider);

  Future<models.User> signup(Map map) => appWriteProvider.signup(map);
  Future<models.Document> createUser(Map map) =>
      appWriteProvider.createUser(map);
  Future<Map<String, dynamic>> login(Map map) => appWriteProvider.login(map);
  Future<dynamic> logout(String sessionId) =>
      appWriteProvider.logout(sessionId);

  Future<models.User?> getUser() => appWriteProvider.getUser();

  Future<models.File> uploadImage(String imagePath) =>
      appWriteProvider.uploadImage(imagePath);
  Future<dynamic> deleteImage(String fileID) =>
      appWriteProvider.deleteImage(fileID);
  Future<models.Document> createStaff(Map map) =>
      appWriteProvider.createStaff(map);
  Future<models.DocumentList> getStaff() => appWriteProvider.getStaff();
  Future<models.Document> updateStaff(Map map, {String? currentImage}) {
    return appWriteProvider.updateStaff(map, currentImage: currentImage);
  }

  Future<dynamic> deleteStaff(Map map) => appWriteProvider.deleteStaff(map);

  Future<models.Document?> getClinicByAdminId(String adminId) =>
      appWriteProvider.getClinicByAdminId(adminId);

  Future<Clinic?> getClinicById(String clinicId) async {
    final doc = await appWriteProvider.getClinicById(clinicId);
    if (doc != null) {
      final clinic = Clinic.fromMap(doc.data);
      clinic.documentId = doc.$id;
      return clinic;
    }
    return null;
  }

  Future<List<Clinic>> getAllClinics() async {
    final docs = await appWriteProvider.getAllClinics();
    return docs.map((doc) {
      final clinic = Clinic.fromMap(doc.data);
      clinic.documentId = doc.$id;
      return clinic;
    }).toList();
  }

  Future<List<Appointment>> getClinicAppointments(String clinicId) async {
    final rawAppointments =
        await appWriteProvider.getClinicAppointments(clinicId);
    return rawAppointments.map((data) {
      return Appointment(
        userId: data['userId'],
        clinicId: data['clinicId'],
        petId: data['petId'],
        service: data['service'],
        dateTime: DateTime.parse(data['dateTime']),
        status: data['status'] ?? 'pending',
        notes: data['notes'],
        createdAt: DateTime.parse(data['createdAt']),
        updatedAt: DateTime.parse(data['updatedAt']),
      );
    }).toList();
  }

  Future<void> updateAppointmentStatus(String documentId, String status,
      {String? notes}) {
    return appWriteProvider.updateAppointmentStatus(documentId, status,
        notes: notes);
  }

  Future<models.Document?> getStaffByClinicId(String clinicId) =>
      appWriteProvider.getStaffByClinicId(clinicId);

  Future<models.Document?> getUserById(String userId) =>
      appWriteProvider.getUserById(userId);

  Future<models.Document> createPet(Map map) => appWriteProvider.createPet(map);

  Future<Pet?> getPetById(String petId) async {
    final doc = await appWriteProvider.getPetById(petId);
    if (doc != null) {
      return Pet.fromMap(doc.data);
    }
    return null;
  }

  Future<Pet?> getPetByName(String userId, String petName) async {
    final doc = await appWriteProvider.getPetByName(userId, petName);
    if (doc != null) {
      return Pet.fromMap(doc.data);
    }
    return null;
  }

  Future<List<models.Document>> getUserPets(String userId) =>
      appWriteProvider.getUserPets(userId);

  Future<models.Document> updatePet(Pet pet) =>
      appWriteProvider.updatePet(pet.toMap(), pet.documentId!);

  Future<void> deletePet(String documentId) =>
      appWriteProvider.deletePet(documentId);

  Future<void> createAppointment(Appointment appointment) {
    return appWriteProvider.createAppointment(appointment.toMap());
  }

  Future<List<Appointment>> getUserAppointments(String userId) async {
    final rawAppointments = await appWriteProvider.getUserAppointments(userId);
    return rawAppointments.map((data) {
      return Appointment(
        userId: data['userId'],
        clinicId: data['clinicId'],
        petId: data['petId'],
        service: data['service'],
        dateTime: DateTime.parse(data['dateTime']),
        status: data['status'] ?? 'pending',
        notes: data['notes'],
        createdAt: DateTime.parse(data['createdAt']),
        updatedAt: DateTime.parse(data['updatedAt']),
      );
    }).toList();
  }
}
