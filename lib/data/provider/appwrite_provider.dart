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

  /// Enhanced regular login - CHECK ADMIN FIRST, THEN STAFF
  Future<Map<String, dynamic>> login(Map map) async {
    try {
      final email = map["email"];
      final password = map["password"];

      print('>>> ============================================');
      print('>>> LOGIN ATTEMPT');
      print('>>> Email: $email');
      print('>>> ============================================');

      // Step 1: Create session first
      print('>>> Step 1: Creating session...');
      final session = await account!.createEmailPasswordSession(
        email: email,
        password: password,
      );
      print('>>> Session created: ${session.$id}');

      final user = await account!.get();
      print('>>> User retrieved: ${user.$id}');

      // Step 2: CRITICAL - Check if ADMIN first (highest priority)
      print('>>> Step 2: Checking if user is ADMIN...');
      final clinicDoc = await getClinicByAdminId(user.$id);

      if (clinicDoc != null) {
        print('>>> ADMIN FOUND! User is admin of clinic: ${clinicDoc.$id}');
        print('>>> Clinic name: ${clinicDoc.data['clinicName']}');

        return {
          'success': true,
          'session': session,
          'user': user,
          'role': 'admin', // Force admin role
          'clinicId': clinicDoc.$id,
          'message': 'Admin login successful',
        };
      }

      // Step 3: Check if STAFF (only if not admin)
      print('>>> Step 3: Not admin, checking if staff...');
      final staffCheck = await checkIfStaffAccount(email);

      if (staffCheck['isStaff'] == true) {
        print('>>> STAFF FOUND! Processing as staff...');

        if (staffCheck['isActive'] != true) {
          print('>>> ERROR: Staff account is deactivated');
          return {
            'success': false,
            'isStaff': true,
            'message': 'Staff account is deactivated',
          };
        }

        final staffDoc = staffCheck['staffDoc'];
        final role = staffCheck['role'] ?? 'staff';
        final clinicId = staffCheck['clinicId'] ?? '';
        final authorities = staffCheck['authorities'] ?? [];

        print('>>> Staff role: $role');
        print('>>> Staff clinic: $clinicId');
        print('>>> Staff authorities: $authorities');

        return {
          'success': true,
          'isStaff': true,
          'session': session,
          'user': user,
          'role': role,
          'clinicId': clinicId,
          'staffDoc': staffDoc,
          'authorities': authorities,
          'staffDocumentId': staffDoc?.$id ?? '',
          'message': 'Staff login successful',
        };
      }

      // Step 4: Regular user/customer
      print('>>> Step 4: Regular user login...');
      String? role = user.prefs.data["role"];
      print('>>> Role from prefs: $role');

      if (role == null || role.isEmpty) {
        print('>>> No role in prefs, checking database...');
        try {
          final userDoc = await getUserById(user.$id);
          if (userDoc != null) {
            role = userDoc.data['role'] ?? 'customer';
            print('>>> Role from database: $role');
          } else {
            print('>>> No user doc found, defaulting to customer');
            role = 'customer';
          }
        } catch (e) {
          print('>>> Error fetching from database: $e');
          role = 'customer';
        }
      }

      print('>>> Final role: $role');
      print('>>> ============================================');

      return {
        'success': true,
        'session': session,
        'user': user,
        'role': role,
        'message': 'Login successful',
      };
    } catch (e) {
      print('>>> LOGIN ERROR: $e');
      print('>>> ============================================');
      rethrow;
    }
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
      collectionId: AppwriteConstants.medicalRecordsCollectionID,
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

        if (file.bytes != null) {
          inputFile = InputFile.fromBytes(
            bytes: file.bytes!,
            filename: fileName,
          );
        } else if (file.path != null) {
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
      }
    }

    return uploadedFiles;
  }

  Future<void> deleteClinicGalleryImages(List<String> fileIds) async {
    for (String fileId in fileIds) {
      try {
        await storage!.deleteFile(
          bucketId: AppwriteConstants.imageBucketID,
          fileId: fileId,
        );
      } catch (e) {
        print("Error deleting image $fileId: $e");
      }
    }
  }

  String getImageUrl(String fileId) {
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
          : currentImage,
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

      final conversationData = {
        'userId': userId,
        'clinicId': clinicId,
        'unreadCount': 0,
        'userUnreadCount': 0,
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

    final conversationId = data['conversationId'];
    final senderType = data['senderType'];

    try {
      final conversation = await databases!.getDocument(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.conversationsCollectionID,
        documentId: conversationId,
      );

      final currentUserUnreadCount = conversation.data['userUnreadCount'] ?? 0;
      final currentClinicUnreadCount =
          conversation.data['clinicUnreadCount'] ?? 0;

      Map<String, dynamic> updateData = {
        'lastMessageId': messageDoc.$id,
        'lastMessageText': data['messageText'],
        'lastMessageTime': data['timestamp'],
        'updatedAt': DateTime.now().toIso8601String(),
      };

      if (senderType == 'user') {
        updateData['clinicUnreadCount'] = currentClinicUnreadCount + 1;
        updateData['userUnreadCount'] = currentUserUnreadCount;
      } else {
        updateData['userUnreadCount'] = currentUserUnreadCount + 1;
        updateData['clinicUnreadCount'] = currentClinicUnreadCount;
      }

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

    if (lastMessageId != null) {
      queries.add(Query.cursorBefore(lastMessageId));
    }

    final result = await databases!.listDocuments(
      databaseId: AppwriteConstants.dbID,
      collectionId: AppwriteConstants.messagesCollectionID,
      queries: queries,
    );

    return result.documents.reversed.toList();
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
      final result = await databases!.listDocuments(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.messagesCollectionID,
        queries: [
          Query.equal("conversationId", conversationId),
          Query.equal("receiverId", userId),
          Query.equal("isRead", false),
        ],
      );

      for (var doc in result.documents) {
        await databases!.updateDocument(
          databaseId: AppwriteConstants.dbID,
          collectionId: AppwriteConstants.messagesCollectionID,
          documentId: doc.$id,
          data: {'isRead': true},
        );
      }

      final conversation = await databases!.getDocument(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.conversationsCollectionID,
        documentId: conversationId,
      );

      final conversationUserId = conversation.data['userId'];
      final currentUserUnreadCount = conversation.data['userUnreadCount'] ?? 0;
      final currentClinicUnreadCount =
          conversation.data['clinicUnreadCount'] ?? 0;

      Map<String, dynamic> updateData = {};

      if (userId == conversationUserId) {
        updateData['userUnreadCount'] = 0;
        updateData['clinicUnreadCount'] = currentClinicUnreadCount;
      } else {
        updateData['clinicUnreadCount'] = 0;
        updateData['userUnreadCount'] = currentUserUnreadCount;
      }

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

  Future<void> initializeDefaultConversationStarters(String clinicId) async {
    try {
      print('Creating default conversation starters for clinic: $clinicId');

      final existing = await getClinicConversationStarters(clinicId);
      if (existing.isNotEmpty) {
        print('Clinic already has ${existing.length} starters');
        return;
      }

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
      final result = await databases!.listDocuments(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.userStatusCollectionID,
        queries: [Query.equal("userId", userId)],
      );

      if (result.documents.isNotEmpty) {
        return await databases!.updateDocument(
          databaseId: AppwriteConstants.dbID,
          collectionId: AppwriteConstants.userStatusCollectionID,
          documentId: result.documents.first.$id,
          data: data,
        );
      } else {
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

  Stream<RealtimeMessage> subscribeToMessages(String conversationId) {
    final realtime = Realtime(client);
    return realtime
        .subscribe([
          'databases.${AppwriteConstants.dbID}.collections.${AppwriteConstants.messagesCollectionID}.documents'
        ])
        .stream
        .where((message) {
          return message.payload['conversationId'] == conversationId;
        });
  }

  Stream<RealtimeMessage> subscribeToConversations(String userId) {
    final realtime = Realtime(client);
    return realtime
        .subscribe([
          'databases.${AppwriteConstants.dbID}.collections.${AppwriteConstants.conversationsCollectionID}.documents'
        ])
        .stream
        .where((message) {
          return message.payload['userId'] == userId;
        });
  }

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
          return message.payload['userId'] == userId;
        });
  }

  Future<List<String>> getOccupiedTimeSlots(
      String clinicId, DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day, 0, 0, 0);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final result = await databases!.listDocuments(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.appointmentCollectionID,
        queries: [
          Query.equal("clinicId", clinicId),
          Query.greaterThanEqual("dateTime", startOfDay.toIso8601String()),
          Query.lessThanEqual("dateTime", endOfDay.toIso8601String()),
          Query.notEqual("status", "cancelled"),
          Query.notEqual("status", "declined"),
          Query.notEqual("status", "no_show"),
        ],
      );

      final List<String> occupiedSlots = [];
      for (var doc in result.documents) {
        final appointmentDateTime = DateTime.parse(doc.data['dateTime']);
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
          return message.payload['clinicId'] == clinicId;
        });
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
  }) async {
    try {
      print('>>> ============================================');
      print('>>> STAFF ACCOUNT CREATION START');
      print('>>> ============================================');

      print('>>> Step 1: Creating Appwrite auth user...');
      final authUser = await account!.create(
        userId: ID.unique(),
        email: email,
        password: password,
        name: name,
      );
      print('>>> Auth user created: ${authUser.$id}');

      print('>>> Step 2: Creating staff database record...');
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

      print('>>> Staff data to be saved:');
      print('>>> Role: ${staffData['role']}');
      print('>>> Email: ${staffData['email']}');
      print('>>> Authorities: ${staffData['authorities']}');

      final staffDoc = await databases!.createDocument(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.staffCollectionID,
        documentId: ID.unique(),
        data: staffData,
      );
      print('>>> Staff database record created: ${staffDoc.$id}');
      print('>>> Staff role in doc: ${staffDoc.data['role']}');

      print('>>> ============================================');
      print('>>> STAFF ACCOUNT CREATION SUCCESS');
      print('>>> ============================================');

      return {
        'success': true,
        'authUser': authUser,
        'staffDoc': staffDoc,
        'message': 'Staff account created successfully',
      };
    } catch (e) {
      print('>>> ============================================');
      print('>>> STAFF ACCOUNT CREATION ERROR: $e');
      print('>>> ============================================');
      rethrow;
    }
  }

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

  Future<Document?> getStaffByUserId(String userId) async {
    try {
      print('>>> ==========================================');
      print('>>> GET STAFF BY USER ID');
      print('>>> User ID: $userId');

      final result = await databases!.listDocuments(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.staffCollectionID,
        queries: [
          Query.equal('userId', userId),
          Query.equal('isActive', true),
        ],
      );

      if (result.documents.isEmpty) {
        print('>>> No staff found for user ID: $userId');
        print('>>> ==========================================');
        return null;
      }

      final doc = result.documents.first;

      print('>>> Staff found!');
      print('>>> Document ID: ${doc.$id}');
      print('>>> Name: ${doc.data['name']}');
      print('>>> Email: ${doc.data['email']}');
      print('>>> Role: ${doc.data['role']}');
      print('>>> Clinic ID: ${doc.data['clinicId']}');
      print('>>> Authorities: ${doc.data['authorities']}');
      print('>>> Is Active: ${doc.data['isActive']}');
      print('>>> ==========================================');

      return doc;
    } catch (e) {
      print('>>> Error getting staff by user ID: $e');
      print('>>> ==========================================');
      return null;
    }
  }

  /// NEW: Get staff by email (fallback method when userId doesn't match)
  Future<Document?> getStaffByEmail(String email) async {
    try {
      print('>>> ==========================================');
      print('>>> GET STAFF BY EMAIL');
      print('>>> Email: $email');

      final result = await databases!.listDocuments(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.staffCollectionID,
        queries: [
          Query.equal('email', email),
          Query.equal('isActive', true),
        ],
      );

      if (result.documents.isEmpty) {
        print('>>> No staff found for email: $email');
        print('>>> ==========================================');
        return null;
      }

      final doc = result.documents.first;

      print('>>> Staff found by email!');
      print('>>> Document ID: ${doc.$id}');
      print('>>> Name: ${doc.data['name']}');
      print('>>> UserId in DB: ${doc.data['userId']}');
      print('>>> Email: ${doc.data['email']}');
      print('>>> Role: ${doc.data['role']}');
      print('>>> Clinic ID: ${doc.data['clinicId']}');
      print('>>> ==========================================');

      return doc;
    } catch (e) {
      print('>>> Error getting staff by email: $e');
      print('>>> ==========================================');
      return null;
    }
  }

  /// NEW: Fix userId mismatch in staff record
  Future<void> fixStaffUserId(String staffDocId, String correctUserId) async {
    try {
      print('>>> Fixing staff userId...');
      print('>>> Staff Doc ID: $staffDocId');
      print('>>> Correct User ID: $correctUserId');

      await databases!.updateDocument(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.staffCollectionID,
        documentId: staffDocId,
        data: {
          'userId': correctUserId,
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );

      print('>>> Staff userId updated successfully');
    } catch (e) {
      print('>>> Error fixing staff userId: $e');
      rethrow;
    }
  }

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

  Future<void> migrateExistingStaffRecords() async {
    try {
      print('>>> ==========================================');
      print('>>> MIGRATING EXISTING STAFF RECORDS');
      print('>>> Adding role field to all staff records');
      print('>>> ==========================================');

      final result = await databases!.listDocuments(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.staffCollectionID,
      );

      print('>>> Found ${result.documents.length} staff records');

      for (var doc in result.documents) {
        try {
          final currentRole = doc.data['role'];

          if (currentRole == null || currentRole.isEmpty) {
            print(
                '>>> Updating staff: ${doc.data['name']} (${doc.data['email']})');

            await databases!.updateDocument(
              databaseId: AppwriteConstants.dbID,
              collectionId: AppwriteConstants.staffCollectionID,
              documentId: doc.$id,
              data: {
                'role': 'staff',
                'updatedAt': DateTime.now().toIso8601String(),
              },
            );

            print('>>> Role field added successfully');
          } else {
            print(
                '>>> Staff already has role: ${doc.data['name']} - $currentRole');
          }
        } catch (e) {
          print('>>> Error updating staff ${doc.$id}: $e');
        }
      }

      print('>>> ==========================================');
      print('>>> MIGRATION COMPLETE');
      print('>>> ==========================================');
    } catch (e) {
      print('>>> Migration error: $e');
    }
  }

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

  Future<void> deactivateStaffAccount(
      String staffDocumentId, String userId) async {
    try {
      await databases!.updateDocument(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.staffCollectionID,
        documentId: staffDocumentId,
        data: {
          'isActive': false,
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      print('Error deactivating staff account: $e');
      rethrow;
    }
  }

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

  Future<void> updateAllStaffEmailsForClinic(
    String clinicId,
    String newTemplate,
  ) async {
    try {
      final staffList = await getClinicStaff(clinicId);

      for (var staffDoc in staffList) {
        final staffName = staffDoc.data['name'] as String;
        final cleanName = staffName
            .toLowerCase()
            .replaceAll(RegExp(r'[^a-z0-9]'), '')
            .replaceAll(' ', '.');
        final newEmail = newTemplate.replaceAll('{name}', cleanName);

        await databases!.updateDocument(
          databaseId: AppwriteConstants.dbID,
          collectionId: AppwriteConstants.staffCollectionID,
          documentId: staffDoc.$id,
          data: {
            'email': newEmail,
            'updatedAt': DateTime.now().toIso8601String(),
          },
        );

        print('Updated email for ${staffDoc.$id} to: $newEmail');
      }
    } catch (e) {
      print('Error updating staff emails: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> checkIfStaffAccount(String email) async {
    try {
      print('>>> Checking staff account in database for: $email');

      final staffResult = await databases!.listDocuments(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.staffCollectionID,
        queries: [
          Query.equal('email', email),
        ],
      );

      if (staffResult.documents.isEmpty) {
        print('>>> No staff account found in database');
        return {
          'isStaff': false,
        };
      }

      final staffDoc = staffResult.documents.first;
      final isActive = staffDoc.data['isActive'] ?? true;
      final role = staffDoc.data['role'] ?? 'staff';
      final clinicId = staffDoc.data['clinicId'] ?? '';
      final authorities = staffDoc.data['authorities'] ?? [];

      print('>>> Staff account found in database!');
      print('>>> Staff Document ID: ${staffDoc.$id}');
      print('>>> Is active: $isActive');
      print('>>> Role from database: $role');
      print('>>> Clinic ID: $clinicId');
      print('>>> Authorities: $authorities');

      return {
        'isStaff': true,
        'isActive': isActive,
        'staffDoc': staffDoc,
        'clinicId': clinicId,
        'role': role,
        'authorities': authorities,
      };
    } catch (e) {
      print('>>> Error checking staff account: $e');
      return {
        'isStaff': false,
      };
    }
  }

  Future<Map<String, dynamic>> staffLogin(String email, String password) async {
    try {
      print('>>> ============================================');
      print('>>> STAFF LOGIN START');
      print('>>> ============================================');
      print('>>> Email: $email');

      print('>>> Step 1: Checking if staff account in database...');
      final staffCheck = await checkIfStaffAccount(email);

      if (staffCheck['isStaff'] != true) {
        print('>>> ERROR: Not a staff account');
        return {
          'success': false,
          'isStaff': false,
          'message': 'Not a staff account',
        };
      }

      if (staffCheck['isActive'] != true) {
        print('>>> ERROR: Staff account is deactivated');
        return {
          'success': false,
          'isStaff': true,
          'message': 'Staff account is deactivated',
        };
      }

      print('>>> Step 2: Staff account confirmed and active');

      print('>>> Step 3: Creating Appwrite session...');
      final session = await account!.createEmailPasswordSession(
        email: email,
        password: password,
      );
      print('>>> Session created successfully: ${session.$id}');

      final user = await account!.get();
      print('>>> User retrieved: ${user.$id}');
      print('>>> User email: ${user.email}');

      final staffDoc = staffCheck['staffDoc'];
      final role = staffCheck['role'] ?? 'staff';
      final clinicId = staffCheck['clinicId'] ?? '';
      final authorities = staffCheck['authorities'] ?? [];

      print('>>> ============================================');
      print('>>> DATA FROM DATABASE (NOT PREFS):');
      print('>>> Role: $role');
      print('>>> Clinic ID: $clinicId');
      print('>>> Authorities: $authorities');
      print('>>> Staff Doc ID: ${staffDoc?.$id}');
      print('>>> ============================================');

      final result = {
        'success': true,
        'isStaff': true,
        'session': session,
        'user': user,
        'role': role,
        'clinicId': clinicId,
        'staffDoc': staffDoc,
        'authorities': authorities,
        'staffDocumentId': staffDoc?.$id ?? '',
        'message': 'Staff login successful',
      };

      print('>>> STAFF LOGIN SUCCESS');
      print('>>> Result role: ${result['role']}');
      print('>>> ============================================');

      return result;
    } catch (e) {
      print('>>> ============================================');
      print('>>> STAFF LOGIN ERROR');
      print('>>> Error: $e');
      print('>>> ============================================');
      return {
        'success': false,
        'isStaff': true,
        'message': 'Authentication failed: ${e.toString()}',
      };
    }
  }

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

  Future<Map<String, dynamic>> deleteClinicCompletely(String clinicId) async {
  try {
    print('=== STARTING CLINIC DELETION ===');
    print('Clinic ID: $clinicId');

    final errors = <String>[];
    final results = {
      'clinicDeleted': false,
      'settingsDeleted': false,
      'appointmentsDeleted': 0,
      'medicalRecordsDeleted': 0,
      'conversationsDeleted': 0,
      'messagesDeleted': 0,
      'staffDeleted': 0,
      'galleryImagesDeleted': 0,
      'errors': errors,
    };

    // Step 1: Get clinic settings first (for gallery images)
    try {
      final settingsDoc = await getClinicSettingsByClinicId(clinicId);
      if (settingsDoc != null) {
        // Delete all gallery images
        final gallery = List<String>.from(settingsDoc.data['gallery'] ?? []);
        for (String imageId in gallery) {
          try {
            await deleteImage(imageId);
            results['galleryImagesDeleted'] = 
                (results['galleryImagesDeleted'] as int) + 1;
          } catch (e) {
            print('Error deleting gallery image $imageId: $e');
            errors.add('Gallery image: $imageId');
          }
        }

        // Delete clinic settings document
        await deleteClinicSettings(settingsDoc.$id);
        results['settingsDeleted'] = true;
        print('✓ Clinic settings deleted');
      }
    } catch (e) {
      print('Error deleting clinic settings: $e');
      errors.add('Clinic settings: ${e.toString()}');
    }

    // Step 2: Delete all appointments
    try {
      final appointments = await databases!.listDocuments(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.appointmentCollectionID,
        queries: [Query.equal('clinicId', clinicId)],
      );

      for (var doc in appointments.documents) {
        try {
          await databases!.deleteDocument(
            databaseId: AppwriteConstants.dbID,
            collectionId: AppwriteConstants.appointmentCollectionID,
            documentId: doc.$id,
          );
          results['appointmentsDeleted'] = 
              (results['appointmentsDeleted'] as int) + 1;
        } catch (e) {
          print('Error deleting appointment ${doc.$id}: $e');
          errors.add('Appointment: ${doc.$id}');
        }
      }
      print('✓ ${results['appointmentsDeleted']} appointments deleted');
    } catch (e) {
      print('Error deleting appointments: $e');
      errors.add('Appointments: ${e.toString()}');
    }

    // Step 3: Delete all medical records
    try {
      final records = await databases!.listDocuments(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.medicalRecordsCollectionID,
        queries: [Query.equal('clinicId', clinicId)],
      );

      for (var doc in records.documents) {
        try {
          await databases!.deleteDocument(
            databaseId: AppwriteConstants.dbID,
            collectionId: AppwriteConstants.medicalRecordsCollectionID,
            documentId: doc.$id,
          );
          results['medicalRecordsDeleted'] = 
              (results['medicalRecordsDeleted'] as int) + 1;
        } catch (e) {
          print('Error deleting medical record ${doc.$id}: $e');
          errors.add('Medical record: ${doc.$id}');
        }
      }
      print('✓ ${results['medicalRecordsDeleted']} medical records deleted');
    } catch (e) {
      print('Error deleting medical records: $e');
      errors.add('Medical records: ${e.toString()}');
    }

    // Step 4: Delete all conversations and messages
    try {
      final conversations = await databases!.listDocuments(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.conversationsCollectionID,
        queries: [Query.equal('clinicId', clinicId)],
      );

      for (var conversation in conversations.documents) {
        // Delete all messages in this conversation
        try {
          final messages = await databases!.listDocuments(
            databaseId: AppwriteConstants.dbID,
            collectionId: AppwriteConstants.messagesCollectionID,
            queries: [Query.equal('conversationId', conversation.$id)],
          );

          for (var message in messages.documents) {
            try {
              await databases!.deleteDocument(
                databaseId: AppwriteConstants.dbID,
                collectionId: AppwriteConstants.messagesCollectionID,
                documentId: message.$id,
              );
              results['messagesDeleted'] = 
                  (results['messagesDeleted'] as int) + 1;
            } catch (e) {
              print('Error deleting message ${message.$id}: $e');
            }
          }

          // Delete conversation
          await databases!.deleteDocument(
            databaseId: AppwriteConstants.dbID,
            collectionId: AppwriteConstants.conversationsCollectionID,
            documentId: conversation.$id,
          );
          results['conversationsDeleted'] = 
              (results['conversationsDeleted'] as int) + 1;
        } catch (e) {
          print('Error deleting conversation ${conversation.$id}: $e');
          errors.add('Conversation: ${conversation.$id}');
        }
      }
      print('✓ ${results['conversationsDeleted']} conversations deleted');
      print('✓ ${results['messagesDeleted']} messages deleted');
    } catch (e) {
      print('Error deleting conversations: $e');
      errors.add('Conversations: ${e.toString()}');
    }

    // Step 5: Delete all conversation starters
    try {
      final starters = await databases!.listDocuments(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.conversationStartersCollectionID,
        queries: [Query.equal('clinicId', clinicId)],
      );

      for (var doc in starters.documents) {
        try {
          await databases!.deleteDocument(
            databaseId: AppwriteConstants.dbID,
            collectionId: AppwriteConstants.conversationStartersCollectionID,
            documentId: doc.$id,
          );
        } catch (e) {
          print('Error deleting conversation starter ${doc.$id}: $e');
        }
      }
      print('✓ ${starters.documents.length} conversation starters deleted');
    } catch (e) {
      print('Error deleting conversation starters: $e');
    }

    // Step 6: Deactivate all staff (don't delete to preserve data)
    try {
      final staff = await databases!.listDocuments(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.staffCollectionID,
        queries: [Query.equal('clinicId', clinicId)],
      );

      for (var doc in staff.documents) {
        try {
          await databases!.updateDocument(
            databaseId: AppwriteConstants.dbID,
            collectionId: AppwriteConstants.staffCollectionID,
            documentId: doc.$id,
            data: {
              'isActive': false,
              'updatedAt': DateTime.now().toIso8601String(),
            },
          );
          results['staffDeleted'] = (results['staffDeleted'] as int) + 1;
        } catch (e) {
          print('Error deactivating staff ${doc.$id}: $e');
          errors.add('Staff: ${doc.$id}');
        }
      }
      print('✓ ${results['staffDeleted']} staff members deactivated');
    } catch (e) {
      print('Error deactivating staff: $e');
      errors.add('Staff: ${e.toString()}');
    }

    // Step 7: Get and delete clinic main image
    try {
      final clinicDoc = await getClinicById(clinicId);
      if (clinicDoc != null) {
        final clinicImage = clinicDoc.data['image'] as String?;
        if (clinicImage != null && clinicImage.isNotEmpty) {
          try {
            await deleteImage(clinicImage);
            print('✓ Clinic main image deleted');
          } catch (e) {
            print('Error deleting clinic main image: $e');
          }
        }
      }
    } catch (e) {
      print('Error handling clinic main image: $e');
    }

    // Step 8: Finally, delete the clinic document
    try {
      await databases!.deleteDocument(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.clinicsCollectionID,
        documentId: clinicId,
      );
      results['clinicDeleted'] = true;
      print('✓ Clinic document deleted');
    } catch (e) {
      print('Error deleting clinic document: $e');
      errors.add('Clinic document: ${e.toString()}');
      throw Exception('Failed to delete clinic: ${e.toString()}');
    }

    print('=== CLINIC DELETION COMPLETE ===');
    print('Total errors: ${errors.length}');
    
    return results;
  } catch (e) {
    print('=== CLINIC DELETION FAILED ===');
    print('Error: $e');
    rethrow;
  }
}

/// Get clinic with full settings (including realtime status)
Future<Map<String, dynamic>?> getClinicWithSettings(String clinicId) async {
  try {
    final clinicDoc = await getClinicById(clinicId);
    if (clinicDoc == null) return null;

    final settingsDoc = await getClinicSettingsByClinicId(clinicId);

    return {
      'clinic': clinicDoc.data,
      'clinicDocId': clinicDoc.$id,
      'settings': settingsDoc?.data,
      'settingsDocId': settingsDoc?.$id,
    };
  } catch (e) {
    print('Error getting clinic with settings: $e');
    return null;
  }
}

/// Real-time subscription for clinic changes
Stream<RealtimeMessage> subscribeToClinicChanges() {
  final realtime = Realtime(client);
  return realtime.subscribe([
    'databases.${AppwriteConstants.dbID}.collections.${AppwriteConstants.clinicsCollectionID}.documents',
  ]).stream;
}

/// Real-time subscription for clinic settings changes
Stream<RealtimeMessage> subscribeToClinicSettingsChanges() {
  final realtime = Realtime(client);
  return realtime.subscribe([
    'databases.${AppwriteConstants.dbID}.collections.${AppwriteConstants.clinicSettingsCollectionID}.documents',
  ]).stream;
}
}
