import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:capstone_app/data/models/medical_record_model.dart';
import 'package:capstone_app/data/models/clinic_settings_model.dart';
import 'package:capstone_app/data/models/pet_model.dart';
import 'package:capstone_app/data/models/ratings_and_review_model.dart';
import 'package:capstone_app/data/models/staff_model.dart';
import 'package:capstone_app/data/provider/appwrite_provider.dart';
import 'package:appwrite/models.dart' as models;

import 'package:file_picker/file_picker.dart';

import '../models/appointment_model.dart';
import 'package:capstone_app/data/models/conversation_model.dart';
import 'package:capstone_app/data/models/message_model.dart';
import 'package:capstone_app/data/models/conversation_starter_model.dart';
import 'package:capstone_app/data/models/user_status_model.dart';

import 'package:capstone_app/data/models/id_verification_model.dart';
import 'package:capstone_app/data/models/vaccination_model.dart';

import '../models/feedback_and_report_model.dart';

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

        return staffLoginResult;
      }

      // Regular user login
      print('Regular user login...');
      final result = await appWriteProvider.login(map);

      return result;
    } catch (e) {
      print('Repository login error: $e');
      rethrow;
    }
  }

  Future<dynamic> logout(String sessionId) =>
      appWriteProvider.logout(sessionId);

  Future<models.User?> getUser() => appWriteProvider.getUser();

  Future<models.File> uploadImage(dynamic image) =>
      appWriteProvider.uploadImage(image);
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
    try {
      final docs = await appWriteProvider.getAllClinics();
      return docs.map((doc) {
        final clinic = Clinic.fromMap(doc.data);
        clinic.documentId = doc.$id;
        return clinic;
      }).toList();
    } catch (e) {
      print('Error getting all clinics: $e');
      return [];
    }
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
    try {
      final rawRecords = await appWriteProvider.getPetMedicalRecords(petId);
      return rawRecords.map((data) => MedicalRecord.fromMap(data)).toList();
    } catch (e) {
      print('Error getting pet medical records: $e');
      return [];
    }
  }

  Future<List<MedicalRecord>> getClinicMedicalRecords(String clinicId) async {
    try {
      final rawRecords = await appWriteProvider.getClinicMedicalRecords(clinicId);
      return rawRecords.map((data) => MedicalRecord.fromMap(data)).toList();
    } catch (e) {
      print('Error getting clinic medical records: $e');
      return [];
    }
  }

  Future<models.Document> createClinicSettings(ClinicSettings clinicSettings) =>
      appWriteProvider.createClinicSettings(clinicSettings.toMap());

  Future<ClinicSettings?> getClinicSettingsByClinicId(String clinicId) async {
    try {
      final doc = await appWriteProvider.getClinicSettingsByClinicId(clinicId);
      if (doc != null) {
        final settings = ClinicSettings.fromMap(doc.data);
        settings.documentId = doc.$id;
        return settings;
      }
      return null;
    } catch (e) {
      print('Error getting clinic settings: $e');
      return null;
    }
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
    try {
      final defaultSettings = ClinicSettings(clinicId: clinicId);
      final doc = await createClinicSettings(defaultSettings);
      defaultSettings.documentId = doc.$id;
      print('>>> Clinic settings initialized successfully');
      return defaultSettings;
    } catch (e) {
      print('Error initializing clinic settings: $e');
      rethrow;
    }
  }

  Future<models.Document> createConversation(Conversation conversation) =>
      appWriteProvider.createConversation(conversation.toMap());

  Future<Conversation?> getOrCreateConversation(
      String userId, String clinicId) async {
    try {
      final doc =
          await appWriteProvider.getOrCreateConversation(userId, clinicId);
      if (doc != null) {
        var conversation = Conversation.fromMap(doc.data);
        conversation = conversation.copyWith(documentId: doc.$id);
        return conversation;
      }
      return null;
    } catch (e) {
      print('Error getting or creating conversation: $e');
      return null;
    }
  }

  Future<List<Conversation>> getUserConversations(String userId) async {
    try {
      final docs = await appWriteProvider.getUserConversations(userId);
      return docs.map((doc) {
        final conversation = Conversation.fromMap(doc.data);
        return conversation.copyWith(documentId: doc.$id);
      }).toList();
    } catch (e) {
      print('Error getting user conversations: $e');
      return [];
    }
  }

  Future<List<Conversation>> getClinicConversations(String clinicId) async {
    try {
      final docs = await appWriteProvider.getClinicConversations(clinicId);
      return docs.map((doc) {
        final conversation = Conversation.fromMap(doc.data);
        return conversation.copyWith(documentId: doc.$id);
      }).toList();
    } catch (e) {
      print('Error getting clinic conversations: $e');
      return [];
    }
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
    try {
      final docs = await appWriteProvider.getConversationMessages(conversationId,
          limit: limit, lastMessageId: lastMessageId);
      return docs.map((doc) {
        final message = Message.fromMap(doc.data);
        return message.copyWith(documentId: doc.$id);
      }).toList();
    } catch (e) {
      print('Error getting conversation messages: $e');
      return [];
    }
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
    try {
      final docs = await appWriteProvider.getClinicConversationStarters(clinicId);
      return docs.map((doc) {
        final starter = ConversationStarter.fromMap(doc.data);
        return starter.copyWith(documentId: doc.$id);
      }).toList();
    } catch (e) {
      print('Error getting clinic conversation starters: $e');
      return [];
    }
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
    try {
      final doc = await appWriteProvider.getUserStatus(userId);
      if (doc != null) {
        final status = UserStatus.fromMap(doc.data);
        return status.copyWith(documentId: doc.$id);
      }
      return null;
    } catch (e) {
      print('Error getting user status: $e');
      return null;
    }
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

  Future<Map<String, dynamic>> createStaffAccount({
    required String name,
    required String username,
    required String password,
    required String clinicId,
    required List<String> authorities,
    String? department,
    String? image,
    String? phone,
    String? email,
    String? createdBy,
  }) {
    return appWriteProvider.createStaffAccount(
      name: name,
      username: username,
      password: password,
      clinicId: clinicId,
      authorities: authorities,
      department: department,
      image: image,
      phone: phone,
      email: email,
      createdBy: createdBy,
    );
  }

  Future<List<Staff>> getClinicStaff(String clinicId) async {
    try {
      final docs = await appWriteProvider.getClinicStaff(clinicId);
      return docs.map((doc) {
        final staff = Staff.fromMap(doc.data);
        staff.documentId = doc.$id;
        return staff;
      }).toList();
    } catch (e) {
      print('Error getting clinic staff: $e');
      return [];
    }
  }

  Future<Staff?> getStaffByUserId(String userId) async {
    try {
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
    } catch (e) {
      print('Error getting staff by user ID: $e');
      return null;
    }
  }

  Future<Staff?> getStaffByUsername(String username) async {
    try {
      print('>>> AUTH REPO: Getting staff by username: $username');
      final doc = await appWriteProvider.getStaffByUsername(username);
      if (doc != null) {
        final staff = Staff.fromMap(doc.data);
        staff.documentId = doc.$id;
        print('>>> AUTH REPO: Staff found by username');
        print('>>> Staff Role: ${staff.role}');
        print('>>> Staff Name: ${staff.name}');
        print('>>> Staff Username: ${staff.username}');
        return staff;
      }
      print('>>> AUTH REPO: No staff found by username');
      return null;
    } catch (e) {
      print('Error getting staff by username: $e');
      return null;
    }
  }

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
    try {
      await appWriteProvider.updateStaffAuthorities(staffDocumentId, authorities);
    } catch (e) {
      print('Error updating staff authorities: $e');
      rethrow;
    }
  }

  Future<void> updateStaffInfo({
    required String staffDocumentId,
    String? name,
    String? department,
    String? image,
    String? email,
    String? phone,
    List<String>? authorities,
  }) async {
    try {
      await appWriteProvider.updateStaffInfo(
        staffDocumentId: staffDocumentId,
        name: name,
        department: department,
        image: image,
        phone: phone,
        authorities: authorities,
      );
    } catch (e) {
      print('Error updating staff info: $e');
      rethrow;
    }
  }

  Future<void> deactivateStaffAccount(String staffDocumentId, String userId) {
    return appWriteProvider.deactivateStaffAccount(staffDocumentId, userId);
  }

  Future<void> deleteStaffAccountPermanently(String staffDocumentId) {
    return appWriteProvider.deleteStaffAccount(staffDocumentId);
  }

  Future<Map<String, dynamic>> staffLogin(String username, String password) {
    return appWriteProvider.staffLogin(username, password);
  }

  Future<bool> checkStaffAuthority(String userId, String authority) {
    return appWriteProvider.checkStaffAuthority(userId, authority);
  }

  Future<Map<String, int>> getClinicStaffStats(String clinicId) {
    return appWriteProvider.getClinicStaffStats(clinicId);
  }

  Future<Map<String, dynamic>> deleteClinicCompletely(String clinicId) {
    return appWriteProvider.deleteClinicCompletely(clinicId);
  }

  Future<Map<String, dynamic>?> getClinicWithSettings(String clinicId) {
    return appWriteProvider.getClinicWithSettings(clinicId);
  }

  Stream<RealtimeMessage> subscribeToClinicChanges() {
    return appWriteProvider.subscribeToClinicChanges();
  }

  Stream<RealtimeMessage> subscribeToClinicSettingsChanges() {
    return appWriteProvider.subscribeToClinicSettingsChanges();
  }

  Future<Document> createIdVerification(IdVerification idVerification) {
    return appWriteProvider.createIdVerification(idVerification.toMap());
  }

  Future<IdVerification?> getIdVerificationByUserId(String userId) async {
    try {
      final doc = await appWriteProvider.getIdVerificationByUserId(userId);
      if (doc != null) {
        final verification = IdVerification.fromMap(doc.data);
        verification.documentId = doc.$id;
        return verification;
      }
      return null;
    } catch (e) {
      print('Error getting ID verification: $e');
      return null;
    }
  }

  Future<IdVerification?> getIdVerificationBySubmissionId(
      String submissionId) async {
    try {
      final doc =
          await appWriteProvider.getIdVerificationBySubmissionId(submissionId);
      if (doc != null) {
        final verification = IdVerification.fromMap(doc.data);
        verification.documentId = doc.$id;
        return verification;
      }
      return null;
    } catch (e) {
      print('Error getting ID verification by submission: $e');
      return null;
    }
  }

  Future<Document> updateIdVerification(IdVerification idVerification) {
    return appWriteProvider.updateIdVerification(
      idVerification.documentId!,
      idVerification.toMap(),
    );
  }

  Future<Map<String, dynamic>> processArgosWebhook(
    Map<String, dynamic> webhookData,
  ) {
    return appWriteProvider.processArgosWebhook(webhookData);
  }

  Future<bool> isUserIdVerified(String userId) {
    return appWriteProvider.isUserIdVerified(userId);
  }

  Future<Map<String, dynamic>> getUserVerificationStatus(String userId) {
    return appWriteProvider.getUserVerificationStatus(userId);
  }

  Stream<RealtimeMessage> subscribeToIdVerification(String userId) {
    return appWriteProvider.subscribeToIdVerification(userId);
  }

  Future<void> cleanupStuckVerifications(String userId) {
    return appWriteProvider.cleanupStuckVerifications(userId);
  }

  Future<RatingAndReview> createRatingAndReview(RatingAndReview review) async {
    try {
      final doc = await appWriteProvider.createRatingAndReview(review.toMap());
      return review.copyWith(documentId: doc.$id);
    } catch (e) {
      print('Error creating rating and review: $e');
      rethrow;
    }
  }

  Future<bool> hasUserReviewedAppointment(String appointmentId) {
    return appWriteProvider.hasUserReviewedAppointment(appointmentId);
  }

  Future<List<RatingAndReview>> getClinicReviews(
    String clinicId, {
    int limit = 50,
    String? lastDocumentId,
  }) async {
    try {
      final docs = await appWriteProvider.getClinicReviews(
        clinicId,
        limit: limit,
        lastDocumentId: lastDocumentId,
      );
      return docs.map((doc) {
        final review = RatingAndReview.fromMap(doc.data);
        return review.copyWith(documentId: doc.$id);
      }).toList();
    } catch (e) {
      print('Error getting clinic reviews: $e');
      return [];
    }
  }

  Future<List<RatingAndReview>> getUserReviews(String userId) async {
    try {
      final docs = await appWriteProvider.getUserReviews(userId);
      return docs.map((doc) {
        final review = RatingAndReview.fromMap(doc.data);
        return review.copyWith(documentId: doc.$id);
      }).toList();
    } catch (e) {
      print('Error getting user reviews: $e');
      return [];
    }
  }

  Future<RatingAndReview?> getReviewByAppointmentId(
      String appointmentId) async {
    try {
      final doc = await appWriteProvider.getReviewByAppointmentId(appointmentId);
      if (doc != null) {
        final review = RatingAndReview.fromMap(doc.data);
        return review.copyWith(documentId: doc.$id);
      }
      return null;
    } catch (e) {
      print('Error getting review by appointment: $e');
      return null;
    }
  }

  Future<RatingAndReview> updateRatingAndReview(RatingAndReview review) async {
    try {
      if (review.documentId == null) {
        throw Exception('Cannot update review without documentId');
      }
      final doc = await appWriteProvider.updateRatingAndReview(
        review.documentId!,
        review.toMap(),
      );
      return RatingAndReview.fromMap(doc.data).copyWith(documentId: doc.$id);
    } catch (e) {
      print('Error updating rating and review: $e');
      rethrow;
    }
  }

  Future<void> deleteRatingAndReview(
      String documentId, List<String> imageIds) async {
    try {
      if (imageIds.isNotEmpty) {
        await appWriteProvider.deleteReviewImages(imageIds);
      }
      await appWriteProvider.deleteRatingAndReview(documentId);
    } catch (e) {
      print('Error deleting rating and review: $e');
      rethrow;
    }
  }

  Future<RatingAndReview> addClinicResponse(
    String documentId,
    String response,
  ) async {
    try {
      final doc = await appWriteProvider.addClinicResponse(documentId, response);
      return RatingAndReview.fromMap(doc.data).copyWith(documentId: doc.$id);
    } catch (e) {
      print('Error adding clinic response: $e');
      rethrow;
    }
  }

  Future<ClinicRatingStats> getClinicRatingStats(String clinicId) async {
    try {
      final stats = await appWriteProvider.getClinicRatingStats(clinicId);
      return ClinicRatingStats(
        averageRating: stats['averageRating'],
        totalReviews: stats['totalReviews'],
        ratingDistribution: Map<int, int>.from(stats['ratingDistribution']),
        reviewsWithText: stats['reviewsWithText'],
        reviewsWithImages: stats['reviewsWithImages'],
      );
    } catch (e) {
      print('Error getting clinic rating stats: $e');
      return ClinicRatingStats(
        averageRating: 0.0,
        totalReviews: 0,
        ratingDistribution: {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
        reviewsWithText: 0,
        reviewsWithImages: 0,
      );
    }
  }

  Future<List<models.File>> uploadReviewImages(List<PlatformFile> files) {
    return appWriteProvider.uploadReviewImages(files);
  }

  Future<void> deleteReviewImages(List<String> fileIds) {
    return appWriteProvider.deleteReviewImages(fileIds);
  }

  Stream<RealtimeMessage> subscribeToClinicReviews(String clinicId) {
    return appWriteProvider.subscribeToClinicReviews(clinicId);
  }

  Future<Vaccination> createVaccination(Vaccination vaccination) async {
    try {
      final doc = await appWriteProvider.createVaccination(vaccination.toMap());
      return vaccination.copyWith(documentId: doc.$id);
    } catch (e) {
      print('Error creating vaccination: $e');
      rethrow;
    }
  }

  Future<List<Vaccination>> getPetVaccinations(String petId) async {
    try {
      final rawVaccinations = await appWriteProvider.getPetVaccinations(petId);
      return rawVaccinations.map((data) => Vaccination.fromMap(data)).toList();
    } catch (e) {
      print('Error getting pet vaccinations: $e');
      return [];
    }
  }

  Future<List<Vaccination>> getClinicVaccinations(String clinicId) async {
    try {
      final rawVaccinations =
          await appWriteProvider.getClinicVaccinations(clinicId);
      return rawVaccinations.map((data) => Vaccination.fromMap(data)).toList();
    } catch (e) {
      print('Error getting clinic vaccinations: $e');
      return [];
    }
  }

  Future<Vaccination> updateVaccination(Vaccination vaccination) async {
    try {
      if (vaccination.documentId == null) {
        throw Exception('Cannot update vaccination without documentId');
      }
      final doc = await appWriteProvider.updateVaccination(
        vaccination.documentId!,
        vaccination.toMap(),
      );
      return Vaccination.fromMap(doc.data).copyWith(documentId: doc.$id);
    } catch (e) {
      print('Error updating vaccination: $e');
      rethrow;
    }
  }

  Future<void> deleteVaccination(String documentId) async {
    try {
      await appWriteProvider.deleteVaccination(documentId);
    } catch (e) {
      print('Error deleting vaccination: $e');
      rethrow;
    }
  }

  Future<FeedbackAndReport> createFeedbackAndReport(FeedbackAndReport feedback) async {
    try {
      final doc = await appWriteProvider.createFeedbackAndReport(feedback.toMap());
      return feedback.copyWith(documentId: doc.$id);
    } catch (e) {
      print('Error creating feedback and report: $e');
      rethrow;
    }
  }

  Future<List<FeedbackAndReport>> getAllFeedback({
    FeedbackStatus? status,
    Priority? priority,
    int limit = 100,
  }) async {
    try {
      final docs = await appWriteProvider.getAllFeedback(
        status: status,
        priority: priority,
        limit: limit,
      );
      return docs.map((doc) {
        final feedback = FeedbackAndReport.fromMap(doc.data);
        return feedback.copyWith(documentId: doc.$id);
      }).toList();
    } catch (e) {
      print('Error getting all feedback: $e');
      return [];
    }
  }

  Future<List<FeedbackAndReport>> getUserFeedback(String userId) async {
    try {
      final docs = await appWriteProvider.getUserFeedback(userId);
      return docs.map((doc) {
        final feedback = FeedbackAndReport.fromMap(doc.data);
        return feedback.copyWith(documentId: doc.$id);
      }).toList();
    } catch (e) {
      print('Error getting user feedback: $e');
      return [];
    }
  }

  Future<void> updateFeedbackStatus(String documentId, FeedbackStatus status) {
    return appWriteProvider.updateFeedbackStatus(documentId, status);
  }

  Future<void> updateFeedbackPriority(String documentId, Priority priority) {
    return appWriteProvider.updateFeedbackPriority(documentId, priority);
  }

  Future<void> addFeedbackReply(
    String documentId,
    String reply,
    String adminName,
  ) {
    return appWriteProvider.addFeedbackReply(documentId, reply, adminName);
  }

  Future<void> archiveFeedback(String documentId, String archivedBy) {
    return appWriteProvider.archiveFeedback(documentId, archivedBy);
  }

  Future<void> deleteFeedback(String documentId, List<String> attachmentIds) {
    return appWriteProvider.deleteFeedback(documentId, attachmentIds);
  }

  Future<List<models.File>> uploadFeedbackAttachments(List<PlatformFile> files) {
    return appWriteProvider.uploadFeedbackAttachments(files);
  }

  Future<void> deleteFeedbackAttachments(List<String> fileIds) {
    return appWriteProvider.deleteFeedbackAttachments(fileIds);
  }

  String getFeedbackAttachmentUrl(String fileId) {
    return appWriteProvider.getFeedbackAttachmentUrl(fileId);
  }

  Stream<RealtimeMessage> subscribeToFeedbackChanges() {
    return appWriteProvider.subscribeToFeedbackChanges();
  }

  Future<Map<String, int>> getFeedbackStatistics() {
    return appWriteProvider.getFeedbackStatistics();
  }
}