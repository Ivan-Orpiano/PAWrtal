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
    try {
      final res = await databases!.listDocuments(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.appointmentCollectionID,
        queries: [Query.equal("userId", userId)],
      );

      return res.documents
          .map((doc) => {
                ...doc.data,
                '\$id': doc.$id,
                'createdAt': doc.$createdAt,
                'updatedAt': doc.$updatedAt,
              })
          .toList();
    } catch (e) {
      print('Error in AppWriteProvider.getUserAppointments: $e');
      return [];
    }
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
    try {
      final res = await databases!.listDocuments(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.appointmentCollectionID,
        queries: [Query.equal("clinicId", clinicId)],
      );

      return res.documents
          .map((doc) => {
                ...doc.data,
                '\$id': doc.$id,
                'createdAt': doc.$createdAt,
                'updatedAt': doc.$updatedAt,
              })
          .toList();
    } catch (e) {
      print('Error in AppWriteProvider.getClinicAppointments: $e');
      return [];
    }
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

  Future<models.File> uploadImage(dynamic image) {
    String fileName = "${DateTime.now().millisecondsSinceEpoch}.jpg";
    InputFile inputFile;

    if (image is String) {
      // Mobile path-based upload
      inputFile = InputFile.fromPath(
        path: image,
        filename: fileName,
      );
    } else if (image is InputFile) {
      // Web bytes-based upload
      inputFile = image;
    } else {
      throw Exception('Invalid image format');
    }

    final response = storage!.createFile(
      bucketId: AppwriteConstants.imageBucketID,
      fileId: ID.unique(),
      file: inputFile,
    );

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
        'userUnreadCount': 0, // Initialize both unread counts
        'clinicUnreadCount': 0,
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

    // After creating message, update conversation unread counts properly
    final conversationId = data['conversationId'];
    final senderType = data['senderType'];

    // Get current conversation
    try {
      final conversation = await databases!.getDocument(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.conversationsCollectionID,
        documentId: conversationId,
      );

      // Get current unread counts
      final currentUserUnreadCount = conversation.data['userUnreadCount'] ?? 0;
      final currentClinicUnreadCount =
          conversation.data['clinicUnreadCount'] ?? 0;

      Map<String, dynamic> updateData = {
        'lastMessageId': messageDoc.$id,
        'lastMessageText': data['messageText'],
        'lastMessageTime': data['timestamp'],
        'updatedAt': DateTime.now().toIso8601String(),
      };

      // Increment unread count for the RECEIVER only
      if (senderType == 'user') {
        // User sent message, increment clinic's unread count, keep user's count same
        updateData['clinicUnreadCount'] = currentClinicUnreadCount + 1;
        updateData['userUnreadCount'] = currentUserUnreadCount;
      } else {
        // Admin/clinic sent message, increment user's unread count, keep clinic's count same
        updateData['userUnreadCount'] = currentUserUnreadCount + 1;
        updateData['clinicUnreadCount'] = currentClinicUnreadCount;
      }

      // Update total unread count for backward compatibility
      updateData['unreadCount'] =
          updateData['userUnreadCount'] + updateData['clinicUnreadCount'];

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

      // Get current conversation to determine user type
      final conversation = await databases!.getDocument(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.conversationsCollectionID,
        documentId: conversationId,
      );

      final conversationUserId = conversation.data['userId'];
      final conversationClinicId = conversation.data['clinicId'];
      final currentUserUnreadCount = conversation.data['userUnreadCount'] ?? 0;
      final currentClinicUnreadCount =
          conversation.data['clinicUnreadCount'] ?? 0;

      Map<String, dynamic> updateData = {};

      // Determine which unread count to reset based on who is reading
      if (userId == conversationUserId) {
        // User is reading, reset their unread count
        updateData['userUnreadCount'] = 0;
        updateData['clinicUnreadCount'] =
            currentClinicUnreadCount; // Keep clinic count
      } else {
        // Admin/clinic is reading, reset their unread count
        updateData['clinicUnreadCount'] = 0;
        updateData['userUnreadCount'] =
            currentUserUnreadCount; // Keep user count
      }

      // Update total unread count for backward compatibility
      updateData['unreadCount'] =
          updateData['userUnreadCount'] + updateData['clinicUnreadCount'];

      await databases!.updateDocument(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.conversationsCollectionID,
        documentId: conversationId,
        data: updateData,
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

  Stream<RealtimeMessage> subscribeToUserAppointments(String userId) {
    final realtime = Realtime(client);
    return realtime
        .subscribe([
          'databases.${AppwriteConstants.dbID}.collections.${AppwriteConstants.appointmentCollectionID}.documents'
        ])
        .stream
        .where((message) {
          // Filter appointments for specific user
          return message.payload['userId'] == userId;
        });
  }

  Future<List<String>> getOccupiedTimeSlots(
      String clinicId, DateTime date) async {
    try {
      // Format date to start and end of day
      final startOfDay = DateTime(date.year, date.month, date.day, 0, 0, 0);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final result = await databases!.listDocuments(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.appointmentCollectionID,
        queries: [
          Query.equal("clinicId", clinicId),
          Query.greaterThanEqual("dateTime", startOfDay.toIso8601String()),
          Query.lessThanEqual("dateTime", endOfDay.toIso8601String()),
          // Only count non-cancelled appointments
          Query.notEqual("status", "cancelled"),
          Query.notEqual("status", "declined"),
          Query.notEqual("status", "no_show"),
        ],
      );

      // Extract time slots from appointments
      final List<String> occupiedSlots = [];
      for (var doc in result.documents) {
        final appointmentDateTime = DateTime.parse(doc.data['dateTime']);
        // Format time as HH:MM
        final timeString =
            '${appointmentDateTime.hour.toString().padLeft(2, '0')}:${appointmentDateTime.minute.toString().padLeft(2, '0')}';
        occupiedSlots.add(timeString);
      }

      return occupiedSlots;
    } catch (e) {
      print("Error getting occupied time slots: $e");
      return [];
    }
  }

  Stream<RealtimeMessage> subscribeToClinicAppointments(String clinicId) {
    final realtime = Realtime(client);
    return realtime
        .subscribe([
          'databases.${AppwriteConstants.dbID}.collections.${AppwriteConstants.appointmentCollectionID}.documents'
        ])
        .stream
        .where((message) {
          // Filter appointments for specific clinic
          return message.payload['clinicId'] == clinicId;
        });
  }
// ============= STAFF ACCOUNT MANAGEMENT METHODS =============

  /// Create a complete staff account - WORKING VERSION
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
  }) async {
    String? adminSessionId;

    try {
      print('=== STAFF CREATION START ===');

      // Save admin session ID before creating new user
      try {
        final sessions = await account!.listSessions();
        if (sessions.sessions.isNotEmpty) {
          adminSessionId = sessions.sessions.first.$id;
          print('Admin session saved: $adminSessionId');
        }
      } catch (e) {
        print('Could not get admin session: $e');
      }

      // Step 1: Create authentication account
      // WARNING: This logs in as the NEW user automatically
      print('Creating auth user...');
      final authUser = await account!.create(
        userId: ID.unique(),
        email: email,
        password: password,
        name: name,
      );
      print('Auth user created: ${authUser.$id}');

      // Step 2: Now we are logged in AS the new user
      // Set preferences for THIS user (the new staff member)
      print('Setting preferences...');
      try {
        await account!.updatePrefs(prefs: {
          'role': 'staff',
          'clinicId': clinicId,
          'verified': false,
        });
        print('Preferences set successfully');

        // Verify preferences were set
        final updatedUser = await account!.get();
        print('Verified role in prefs: ${updatedUser.prefs.data["role"]}');
      } catch (prefError) {
        print('ERROR setting preferences: $prefError');
        throw Exception('Failed to set user role: $prefError');
      }

      // Step 3: Create staff database record BEFORE logging out
      print('Creating staff database record...');
      final staffData = {
        'userId': authUser.$id,
        'name': name,
        'email': email,
        'phone': phone ?? '',
        'clinicId': clinicId,
        'authorities': authorities,
        'department': department ?? 'General',
        'image': image ?? '',
        'createdBy': createdBy ?? 'admin',
        'role': 'staff',
        'isActive': true,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      final staffDoc = await databases!.createDocument(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.staffCollectionID,
        documentId: ID.unique(),
        data: staffData,
      );
      print('Staff database record created: ${staffDoc.$id}');

      // Step 4: Logout the new user
      print('Logging out new user...');
      try {
        await account!.deleteSession(sessionId: 'current');
        print('New user logged out');
      } catch (e) {
        print('Warning: Could not delete new user session: $e');
      }

      print('=== STAFF CREATION SUCCESS ===');
      return {
        'success': true,
        'authUser': authUser,
        'staffDoc': staffDoc,
        'message': 'Staff account created successfully',
        'adminSessionId': adminSessionId,
      };
    } catch (e) {
      print('=== STAFF CREATION ERROR ===');
      print('Error: $e');

      // Try to logout any session that might be active
      try {
        await account!.deleteSession(sessionId: 'current');
      } catch (cleanupError) {
        print('Cleanup error: $cleanupError');
      }

      rethrow;
    }
  }

  /// Get all staff members for a specific clinic
  Future<List<Document>> getClinicStaff(String clinicId) async {
    try {
      final result = await databases!.listDocuments(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.staffCollectionID,
        queries: [
          Query.equal('clinicId', clinicId),
          Query.equal('isActive', true),
          Query.orderDesc('createdAt'),
        ],
      );
      return result.documents;
    } catch (e) {
      print('Error getting clinic staff: $e');
      return [];
    }
  }

  /// Get staff by user ID (for authentication)
  Future<Document?> getStaffByUserId(String userId) async {
    try {
      final result = await databases!.listDocuments(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.staffCollectionID,
        queries: [
          Query.equal('userId', userId),
          Query.equal('isActive', true),
        ],
      );
      return result.documents.isNotEmpty ? result.documents.first : null;
    } catch (e) {
      print('Error getting staff by user ID: $e');
      return null;
    }
  }

  /// Update staff permissions/authorities
  Future<Document> updateStaffAuthorities(
    String staffDocumentId,
    List<String> authorities,
  ) async {
    try {
      return await databases!.updateDocument(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.staffCollectionID,
        documentId: staffDocumentId,
        data: {
          'authorities': authorities,
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      print('Error updating staff authorities: $e');
      rethrow;
    }
  }

  /// Update staff information
  Future<Document> updateStaffInfo({
    required String staffDocumentId,
    String? name,
    String? department,
    String? image,
    List<String>? authorities,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updatedAt': DateTime.now().toIso8601String(),
      };

      if (name != null) updateData['name'] = name;
      if (department != null) updateData['department'] = department;
      if (image != null) updateData['image'] = image;
      if (authorities != null) updateData['authorities'] = authorities;

      return await databases!.updateDocument(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.staffCollectionID,
        documentId: staffDocumentId,
        data: updateData,
      );
    } catch (e) {
      print('Error updating staff info: $e');
      rethrow;
    }
  }

  /// Deactivate staff account (soft delete)
  Future<void> deactivateStaffAccount(
      String staffDocumentId, String userId) async {
    try {
      // Deactivate in database
      await databases!.updateDocument(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.staffCollectionID,
        documentId: staffDocumentId,
        data: {
          'isActive': false,
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );

      // Note: We don't delete the auth account to preserve data integrity
      // Admin can manually delete from Appwrite console if needed
    } catch (e) {
      print('Error deactivating staff account: $e');
      rethrow;
    }
  }

  /// Permanently delete staff account
  Future<void> deleteStaffAccount(String staffDocumentId) async {
    try {
      await databases!.deleteDocument(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.staffCollectionID,
        documentId: staffDocumentId,
      );
    } catch (e) {
      print('Error deleting staff account: $e');
      rethrow;
    }
  }

  /// Update clinic settings email template
  Future<Document> updateClinicSettingsEmailTemplate(
    String clinicSettingsDocumentId,
    String newTemplate,
  ) async {
    try {
      return await databases!.updateDocument(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.clinicSettingsCollectionID,
        documentId: clinicSettingsDocumentId,
        data: {
          'staffEmailTemplate': newTemplate,
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      print('Error updating email template: $e');
      rethrow;
    }
  }

  /// Update all staff emails when template changes
  Future<void> updateAllStaffEmailsForClinic(
    String clinicId,
    String newTemplate,
  ) async {
    try {
      // Get all staff for this clinic
      final staffList = await getClinicStaff(clinicId);

      // Update each staff email
      for (var staffDoc in staffList) {
        final staffName = staffDoc.data['name'] as String;
        final cleanName = staffName
            .toLowerCase()
            .replaceAll(RegExp(r'[^a-z0-9]'), '')
            .replaceAll(' ', '.');
        final newEmail = newTemplate.replaceAll('{name}', cleanName);

        // Update staff document
        await databases!.updateDocument(
          databaseId: AppwriteConstants.dbID,
          collectionId: AppwriteConstants.staffCollectionID,
          documentId: staffDoc.$id,
          data: {
            'email': newEmail,
            'updatedAt': DateTime.now().toIso8601String(),
          },
        );

        // Note: Appwrite doesn't allow email update for existing auth users
        // New staff will use the new template
        print('Updated email for ${staffDoc.$id} to: $newEmail');
      }
    } catch (e) {
      print('Error updating staff emails: $e');
      rethrow;
    }
  }

  /// Check if email belongs to a staff account (does NOT authenticate)
  Future<Map<String, dynamic>> checkIfStaffAccount(String email) async {
    try {
      // Just check if this email exists in staff table
      final staffResult = await databases!.listDocuments(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.staffCollectionID,
        queries: [
          Query.equal('email', email),
        ],
      );

      if (staffResult.documents.isEmpty) {
        return {
          'isStaff': false,
        };
      }

      final staffDoc = staffResult.documents.first;
      final isActive = staffDoc.data['isActive'] ?? true;

      return {
        'isStaff': true,
        'isActive': isActive,
        'staffDoc': staffDoc,
        'clinicId': staffDoc.data['clinicId'] ?? '',
      };
    } catch (e) {
      print('Error checking staff account: $e');
      return {
        'isStaff': false,
      };
    }
  }

  /// Staff login - uses regular auth, just adds staff context
  Future<Map<String, dynamic>> staffLogin(String email, String password) async {
    try {
      // First check if this is a staff account (NO authentication yet)
      final staffCheck = await checkIfStaffAccount(email);

      if (staffCheck['isStaff'] != true) {
        return {
          'success': false,
          'isStaff': false,
          'message': 'Not a staff account',
        };
      }

      // Check if staff account is active
      if (staffCheck['isActive'] != true) {
        return {
          'success': false,
          'isStaff': true,
          'message': 'Staff account is deactivated',
        };
      }

      // Now authenticate (same as regular login)
      final session = await account!.createEmailPasswordSession(
        email: email,
        password: password,
      );

      final user = await account!.get();

      // Return success with staff context
      return {
        'success': true,
        'isStaff': true,
        'session': session,
        'user': user,
        'role': 'staff',
        'clinicId': staffCheck['clinicId'],
        'staffDoc': staffCheck['staffDoc'],
        'authorities': staffCheck['staffDoc']?.data['authorities'] ?? [],
        'message': 'Staff login successful',
      };
    } catch (e) {
      print('Staff login error: $e');
      // Return the actual error for debugging
      return {
        'success': false,
        'isStaff': true, // Keep as true since we confirmed it's a staff account
        'message': 'Authentication failed: ${e.toString()}',
      };
    }
  }

  /// Check if staff has specific authority
  Future<bool> checkStaffAuthority(String userId, String authority) async {
    try {
      final staffDoc = await getStaffByUserId(userId);
      if (staffDoc == null) return false;

      final authorities = staffDoc.data['authorities'] as List<dynamic>?;
      if (authorities == null) return false;

      return authorities.contains(authority);
    } catch (e) {
      print('Error checking staff authority: $e');
      return false;
    }
  }

  /// Get staff statistics for a clinic
  Future<Map<String, int>> getClinicStaffStats(String clinicId) async {
    try {
      final allStaff = await databases!.listDocuments(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.staffCollectionID,
        queries: [Query.equal('clinicId', clinicId)],
      );

      int activeCount = 0;
      int inactiveCount = 0;

      for (var doc in allStaff.documents) {
        final isActive = doc.data['isActive'] ?? true;
        if (isActive) {
          activeCount++;
        } else {
          inactiveCount++;
        }
      }

      return {
        'total': allStaff.documents.length,
        'active': activeCount,
        'inactive': inactiveCount,
      };
    } catch (e) {
      print('Error getting staff stats: $e');
      return {'total': 0, 'active': 0, 'inactive': 0};
    }
  }
}
