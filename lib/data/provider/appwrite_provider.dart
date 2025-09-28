import 'dart:async';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:appwrite/models.dart';
import 'package:capstone_app/utils/appwrite_constant.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:appwrite/enums.dart';

enum AuthStatus {
  uninitialized,
  authenticated,
  unauthenticated,
}

class AppWriteProvider {
  Client client = Client();
  Client get appwriteClient => client;

  Account? account;
  Storage? storage;
  Databases? databases;

  AppWriteProvider() {
    client
        .setEndpoint(AppwriteConstants.endPoint)
        .setProject(AppwriteConstants.projectID);

    account = Account(client);
    storage = Storage(client);
    databases = Databases(client);
  }

  Future<models.User> signup(Map map) async {
    try {
      final response = await account!.create(
        userId: map["userId"],
        email: map["email"],
        password: map["password"],
        name: map["name"],
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<models.Document> createUser(Map map) async {
    return await databases!.createDocument(
      databaseId: AppwriteConstants.dbID,
      collectionId: AppwriteConstants.usersCollectionID,
      documentId: ID.unique(),
      data: map,
    );
  }

  Future<Map<String, dynamic>> login(Map map) async {
    final session = await account!.createEmailPasswordSession(
      email: map["email"],
      password: map["password"],
    );

    final user = await account!.get();
    final role = user.prefs.data["role"] ?? "customer";

    return {
      "session": session,
      "user": user,
      "role": role,
    };
  }

  Future<bool> signInWithGoogle() async {
    try {
      final response = await account
          ?.createOAuth2Session(provider: OAuthProvider.google, scopes: [
        "profile",
        "email",
      ]);
      print(response);
      return true;
    } catch (e) {
      print("error: ${e.toString()}");
      return false;
    }
  }

  Future<bool> sendVerificationEmail() async {
    try {
      await account?.createVerification(url: 'http://localhost:3000/verify');
      return true;
    } catch (e) {
      debugPrint("Error sending verification email: $e");
      return false;
    }
  }

  Future<bool> sendRecoveryEmail(String email) async {
    try {
      await account?.createRecovery(
          email: email, url: "http://localhost:3000/recovery");
      return true;
    } catch (e) {
      debugPrint("Error sending recovery email: $e");
      return false;
    }
  }

  Future<void> verifyUser() async {
    try {
      final user = await account!.get();
      await account!.updatePrefs(prefs: {
        "role": user.prefs.data["role"] ?? "customer",
        "verified": true,
      });
      debugPrint("User verified successfully");
    } catch (e) {
      debugPrint("Verification error: $e");
      rethrow;
    }
  }

  Future<List<Document>> getClinics() async {
    final result = await databases!.listDocuments(
      databaseId: AppwriteConstants.dbID,
      collectionId: AppwriteConstants.clinicsCollectionID,
    );
    return result.documents;
  }

  Future<models.User?> getUser() async {
    try {
      final user = await account!.get();
      return user;
    } catch (e) {
      return null;
    }
  }

  Future<Document> createPet(Map map) async {
    return await databases!.createDocument(
      databaseId: AppwriteConstants.dbID,
      collectionId: AppwriteConstants.petsCollectionID,
      documentId: ID.unique(),
      data: map,
    );
  }

  Future<Document?> getPetById(String petId) async {
    try {
      final result = await databases!.getDocument(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.petsCollectionID,
        documentId: petId,
      );
      return result;
    } catch (e) {
      print("Error fetching pet: $e");
      return null;
    }
  }

  Future<Document?> getPetByName(String petName) async {
    try {
      final result = await databases!.listDocuments(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.petsCollectionID,
        queries: [Query.equal("name", petName)],
      );
      return result.documents.isNotEmpty ? result.documents.first : null;
    } catch (e) {
      print("Error fetching pet by name: $e");
      return null;
    }
  }

  Future<List<Document>> getUserPets(String userId) async {
    final result = await databases!.listDocuments(
      databaseId: AppwriteConstants.dbID,
      collectionId: AppwriteConstants.petsCollectionID,
      queries: [Query.equal("userId", userId)],
    );
    return result.documents;
  }

  Future<Document> updatePet(Map map, String documentId) async {
    return await databases!.updateDocument(
      databaseId: AppwriteConstants.dbID,
      collectionId: AppwriteConstants.petsCollectionID,
      documentId: documentId,
      data: map,
    );
  }

  Future<void> deletePet(String documentId) async {
    await databases!.deleteDocument(
      databaseId: AppwriteConstants.dbID,
      collectionId: AppwriteConstants.petsCollectionID,
      documentId: documentId,
    );
  }

  Future<void> createAppointment(Map<String, dynamic> data) async {
    await databases!.createDocument(
      databaseId: AppwriteConstants.dbID,
      collectionId: AppwriteConstants.appointmentCollectionID,
      documentId: ID.unique(),
      data: data,
    );
  }

  Future<List<Map<String, dynamic>>> getUserAppointments(String userId) async {
    final res = await databases!.listDocuments(
      databaseId: AppwriteConstants.dbID,
      collectionId: AppwriteConstants.appointmentCollectionID,
      queries: [Query.equal("userId", userId)],
    );

    return res.documents.map((doc) => doc.data).toList();
  }

  Future<dynamic> logout(String sessionId) async {
    final response = await account!.deleteSession(sessionId: sessionId);
    return response;
  }

  Future<bool> webLogout() async {
    try {
      await account?.deleteSession(sessionId: 'current');
      return true;
    } catch (e) {
      print('Logout error: $e');
      return false;
    }
  }

  Future<bool> isSessionValid() async {
    try {
      await account?.get();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<Document?> getClinicByAdminId(String adminId) async {
    final result = await databases!.listDocuments(
      databaseId: AppwriteConstants.dbID,
      collectionId: AppwriteConstants.clinicsCollectionID,
      queries: [Query.equal("adminId", adminId)],
    );
    return result.documents.isNotEmpty ? result.documents.first : null;
  }

  Future<Document?> getClinicById(String clinicId) async {
    try {
      final result = await databases!.getDocument(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.clinicsCollectionID,
        documentId: clinicId,
      );
      return result;
    } catch (e) {
      print("Error fetching clinic: $e");
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getClinicAppointments(
      String clinicId) async {
    final res = await databases!.listDocuments(
      databaseId: AppwriteConstants.dbID,
      collectionId: AppwriteConstants.appointmentCollectionID,
      queries: [Query.equal("clinicId", clinicId)],
    );

    return res.documents
        .map((doc) => {
              ...doc.data,
              '\$id': doc.$id, // Include document ID for updates
            })
        .toList();
  }

  Future<Map<String, int>> getClinicAppointmentStats(String clinicId) async {
    try {
      final allAppointments = await databases!.listDocuments(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.appointmentCollectionID,
        queries: [Query.equal("clinicId", clinicId)],
      );

      final now = DateTime.now();
      final thisMonth = DateTime(now.year, now.month, 1);

      int totalAppointments = allAppointments.documents.length;
      int pendingCount = 0;
      int acceptedCount = 0;
      int declinedCount = 0;
      int thisMonthCount = 0;

      for (var doc in allAppointments.documents) {
        final status = doc.data['status'] ?? 'pending';
        final createdAt = DateTime.parse(doc.data['createdAt']);

        switch (status) {
          case 'pending':
            pendingCount++;
            break;
          case 'accepted':
            acceptedCount++;
            break;
          case 'declined':
            declinedCount++;
            break;
        }

        if (createdAt.isAfter(thisMonth)) {
          thisMonthCount++;
        }
      }

      return {
        'total': totalAppointments,
        'pending': pendingCount,
        'accepted': acceptedCount,
        'declined': declinedCount,
        'thisMonth': thisMonthCount,
      };
    } catch (e) {
      print("Error getting appointment stats: $e");
      return {
        'total': 0,
        'pending': 0,
        'accepted': 0,
        'declined': 0,
        'thisMonth': 0,
      };
    }
  }

  Future<void> updateAppointmentStatus(String documentId, String status) async {
    await databases!.updateDocument(
      databaseId: AppwriteConstants.dbID,
      collectionId: AppwriteConstants.appointmentCollectionID,
      documentId: documentId,
      data: {
        'status': status,
        'updatedAt': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<void> updateFullAppointment(
      String documentId, Map<String, dynamic> data) async {
    await databases!.updateDocument(
      databaseId: AppwriteConstants.dbID,
      collectionId: AppwriteConstants.appointmentCollectionID,
      documentId: documentId,
      data: data,
    );
  }

  Future<models.Document> createMedicalRecord(Map<String, dynamic> data) async {
    return await databases!.createDocument(
      databaseId: AppwriteConstants.dbID,
      collectionId: AppwriteConstants
          .medicalRecordsCollectionID, // You'll need to add this constant
      documentId: ID.unique(),
      data: data,
    );
  }

  Future<List<Map<String, dynamic>>> getPetMedicalRecords(String petId) async {
    final res = await databases!.listDocuments(
      databaseId: AppwriteConstants.dbID,
      collectionId: AppwriteConstants.medicalRecordsCollectionID,
      queries: [Query.equal("petId", petId)],
    );

    return res.documents
        .map((doc) => {
              ...doc.data,
              '\$id': doc.$id,
            })
        .toList();
  }

  Future<List<Map<String, dynamic>>> getClinicMedicalRecords(
      String clinicId) async {
    final res = await databases!.listDocuments(
      databaseId: AppwriteConstants.dbID,
      collectionId: AppwriteConstants.medicalRecordsCollectionID,
      queries: [Query.equal("clinicId", clinicId)],
    );

    return res.documents
        .map((doc) => {
              ...doc.data,
              '\$id': doc.$id,
            })
        .toList();
  }

  Future<Document> updateClinic(
      String documentId, Map<String, dynamic> data) async {
    return await databases!.updateDocument(
      databaseId: AppwriteConstants.dbID,
      collectionId: AppwriteConstants.clinicsCollectionID,
      documentId: documentId,
      data: data,
    );
  }

  Future<List<Document>> getAllClinics() async {
    final result = await databases!.listDocuments(
      databaseId: AppwriteConstants.dbID,
      collectionId: AppwriteConstants.clinicsCollectionID,
    );
    return result.documents;
  }

  Future<Document?> getStaffByClinicId(String clinicId) async {
    final result = await databases!.listDocuments(
      databaseId: AppwriteConstants.dbID,
      collectionId: AppwriteConstants.staffCollectionID,
      queries: [Query.equal("clinicId", clinicId)],
    );
    return result.documents.isNotEmpty ? result.documents.first : null;
  }

  // ClinicSettings methods
  Future<Document> createClinicSettings(Map<String, dynamic> data) async {
    return await databases!.createDocument(
      databaseId: AppwriteConstants.dbID,
      collectionId: AppwriteConstants.clinicSettingsCollectionID,
      documentId: ID.unique(),
      data: data,
    );
  }

  Future<Document?> getClinicSettingsByClinicId(String clinicId) async {
    try {
      final result = await databases!.listDocuments(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.clinicSettingsCollectionID,
        queries: [Query.equal("clinicId", clinicId)],
      );
      return result.documents.isNotEmpty ? result.documents.first : null;
    } catch (e) {
      print("Error fetching clinic settings: $e");
      return null;
    }
  }

  Future<Document> updateClinicSettings(
      String documentId, Map<String, dynamic> data) async {
    data['updatedAt'] = DateTime.now().toIso8601String();
    return await databases!.updateDocument(
      databaseId: AppwriteConstants.dbID,
      collectionId: AppwriteConstants.clinicSettingsCollectionID,
      documentId: documentId,
      data: data,
    );
  }

  Future<void> deleteClinicSettings(String documentId) async {
    await databases!.deleteDocument(
      databaseId: AppwriteConstants.dbID,
      collectionId: AppwriteConstants.clinicSettingsCollectionID,
      documentId: documentId,
    );
  }

  // Upload multiple images for clinic gallery - handles both mobile and web
  Future<List<models.File>> uploadClinicGalleryImages(
      List<PlatformFile> files) async {
    final List<models.File> uploadedFiles = [];

    for (int i = 0; i < files.length; i++) {
      try {
        final file = files[i];
        String fileName =
            "${DateTime.now().millisecondsSinceEpoch}_$i.${file.extension ?? 'jpg'}";

        InputFile inputFile;

        // Handle web vs mobile platforms
        if (file.bytes != null) {
          // Web platform - use bytes
          inputFile = InputFile.fromBytes(
            bytes: file.bytes!,
            filename: fileName,
          );
        } else if (file.path != null) {
          // Mobile platform - use path
          inputFile = InputFile.fromPath(
            path: file.path!,
            filename: fileName,
          );
        } else {
          print("Error: File has neither bytes nor path");
          continue;
        }

        final response = await storage!.createFile(
          bucketId: AppwriteConstants.imageBucketID,
          fileId: ID.unique(),
          file: inputFile,
        );

        uploadedFiles.add(response);
      } catch (e) {
        print("Error uploading image ${files[i].name}: $e");
        // Continue with other images even if one fails
      }
    }

    return uploadedFiles;
  }

  // Delete multiple images from clinic gallery
  Future<void> deleteClinicGalleryImages(List<String> fileIds) async {
    for (String fileId in fileIds) {
      try {
        await storage!.deleteFile(
          bucketId: AppwriteConstants.imageBucketID,
          fileId: fileId,
        );
      } catch (e) {
        print("Error deleting image $fileId: $e");
        // Continue with other deletions even if one fails
      }
    }
  }

  // Get image URL from file ID with proper authentication
  String getImageUrl(String fileId) {
    // Simple, direct URL construction for public access
    final url =
        '${AppwriteConstants.endPoint}/storage/buckets/${AppwriteConstants.imageBucketID}/files/$fileId/view?project=${AppwriteConstants.projectID}';
    print("Generated URL: $url");
    return url;
  }

  Future<Document?> getUserById(String userId) async {
    final result = await databases!.listDocuments(
      databaseId: AppwriteConstants.dbID,
      collectionId: AppwriteConstants.usersCollectionID,
      queries: [Query.equal("userId", userId)],
    );
    return result.documents.isNotEmpty ? result.documents.first : null;
  }

  Future<models.File> uploadImage(String imagePath) {
    String fileName =
        "${DateTime.now().millisecondsSinceEpoch}.${imagePath.split('.').last}";

    final response = storage!.createFile(
        bucketId: AppwriteConstants.imageBucketID,
        fileId: ID.unique(),
        file: InputFile.fromPath(path: imagePath, filename: fileName));

    return response;
  }

  Future<dynamic> deleteImage(String fileId) async {
    await storage!.deleteFile(
      bucketId: AppwriteConstants.imageBucketID,
      fileId: fileId,
    );
  }

  Future<models.Document> createStaff(Map map) async {
    final response = await databases!.createDocument(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.staffCollectionID,
        documentId: ID.unique(),
        data: {
          "name": map["name"],
          "department": map["department"],
          "createdBy": map["createdBy"] ?? "unknown",
          "image": map["image"],
          "createdAt": map["createdAt"]
        });
    return response;
  }

  Future<models.DocumentList> getStaff() async {
    final response = await databases!.listDocuments(
      databaseId: AppwriteConstants.dbID,
      collectionId: AppwriteConstants.staffCollectionID,
    );
    return response;
  }

  Future<models.Document> updateStaff(Map map, {String? currentImage}) async {
    if (databases == null) throw Exception('Databases is not initialized');

    if (map["documentId"] == null || map["documentId"].isEmpty) {
      throw Exception("Document ID cannot be null or empty");
    }

    final updatedData = {
      "name": map["name"],
      "department": map["department"],
      "createdBy": map["createdBy"] ?? "unknown",
      "image": map.containsKey("image") && map["image"].isNotEmpty
          ? map["image"]
          : currentImage, // use current image if no new one is uploaded
    };

    final response = await databases!.updateDocument(
      databaseId: AppwriteConstants.dbID,
      collectionId: AppwriteConstants.staffCollectionID,
      documentId: map["documentId"],
      data: updatedData,
    );

    return response;
  }

  Future<dynamic> deleteStaff(Map map) async {
    final response = databases!.deleteDocument(
      databaseId: AppwriteConstants.dbID,
      collectionId: AppwriteConstants.staffCollectionID,
      documentId: map["documentId"],
    );

    return response;
  }

  // ============= CONVERSATION METHODS =============

  Future<Document> createConversation(Map<String, dynamic> data) async {
    return await databases!.createDocument(
      databaseId: AppwriteConstants.dbID,
      collectionId: AppwriteConstants.conversationsCollectionID,
      documentId: ID.unique(),
      data: data,
    );
  }

  Future<Document?> getOrCreateConversation(
      String userId, String clinicId) async {
    try {
      // First, try to find existing conversation
      final result = await databases!.listDocuments(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.conversationsCollectionID,
        queries: [
          Query.equal("userId", userId),
          Query.equal("clinicId", clinicId),
        ],
      );

      if (result.documents.isNotEmpty) {
        return result.documents.first;
      }

      // If no conversation exists, create new one
      final conversationData = {
        'userId': userId,
        'clinicId': clinicId,
        'unreadCount': 0,
        'isActive': true,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      return await createConversation(conversationData);
    } catch (e) {
      print("Error getting or creating conversation: $e");
      return null;
    }
  }

  Future<List<Document>> getUserConversations(String userId) async {
    final result = await databases!.listDocuments(
      databaseId: AppwriteConstants.dbID,
      collectionId: AppwriteConstants.conversationsCollectionID,
      queries: [
        Query.equal("userId", userId),
        Query.equal("isActive", true),
        Query.orderDesc("updatedAt"),
      ],
    );
    return result.documents;
  }

  Future<List<Document>> getClinicConversations(String clinicId) async {
    final result = await databases!.listDocuments(
      databaseId: AppwriteConstants.dbID,
      collectionId: AppwriteConstants.conversationsCollectionID,
      queries: [
        Query.equal("clinicId", clinicId),
        Query.equal("isActive", true),
        Query.orderDesc("updatedAt"),
      ],
    );
    return result.documents;
  }

  Future<Document> updateConversation(
      String documentId, Map<String, dynamic> data) async {
    data['updatedAt'] = DateTime.now().toIso8601String();
    return await databases!.updateDocument(
      databaseId: AppwriteConstants.dbID,
      collectionId: AppwriteConstants.conversationsCollectionID,
      documentId: documentId,
      data: data,
    );
  }

// ============= MESSAGE METHODS =============

  Future<Document> createMessage(Map<String, dynamic> data) async {
    final messageDoc = await databases!.createDocument(
      databaseId: AppwriteConstants.dbID,
      collectionId: AppwriteConstants.messagesCollectionID,
      documentId: ID.unique(),
      data: data,
    );

    // After creating message, update conversation unread count for the RECEIVER only
    final conversationId = data['conversationId'];
    final senderId = data['senderId'];
    final senderType = data['senderType'];
    final receiverId = data['receiverId'];

    // Get current conversation
    try {
      final conversation = await databases!.getDocument(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.conversationsCollectionID,
        documentId: conversationId,
      );

      // Determine which unread count to increment based on receiver type
      final currentUserUnreadCount = conversation.data['userUnreadCount'] ?? 0;
      final currentClinicUnreadCount =
          conversation.data['clinicUnreadCount'] ?? 0;

      Map<String, dynamic> updateData = {
        'lastMessageId': messageDoc.$id,
        'lastMessageText': data['messageText'],
        'lastMessageTime': data['timestamp'],
        'updatedAt': DateTime.now().toIso8601String(),
      };

      // Increment unread count for the receiver only
      if (senderType == 'user') {
        // User sent message, increment clinic unread count
        updateData['clinicUnreadCount'] = currentClinicUnreadCount + 1;
        updateData['userUnreadCount'] =
            currentUserUnreadCount; // Keep user count same
      } else {
        // Admin/clinic sent message, increment user unread count
        updateData['userUnreadCount'] = currentUserUnreadCount + 1;
        updateData['clinicUnreadCount'] =
            currentClinicUnreadCount; // Keep clinic count same
      }

      await databases!.updateDocument(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.conversationsCollectionID,
        documentId: conversationId,
        data: updateData,
      );
    } catch (e) {
      print('Error updating conversation after message: $e');
    }

    return messageDoc;
  }

  Future<List<Document>> getConversationMessages(String conversationId,
      {int limit = 50, String? lastMessageId}) async {
    List<String> queries = [
      Query.equal("conversationId", conversationId),
      Query.equal("isDeleted", false),
      Query.orderDesc("timestamp"),
      Query.limit(limit),
    ];

    // For pagination
    if (lastMessageId != null) {
      queries.add(Query.cursorBefore(lastMessageId));
    }

    final result = await databases!.listDocuments(
      databaseId: AppwriteConstants.dbID,
      collectionId: AppwriteConstants.messagesCollectionID,
      queries: queries,
    );

    return result.documents.reversed.toList(); // Reverse to show oldest first
  }

  Future<Document> updateMessage(
      String documentId, Map<String, dynamic> data) async {
    return await databases!.updateDocument(
      databaseId: AppwriteConstants.dbID,
      collectionId: AppwriteConstants.messagesCollectionID,
      documentId: documentId,
      data: data,
    );
  }

  Future<void> markMessagesAsRead(String conversationId, String userId) async {
    try {
      // Get unread messages for this user in this conversation
      final result = await databases!.listDocuments(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.messagesCollectionID,
        queries: [
          Query.equal("conversationId", conversationId),
          Query.equal("receiverId", userId), // Only messages TO this user
          Query.equal("isRead", false),
        ],
      );

      // Mark each message as read
      for (var doc in result.documents) {
        await databases!.updateDocument(
          databaseId: AppwriteConstants.dbID,
          collectionId: AppwriteConstants.messagesCollectionID,
          documentId: doc.$id,
          data: {'isRead': true},
        );
      }

      // Reset unread count to 0 for this conversation
      await databases!.updateDocument(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.conversationsCollectionID,
        documentId: conversationId,
        data: {
          'unreadCount': 0,
          // DON'T update updatedAt here to avoid reordering
        },
      );

      print(
          'Marked ${result.documents.length} messages as read for user $userId');
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

// ============= CONVERSATION STARTERS METHODS =============

  Future<Document> createConversationStarter(Map<String, dynamic> data) async {
    return await databases!.createDocument(
      databaseId: AppwriteConstants.dbID,
      collectionId: AppwriteConstants.conversationStartersCollectionID,
      documentId: ID.unique(),
      data: data,
    );
  }

  Future<List<Document>> getClinicConversationStarters(String clinicId) async {
    final result = await databases!.listDocuments(
      databaseId: AppwriteConstants.dbID,
      collectionId: AppwriteConstants.conversationStartersCollectionID,
      queries: [
        Query.equal("clinicId", clinicId),
        Query.equal("isActive", true),
        Query.orderAsc("displayOrder"),
      ],
    );
    return result.documents;
  }

  Future<Document> updateConversationStarter(
      String documentId, Map<String, dynamic> data) async {
    data['updatedAt'] = DateTime.now().toIso8601String();
    return await databases!.updateDocument(
      databaseId: AppwriteConstants.dbID,
      collectionId: AppwriteConstants.conversationStartersCollectionID,
      documentId: documentId,
      data: data,
    );
  }

  Future<void> deleteConversationStarter(String documentId) async {
    await databases!.deleteDocument(
      databaseId: AppwriteConstants.dbID,
      collectionId: AppwriteConstants.conversationStartersCollectionID,
      documentId: documentId,
    );
  }

// Initialize default conversation starters for a clinic
  Future<void> initializeDefaultConversationStarters(String clinicId) async {
    try {
      print('Creating default conversation starters for clinic: $clinicId');

      // Check if clinic already has starters
      final existing = await getClinicConversationStarters(clinicId);
      if (existing.isNotEmpty) {
        print('Clinic already has ${existing.length} starters');
        return;
      }

      // Create default starters WITHOUT starterId field - AppWrite will auto-generate document ID
      final defaultStarters = [
        {
          'clinicId': clinicId,
          'triggerText': "Book an appointment",
          'responseText':
              "I'd be happy to help you book an appointment! What type of service do you need for your pet?",
          'category': 'appointment',
          'isActive': true,
          'displayOrder': 1,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        },
        {
          'clinicId': clinicId,
          'triggerText': "What services do you offer?",
          'responseText':
              "We offer comprehensive veterinary services including general checkups, vaccinations, surgery, dental care, and emergency services. What specific service are you interested in?",
          'category': 'services',
          'isActive': true,
          'displayOrder': 2,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        },
        {
          'clinicId': clinicId,
          'triggerText': "Emergency help",
          'responseText':
              "This is an emergency situation. Please call our emergency line immediately or bring your pet to our clinic right away. For immediate assistance, contact us at our emergency number.",
          'category': 'emergency',
          'isActive': true,
          'displayOrder': 3,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        },
        {
          'clinicId': clinicId,
          'triggerText': "What are your operating hours?",
          'responseText':
              "Our regular operating hours vary by day. You can check our current hours in the clinic information. For emergencies, we have extended support available.",
          'category': 'general',
          'isActive': true,
          'displayOrder': 4,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        },
      ];

      print('Creating ${defaultStarters.length} default starters...');

      for (var starter in defaultStarters) {
        try {
          final doc = await createConversationStarter(starter);
          print(
              'Created starter: ${starter['triggerText']} with ID: ${doc.$id}');
        } catch (e) {
          print('Failed to create starter "${starter['triggerText']}": $e');
        }
      }

      print('Default conversation starters creation completed');
    } catch (e) {
      print("Error initializing default conversation starters: $e");
    }
  }

// ============= USER STATUS METHODS =============

  Future<Document> createOrUpdateUserStatus(
      String userId, Map<String, dynamic> data) async {
    try {
      // First, try to find existing status
      final result = await databases!.listDocuments(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.userStatusCollectionID,
        queries: [Query.equal("userId", userId)],
      );

      if (result.documents.isNotEmpty) {
        // Update existing status
        return await databases!.updateDocument(
          databaseId: AppwriteConstants.dbID,
          collectionId: AppwriteConstants.userStatusCollectionID,
          documentId: result.documents.first.$id,
          data: data,
        );
      } else {
        // Create new status
        data['userId'] = userId;
        return await databases!.createDocument(
          databaseId: AppwriteConstants.dbID,
          collectionId: AppwriteConstants.userStatusCollectionID,
          documentId: ID.unique(),
          data: data,
        );
      }
    } catch (e) {
      print("Error creating or updating user status: $e");
      rethrow;
    }
  }

  Future<Document?> getUserStatus(String userId) async {
    try {
      final result = await databases!.listDocuments(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.userStatusCollectionID,
        queries: [Query.equal("userId", userId)],
      );
      return result.documents.isNotEmpty ? result.documents.first : null;
    } catch (e) {
      print("Error getting user status: $e");
      return null;
    }
  }

  Future<void> setUserOnline(String userId) async {
    final data = {
      'isOnline': true,
      'status': 'online',
      'lastSeen': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
    await createOrUpdateUserStatus(userId, data);
  }

  Future<void> setUserOffline(String userId) async {
    final data = {
      'isOnline': false,
      'status': 'offline',
      'lastSeen': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
    await createOrUpdateUserStatus(userId, data);
  }

// ============= REAL-TIME SUBSCRIPTION METHODS =============

  StreamSubscription<RealtimeMessage>? _messageSubscription;
  StreamSubscription<RealtimeMessage>? _conversationSubscription;
  StreamSubscription<RealtimeMessage>? _statusSubscription;

// Subscribe to messages in a conversation
  Stream<RealtimeMessage> subscribeToMessages(String conversationId) {
    final realtime = Realtime(client);
    return realtime
        .subscribe([
          'databases.${AppwriteConstants.dbID}.collections.${AppwriteConstants.messagesCollectionID}.documents'
        ])
        .stream
        .where((message) {
          // Filter messages for specific conversation
          return message.payload['conversationId'] == conversationId;
        });
  }

// Subscribe to conversation updates
  Stream<RealtimeMessage> subscribeToConversations(String userId) {
    final realtime = Realtime(client);
    return realtime
        .subscribe([
          'databases.${AppwriteConstants.dbID}.collections.${AppwriteConstants.conversationsCollectionID}.documents'
        ])
        .stream
        .where((message) {
          // Filter conversations for specific user
          return message.payload['userId'] == userId;
        });
  }

// Subscribe to user status updates
  Stream<RealtimeMessage> subscribeToUserStatus(String userId) {
    final realtime = Realtime(client);
    return realtime
        .subscribe([
          'databases.${AppwriteConstants.dbID}.collections.${AppwriteConstants.userStatusCollectionID}.documents'
        ])
        .stream
        .where((message) {
          return message.payload['userId'] == userId;
        });
  }

// Cleanup subscriptions
  void disposeMessageSubscriptions() {
    _messageSubscription?.cancel();
    _conversationSubscription?.cancel();
    _statusSubscription?.cancel();
  }
}
