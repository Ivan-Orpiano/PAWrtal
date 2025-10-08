import 'package:appwrite/appwrite.dart';
import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:capstone_app/data/models/medical_record_model.dart';
import 'package:capstone_app/data/models/clinic_settings_model.dart';
import 'package:capstone_app/data/models/pet_model.dart';
import 'package:capstone_app/data/models/staff_model.dart';
import 'package:capstone_app/data/provider/appwrite_provider.dart';
import 'package:appwrite/models.dart' as models;

import 'package:file_picker/file_picker.dart';

import '../models/appointment_model.dart';
import 'package:capstone_app/data/models/conversation_model.dart';
import 'package:capstone_app/data/models/message_model.dart';
import 'package:capstone_app/data/models/conversation_starter_model.dart';
import 'package:capstone_app/data/models/user_status_model.dart';

class AuthRepository {
  final AppWriteProvider appWriteProvider;
  AuthRepository(this.appWriteProvider);
  Client get client => appWriteProvider.appwriteClient;

  Future<models.User> signup(Map map) => appWriteProvider.signup(map);
  Future<models.Document> createUser(Map map) =>
      appWriteProvider.createUser(map);

  Future<Map<String, dynamic>> login(Map map) async {
    try {
      final email = map["email"];
      final password = map["password"];

      print('=== AUTH REPOSITORY LOGIN ===');
      print('Email: $email');

      // First check if this is a staff account BY CHECKING DATABASE
      final staffCheck = await appWriteProvider.checkIfStaffAccount(email);

      if (staffCheck['isStaff'] == true) {
        print('Detected staff account, using staff login...');
        final staffLoginResult =
            await appWriteProvider.staffLogin(email, password);

        // Return the result directly - role is already included from database
        return staffLoginResult;
      }

      // Regular user login
      print('Regular user login...');
      final result = await appWriteProvider.login(map);

      // The result already has the role from the provider
      return result;
    } catch (e) {
      print('Repository login error: $e');
      rethrow;
    }
  }

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

  Future<models.Document?> getClinicById(String clinicId) =>
      appWriteProvider.getClinicById(clinicId);

  Future<models.Document> updateClinic(
          String documentId, Map<String, dynamic> data) =>
      appWriteProvider.updateClinic(documentId, data);

  Future<List<Clinic>> getAllClinics() async {
    final docs = await appWriteProvider.getAllClinics();
    return docs.map((doc) {
      final clinic = Clinic.fromMap(doc.data);
      clinic.documentId = doc.$id;
      return clinic;
    }).toList();
  }

  Future<List<Appointment>> getClinicAppointments(String clinicId) async {
    try {
      final rawAppointments =
          await appWriteProvider.getClinicAppointments(clinicId);
      return rawAppointments.map((data) {
        try {
          return Appointment.fromMap(Map<String, dynamic>.from(data));
        } catch (e) {
          print('Error converting appointment data: $e');
          print('Problematic data: $data');
          throw Exception('Invalid appointment data: $e');
        }
      }).toList();
    } catch (e) {
      print('Error in getClinicAppointments: $e');
      return [];
    }
  }

  Future<Map<String, int>> getClinicAppointmentStats(String clinicId) =>
      appWriteProvider.getClinicAppointmentStats(clinicId);

  Future<void> updateAppointmentStatus(String documentId, String status) {
    return appWriteProvider.updateAppointmentStatus(documentId, status);
  }

  Future<void> updateFullAppointment(
      String documentId, Map<String, dynamic> data) {
    return appWriteProvider.updateFullAppointment(documentId, data);
  }

  Future<models.Document?> getStaffByClinicId(String clinicId) =>
      appWriteProvider.getStaffByClinicId(clinicId);

  Future<models.Document?> getUserById(String userId) =>
      appWriteProvider.getUserById(userId);

  Future<models.Document> createPet(Map map) => appWriteProvider.createPet(map);

  Future<models.Document?> getPetById(String petId) =>
      appWriteProvider.getPetById(petId);

  Future<models.Document?> getPetByName(String petName) =>
      appWriteProvider.getPetByName(petName);

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
    try {
      final rawAppointments =
          await appWriteProvider.getUserAppointments(userId);
      return rawAppointments.map((data) {
        try {
          return Appointment.fromMap(Map<String, dynamic>.from(data));
        } catch (e) {
          print('Error converting appointment data: $e');
          print('Problematic data: $data');
          throw Exception('Invalid appointment data: $e');
        }
      }).toList();
    } catch (e) {
      print('Error in getUserAppointments: $e');
      return [];
    }
  }

  Future<models.Document> createMedicalRecord(MedicalRecord medicalRecord) {
    return appWriteProvider.createMedicalRecord(medicalRecord.toMap());
  }

  Future<List<MedicalRecord>> getPetMedicalRecords(String petId) async {
    final rawRecords = await appWriteProvider.getPetMedicalRecords(petId);
    return rawRecords.map((data) => MedicalRecord.fromMap(data)).toList();
  }

  Future<List<MedicalRecord>> getClinicMedicalRecords(String clinicId) async {
    final rawRecords = await appWriteProvider.getClinicMedicalRecords(clinicId);
    return rawRecords.map((data) => MedicalRecord.fromMap(data)).toList();
  }

  Future<models.Document> createClinicSettings(ClinicSettings clinicSettings) =>
      appWriteProvider.createClinicSettings(clinicSettings.toMap());

  Future<ClinicSettings?> getClinicSettingsByClinicId(String clinicId) async {
    final doc = await appWriteProvider.getClinicSettingsByClinicId(clinicId);
    if (doc != null) {
      final settings = ClinicSettings.fromMap(doc.data);
      settings.documentId = doc.$id;
      return settings;
    }
    return null;
  }

  Future<models.Document> updateClinicSettings(ClinicSettings clinicSettings) =>
      appWriteProvider.updateClinicSettings(
        clinicSettings.documentId!,
        clinicSettings.toMap(),
      );

  Future<void> deleteClinicSettings(String documentId) =>
      appWriteProvider.deleteClinicSettings(documentId);

  Future<List<models.File>> uploadClinicGalleryImages(
          List<PlatformFile> files) =>
      appWriteProvider.uploadClinicGalleryImages(files);

  Future<void> deleteClinicGalleryImages(List<String> fileIds) =>
      appWriteProvider.deleteClinicGalleryImages(fileIds);

  String getImageUrl(String fileId) => appWriteProvider.getImageUrl(fileId);

  Future<ClinicSettings> initializeClinicSettings(String clinicId) async {
    final defaultSettings = ClinicSettings(clinicId: clinicId);
    final doc = await createClinicSettings(defaultSettings);
    defaultSettings.documentId = doc.$id;
    return defaultSettings;
  }

  Future<models.Document> createConversation(Conversation conversation) =>
      appWriteProvider.createConversation(conversation.toMap());

  Future<Conversation?> getOrCreateConversation(
      String userId, String clinicId) async {
    final doc =
        await appWriteProvider.getOrCreateConversation(userId, clinicId);
    if (doc != null) {
      var conversation = Conversation.fromMap(doc.data);
      conversation = conversation.copyWith(documentId: doc.$id);
      return conversation;
    }
    return null;
  }

  Future<List<Conversation>> getUserConversations(String userId) async {
    final docs = await appWriteProvider.getUserConversations(userId);
    return docs.map((doc) {
      final conversation = Conversation.fromMap(doc.data);
      return conversation.copyWith(documentId: doc.$id);
    }).toList();
  }

  Future<List<Conversation>> getClinicConversations(String clinicId) async {
    final docs = await appWriteProvider.getClinicConversations(clinicId);
    return docs.map((doc) {
      final conversation = Conversation.fromMap(doc.data);
      return conversation.copyWith(documentId: doc.$id);
    }).toList();
  }

  Future<models.Document> updateConversation(Conversation conversation) =>
      appWriteProvider.updateConversation(
        conversation.documentId!,
        conversation.toMap(),
      );

  Future<models.Document> createMessage(Message message) =>
      appWriteProvider.createMessage(message.toMap());

  Future<List<Message>> getConversationMessages(String conversationId,
      {int limit = 50, String? lastMessageId}) async {
    final docs = await appWriteProvider.getConversationMessages(conversationId,
        limit: limit, lastMessageId: lastMessageId);
    return docs.map((doc) {
      final message = Message.fromMap(doc.data);
      return message.copyWith(documentId: doc.$id);
    }).toList();
  }

  Future<models.Document> updateMessage(Message message) =>
      appWriteProvider.updateMessage(message.documentId!, message.toMap());

  Future<void> markMessagesAsRead(String conversationId, String receiverId) =>
      appWriteProvider.markMessagesAsRead(conversationId, receiverId);

  Future<Message> sendMessage({
    required String conversationId,
    required String senderId,
    required String senderType,
    required String receiverId,
    required String messageText,
    String messageType = 'text',
    String? attachmentUrl,
  }) async {
    final message = Message(
      conversationId: conversationId,
      senderId: senderId,
      senderType: senderType,
      receiverId: receiverId,
      messageText: messageText,
      messageType: messageType,
      attachmentUrl: attachmentUrl,
    );

    final messageDoc = await createMessage(message);
    final createdMessage = message.copyWith(documentId: messageDoc.$id);

    await appWriteProvider.updateConversation(conversationId, {
      'lastMessageId': messageDoc.$id,
      'lastMessageText': messageText,
      'lastMessageTime': DateTime.now().toIso8601String(),
      'unreadCount': 1,
    });

    return createdMessage;
  }

  Future<models.Document> createConversationStarter(
          ConversationStarter starter) =>
      appWriteProvider.createConversationStarter(starter.toMap());

  Future<List<ConversationStarter>> getClinicConversationStarters(
      String clinicId) async {
    final docs = await appWriteProvider.getClinicConversationStarters(clinicId);
    return docs.map((doc) {
      final starter = ConversationStarter.fromMap(doc.data);
      return starter.copyWith(documentId: doc.$id);
    }).toList();
  }

  Future<models.Document> updateConversationStarter(
          ConversationStarter starter) =>
      appWriteProvider.updateConversationStarter(
        starter.documentId!,
        starter.toMap(),
      );

  Future<void> deleteConversationStarter(String documentId) =>
      appWriteProvider.deleteConversationStarter(documentId);

  Future<void> initializeDefaultConversationStarters(String clinicId) =>
      appWriteProvider.initializeDefaultConversationStarters(clinicId);

  Future<models.Document> createOrUpdateUserStatus(UserStatus status) =>
      appWriteProvider.createOrUpdateUserStatus(status.userId, status.toMap());

  Future<UserStatus?> getUserStatus(String userId) async {
    final doc = await appWriteProvider.getUserStatus(userId);
    if (doc != null) {
      final status = UserStatus.fromMap(doc.data);
      return status.copyWith(documentId: doc.$id);
    }
    return null;
  }

  Future<void> setUserOnline(String userId) =>
      appWriteProvider.setUserOnline(userId);

  Future<void> setUserOffline(String userId) =>
      appWriteProvider.setUserOffline(userId);

  Stream<RealtimeMessage> subscribeToMessages(String conversationId) =>
      appWriteProvider.subscribeToMessages(conversationId);

  Stream<RealtimeMessage> subscribeToConversations(String userId) =>
      appWriteProvider.subscribeToConversations(userId);

  Stream<RealtimeMessage> subscribeToUserStatus(String userId) =>
      appWriteProvider.subscribeToUserStatus(userId);

  void disposeMessageSubscriptions() =>
      appWriteProvider.disposeMessageSubscriptions();

  Future<List<Map<String, dynamic>>> getClinicsWithSettings() async {
    try {
      final clinics = await getAllClinics();
      final List<Map<String, dynamic>> clinicsWithSettings = [];

      for (final clinic in clinics) {
        final settings =
            await getClinicSettingsByClinicId(clinic.documentId ?? '');
        clinicsWithSettings.add({
          'clinic': clinic,
          'settings': settings,
        });
      }

      return clinicsWithSettings;
    } catch (e) {
      print("Error fetching clinics with settings: $e");
      return [];
    }
  }

  Stream<RealtimeMessage> subscribeToUserAppointments(String userId) {
    return appWriteProvider.subscribeToUserAppointments(userId);
  }

  Stream<RealtimeMessage> subscribeToClinicAppointments(String clinicId) {
    return appWriteProvider.subscribeToClinicAppointments(clinicId);
  }

  Future<List<String>> getOccupiedTimeSlots(String clinicId, DateTime date) {
    return appWriteProvider.getOccupiedTimeSlots(clinicId, date);
  }

  // ============= STAFF ACCOUNT MANAGEMENT METHODS =============

  Future<Map<String, dynamic>> createStaffAccount({
    required String name,
    required String email,
    required String password,
    required String clinicId,
    required List<String> authorities,
    String? department,
    String? image,
    String? phone,
    String? createdBy,
  }) {
    return appWriteProvider.createStaffAccount(
      name: name,
      email: email,
      password: password,
      clinicId: clinicId,
      authorities: authorities,
      department: department,
      image: image,
      phone: phone,
      createdBy: createdBy,
    );
  }

  Future<List<Staff>> getClinicStaff(String clinicId) async {
    final docs = await appWriteProvider.getClinicStaff(clinicId);
    return docs.map((doc) {
      final staff = Staff.fromMap(doc.data);
      staff.documentId = doc.$id;
      return staff;
    }).toList();
  }

  Future<Staff?> getStaffByUserId(String userId) async {
    print('>>> AUTH REPO: Getting staff by user ID: $userId');

    final doc = await appWriteProvider.getStaffByUserId(userId);
    if (doc != null) {
      final staff = Staff.fromMap(doc.data);
      staff.documentId = doc.$id;

      print('>>> AUTH REPO: Staff found');
      print('>>> Staff Role: ${staff.role}');
      print('>>> Staff Name: ${staff.name}');

      return staff;
    }

    print('>>> AUTH REPO: No staff found');
    return null;
  }

  /// NEW: Get staff by email (fallback method)
  Future<Staff?> getStaffByEmail(String email) async {
    print('>>> AUTH REPO: Getting staff by email: $email');

    final doc = await appWriteProvider.getStaffByEmail(email);
    if (doc != null) {
      final staff = Staff.fromMap(doc.data);
      staff.documentId = doc.$id;

      print('>>> AUTH REPO: Staff found by email');
      print('>>> Staff Role: ${staff.role}');
      print('>>> Staff Name: ${staff.name}');
      print('>>> Staff UserId: ${staff.userId}');

      return staff;
    }

    print('>>> AUTH REPO: No staff found by email');
    return null;
  }

  /// NEW: Fix userId mismatch in staff record
  Future<void> fixStaffUserId(String staffDocId, String correctUserId) {
    return appWriteProvider.fixStaffUserId(staffDocId, correctUserId);
  }

  Future<void> migrateExistingStaffRecords() {
    return appWriteProvider.migrateExistingStaffRecords();
  }

  Future<void> updateStaffAuthorities(
    String staffDocumentId,
    List<String> authorities,
  ) async {
    await appWriteProvider.updateStaffAuthorities(staffDocumentId, authorities);
  }

  Future<void> updateStaffInfo({
    required String staffDocumentId,
    String? name,
    String? department,
    String? image,
    List<String>? authorities,
  }) async {
    await appWriteProvider.updateStaffInfo(
      staffDocumentId: staffDocumentId,
      name: name,
      department: department,
      image: image,
      authorities: authorities,
    );
  }

  Future<void> deactivateStaffAccount(String staffDocumentId, String userId) {
    return appWriteProvider.deactivateStaffAccount(staffDocumentId, userId);
  }

  Future<void> deleteStaffAccountPermanently(String staffDocumentId) {
    return appWriteProvider.deleteStaffAccount(staffDocumentId);
  }

  Future<void> updateClinicSettingsEmailTemplate(
    String clinicSettingsDocumentId,
    String newTemplate,
  ) async {
    await appWriteProvider.updateClinicSettingsEmailTemplate(
      clinicSettingsDocumentId,
      newTemplate,
    );
  }

  Future<void> updateAllStaffEmailsForClinic(
    String clinicId,
    String newTemplate,
  ) {
    return appWriteProvider.updateAllStaffEmailsForClinic(
        clinicId, newTemplate);
  }

  Future<Map<String, dynamic>> staffLogin(String email, String password) {
    return appWriteProvider.staffLogin(email, password);
  }

  Future<bool> checkStaffAuthority(String userId, String authority) {
    return appWriteProvider.checkStaffAuthority(userId, authority);
  }

  Future<Map<String, int>> getClinicStaffStats(String clinicId) {
    return appWriteProvider.getClinicStaffStats(clinicId);
  }
}
