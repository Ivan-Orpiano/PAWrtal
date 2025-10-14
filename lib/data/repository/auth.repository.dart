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

  // MODIFIED: Create staff account with username
  Future<Map<String, dynamic>> createStaffAccount({
    required String name,
    required String username, // NEW: Username instead of email
    required String password,
    required String clinicId,
    required List<String> authorities,
    String? department,
    String? image,
    String? phone,
    String? email, // OPTIONAL: For display/contact
    String? createdBy,
  }) {
    return appWriteProvider.createStaffAccount(
      name: name,
      username: username, // Pass username
      password: password,
      clinicId: clinicId,
      authorities: authorities,
      department: department,
      image: image,
      phone: phone,
      email: email, // Pass optional email
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

  // RENAMED: getStaffByEmail -> getStaffByUsername
  Future<Staff?> getStaffByUsername(String username) async {
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
    String? email,
    String? phone, // Add this
    List<String>? authorities,
  }) async {
    await appWriteProvider.updateStaffInfo(
      staffDocumentId: staffDocumentId,
      name: name,
      department: department,
      image: image,
      phone: phone, // Add this
      authorities: authorities,
    );
  }

  Future<void> deactivateStaffAccount(String staffDocumentId, String userId) {
    return appWriteProvider.deactivateStaffAccount(staffDocumentId, userId);
  }

  Future<void> deleteStaffAccountPermanently(String staffDocumentId) {
    return appWriteProvider.deleteStaffAccount(staffDocumentId);
  }

  // MODIFIED: Staff login with username
  Future<Map<String, dynamic>> staffLogin(String username, String password) {
    return appWriteProvider.staffLogin(username, password);
  }

  Future<bool> checkStaffAuthority(String userId, String authority) {
    return appWriteProvider.checkStaffAuthority(userId, authority);
  }

  Future<Map<String, int>> getClinicStaffStats(String clinicId) {
    return appWriteProvider.getClinicStaffStats(clinicId);
  }
  // Add these methods to your AuthRepository class

  /// Delete clinic completely with all associated data
  Future<Map<String, dynamic>> deleteClinicCompletely(String clinicId) {
    return appWriteProvider.deleteClinicCompletely(clinicId);
  }

  /// Get clinic with settings
  Future<Map<String, dynamic>?> getClinicWithSettings(String clinicId) {
    return appWriteProvider.getClinicWithSettings(clinicId);
  }

  /// Subscribe to clinic changes (real-time)
  Stream<RealtimeMessage> subscribeToClinicChanges() {
    return appWriteProvider.subscribeToClinicChanges();
  }

  /// Subscribe to clinic settings changes (real-time)
  Stream<RealtimeMessage> subscribeToClinicSettingsChanges() {
    return appWriteProvider.subscribeToClinicSettingsChanges();
  }

// ============= ID VERIFICATION METHODS =============

  Future<Document> createIdVerification(IdVerification idVerification) {
    return appWriteProvider.createIdVerification(idVerification.toMap());
  }

  Future<IdVerification?> getIdVerificationByUserId(String userId) async {
    final doc = await appWriteProvider.getIdVerificationByUserId(userId);
    if (doc != null) {
      final verification = IdVerification.fromMap(doc.data);
      verification.documentId = doc.$id;
      return verification;
    }
    return null;
  }

  Future<IdVerification?> getIdVerificationBySubmissionId(
      String submissionId) async {
    final doc =
        await appWriteProvider.getIdVerificationBySubmissionId(submissionId);
    if (doc != null) {
      final verification = IdVerification.fromMap(doc.data);
      verification.documentId = doc.$id;
      return verification;
    }
    return null;
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

  /// Create a new rating and review
  Future<RatingAndReview> createRatingAndReview(RatingAndReview review) async {
    final doc = await appWriteProvider.createRatingAndReview(review.toMap());
    return review.copyWith(documentId: doc.$id);
  }

  /// Check if user has already reviewed an appointment
  Future<bool> hasUserReviewedAppointment(String appointmentId) {
    return appWriteProvider.hasUserReviewedAppointment(appointmentId);
  }

  /// Get all reviews for a clinic
  Future<List<RatingAndReview>> getClinicReviews(
    String clinicId, {
    int limit = 50,
    String? lastDocumentId,
  }) async {
    final docs = await appWriteProvider.getClinicReviews(
      clinicId,
      limit: limit,
      lastDocumentId: lastDocumentId,
    );

    return docs.map((doc) {
      final review = RatingAndReview.fromMap(doc.data);
      return review.copyWith(documentId: doc.$id);
    }).toList();
  }

  /// Get reviews by a specific user
  Future<List<RatingAndReview>> getUserReviews(String userId) async {
    final docs = await appWriteProvider.getUserReviews(userId);

    return docs.map((doc) {
      final review = RatingAndReview.fromMap(doc.data);
      return review.copyWith(documentId: doc.$id);
    }).toList();
  }

  /// Get a specific review by appointment ID
  Future<RatingAndReview?> getReviewByAppointmentId(
      String appointmentId) async {
    final doc = await appWriteProvider.getReviewByAppointmentId(appointmentId);

    if (doc != null) {
      final review = RatingAndReview.fromMap(doc.data);
      return review.copyWith(documentId: doc.$id);
    }

    return null;
  }

  /// Update an existing review
  Future<RatingAndReview> updateRatingAndReview(RatingAndReview review) async {
    if (review.documentId == null) {
      throw Exception('Cannot update review without documentId');
    }

    final doc = await appWriteProvider.updateRatingAndReview(
      review.documentId!,
      review.toMap(),
    );

    return RatingAndReview.fromMap(doc.data).copyWith(documentId: doc.$id);
  }

  /// Delete a review
  Future<void> deleteRatingAndReview(
      String documentId, List<String> imageIds) async {
    // Delete review images first
    if (imageIds.isNotEmpty) {
      await appWriteProvider.deleteReviewImages(imageIds);
    }

    // Then delete the review document
    await appWriteProvider.deleteRatingAndReview(documentId);
  }

  /// Add clinic response to a review
  Future<RatingAndReview> addClinicResponse(
    String documentId,
    String response,
  ) async {
    final doc = await appWriteProvider.addClinicResponse(documentId, response);
    return RatingAndReview.fromMap(doc.data).copyWith(documentId: doc.$id);
  }

  /// Get clinic rating statistics
  Future<ClinicRatingStats> getClinicRatingStats(String clinicId) async {
    final stats = await appWriteProvider.getClinicRatingStats(clinicId);

    return ClinicRatingStats(
      averageRating: stats['averageRating'],
      totalReviews: stats['totalReviews'],
      ratingDistribution: Map<int, int>.from(stats['ratingDistribution']),
      reviewsWithText: stats['reviewsWithText'],
      reviewsWithImages: stats['reviewsWithImages'],
    );
  }

  /// Upload review images
  Future<List<models.File>> uploadReviewImages(List<PlatformFile> files) {
    return appWriteProvider.uploadReviewImages(files);
  }

  /// Delete review images
  Future<void> deleteReviewImages(List<String> fileIds) {
    return appWriteProvider.deleteReviewImages(fileIds);
  }

  /// Subscribe to clinic reviews (real-time)
  Stream<RealtimeMessage> subscribeToClinicReviews(String clinicId) {
    return appWriteProvider.subscribeToClinicReviews(clinicId);
  }

  /// Helper method to create review from appointment
  Future<RatingAndReview> createReviewFromAppointment({
    required Appointment appointment,
    required String userName,
    required double rating,
    String? reviewText,
    List<String> images = const [],
  }) async {
    // Check if already reviewed
    final alreadyReviewed =
        await hasUserReviewedAppointment(appointment.documentId!);
    if (alreadyReviewed) {
      throw Exception('This appointment has already been reviewed');
    }

    // Create the review
    final review = RatingAndReview(
      userId: appointment.userId,
      clinicId: appointment.clinicId,
      appointmentId: appointment.documentId!,
      rating: rating,
      reviewText: reviewText,
      images: images,
      userName: userName,
      petName: appointment.petId, // You might want to get actual pet name
      serviceName: appointment.service,
    );

    return await createRatingAndReview(review);
  }

  // ============= VACCINATION METHODS =============

  Future<Vaccination> createVaccination(Vaccination vaccination) async {
    final doc = await appWriteProvider.createVaccination(vaccination.toMap());
    return vaccination.copyWith(documentId: doc.$id);
  }

  Future<List<Vaccination>> getPetVaccinations(String petId) async {
    final rawVaccinations = await appWriteProvider.getPetVaccinations(petId);
    return rawVaccinations.map((data) => Vaccination.fromMap(data)).toList();
  }

  Future<List<Vaccination>> getClinicVaccinations(String clinicId) async {
    final rawVaccinations =
        await appWriteProvider.getClinicVaccinations(clinicId);
    return rawVaccinations.map((data) => Vaccination.fromMap(data)).toList();
  }

  Future<Vaccination> updateVaccination(Vaccination vaccination) async {
    if (vaccination.documentId == null) {
      throw Exception('Cannot update vaccination without documentId');
    }

    final doc = await appWriteProvider.updateVaccination(
      vaccination.documentId!,
      vaccination.toMap(),
    );

    return Vaccination.fromMap(doc.data).copyWith(documentId: doc.$id);
  }

  Future<void> deleteVaccination(String documentId) async {
    await appWriteProvider.deleteVaccination(documentId);
  }
}
