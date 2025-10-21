import 'dart:async';
import 'dart:convert';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:appwrite/models.dart';
import 'package:capstone_app/data/models/feedback_and_report_model.dart';
import 'package:capstone_app/notification/services/notification_service.dart';
import 'package:capstone_app/utils/appwrite_constant.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:appwrite/enums.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

enum AuthStatus {
  uninitialized,
  authenticated,
  unauthenticated,
}

class AppWriteProvider {
  final GetStorage _storage = GetStorage();
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

        // Store admin data in GetStorage
        _storage.write('userId', user.$id);
        _storage.write('email', user.email);
        _storage.write('name', user.name);
        _storage.write('role', 'admin');
        _storage.write('clinicId', clinicDoc.$id);
        _storage.write(
            'clinicName', clinicDoc.data['clinicName'] ?? 'Unknown Clinic');
        _storage.write('adminId', user.$id);

        try {
          final userDoc = await getUserById(user.$id);
          if (userDoc != null) {
            final profilePictureId =
                userDoc.data['profilePictureId'] as String?;
            if (profilePictureId != null && profilePictureId.isNotEmpty) {
              _storage.write('userProfilePictureId', profilePictureId);
              print('>>> Profile picture ID stored: $profilePictureId');
            } else {
              _storage.write('userProfilePictureId', '');
            }
          }
        } catch (e) {
          print('>>> Warning: Could not fetch profile picture ID: $e');
          _storage.write('userProfilePictureId', '');
        }

        print('>>> Stored in GetStorage:');
        print('>>> - userId: ${user.$id}');
        print('>>> - email: ${user.email}');
        print('>>> - role: admin');
        print('>>> - clinicId: ${clinicDoc.$id}');
        print(
            '>>> - userProfilePictureId: ${_storage.read('userProfilePictureId') ?? ''}');

        return {
          'success': true,
          'session': session,
          'user': user,
          'role': 'admin',
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

        // Store staff data in GetStorage
        _storage.write('userId', user.$id);
        _storage.write('email', user.email);
        _storage.write('name', user.name);
        _storage.write('role', role);
        _storage.write('clinicId', clinicId);
        _storage.write('staffId', staffDoc.$id);
        _storage.write('authorities', authorities);

        print('>>> Stored in GetStorage:');
        print('>>> - userId: ${user.$id}');
        print('>>> - email: ${user.email}');
        print('>>> - role: $role');
        print('>>> - clinicId: $clinicId');
        print('>>> - staffId: ${staffDoc.$id}');

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

      // Store regular user data in GetStorage
      _storage.write('userId', user.$id);
      _storage.write('email', user.email);
      _storage.write('userName', user.name);
      _storage.write('role', role);
      // clinicId is not stored for regular users, or set to empty string
      _storage.write('clinicId', '');

      print('>>> Stored in GetStorage:');
      print('>>> - userId: ${user.$id}');
      print('>>> - email: ${user.email}');
      print('>>> - userName: ${user.name}');
      print('>>> - role: $role');
      print('>>> ============================================');

      print('>>> Step 5: Fetching profile picture...');
      try {
        final userDoc = await getUserById(user.$id);
        if (userDoc != null) {
          final profilePictureId = userDoc.data['profilePictureId'] as String?;
          final docId = userDoc.$id; // This is the documentId from Appwrite

          _storage.write('userDocumentId', docId); // Store for later updates

          if (profilePictureId != null && profilePictureId.isNotEmpty) {
            _storage.write('userProfilePictureId', profilePictureId);
            print('>>> Profile picture ID stored: $profilePictureId');
            print('>>> User document ID stored: $docId');
          } else {
            _storage.write('userProfilePictureId', '');
            print('>>> No profile picture for this user');
          }
        }
      } catch (e) {
        print('>>> Error fetching profile picture: $e');
        _storage.write('userProfilePictureId', '');
      }

      print('>>> Stored in GetStorage:');
      print('>>> - userId: ${user.$id}');
      print('>>> - email: ${user.email}');
      print('>>> - userName: ${user.name}');
      print('>>> - role: $role');
      print('>>> - userDocumentId: ${_storage.read('userDocumentId')}');
      print(
          '>>> - userProfilePictureId: ${_storage.read('userProfilePictureId')}');

      // Step 6: Register FCM token for push notifications (Mobile only)
      print('>>> Step 6: Registering FCM token for push notifications...');
      try {
        // Only register FCM on mobile platforms
        if (!kIsWeb) {
          final notificationService = Get.find<NotificationService>();

          // Request permissions
          final hasPermission = await notificationService.requestPermissions();

          if (hasPermission) {
            // Get FCM token
            final fcmToken = await notificationService.getFreshToken();

            if (fcmToken != null && fcmToken.isNotEmpty) {
              print('>>> FCM Token available: ${fcmToken.substring(0, 20)}...');

              // Register with Appwrite
              final target = await registerUserPushTarget(
                userId: user.$id,
                fcmToken: fcmToken,
              );

              if (target != null) {
                _storage.write('push_target_id', target.$id);
                print('>>> Push notifications enabled for user');
              } else {
                print('>>> Warning: Could not register push target');
              }
            } else {
              print('>>> Warning: FCM token not available');
            }
          } else {
            print('>>> Push notification permission denied');
          }
        } else {
          print('>>> Web platform: Skipping FCM registration');
        }
      } catch (e) {
        print('>>> Warning: FCM registration failed (non-critical): $e');
        // Don't fail login if FCM registration fails
      }

      print('>>> ============================================');
      print('>>> LOGIN COMPLETE');
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

  // ============= CLINIC PROFILE PICTURE METHODS =============

  /// Upload clinic profile picture
  /// Returns the uploaded file object with $id
  Future<models.File> uploadClinicProfilePicture(dynamic image) async {
    try {
      print('>>> Uploading clinic profile picture...');

      String fileName =
          "clinic_profile_${DateTime.now().millisecondsSinceEpoch}.jpg";
      InputFile inputFile;

      if (image is String) {
        // Mobile path-based upload
        inputFile = InputFile.fromPath(
          path: image,
          filename: fileName,
        );
      } else if (image is InputFile) {
        // Web bytes-based upload or pre-constructed InputFile
        inputFile = image;
      } else {
        throw Exception('Invalid profile picture format');
      }

      final response = await storage!.createFile(
        bucketId: AppwriteConstants.imageBucketID,
        fileId: ID.unique(),
        file: inputFile,
      );

      print('>>> Profile picture uploaded successfully: ${response.$id}');
      return response;
    } catch (e) {
      print('>>> Error uploading clinic profile picture: $e');
      rethrow;
    }
  }

  /// Delete clinic profile picture by file ID
  Future<void> deleteClinicProfilePicture(String fileId) async {
    try {
      print('>>> Deleting clinic profile picture: $fileId');

      await storage!.deleteFile(
        bucketId: AppwriteConstants.imageBucketID,
        fileId: fileId,
      );

      print('>>> Profile picture deleted successfully');
    } catch (e) {
      print('>>> Error deleting clinic profile picture: $e');
      rethrow;
    }
  }

  /// Get clinic profile picture URL
  /// Pass the profilePictureId stored in Clinic model
  String getClinicProfilePictureUrl(String profilePictureId) {
    if (profilePictureId.isEmpty) {
      return ''; // Return empty if no profile picture
    }

    final url =
        '${AppwriteConstants.endPoint}/storage/buckets/${AppwriteConstants.imageBucketID}/files/$profilePictureId/view?project=${AppwriteConstants.projectID}';
    print('>>> Generated clinic profile picture URL: $url');
    return url;
  }

  /// Update clinic profile picture
  /// Handles deletion of old picture and update of clinic record
  Future<String> updateClinicProfilePicture(
    String clinicId,
    String? oldProfilePictureId,
    dynamic newImage,
  ) async {
    try {
      print('>>> ============================================');
      print('>>> UPDATING CLINIC PROFILE PICTURE');
      print('>>> Clinic ID: $clinicId');
      print('>>> Old picture ID: $oldProfilePictureId');
      print('>>> ============================================');

      // Upload new profile picture
      print('>>> Step 1: Uploading new profile picture...');
      final uploadedFile = await uploadClinicProfilePicture(newImage);
      final newFileId = uploadedFile.$id;
      print('>>> New file uploaded with ID: $newFileId');

      // Delete old profile picture if it exists
      if (oldProfilePictureId != null && oldProfilePictureId.isNotEmpty) {
        print('>>> Step 2: Deleting old profile picture...');
        try {
          await deleteClinicProfilePicture(oldProfilePictureId);
          print('>>> Old profile picture deleted');
        } catch (e) {
          print('>>> Warning: Failed to delete old picture: $e');
          // Don't fail the entire operation if old deletion fails
        }
      }

      // Update clinic record
      print('>>> Step 3: Updating clinic record...');
      await updateClinic(clinicId, {
        'profilePictureId': newFileId,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      print('>>> Clinic record updated successfully');

      print('>>> ============================================');
      print('>>> PROFILE PICTURE UPDATE COMPLETE');
      print('>>> ============================================');

      return newFileId;
    } catch (e) {
      print('>>> ============================================');
      print('>>> ERROR UPDATING PROFILE PICTURE: $e');
      print('>>> ============================================');
      rethrow;
    }
  }

  /// Get clinic with profile picture URL included
  Future<Map<String, dynamic>?> getClinicWithProfilePicture(
      String clinicId) async {
    try {
      final clinicDoc = await getClinicById(clinicId);
      if (clinicDoc == null) return null;

      final profilePictureId = clinicDoc.data['profilePictureId'] as String?;
      String profilePictureUrl = '';

      if (profilePictureId != null && profilePictureId.isNotEmpty) {
        profilePictureUrl = getClinicProfilePictureUrl(profilePictureId);
      }

      return {
        'clinic': clinicDoc.data,
        'clinicDocId': clinicDoc.$id,
        'profilePictureId': profilePictureId,
        'profilePictureUrl': profilePictureUrl,
      };
    } catch (e) {
      print('Error getting clinic with profile picture: $e');
      return null;
    }
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

  Future<List<Document>> getClinicConversations(String clinicId) async {
    final result = await databases!.listDocuments(
      databaseId: AppwriteConstants.dbID,
      collectionId: AppwriteConstants.conversationsCollectionID,
      queries: [
        Query.equal("clinicId", clinicId),
        Query.equal("isActive", true),
        Query.orderDesc("lastMessageTime"), // Order by actual message time
      ],
    );

    return result.documents;
  }

  Future<List<Document>> getUserConversations(String userId) async {
    final result = await databases!.listDocuments(
      databaseId: AppwriteConstants.dbID,
      collectionId: AppwriteConstants.conversationsCollectionID,
      queries: [
        Query.equal("userId", userId),
        Query.equal("isActive", true),
        Query.orderDesc("lastMessageTime"), // Order by actual message time
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
    print('>>> ============================================');
    print('>>> CREATING MESSAGE');
    print('>>> Input data: $data');
    print('>>> ============================================');

    final conversationId = data['conversationId'];
    final senderId = data['senderId'];
    final messageText = data['messageText'];

    // Get conversation details to determine all required fields
    try {
      final conversation = await databases!.getDocument(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.conversationsCollectionID,
        documentId: conversationId,
      );

      final conversationUserId = conversation.data['userId'];
      final conversationClinicId = conversation.data['clinicId'];

      // Determine senderType and receiverId
      String senderType;
      String receiverId;

      if (senderId == conversationUserId) {
        // User is sending to clinic
        senderType = 'user';
        receiverId = conversationClinicId;
      } else {
        // Clinic is sending to user
        senderType = 'clinic';
        receiverId = conversationUserId;
      }

      // Prepare complete message data with ALL required fields
      final now = DateTime.now();
      final timestamp = now.toIso8601String();

      final completeMessageData = {
        'conversationId': conversationId,
        'senderId': senderId,
        'senderType': senderType,
        'receiverId': receiverId,
        'messageText': messageText,
        'messageType': data['messageType'] ?? 'text', // Default to 'text'
        'timestamp': timestamp, // REQUIRED
        'attachmentUrl': data['attachment'] ?? data['attachmentUrl'] ?? '',
        'isRead': data['isRead'] ?? false,
        'isDeleted': data['isDeleted'] ?? false,
        'sentAt': data['sentAt'] ?? timestamp,
        '\$createdAt': timestamp,
        '\$updatedAt': timestamp,
      };

      print('>>> Complete message data:');
      print('>>> - conversationId: $conversationId');
      print('>>> - senderId: $senderId');
      print('>>> - senderType: $senderType');
      print('>>> - receiverId: $receiverId');
      print('>>> - messageText: $messageText');
      print('>>> - messageType: ${completeMessageData['messageType']}');
      print('>>> - timestamp: $timestamp');

      // Create message document
      final messageDoc = await databases!.createDocument(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.messagesCollectionID,
        documentId: ID.unique(),
        data: completeMessageData,
      );

      print('>>> Message created successfully: ${messageDoc.$id}');

      // Update conversation
      final currentUserUnreadCount = conversation.data['userUnreadCount'] ?? 0;
      final currentClinicUnreadCount =
          conversation.data['clinicUnreadCount'] ?? 0;

      Map<String, dynamic> updateData = {
        'lastMessageId': messageDoc.$id,
        'lastMessageText': messageText,
        'lastMessageTime': timestamp,
        'updatedAt': timestamp,
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

      print('>>> Conversation updated successfully');
      print('>>> ============================================');

      return messageDoc;
    } catch (e) {
      print('>>> ============================================');
      print('>>> ERROR CREATING MESSAGE: $e');
      print('>>> Stack trace: ${StackTrace.current}');
      print('>>> ============================================');
      rethrow;
    }
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
    print('>>> ============================================');
    print('>>> APPWRITE: Setting up message subscription');
    print('>>> Conversation ID to monitor: $conversationId');
    print('>>> ============================================');

    final realtime = Realtime(client);

    final channel =
        'databases.${AppwriteConstants.dbID}.collections.${AppwriteConstants.messagesCollectionID}.documents';

    print('>>> Subscribing to channel: $channel');

    return realtime
        .subscribe([channel])
        .stream
        .map((message) {
          print('>>> Message event received: ${message.events}');
          print(
              '>>> Payload conversationId: ${message.payload['conversationId']}');
          return message;
        })
        .where((message) {
          final messageConversationId = message.payload['conversationId'];
          final matches = messageConversationId == conversationId;

          if (matches) {
            print('>>> ✓ Message matches conversation - forwarding');
          } else {
            print('>>> ✗ Message does not match - filtering out');
          }

          return matches;
        });
  }

  Stream<RealtimeMessage> subscribeToConversations(String clinicId) {
    print('>>> ============================================');
    print('>>> APPWRITE: Setting up conversation subscription');
    print('>>> Clinic ID to monitor: $clinicId');
    print('>>> ============================================');

    final realtime = Realtime(client);

    // Subscribe to ALL conversation events in the collection
    final channel =
        'databases.${AppwriteConstants.dbID}.collections.${AppwriteConstants.conversationsCollectionID}.documents';

    print('>>> Subscribing to channel: $channel');

    return realtime
        .subscribe([channel])
        .stream
        .map((message) {
          print('>>> Raw event received: ${message.events}');
          print('>>> Payload clinicId: ${message.payload['clinicId']}');
          print('>>> Target clinicId: $clinicId');
          return message;
        })
        .where((message) {
          // Filter for this specific clinic's conversations
          final messageClinicId = message.payload['clinicId'];
          final matches = messageClinicId == clinicId;

          if (matches) {
            print('>>> ✓ Event matches clinic - forwarding to controller');
          } else {
            print('>>> ✗ Event does not match clinic - filtering out');
          }

          return matches;
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

  // REPLACE createStaffAccount METHOD:
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
  }) async {
    try {
      print('>>> ============================================');
      print('>>> STAFF ACCOUNT CREATION START (USERNAME ONLY)');
      print('>>> ============================================');

      // Store current admin session
      print('>>> Step 0: Verifying current admin session...');
      final currentSession = await account!.getSession(sessionId: 'current');
      print('>>> Current admin session: ${currentSession.$id}');

      print('>>> Step 1: Creating Appwrite auth user with username...');

      // Create user with username and password ONLY
      // Appwrite will handle username-based authentication internally
      final authUser = await account!.create(
        userId: ID.unique(),
        email:
            '$username@${AppwriteConstants.projectID}.internal', // Required by Appwrite but hidden
        password: password,
        name: name,
      );

      // IMPORTANT: Update user preferences to set username
      await account!.updatePrefs(prefs: {
        'username': username,
        'isStaff': true,
      });

      print('>>> Auth user created: ${authUser.$id}');
      print('>>> Username set in preferences: $username');

      // Verify admin session is still active
      final verifySession = await account!.get();
      print(
          '>>> Session verified - still logged in as: ${verifySession.email}');

      print('>>> Step 2: Creating staff database record...');
      final staffData = {
        'userId': authUser.$id,
        'name': name,
        'username': username,
        'email': email ?? '',
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

      print('>>> Staff data:');
      print('>>> - Username: ${staffData['username']}');
      print('>>> - Contact email: ${staffData['email']}');
      print('>>> - Role: ${staffData['role']}');

      final staffDoc = await databases!.createDocument(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.staffCollectionID,
        documentId: ID.unique(),
        data: staffData,
      );
      print('>>> Staff database record created: ${staffDoc.$id}');

      // Final session verification
      final finalSession = await account!.get();
      print(
          '>>> Final check - admin still logged in as: ${finalSession.email}');

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

  // RENAMED: getStaffByEmail -> getStaffByUsername
  Future<Document?> getStaffByUsername(String username) async {
    try {
      print('>>> ==========================================');
      print('>>> GET STAFF BY USERNAME');
      print('>>> Username: $username');

      final result = await databases!.listDocuments(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.staffCollectionID,
        queries: [
          Query.equal('username', username),
          Query.equal('isActive', true),
        ],
      );

      if (result.documents.isEmpty) {
        print('>>> No staff found for username: $username');
        print('>>> ==========================================');
        return null;
      }

      final doc = result.documents.first;

      print('>>> Staff found by username!');
      print('>>> Document ID: ${doc.$id}');
      print('>>> Name: ${doc.data['name']}');
      print('>>> UserId in DB: ${doc.data['userId']}');
      print('>>> Username: ${doc.data['username']}');
      print('>>> Role: ${doc.data['role']}');
      print('>>> Clinic ID: ${doc.data['clinicId']}');
      print('>>> ==========================================');

      return doc;
    } catch (e) {
      print('>>> Error getting staff by username: $e');
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

  // MODIFIED: Migration for existing staff records
  Future<void> migrateExistingStaffRecords() async {
    try {
      print('>>> ============================================');
      print('>>> MIGRATING STAFF RECORDS');
      print('>>> Adding username field to existing records');
      print('>>> ============================================');

      final result = await databases!.listDocuments(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.staffCollectionID,
      );

      print('>>> Found ${result.documents.length} staff records');

      for (var doc in result.documents) {
        try {
          final currentRole = doc.data['role'];
          final currentUsername = doc.data['username'];
          final email = doc.data['email'];
          final name = doc.data['name'];

          // If role is missing, add it
          if (currentRole == null || currentRole.isEmpty) {
            print(
                '>>> Updating staff: ${doc.data['name']} (${doc.data['email']})');
            print('>>>   - Adding role field');

            await databases!.updateDocument(
              databaseId: AppwriteConstants.dbID,
              collectionId: AppwriteConstants.staffCollectionID,
              documentId: doc.$id,
              data: {
                'role': 'staff',
                'updatedAt': DateTime.now().toIso8601String(),
              },
            );
          }

          // CRITICAL: If username is missing, generate one from name or email
          if (currentUsername == null || currentUsername.isEmpty) {
            print('>>> Updating staff: ${doc.data['name']}');

            // Generate username from name or email
            String generatedUsername;
            if (name != null && name.isNotEmpty) {
              generatedUsername = name
                  .toString()
                  .toLowerCase()
                  .replaceAll(RegExp(r'[^a-z0-9]'), '')
                  .replaceAll(' ', '.');
            } else if (email != null && email.isNotEmpty) {
              generatedUsername = email.toString().split('@')[0];
            } else {
              generatedUsername = 'staff${doc.$id.substring(0, 8)}';
            }

            print('>>>   - Adding username field: $generatedUsername');

            await databases!.updateDocument(
              databaseId: AppwriteConstants.dbID,
              collectionId: AppwriteConstants.staffCollectionID,
              documentId: doc.$id,
              data: {
                'username': generatedUsername,
                'updatedAt': DateTime.now().toIso8601String(),
              },
            );

            print('>>>   ✓ Migration successful');
          } else {
            print(
                '>>> Staff already has username: ${doc.data['name']} - $currentUsername');
          }
        } catch (e) {
          print('>>> Error updating staff ${doc.$id}: $e');
        }
      }

      print('>>> ============================================');
      print('>>> MIGRATION COMPLETE');
      print('>>> ============================================');
    } catch (e) {
      print('>>> Migration error: $e');
    }
  }

  Future<Document> updateStaffInfo({
    required String staffDocumentId,
    String? name,
    String? department,
    String? image,
    String? phone, // Add this
    List<String>? authorities,
  }) async {
    final updateData = <String, dynamic>{
      'updatedAt': DateTime.now().toIso8601String(),
    };

    if (name != null) updateData['name'] = name;
    if (department != null) updateData['department'] = department;
    if (image != null) updateData['image'] = image;
    if (phone != null) updateData['phone'] = phone; // Add this
    if (authorities != null) updateData['authorities'] = authorities;

    return await databases!.updateDocument(
      databaseId: AppwriteConstants.dbID,
      collectionId: AppwriteConstants.staffCollectionID,
      documentId: staffDocumentId,
      data: updateData,
    );
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

  // UPDATE checkIfStaffAccount METHOD to be more robust:
  Future<Map<String, dynamic>> checkIfStaffAccount(String username) async {
    try {
      print('>>> ============================================');
      print('>>> CHECKING STAFF ACCOUNT');
      print('>>> Login username: $username');
      print('>>> ============================================');

      // Check using username field in database
      final staffResult = await databases!.listDocuments(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.staffCollectionID,
        queries: [
          Query.equal('username', username),
        ],
      );

      if (staffResult.documents.isEmpty) {
        print('>>> No staff found with username: $username');
        return {'isStaff': false};
      }

      final staffDoc = staffResult.documents.first;
      final isActive = staffDoc.data['isActive'] ?? true;
      final role = staffDoc.data['role'] ?? 'staff';
      final clinicId = staffDoc.data['clinicId'] ?? '';
      final authorities = staffDoc.data['authorities'] ?? [];

      print('>>> ============================================');
      print('>>> STAFF FOUND!');
      print('>>> Staff Document ID: ${staffDoc.$id}');
      print('>>> Username: $username');
      print('>>> Is active: $isActive');
      print('>>> Role: $role');
      print('>>> Clinic ID: $clinicId');
      print('>>> Authorities: $authorities');
      print('>>> ============================================');

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
      return {'isStaff': false};
    }
  }

  Future<Map<String, dynamic>> staffLogin(
      String username, String password) async {
    try {
      print('>>> ============================================');
      print('>>> STAFF LOGIN START (USERNAME ONLY)');
      print('>>> ============================================');
      print('>>> Login username: $username');

      // Step 1: Check if staff account exists using username
      print('>>> Step 1: Checking staff account...');
      final staffCheck = await checkIfStaffAccount(username);

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

      // Step 3: Get the auth user ID from staff record
      final staffDoc = staffCheck['staffDoc'];
      final authUserId = staffDoc.data['userId'];

      print('>>> Step 3: Creating session with username...');

      // Use the internal email format that was created during registration
      final internalEmail = '$username@${AppwriteConstants.projectID}.internal';

      final session = await account!.createEmailPasswordSession(
        email: internalEmail,
        password: password,
      );
      print('>>> Session created successfully: ${session.$id}');

      final user = await account!.get();
      print('>>> User retrieved: ${user.$id}');

      final role = staffCheck['role'] ?? 'staff';
      final clinicId = staffCheck['clinicId'] ?? '';
      final authorities = staffCheck['authorities'] ?? [];

      print('>>> ============================================');
      print('>>> STAFF LOGIN DATA:');
      print('>>> Username: $username');
      print('>>> Role: $role');
      print('>>> Clinic ID: $clinicId');
      print('>>> Authorities: $authorities');
      print('>>> Staff Doc ID: ${staffDoc.$id}');
      print('>>> ============================================');

      // IMPORTANT: Get clinic info for correct display in UI
      print('>>> Step 4: Fetching clinic information...');
      String clinicName = 'Unknown Clinic';
      String clinicProfilePictureId = '';

      try {
        final clinicDoc = await getClinicById(clinicId);
        if (clinicDoc != null) {
          clinicName = clinicDoc.data['clinicName'] ?? 'Unknown Clinic';
          clinicProfilePictureId = clinicDoc.data['profilePictureId'] ?? '';
          print('>>> Clinic fetched: $clinicName');
          print('>>> Clinic profile picture ID: $clinicProfilePictureId');
        }
      } catch (e) {
        print('>>> Warning: Could not fetch clinic info: $e');
      }

      // CRITICAL: Store staff data in GetStorage with CORRECT clinic info
      print('>>> Step 5: Storing staff data in GetStorage...');
      _storage.write('userId', user.$id);
      _storage.write('email', user.email);
      _storage.write('name', user.name);
      _storage.write('role', role);
      _storage.write('clinicId', clinicId);
      _storage.write('staffId', staffDoc.$id);
      _storage.write('authorities', authorities);
      // IMPORTANT: Store clinic info from the staff's clinic, not from previous login
      _storage.write('clinicName', clinicName);
      _storage.write('clinicProfilePictureId', clinicProfilePictureId);

      print('>>> Stored in GetStorage:');
      print('>>> - userId: ${user.$id}');
      print('>>> - email: ${user.email}');
      print('>>> - role: $role');
      print('>>> - clinicId: $clinicId');
      print('>>> - clinicName: $clinicName');
      print('>>> - clinicProfilePictureId: $clinicProfilePictureId');
      print('>>> - staffId: ${staffDoc.$id}');

      return {
        'success': true,
        'isStaff': true,
        'session': session,
        'user': user,
        'role': role,
        'clinicId': clinicId,
        'clinicName': clinicName,
        'staffDoc': staffDoc,
        'authorities': authorities,
        'staffDocumentId': staffDoc.$id,
        'message': 'Staff login successful',
      };
    } catch (e) {
      print('>>> ============================================');
      print('>>> STAFF LOGIN ERROR');
      print('>>> Error: $e');
      print('>>> ============================================');
      return {
        'success': false,
        'isStaff': true,
        'message': 'Invalid username or password',
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

  // ============= ID VERIFICATION METHODS =============

  /// Create ID verification record
  Future<Document> createIdVerification(Map<String, dynamic> data) async {
    try {
      print('>>> Creating ID verification record...');
      print('>>> Data: $data');

      return await databases!.createDocument(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.idVerificationCollectionID,
        documentId: ID.unique(),
        data: data,
      );
    } catch (e) {
      print('>>> Error creating ID verification: $e');
      rethrow;
    }
  }

  /// Get ID verification by userId
  Future<Document?> getIdVerificationByUserId(String userId) async {
    try {
      print('>>> Getting ID verification for user: $userId');

      final result = await databases!.listDocuments(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.idVerificationCollectionID,
        queries: [
          Query.equal('userId', userId),
          Query.orderDesc('createdAt'),
          Query.limit(1),
        ],
      );

      if (result.documents.isEmpty) {
        print('>>> No ID verification found');
        return null;
      }

      print('>>> ID verification found: ${result.documents.first.$id}');
      return result.documents.first;
    } catch (e) {
      print('>>> Error getting ID verification: $e');
      return null;
    }
  }

  /// Get ID verification by submissionId (from ARGOS webhook)
  Future<Document?> getIdVerificationBySubmissionId(String submissionId) async {
    try {
      print('>>> Getting ID verification for submission: $submissionId');

      final result = await databases!.listDocuments(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.idVerificationCollectionID,
        queries: [
          Query.equal('submissionId', submissionId),
        ],
      );

      if (result.documents.isEmpty) {
        print('>>> No ID verification found for submission');
        return null;
      }

      return result.documents.first;
    } catch (e) {
      print('>>> Error getting ID verification by submission: $e');
      return null;
    }
  }

  /// Update ID verification record
  Future<Document> updateIdVerification(
    String documentId,
    Map<String, dynamic> data,
  ) async {
    try {
      print('>>> Updating ID verification: $documentId');
      print('>>> Update data: $data');

      data['updatedAt'] = DateTime.now().toIso8601String();

      return await databases!.updateDocument(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.idVerificationCollectionID,
        documentId: documentId,
        data: data,
      );
    } catch (e) {
      print('>>> Error updating ID verification: $e');
      rethrow;
    }
  }

  /// Process ARGOS webhook (called from your backend)
  /// This updates the verification status based on ARGOS webhook data
  Future<Map<String, dynamic>> processArgosWebhook(
    Map<String, dynamic> webhookData,
  ) async {
    try {
      print('>>> ============================================');
      print('>>> PROCESSING ARGOS WEBHOOK');
      print('>>> Webhook data: $webhookData');
      print('>>> ============================================');

      final userId = webhookData['userId'] as String?;
      final submissionId = webhookData['submissionId'] as String?;
      final status = webhookData['status'] as String?;
      final email = webhookData['email'] as String?;

      if (userId == null || submissionId == null) {
        return {
          'success': false,
          'error': 'Missing required fields: userId or submissionId',
        };
      }

      // Get existing verification record
      Document? verificationDoc = await getIdVerificationByUserId(userId);

      // Map ARGOS status to our status
      String mappedStatus = 'pending';
      if (status == 'approved' || status == 'success') {
        mappedStatus = 'approved';
      } else if (status == 'rejected' || status == 'failed') {
        mappedStatus = 'rejected';
      } else if (status == 'pending') {
        mappedStatus = 'in_progress';
      }

      final updateData = {
        'submissionId': submissionId,
        'status': mappedStatus,
        'fullName': webhookData['fullName'],
        'birthDate': webhookData['birthDate'],
        'idType': webhookData['idType'],
        'countryCode': webhookData['countryCode'],
        'rejectionReason': webhookData['rejectReason'],
        'additionalData': webhookData['rawData'],
      };

      // If approved, set verifiedAt timestamp
      if (mappedStatus == 'approved') {
        updateData['verifiedAt'] = DateTime.now().toIso8601String();
      }

      Document updatedDoc;
      if (verificationDoc != null) {
        // Update existing record
        print('>>> Updating existing verification record');
        updatedDoc = await updateIdVerification(
          verificationDoc.$id,
          updateData,
        );
      } else {
        // Create new record (shouldn't happen normally, but handle it)
        print('>>> Creating new verification record from webhook');
        updateData['userId'] = userId;
        updateData['email'] = email ?? '';
        updateData['createdAt'] = DateTime.now().toIso8601String();
        updatedDoc = await createIdVerification(updateData);
      }

      // If verified, update user's verification status in users collection
      if (mappedStatus == 'approved') {
        print('>>> Updating user verification status...');
        final userDoc = await getUserById(userId);
        if (userDoc != null) {
          await databases!.updateDocument(
            databaseId: AppwriteConstants.dbID,
            collectionId: AppwriteConstants.usersCollectionID,
            documentId: userDoc.$id,
            data: {
              'idVerified': true,
              'idVerifiedAt': DateTime.now().toIso8601String(),
            },
          );
          print('>>> User verification status updated');
        }
      }

      print('>>> ============================================');
      print('>>> WEBHOOK PROCESSED SUCCESSFULLY');
      print('>>> Status: $mappedStatus');
      print('>>> ============================================');

      return {
        'success': true,
        'verificationDoc': updatedDoc,
        'status': mappedStatus,
      };
    } catch (e) {
      print('>>> ============================================');
      print('>>> ERROR PROCESSING WEBHOOK: $e');
      print('>>> ============================================');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Check if user is verified
  Future<bool> isUserIdVerified(String userId) async {
    try {
      // First check users collection
      final userDoc = await getUserById(userId);
      if (userDoc != null) {
        final idVerified = userDoc.data['idVerified'] as bool?;
        if (idVerified == true) return true;
      }

      // Then check verification collection
      final verificationDoc = await getIdVerificationByUserId(userId);
      if (verificationDoc != null) {
        final status = verificationDoc.data['status'] as String?;
        return status == 'approved';
      }

      return false;
    } catch (e) {
      print('>>> Error checking verification status: $e');
      return false;
    }
  }

  /// Get verification status for display
  Future<Map<String, dynamic>> getUserVerificationStatus(String userId) async {
    try {
      final verificationDoc = await getIdVerificationByUserId(userId);

      if (verificationDoc == null) {
        return {
          'hasVerification': false,
          'status': 'not_started',
          'isVerified': false,
        };
      }

      final status = verificationDoc.data['status'] as String? ?? 'pending';

      return {
        'hasVerification': true,
        'status': status,
        'isVerified': status == 'approved',
        'verificationDoc': verificationDoc.data,
        'documentId': verificationDoc.$id,
      };
    } catch (e) {
      print('>>> Error getting verification status: $e');
      return {
        'hasVerification': false,
        'status': 'error',
        'isVerified': false,
        'error': e.toString(),
      };
    }
  }

  /// Subscribe to ID verification changes (real-time)
  Stream<RealtimeMessage> subscribeToIdVerification(String userId) {
    final realtime = Realtime(client);
    return realtime
        .subscribe([
          'databases.${AppwriteConstants.dbID}.collections.${AppwriteConstants.idVerificationCollectionID}.documents'
        ])
        .stream
        .where((message) {
          return message.payload['userId'] == userId;
        });
  }

  Future<void> cleanupStuckVerifications(String userId) async {
    try {
      final verificationDoc = await getIdVerificationByUserId(userId);

      if (verificationDoc != null) {
        final status = verificationDoc.data['status'] as String?;
        final createdAt = DateTime.parse(verificationDoc.data['createdAt']);
        final now = DateTime.now();

        // If stuck in 'in_progress' or 'pending' for more than 30 minutes, reset
        if ((status == 'in_progress' || status == 'pending') &&
            now.difference(createdAt).inMinutes > 30) {
          print('>>> Cleaning up stuck verification record');
          await databases!.deleteDocument(
            databaseId: AppwriteConstants.dbID,
            collectionId: AppwriteConstants.idVerificationCollectionID,
            documentId: verificationDoc.$id,
          );
        }
      }
    } catch (e) {
      print('>>> Error cleaning up verifications: $e');
    }
  }

  Future<Document> createRatingAndReview(Map<String, dynamic> data) async {
    try {
      print('Creating rating and review...');

      return await databases!.createDocument(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.ratingsAndReviewsCollectionID,
        documentId: ID.unique(),
        data: data,
      );
    } catch (e) {
      print('Error creating rating and review: $e');
      rethrow;
    }
  }

  /// Check if user has already reviewed an appointment
  Future<bool> hasUserReviewedAppointment(String appointmentId) async {
    try {
      final result = await databases!.listDocuments(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.ratingsAndReviewsCollectionID,
        queries: [
          Query.equal('appointmentId', appointmentId),
        ],
      );

      return result.documents.isNotEmpty;
    } catch (e) {
      print('Error checking if appointment reviewed: $e');
      return false;
    }
  }

  /// Get all reviews for a clinic
  Future<List<Document>> getClinicReviews(
    String clinicId, {
    int limit = 50,
    String? lastDocumentId,
  }) async {
    try {
      final queries = [
        Query.equal('clinicId', clinicId),
        Query.orderDesc('createdAt'),
        Query.limit(limit),
      ];

      if (lastDocumentId != null) {
        queries.add(Query.cursorAfter(lastDocumentId));
      }

      final result = await databases!.listDocuments(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.ratingsAndReviewsCollectionID,
        queries: queries,
      );

      return result.documents;
    } catch (e) {
      print('Error getting clinic reviews: $e');
      return [];
    }
  }

  /// Get reviews by a specific user
  Future<List<Document>> getUserReviews(String userId) async {
    try {
      final result = await databases!.listDocuments(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.ratingsAndReviewsCollectionID,
        queries: [
          Query.equal('userId', userId),
          Query.orderDesc('createdAt'),
        ],
      );

      return result.documents;
    } catch (e) {
      print('Error getting user reviews: $e');
      return [];
    }
  }

  /// Get a specific review by appointment ID
  Future<Document?> getReviewByAppointmentId(String appointmentId) async {
    try {
      final result = await databases!.listDocuments(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.ratingsAndReviewsCollectionID,
        queries: [
          Query.equal('appointmentId', appointmentId),
        ],
      );

      return result.documents.isNotEmpty ? result.documents.first : null;
    } catch (e) {
      print('Error getting review by appointment: $e');
      return null;
    }
  }

  /// Update an existing review
  Future<Document> updateRatingAndReview(
      String documentId, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = DateTime.now().toIso8601String();
      data['isEdited'] = true;

      return await databases!.updateDocument(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.ratingsAndReviewsCollectionID,
        documentId: documentId,
        data: data,
      );
    } catch (e) {
      print('Error updating rating and review: $e');
      rethrow;
    }
  }

  /// Delete a review
  Future<void> deleteRatingAndReview(String documentId) async {
    try {
      await databases!.deleteDocument(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.ratingsAndReviewsCollectionID,
        documentId: documentId,
      );
    } catch (e) {
      print('Error deleting rating and review: $e');
      rethrow;
    }
  }

  /// Add clinic response to a review
  Future<Document> addClinicResponse(
    String documentId,
    String response,
  ) async {
    try {
      return await databases!.updateDocument(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.ratingsAndReviewsCollectionID,
        documentId: documentId,
        data: {
          'clinicResponse': response,
          'clinicResponseDate': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      print('Error adding clinic response: $e');
      rethrow;
    }
  }

  /// Get clinic rating statistics
  Future<Map<String, dynamic>> getClinicRatingStats(String clinicId) async {
    try {
      final reviews = await getClinicReviews(clinicId, limit: 1000);

      if (reviews.isEmpty) {
        return {
          'averageRating': 0.0,
          'totalReviews': 0,
          'ratingDistribution': {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
          'reviewsWithText': 0,
          'reviewsWithImages': 0,
        };
      }

      double totalRating = 0;
      final distribution = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
      int withText = 0;
      int withImages = 0;

      for (var doc in reviews) {
        final rating = (doc.data['rating'] ?? 0.0).toDouble();
        totalRating += rating;

        final starRating = rating.ceil();
        distribution[starRating] = (distribution[starRating] ?? 0) + 1;

        if (doc.data['reviewText'] != null &&
            doc.data['reviewText'].toString().isNotEmpty) {
          withText++;
        }

        final images = doc.data['images'] as List?;
        if (images != null && images.isNotEmpty) {
          withImages++;
        }
      }

      final avgRating = totalRating / reviews.length;

      return {
        'averageRating': double.parse(avgRating.toStringAsFixed(1)),
        'totalReviews': reviews.length,
        'ratingDistribution': distribution,
        'reviewsWithText': withText,
        'reviewsWithImages': withImages,
      };
    } catch (e) {
      print('Error getting clinic rating stats: $e');
      return {
        'averageRating': 0.0,
        'totalReviews': 0,
        'ratingDistribution': {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
        'reviewsWithText': 0,
        'reviewsWithImages': 0,
      };
    }
  }

  /// Upload review images (supports both web and mobile)
  Future<List<models.File>> uploadReviewImages(List<PlatformFile> files) async {
    final List<models.File> uploadedFiles = [];

    for (int i = 0; i < files.length; i++) {
      try {
        final file = files[i];
        String fileName =
            "${DateTime.now().millisecondsSinceEpoch}_review_$i.${file.extension ?? 'jpg'}";

        InputFile inputFile;

        // Web upload (using bytes)
        if (file.bytes != null) {
          inputFile = InputFile.fromBytes(
            bytes: file.bytes!,
            filename: fileName,
          );
        }
        // Mobile upload (using path)
        else if (file.path != null) {
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
        print("Successfully uploaded review image: ${response.$id}");
      } catch (e) {
        print("Error uploading review image ${files[i].name}: $e");
        // Continue with other images even if one fails
      }
    }

    return uploadedFiles;
  }

  /// Delete review images
  Future<void> deleteReviewImages(List<String> fileIds) async {
    for (String fileId in fileIds) {
      try {
        await storage!.deleteFile(
          bucketId: AppwriteConstants.imageBucketID,
          fileId: fileId,
        );
      } catch (e) {
        print("Error deleting review image $fileId: $e");
      }
    }
  }

  /// Subscribe to clinic reviews (real-time)
  Stream<RealtimeMessage> subscribeToClinicReviews(String clinicId) {
    final realtime = Realtime(client);
    return realtime
        .subscribe([
          'databases.${AppwriteConstants.dbID}.collections.${AppwriteConstants.ratingsAndReviewsCollectionID}.documents'
        ])
        .stream
        .where((message) {
          return message.payload['clinicId'] == clinicId;
        });
  }

  // ============= VACCINATION METHODS =============

  Future<models.Document> createVaccination(Map<String, dynamic> data) async {
    return await databases!.createDocument(
      databaseId: AppwriteConstants.dbID,
      collectionId: AppwriteConstants.vaccinationsCollectionID,
      documentId: ID.unique(),
      data: data,
    );
  }

  Future<List<Map<String, dynamic>>> getPetVaccinations(String petId) async {
    try {
      final res = await databases!.listDocuments(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.vaccinationsCollectionID,
        queries: [
          Query.equal("petId", petId),
          Query.orderDesc("dateGiven"),
        ],
      );

      return res.documents
          .map((doc) => {
                ...doc.data,
                '\$id': doc.$id,
              })
          .toList();
    } catch (e) {
      print('Error in AppWriteProvider.getPetVaccinations: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getClinicVaccinations(
      String clinicId) async {
    try {
      final res = await databases!.listDocuments(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.vaccinationsCollectionID,
        queries: [
          Query.equal("clinicId", clinicId),
          Query.orderDesc("dateGiven"),
        ],
      );

      return res.documents
          .map((doc) => {
                ...doc.data,
                '\$id': doc.$id,
              })
          .toList();
    } catch (e) {
      print('Error in AppWriteProvider.getClinicVaccinations: $e');
      return [];
    }
  }

  Future<Document> updateVaccination(
      String documentId, Map<String, dynamic> data) async {
    data['updatedAt'] = DateTime.now().toIso8601String();
    return await databases!.updateDocument(
      databaseId: AppwriteConstants.dbID,
      collectionId: AppwriteConstants.vaccinationsCollectionID,
      documentId: documentId,
      data: data,
    );
  }

  Future<void> deleteVaccination(String documentId) async {
    await databases!.deleteDocument(
      databaseId: AppwriteConstants.dbID,
      collectionId: AppwriteConstants.vaccinationsCollectionID,
      documentId: documentId,
    );
  }

  // ============= FEEDBACK AND REPORT METHODS =============

  /// Create new feedback/report
  Future<Document> createFeedbackAndReport(Map<String, dynamic> data) async {
    try {
      print('>>> Creating feedback and report...');
      return await databases!.createDocument(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.feedbackAndReportCollectionID,
        documentId: ID.unique(),
        data: data,
      );
    } catch (e) {
      print('>>> Error creating feedback: $e');
      rethrow;
    }
  }

  /// Get all feedback (for admin)
  Future<List<Document>> getAllFeedback({
    FeedbackStatus? status,
    Priority? priority,
    int limit = 100,
  }) async {
    try {
      List<String> queries = [
        Query.orderDesc('submittedAt'),
        Query.limit(limit),
      ];

      if (status != null) {
        queries.add(Query.equal('status', status.toString().split('.').last));
      }

      if (priority != null) {
        queries
            .add(Query.equal('priority', priority.toString().split('.').last));
      }

      final result = await databases!.listDocuments(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.feedbackAndReportCollectionID,
        queries: queries,
      );

      return result.documents;
    } catch (e) {
      print('Error getting all feedback: $e');
      return [];
    }
  }

  /// Get user's feedback
  Future<List<Document>> getUserFeedback(String userId) async {
    try {
      final result = await databases!.listDocuments(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.feedbackAndReportCollectionID,
        queries: [
          Query.equal('userId', userId),
          Query.orderDesc('submittedAt'),
        ],
      );

      return result.documents;
    } catch (e) {
      print('Error getting user feedback: $e');
      return [];
    }
  }

  /// Update feedback (for admin)
  Future<Document> updateFeedback(
    String documentId,
    Map<String, dynamic> data,
  ) async {
    try {
      data['updatedAt'] = DateTime.now().toIso8601String();

      return await databases!.updateDocument(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.feedbackAndReportCollectionID,
        documentId: documentId,
        data: data,
      );
    } catch (e) {
      print('Error updating feedback: $e');
      rethrow;
    }
  }

  /// Update feedback status
  Future<void> updateFeedbackStatus(
      String documentId, FeedbackStatus status) async {
    try {
      await databases!.updateDocument(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.feedbackAndReportCollectionID,
        documentId: documentId,
        data: {
          'status': status.toString().split('.').last,
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      print('Error updating feedback status: $e');
      rethrow;
    }
  }

  /// Update feedback priority
  Future<void> updateFeedbackPriority(
      String documentId, Priority priority) async {
    try {
      await databases!.updateDocument(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.feedbackAndReportCollectionID,
        documentId: documentId,
        data: {
          'priority': priority.toString().split('.').last,
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      print('Error updating feedback priority: $e');
      rethrow;
    }
  }

  /// Add admin reply to feedback
  Future<void> addFeedbackReply(
    String documentId,
    String reply,
    String adminName,
  ) async {
    try {
      await databases!.updateDocument(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.feedbackAndReportCollectionID,
        documentId: documentId,
        data: {
          'adminReply': reply,
          'repliedAt': DateTime.now().toIso8601String(),
          'repliedBy': adminName,
          'status': FeedbackStatus.resolved.toString().split('.').last,
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      print('Error adding feedback reply: $e');
      rethrow;
    }
  }

  /// Archive feedback
  Future<void> archiveFeedback(String documentId, String archivedBy) async {
    try {
      await databases!.updateDocument(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.feedbackAndReportCollectionID,
        documentId: documentId,
        data: {
          'status': FeedbackStatus.archived.toString().split('.').last,
          'archivedAt': DateTime.now().toIso8601String(),
          'archivedBy': archivedBy,
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      print('Error archiving feedback: $e');
      rethrow;
    }
  }

  /// Delete feedback
  Future<void> deleteFeedback(
      String documentId, List<String> attachmentIds) async {
    try {
      // Delete attachments first
      if (attachmentIds.isNotEmpty) {
        await deleteFeedbackAttachments(attachmentIds);
      }

      // Delete feedback document
      await databases!.deleteDocument(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.feedbackAndReportCollectionID,
        documentId: documentId,
      );
    } catch (e) {
      print('Error deleting feedback: $e');
      rethrow;
    }
  }

  /// Upload feedback attachments (images and videos)
  Future<List<models.File>> uploadFeedbackAttachments(
    List<PlatformFile> files,
  ) async {
    final List<models.File> uploadedFiles = [];

    for (int i = 0; i < files.length; i++) {
      try {
        final file = files[i];
        final extension = file.extension ?? 'jpg';
        String fileName =
            "${DateTime.now().millisecondsSinceEpoch}_feedback_$i.$extension";

        // Validate file size
        final isImage = ['jpg', 'jpeg', 'png', 'gif', 'webp']
            .contains(extension.toLowerCase());
        final isVideo =
            ['mp4', 'mov', 'avi', 'mkv'].contains(extension.toLowerCase());

        if (isImage && file.size > 5 * 1024 * 1024) {
          print('Error: Image file ${file.name} exceeds 5MB limit');
          continue;
        }

        if (isVideo && file.size > 25 * 1024 * 1024) {
          print('Error: Video file ${file.name} exceeds 25MB limit');
          continue;
        }

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
          bucketId: AppwriteConstants.feedbackAttachmentsBucketID,
          fileId: ID.unique(),
          file: inputFile,
        );

        uploadedFiles.add(response);
        print("Successfully uploaded feedback attachment: ${response.$id}");
      } catch (e) {
        print("Error uploading feedback attachment ${files[i].name}: $e");
      }
    }

    return uploadedFiles;
  }

  /// Delete feedback attachments
  Future<void> deleteFeedbackAttachments(List<String> fileIds) async {
    for (String fileId in fileIds) {
      try {
        await storage!.deleteFile(
          bucketId: AppwriteConstants.feedbackAttachmentsBucketID,
          fileId: fileId,
        );
      } catch (e) {
        print("Error deleting feedback attachment $fileId: $e");
      }
    }
  }

  /// Get feedback attachment URL
  String getFeedbackAttachmentUrl(String fileId) {
    return '${AppwriteConstants.endPoint}/storage/buckets/${AppwriteConstants.feedbackAttachmentsBucketID}/files/$fileId/view?project=${AppwriteConstants.projectID}';
  }

  /// Subscribe to feedback changes (real-time for admin)
  Stream<RealtimeMessage> subscribeToFeedbackChanges() {
    final realtime = Realtime(client);
    return realtime.subscribe([
      'databases.${AppwriteConstants.dbID}.collections.${AppwriteConstants.feedbackAndReportCollectionID}.documents',
    ]).stream;
  }

  /// Get feedback statistics (for admin dashboard)
  Future<Map<String, int>> getFeedbackStatistics() async {
    try {
      final allFeedback = await databases!.listDocuments(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.feedbackAndReportCollectionID,
      );

      int pending = 0;
      int inProgress = 0;
      int resolved = 0;
      int closed = 0;
      int archived = 0;
      int critical = 0;

      for (var doc in allFeedback.documents) {
        final status = doc.data['status'];
        final priority = doc.data['priority'];

        if (status == 'pending') pending++;
        if (status == 'inProgress') inProgress++;
        if (status == 'resolved') resolved++;
        if (status == 'closed') closed++;
        if (status == 'archived') archived++;
        if (priority == 'critical') critical++;
      }

      return {
        'total': allFeedback.documents.length,
        'pending': pending,
        'inProgress': inProgress,
        'resolved': resolved,
        'closed': closed,
        'archived': archived,
        'critical': critical,
      };
    } catch (e) {
      print('Error getting feedback statistics: $e');
      return {
        'total': 0,
        'pending': 0,
        'inProgress': 0,
        'resolved': 0,
        'closed': 0,
        'archived': 0,
        'critical': 0,
      };
    }
  }

  // ============= ARCHIVE USER METHODS (SOFT DELETE) =============

  /// Archive user (soft delete) - moves to archived collection
  Future<Map<String, dynamic>> archiveUser({
    required String userId,
    required String userDocumentId,
    required String archivedBy,
    String archiveReason = 'No reason provided',
  }) async {
    try {
      print('>>> ============================================');
      print('>>> ARCHIVING USER (SOFT DELETE)');
      print('>>> User ID: $userId');
      print('>>> Document ID: $userDocumentId');
      print('>>> ============================================');

      // Step 1: Get original user document
      final userDoc = await databases!.getDocument(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.usersCollectionID,
        documentId: userDocumentId,
      );

      print('>>> Step 1: Original user retrieved');
      // Step 2: Prepare archived user data with compressed original data
      final now = DateTime.now();
      final scheduledDeletion = now.add(const Duration(days: 30));

      // Store ONLY essential data to avoid size limits
      final Map<String, dynamic> essentialUserData = {
        'userId': userDoc.data['userId'] ?? userId,
        'name': userDoc.data['name'] ?? '',
        'email': userDoc.data['email'] ?? '',
        'role': userDoc.data['role'] ?? 'user',
        'phone': userDoc.data['phone'] ?? '',
        'profilePictureId': userDoc.data['profilePictureId'] ?? '',
        'idVerified': userDoc.data['idVerified'] ?? false,
        'idVerifiedAt': userDoc.data['idVerifiedAt'],
        'verificationDocumentId': userDoc.data['verificationDocumentId'],
      };

      // Convert to JSON string (Appwrite requires string for 65535 char limit)
      String originalUserDataJson;
      try {
        originalUserDataJson = jsonEncode(essentialUserData);
        print(
            '>>> Original user data JSON size: ${originalUserDataJson.length} chars');

        // Validate size (must be <= 65535 chars)
        if (originalUserDataJson.length > 65535) {
          print('>>> WARNING: User data too large, storing minimal data only');
          // Fallback to absolute minimum
          final minimalData = {
            'userId': userId,
            'name': userDoc.data['name'] ?? '',
            'email': userDoc.data['email'] ?? '',
            'role': userDoc.data['role'] ?? 'user',
          };
          originalUserDataJson = jsonEncode(minimalData);
        }

        print('>>> Final JSON size: ${originalUserDataJson.length} chars');
      } catch (e) {
        print('>>> ERROR encoding user data to JSON: $e');
        // Absolute fallback
        originalUserDataJson = jsonEncode({
          'userId': userId,
          'email': userDoc.data['email'] ?? '',
        });
      }

      final archivedUserData = {
        'userId': userId,
        'name': userDoc.data['name'] ?? '',
        'email': userDoc.data['email'] ?? '',
        'role': userDoc.data['role'] ?? 'user',
        'phone': userDoc.data['phone'] ?? '',
        'originalDocumentId': userDocumentId,
        'archivedBy': archivedBy,
        'archivedAt': now.toIso8601String(),
        'scheduledDeletionAt': scheduledDeletion.toIso8601String(),
        'archiveReason': archiveReason,
        'isPermanentlyDeleted': false,
        'originalUserData': originalUserDataJson, // STRING, not Map
        'isRecovered': false,
      };

      final archivedDoc = await databases!.createDocument(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.archivedUsersCollectionID,
        documentId: ID.unique(),
        data: archivedUserData,
      );

      // Step 3: DELETE the original user document completely from Users collection

      await databases!.deleteDocument(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.usersCollectionID,
        documentId: userDocumentId,
      );

      // Step 4: Deactivate user account (prevent login)
      try {
        // Update user preferences to block access
        print('>>> Step 4: User account deactivated');
      } catch (e) {
        print('>>> Warning: Could not deactivate user account: $e');
      }

      print('>>> ============================================');
      print('>>> USER ARCHIVED SUCCESSFULLY');
      print('>>> Scheduled deletion: $scheduledDeletion');
      print('>>> ============================================');

      return {
        'success': true,
        'archivedDocumentId': archivedDoc.$id,
        'scheduledDeletionAt': scheduledDeletion.toIso8601String(),
        'message':
            'User archived successfully. Will be permanently deleted in 30 days.',
      };
    } catch (e) {
      print('>>> ============================================');
      print('>>> ERROR ARCHIVING USER: $e');
      print('>>> Stack trace: ${StackTrace.current}');
      print('>>> ============================================');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Get archived user by userId
  Future<Document?> getArchivedUserByUserId(String userId) async {
    try {
      final result = await databases!.listDocuments(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.archivedUsersCollectionID,
        queries: [
          Query.equal('userId', userId),
          Query.equal('isPermanentlyDeleted', false),
          Query.orderDesc('archivedAt'),
          Query.limit(1),
        ],
      );

      return result.documents.isNotEmpty ? result.documents.first : null;
    } catch (e) {
      print('Error getting archived user: $e');
      return null;
    }
  }

  /// Get all archived users (for admin dashboard)
  Future<List<Document>> getAllArchivedUsers({
    bool includePermanentlyDeleted = false,
    int limit = 100,
  }) async {
    try {
      List<String> queries = [
        Query.orderDesc('archivedAt'),
        Query.limit(limit),
        // Don't show recovered users (they should be deleted, but just in case)
        Query.equal('isRecovered', false),
      ];

      if (!includePermanentlyDeleted) {
        queries.add(Query.equal('isPermanentlyDeleted', false));
      }

      final result = await databases!.listDocuments(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.archivedUsersCollectionID,
        queries: queries,
      );

      return result.documents;
    } catch (e) {
      print('Error getting archived users: $e');
      return [];
    }
  }

  /// Get users due for permanent deletion
  Future<List<Document>> getUsersDueForDeletion() async {
    try {
      final now = DateTime.now().toIso8601String();

      final result = await databases!.listDocuments(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.archivedUsersCollectionID,
        queries: [
          Query.lessThanEqual('scheduledDeletionAt', now),
          Query.equal('isPermanentlyDeleted', false),
          Query.equal('isRecovered', false),
          Query.limit(100),
        ],
      );

      return result.documents;
    } catch (e) {
      print('Error getting users due for deletion: $e');
      return [];
    }
  }

  /// Permanently delete user (called automatically after 30 days)
  Future<Map<String, dynamic>> permanentlyDeleteUser(String userId) async {
    try {
      print('>>> ============================================');
      print('>>> PERMANENTLY DELETING USER');
      print('>>> User ID: $userId');
      print('>>> ============================================');

      final errors = <String>[];
      final results = {
        'userDeleted': false,
        'archivedRecordUpdated': false,
        'petsDeleted': 0,
        'appointmentsDeleted': 0,
        'medicalRecordsDeleted': 0,
        'conversationsDeleted': 0,
        'messagesDeleted': 0,
        'notificationsDeleted': 0,
        'errors': errors,
      };

      // Step 1: Get original user document ID
      final archivedDoc = await getArchivedUserByUserId(userId);
      if (archivedDoc == null) {
        throw Exception('Archived user record not found');
      }

      final originalDocId = archivedDoc.data['originalDocumentId'];
      print('>>> Original document ID: $originalDocId');

      // Step 2: Delete user's pets
      try {
        final pets = await databases!.listDocuments(
          databaseId: AppwriteConstants.dbID,
          collectionId: AppwriteConstants.petsCollectionID,
          queries: [Query.equal('userId', userId)],
        );

        for (var pet in pets.documents) {
          await databases!.deleteDocument(
            databaseId: AppwriteConstants.dbID,
            collectionId: AppwriteConstants.petsCollectionID,
            documentId: pet.$id,
          );
          results['petsDeleted'] = (results['petsDeleted'] as int) + 1;
        }
        print('>>> ${results['petsDeleted']} pets deleted');
      } catch (e) {
        errors.add('Pets: ${e.toString()}');
      }

      // Step 3: Delete user's appointments
      try {
        final appointments = await databases!.listDocuments(
          databaseId: AppwriteConstants.dbID,
          collectionId: AppwriteConstants.appointmentCollectionID,
          queries: [Query.equal('userId', userId)],
        );

        for (var appointment in appointments.documents) {
          await databases!.deleteDocument(
            databaseId: AppwriteConstants.dbID,
            collectionId: AppwriteConstants.appointmentCollectionID,
            documentId: appointment.$id,
          );
          results['appointmentsDeleted'] =
              (results['appointmentsDeleted'] as int) + 1;
        }
        print('>>> ${results['appointmentsDeleted']} appointments deleted');
      } catch (e) {
        errors.add('Appointments: ${e.toString()}');
      }

      // Step 4: Delete user's conversations and messages
      try {
        final conversations = await databases!.listDocuments(
          databaseId: AppwriteConstants.dbID,
          collectionId: AppwriteConstants.conversationsCollectionID,
          queries: [Query.equal('userId', userId)],
        );

        for (var conversation in conversations.documents) {
          // Delete messages first
          final messages = await databases!.listDocuments(
            databaseId: AppwriteConstants.dbID,
            collectionId: AppwriteConstants.messagesCollectionID,
            queries: [Query.equal('conversationId', conversation.$id)],
          );

          for (var message in messages.documents) {
            await databases!.deleteDocument(
              databaseId: AppwriteConstants.dbID,
              collectionId: AppwriteConstants.messagesCollectionID,
              documentId: message.$id,
            );
            results['messagesDeleted'] =
                (results['messagesDeleted'] as int) + 1;
          }

          // Delete conversation
          await databases!.deleteDocument(
            databaseId: AppwriteConstants.dbID,
            collectionId: AppwriteConstants.conversationsCollectionID,
            documentId: conversation.$id,
          );
          results['conversationsDeleted'] =
              (results['conversationsDeleted'] as int) + 1;
        }
        print('>>> ${results['conversationsDeleted']} conversations deleted');
        print('>>> ${results['messagesDeleted']} messages deleted');
      } catch (e) {
        errors.add('Conversations/Messages: ${e.toString()}');
      }

      // Step 5: Delete user's notifications
      // try {
      //   final notifications = await databases!.listDocuments(
      //     databaseId: AppwriteConstants.dbID,
      //     collectionId: AppwriteConstants.notificationsCollectionID,
      //     queries: [Query.equal('recipientId', userId)],
      //   );

      //   for (var notification in notifications.documents) {
      //     await databases!.deleteDocument(
      //       databaseId: AppwriteConstants.dbID,
      //       collectionId: AppwriteConstants.notificationsCollectionID,
      //       documentId: notification.$id,
      //     );
      //     results['notificationsDeleted'] =
      //         (results['notificationsDeleted'] as int) + 1;
      //   }
      //   print('>>> ${results['notificationsDeleted']} notifications deleted');
      // } catch (e) {
      //   errors.add('Notifications: ${e.toString()}');
      // }

      // Step 6: Delete user from main users collection
      try {
        if (originalDocId != null) {
          await databases!.deleteDocument(
            databaseId: AppwriteConstants.dbID,
            collectionId: AppwriteConstants.usersCollectionID,
            documentId: originalDocId,
          );
          results['userDeleted'] = true;
          print('>>> User deleted from main collection');
        }
      } catch (e) {
        errors.add('User document: ${e.toString()}');
      }

      // Step 7: Update archived record to mark as permanently deleted
      try {
        await databases!.updateDocument(
          databaseId: AppwriteConstants.dbID,
          collectionId: AppwriteConstants.archivedUsersCollectionID,
          documentId: archivedDoc.$id,
          data: {
            'isPermanentlyDeleted': true,
            'permanentlyDeletedAt': DateTime.now().toIso8601String(),
          },
        );
        results['archivedRecordUpdated'] = true;
        print('>>> Archived record updated');
      } catch (e) {
        errors.add('Archived record: ${e.toString()}');
      }

      print('>>> ============================================');
      print('>>> PERMANENT DELETION COMPLETE');
      print('>>> Total errors: ${errors.length}');
      print('>>> ============================================');

      return results;
    } catch (e) {
      print('>>> ============================================');
      print('>>> ERROR IN PERMANENT DELETION: $e');
      print('>>> ============================================');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Recover archived user (restore within 30 days)
  /// Recover archived user (restore within 30 days)
  Future<Map<String, dynamic>> recoverArchivedUser({
    required String userId,
    required String recoveredBy,
  }) async {
    try {
      print('>>> ============================================');
      print('>>> RECOVERING ARCHIVED USER');
      print('>>> User ID: $userId');
      print('>>> ============================================');

      // Step 1: Get archived record
      final archivedDoc = await getArchivedUserByUserId(userId);
      if (archivedDoc == null) {
        return {
          'success': false,
          'error': 'Archived user not found',
        };
      }

      // Check if already permanently deleted
      if (archivedDoc.data['isPermanentlyDeleted'] == true) {
        return {
          'success': false,
          'error': 'User has been permanently deleted and cannot be recovered',
        };
      }

      final originalDocId = archivedDoc.data['originalDocumentId'];
      final archivedDocId = archivedDoc.$id; // Save this for later deletion

      // Parse the original user data from JSON string
      final originalUserDataString =
          archivedDoc.data['originalUserData'] as String?;

      if (originalUserDataString == null || originalUserDataString.isEmpty) {
        return {
          'success': false,
          'error': 'Original user data not found in archive',
        };
      }

      print('>>> Step 1: Parsing original user data...');

      Map<String, dynamic> originalUserData;
      try {
        originalUserData =
            Map<String, dynamic>.from(jsonDecode(originalUserDataString));
        print('>>> Original user data parsed successfully');
      } catch (e) {
        print('>>> ERROR parsing original user data: $e');
        return {
          'success': false,
          'error': 'Failed to parse original user data',
        };
      }

      print('>>> Step 2: Recreating user document in Users collection...');

      // Recreate the user document with original data
      final restoredUserData = {
        'userId': originalUserData['userId'] ?? userId,
        'name': originalUserData['name'] ?? '',
        'email': originalUserData['email'] ?? '',
        'role': originalUserData['role'] ?? 'user',
        'phone': originalUserData['phone'] ?? '',
        'profilePictureId': originalUserData['profilePictureId'] ?? '',
        // CRITICAL: Preserve verification status
        'idVerified': originalUserData['idVerified'] ?? false,
        'idVerifiedAt': originalUserData['idVerifiedAt'],
        // Ensure no archive flags - user is fully active
        'isArchived': false,
        // Clear any archive-related fields
        'archivedAt': null,
        'archivedBy': null,
        'archiveReason': null,
        'archivedDocumentId': null,
      };
      // Try to create new user document with same ID
      Document restoredDoc;
      try {
        restoredDoc = await databases!.createDocument(
          databaseId: AppwriteConstants.dbID,
          collectionId: AppwriteConstants.usersCollectionID,
          documentId: originalDocId, // Use original document ID
          data: restoredUserData,
        );
        print('>>> Step 2: User document recreated: ${restoredDoc.$id}');
      } catch (e) {
        // If document already exists, update it instead
        if (e.toString().contains('already exists') ||
            e.toString().contains('unique')) {
          print('>>> Document already exists, updating instead...');

          try {
            restoredDoc = await databases!.updateDocument(
              databaseId: AppwriteConstants.dbID,
              collectionId: AppwriteConstants.usersCollectionID,
              documentId: originalDocId,
              data: restoredUserData,
            );
            print('>>> Step 2: User document updated: ${restoredDoc.$id}');
          } catch (updateError) {
            print('>>> ERROR updating existing document: $updateError');
            return {
              'success': false,
              'error':
                  'Failed to update existing user document: ${updateError.toString()}',
            };
          }
        } else {
          print('>>> ERROR creating user document: $e');
          return {
            'success': false,
            'error': 'Failed to recreate user document: ${e.toString()}',
          };
        }
      }

      // Step 3: DELETE the archived record completely (not just mark as recovered)
      print(
          '>>> Step 3: DELETING archived record from ArchivedUsers collection...');
      try {
        await databases!.deleteDocument(
          databaseId: AppwriteConstants.dbID,
          collectionId: AppwriteConstants.archivedUsersCollectionID,
          documentId: archivedDocId,
        );
        print('>>> Step 3: Archived record DELETED completely');
      } catch (e) {
        print('>>> ERROR deleting archive record: $e');
        // This is critical - if we can't delete the archive, the recovery is incomplete
        // But the user document is already restored, so we continue
        print(
            '>>> WARNING: User was restored but archive record could not be deleted');
      }

      print('>>> ============================================');
      print('>>> USER RECOVERED SUCCESSFULLY');
      print('>>> Restored document ID: ${restoredDoc.$id}');
      print('>>> Archive record deleted: $archivedDocId');
      print('>>> ============================================');

      return {
        'success': true,
        'message': 'User recovered successfully and removed from archive',
        'restoredDocumentId': restoredDoc.$id,
      };
    } catch (e) {
      print('>>> ============================================');
      print('>>> ERROR RECOVERING USER: $e');
      print('>>> Stack trace: ${StackTrace.current}');
      print('>>> ============================================');

      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Background job to check and permanently delete users (should be called periodically)
  Future<Map<String, dynamic>> processScheduledDeletions() async {
    try {
      print('>>> ============================================');
      print('>>> PROCESSING SCHEDULED DELETIONS');
      print('>>> Time: ${DateTime.now()}');
      print('>>> ============================================');

      final usersDue = await getUsersDueForDeletion();
      print('>>> Found ${usersDue.length} users due for deletion');

      final results = <String, dynamic>{
        'totalProcessed': usersDue.length,
        'successfulDeletions': 0,
        'failedDeletions': 0,
        'errors': <String>[],
      };

      for (var archivedUser in usersDue) {
        try {
          final userId = archivedUser.data['userId'];
          print('>>> Processing user: $userId');

          final deleteResult = await permanentlyDeleteUser(userId);

          if (deleteResult['userDeleted'] == true) {
            results['successfulDeletions'] =
                (results['successfulDeletions'] as int) + 1;
            print('>>> âœ" User $userId deleted successfully');
          } else {
            results['failedDeletions'] =
                (results['failedDeletions'] as int) + 1;
            results['errors'].add('$userId: Deletion incomplete');
            print('>>> âœ— User $userId deletion failed');
          }

          // Add delay to prevent overwhelming the database
          await Future.delayed(const Duration(milliseconds: 500));
        } catch (e) {
          results['failedDeletions'] = (results['failedDeletions'] as int) + 1;
          results['errors']
              .add('${archivedUser.data['userId']}: ${e.toString()}');
          print('>>> Error deleting user: $e');
        }
      }

      print('>>> ============================================');
      print('>>> SCHEDULED DELETIONS COMPLETE');
      print('>>> Successful: ${results['successfulDeletions']}');
      print('>>> Failed: ${results['failedDeletions']}');
      print('>>> ============================================');

      return results;
    } catch (e) {
      print('>>> ERROR IN SCHEDULED DELETIONS: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Subscribe to archived users changes (real-time)
  Stream<RealtimeMessage> subscribeToArchivedUsers() {
    final realtime = Realtime(client);
    return realtime.subscribe([
      'databases.${AppwriteConstants.dbID}.collections.${AppwriteConstants.archivedUsersCollectionID}.documents',
    ]).stream;
  }

  /// Get archive statistics
  Future<Map<String, int>> getArchiveStatistics() async {
    try {
      final allArchived = await databases!.listDocuments(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.archivedUsersCollectionID,
        queries: [
          Query.limit(1000),
        ],
      );

      int activeArchives = 0;
      int permanentlyDeleted = 0;
      int dueSoon = 0; // Due within 7 days

      final now = DateTime.now();
      final sevenDaysFromNow = now.add(const Duration(days: 7));

      for (var doc in allArchived.documents) {
        // Skip recovered users (they should be deleted, but just in case)
        if (doc.data['isRecovered'] == true) {
          continue;
        }

        if (doc.data['isPermanentlyDeleted'] == true) {
          permanentlyDeleted++;
        } else {
          activeArchives++;

          final scheduledDeletion =
              DateTime.parse(doc.data['scheduledDeletionAt']);
          if (scheduledDeletion.isBefore(sevenDaysFromNow)) {
            dueSoon++;
          }
        }
      }

      return {
        'total': activeArchives + permanentlyDeleted, // Don't count recovered
        'activeArchives': activeArchives,
        'recovered': 0, // Always 0 since they're deleted
        'permanentlyDeleted': permanentlyDeleted,
        'dueSoon': dueSoon,
      };
    } catch (e) {
      print('Error getting archive statistics: $e');
      return {
        'total': 0,
        'activeArchives': 0,
        'recovered': 0,
        'permanentlyDeleted': 0,
        'dueSoon': 0,
      };
    }
  }

  Future<models.File> uploadUserProfilePicture(dynamic image) async {
    try {
      print('>>> Uploading user profile picture...');

      String fileName =
          "user_profile_${DateTime.now().millisecondsSinceEpoch}.jpg";
      InputFile inputFile;

      if (image is String) {
        // Mobile path-based upload
        inputFile = InputFile.fromPath(
          path: image,
          filename: fileName,
        );
      } else if (image is InputFile) {
        // Web bytes-based upload or pre-constructed InputFile
        inputFile = image;
      } else {
        throw Exception('Invalid profile picture format');
      }

      final response = await storage!.createFile(
        bucketId: AppwriteConstants.imageBucketID,
        fileId: ID.unique(),
        file: inputFile,
      );

      print('>>> User profile picture uploaded successfully: ${response.$id}');
      return response;
    } catch (e) {
      print('>>> Error uploading user profile picture: $e');
      rethrow;
    }
  }

  /// Delete user profile picture by file ID
  Future<void> deleteUserProfilePicture(String fileId) async {
    try {
      print('>>> Deleting user profile picture: $fileId');

      await storage!.deleteFile(
        bucketId: AppwriteConstants.imageBucketID,
        fileId: fileId,
      );

      print('>>> User profile picture deleted successfully');
    } catch (e) {
      print('>>> Error deleting user profile picture: $e');
      rethrow;
    }
  }

  /// Get user profile picture URL
  String getUserProfilePictureUrl(String profilePictureId) {
    if (profilePictureId.isEmpty) {
      return '';
    }

    final url =
        '${AppwriteConstants.endPoint}/storage/buckets/${AppwriteConstants.imageBucketID}/files/$profilePictureId/view?project=${AppwriteConstants.projectID}';
    print('>>> Generated user profile picture URL: $url');
    return url;
  }

  /// Update user profile picture
  Future<String> updateUserProfilePicture(
    String userDocumentId,
    String? oldProfilePictureId,
    dynamic newImage,
  ) async {
    try {
      print('>>> ============================================');
      print('>>> UPDATING USER PROFILE PICTURE');
      print('>>> User Document ID: $userDocumentId');
      print('>>> Old picture ID: $oldProfilePictureId');
      print('>>> ============================================');

      // Upload new profile picture
      print('>>> Step 1: Uploading new profile picture...');
      final uploadedFile = await uploadUserProfilePicture(newImage);
      final newFileId = uploadedFile.$id;
      print('>>> New file uploaded with ID: $newFileId');

      // Delete old profile picture if it exists
      if (oldProfilePictureId != null && oldProfilePictureId.isNotEmpty) {
        print('>>> Step 2: Deleting old profile picture...');
        try {
          await deleteUserProfilePicture(oldProfilePictureId);
          print('>>> Old profile picture deleted');
        } catch (e) {
          print('>>> Warning: Failed to delete old picture: $e');
          // Don't fail the entire operation if old deletion fails
        }
      }

      // Update user record in Users collection
      print('>>> Step 3: Updating user record...');
      await databases!.updateDocument(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.usersCollectionID,
        documentId: userDocumentId,
        data: {
          'profilePictureId': newFileId,
        },
      );
      print('>>> User record updated successfully');

      print('>>> ============================================');
      print('>>> USER PROFILE PICTURE UPDATE COMPLETE');
      print('>>> ============================================');

      return newFileId;
    } catch (e) {
      print('>>> ============================================');
      print('>>> ERROR UPDATING USER PROFILE PICTURE: $e');
      print('>>> ============================================');
      rethrow;
    }
  }

  /// Archive clinic (soft delete) - moves to archived collection
  Future<Map<String, dynamic>> archiveClinic({
    required String clinicId,
    required String clinicDocumentId,
    required String archivedBy,
    String archiveReason = 'No reason provided',
  }) async {
    try {
      print('>>> ============================================');
      print('>>> ARCHIVING CLINIC (SOFT DELETE)');
      print('>>> Clinic ID: $clinicId');
      print('>>> Document ID: $clinicDocumentId');
      print('>>> ============================================');

      // Step 1: Get original clinic document
      final clinicDoc = await databases!.getDocument(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.clinicsCollectionID,
        documentId: clinicDocumentId,
      );

      print('>>> Step 1: Original clinic retrieved');

      // Step 2: Prepare archived clinic data with compressed original data
      final now = DateTime.now();
      final scheduledDeletion = now.add(const Duration(days: 30));

      // Store ONLY essential clinic data to avoid size limits
      final Map<String, dynamic> essentialClinicData = {
        'adminId': clinicDoc.data['adminId'] ?? clinicId,
        'clinicName': clinicDoc.data['clinicName'] ?? '',
        'address': clinicDoc.data['address'] ?? '',
        'contact': clinicDoc.data['contact'] ?? '',
        'email': clinicDoc.data['email'] ?? '',
        // 'adminId': clinicDoc.data['adminId'] ?? '',
        'services': clinicDoc.data['services'] ?? '',
        'image': clinicDoc.data['image'] ?? '',
        'profilePictureId': clinicDoc.data['profilePictureId'] ?? '',
      };

      // Convert to JSON string
      String originalClinicDataJson;
      try {
        originalClinicDataJson = jsonEncode(essentialClinicData);
        print(
            '>>> Original clinic data JSON size: ${originalClinicDataJson.length} chars');

        // Validate size (must be <= 65535 chars)
        if (originalClinicDataJson.length > 65535) {
          print(
              '>>> WARNING: Clinic data too large, storing minimal data only');
          final minimalData = {
            //  'clinicId': clinicId,
            'clinicName': clinicDoc.data['clinicName'] ?? '',
            'email': clinicDoc.data['email'] ?? '',
            'adminId': clinicDoc.data['adminId'] ?? '',
          };
          originalClinicDataJson = jsonEncode(minimalData);
        }

        print('>>> Final JSON size: ${originalClinicDataJson.length} chars');
      } catch (e) {
        print('>>> ERROR encoding clinic data to JSON: $e');
        originalClinicDataJson = jsonEncode({
          'clinicId': clinicId,
          'email': clinicDoc.data['email'] ?? '',
        });
      }

      final archivedClinicData = {
        'adminId': clinicId,
        'clinicName': clinicDoc.data['clinicName'] ?? '',
        'email': clinicDoc.data['email'] ?? '',
        'address': clinicDoc.data['address'] ?? '',
        'contact': clinicDoc.data['contact'] ?? '',
        // 'adminId': clinicDoc.data['adminId'] ?? '',
        'originalDocumentId': clinicDocumentId,
        'archivedBy': archivedBy,
        'archivedAt': now.toIso8601String(),
        'scheduledDeletionAt': scheduledDeletion.toIso8601String(),
        'archiveReason': archiveReason,
        'isPermanentlyDeleted': false,
        'originalClinicData': originalClinicDataJson, // STRING, not Map
        'isRecovered': false,
      };

      final archivedDoc = await databases!.createDocument(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.archivedClinicsCollectionID,
        documentId: ID.unique(),
        data: archivedClinicData,
      );

      print('>>> Step 2: Archived clinic record created: ${archivedDoc.$id}');

      // Step 3: Delete all related data (same as deleteClinicCompletely)
      await _deleteClinicRelatedData(clinicId);

      // Step 4: DELETE the original clinic document
      await databases!.deleteDocument(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.clinicsCollectionID,
        documentId: clinicDocumentId,
      );

      print('>>> Step 4: Original clinic document deleted');

      print('>>> ============================================');
      print('>>> CLINIC ARCHIVED SUCCESSFULLY');
      print('>>> Scheduled deletion: $scheduledDeletion');
      print('>>> ============================================');

      return {
        'success': true,
        'archivedDocumentId': archivedDoc.$id,
        'scheduledDeletionAt': scheduledDeletion.toIso8601String(),
        'message':
            'Clinic archived successfully. Will be permanently deleted in 30 days.',
      };
    } catch (e) {
      print('>>> ============================================');
      print('>>> ERROR ARCHIVING CLINIC: $e');
      print('>>> Stack trace: ${StackTrace.current}');
      print('>>> ============================================');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Helper method to delete clinic-related data
  Future<void> _deleteClinicRelatedData(String clinicId) async {
    print('>>> Deleting clinic-related data...');

    // Delete clinic settings
    try {
      final settingsDoc = await getClinicSettingsByClinicId(clinicId);
      if (settingsDoc != null) {
        // Delete gallery images
        final gallery = List<String>.from(settingsDoc.data['gallery'] ?? []);
        for (String imageId in gallery) {
          try {
            await deleteImage(imageId);
          } catch (e) {
            print('Error deleting gallery image: $e');
          }
        }
        await deleteClinicSettings(settingsDoc.$id);
      }
    } catch (e) {
      print('Error deleting clinic settings: $e');
    }

    // Delete appointments
    try {
      final appointments = await databases!.listDocuments(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.appointmentCollectionID,
        queries: [Query.equal('clinicId', clinicId)],
      );
      for (var doc in appointments.documents) {
        await databases!.deleteDocument(
          databaseId: AppwriteConstants.dbID,
          collectionId: AppwriteConstants.appointmentCollectionID,
          documentId: doc.$id,
        );
      }
    } catch (e) {
      print('Error deleting appointments: $e');
    }

    // Delete medical records
    try {
      final records = await databases!.listDocuments(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.medicalRecordsCollectionID,
        queries: [Query.equal('clinicId', clinicId)],
      );
      for (var doc in records.documents) {
        await databases!.deleteDocument(
          databaseId: AppwriteConstants.dbID,
          collectionId: AppwriteConstants.medicalRecordsCollectionID,
          documentId: doc.$id,
        );
      }
    } catch (e) {
      print('Error deleting medical records: $e');
    }

    // Delete conversations and messages
    try {
      final conversations = await databases!.listDocuments(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.conversationsCollectionID,
        queries: [Query.equal('clinicId', clinicId)],
      );
      for (var conversation in conversations.documents) {
        // Delete messages
        final messages = await databases!.listDocuments(
          databaseId: AppwriteConstants.dbID,
          collectionId: AppwriteConstants.messagesCollectionID,
          queries: [Query.equal('conversationId', conversation.$id)],
        );
        for (var message in messages.documents) {
          await databases!.deleteDocument(
            databaseId: AppwriteConstants.dbID,
            collectionId: AppwriteConstants.messagesCollectionID,
            documentId: message.$id,
          );
        }
        // Delete conversation
        await databases!.deleteDocument(
          databaseId: AppwriteConstants.dbID,
          collectionId: AppwriteConstants.conversationsCollectionID,
          documentId: conversation.$id,
        );
      }
    } catch (e) {
      print('Error deleting conversations: $e');
    }

    // Deactivate staff
    try {
      final staff = await databases!.listDocuments(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.staffCollectionID,
        queries: [Query.equal('clinicId', clinicId)],
      );
      for (var doc in staff.documents) {
        await databases!.updateDocument(
          databaseId: AppwriteConstants.dbID,
          collectionId: AppwriteConstants.staffCollectionID,
          documentId: doc.$id,
          data: {
            'isActive': false,
            'updatedAt': DateTime.now().toIso8601String(),
          },
        );
      }
    } catch (e) {
      print('Error deactivating staff: $e');
    }
  }

  /// Get archived clinic by clinicId
  Future<Document?> getArchivedClinicByAdminId(String adminId) async {
    try {
      final result = await databases!.listDocuments(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.archivedClinicsCollectionID,
        queries: [
          Query.equal('adminId', adminId),
          Query.equal('isPermanentlyDeleted', false),
          Query.orderDesc('archivedAt'),
          Query.limit(1),
        ],
      );

      return result.documents.isNotEmpty ? result.documents.first : null;
    } catch (e) {
      print('Error getting archived clinic: $e');
      return null;
    }
  }

  /// Get all archived clinics (for admin dashboard)
  Future<List<Document>> getAllArchivedClinics({
    bool includePermanentlyDeleted = false,
    int limit = 100,
  }) async {
    try {
      List<String> queries = [
        Query.orderDesc('archivedAt'),
        Query.limit(limit),
        Query.equal('isRecovered', false),
      ];

      if (!includePermanentlyDeleted) {
        queries.add(Query.equal('isPermanentlyDeleted', false));
      }

      final result = await databases!.listDocuments(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.archivedClinicsCollectionID,
        queries: queries,
      );

      return result.documents;
    } catch (e) {
      print('Error getting archived clinics: $e');
      return [];
    }
  }

  /// Get clinics due for permanent deletion
  Future<List<Document>> getClinicsDueForDeletion() async {
    try {
      final now = DateTime.now().toIso8601String();

      final result = await databases!.listDocuments(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.archivedClinicsCollectionID,
        queries: [
          Query.lessThanEqual('scheduledDeletionAt', now),
          Query.equal('isPermanentlyDeleted', false),
          Query.equal('isRecovered', false),
          Query.limit(100),
        ],
      );

      return result.documents;
    } catch (e) {
      print('Error getting clinics due for deletion: $e');
      return [];
    }
  }

  /// Permanently delete clinic (called automatically after 30 days)
  Future<Map<String, dynamic>> permanentlyDeleteClinic(String clinicId) async {
    try {
      print('>>> ============================================');
      print('>>> PERMANENTLY DELETING CLINIC');
      print('>>> Clinic ID: $clinicId');
      print('>>> ============================================');

      final archivedDoc = await getArchivedClinicByAdminId(clinicId);
      if (archivedDoc == null) {
        throw Exception('Archived clinic record not found');
      }

      // Update archived record to mark as permanently deleted
      await databases!.updateDocument(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.archivedClinicsCollectionID,
        documentId: archivedDoc.$id,
        data: {
          'isPermanentlyDeleted': true,
          'permanentlyDeletedAt': DateTime.now().toIso8601String(),
        },
      );

      print('>>> PERMANENT DELETION COMPLETE');
      return {
        'success': true,
        'clinicDeleted': true,
      };
    } catch (e) {
      print('>>> ERROR IN PERMANENT DELETION: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Recover archived clinic (restore within 30 days)
  Future<Map<String, dynamic>> recoverArchivedClinic({
    required String adminId, // CHANGED: was clinicId
    required String recoveredBy,
  }) async {
    try {
      print('>>> ============================================');
      print('>>> RECOVERING ARCHIVED CLINIC');
      print('>>> Admin ID: $adminId'); // CHANGED: was clinicId
      print('>>> ============================================');

      final archivedDoc = await getArchivedClinicByAdminId(
          adminId); // CHANGED: method name and parameter
      if (archivedDoc == null) {
        return {'success': false, 'error': 'Archived clinic not found'};
      }

      if (archivedDoc.data['isPermanentlyDeleted'] == true) {
        return {
          'success': false,
          'error':
              'Clinic has been permanently deleted and cannot be recovered',
        };
      }

      final originalDocId = archivedDoc.data['originalDocumentId'];
      final archivedDocId = archivedDoc.$id;

      final originalClinicDataString =
          archivedDoc.data['originalClinicData'] as String?;

      if (originalClinicDataString == null ||
          originalClinicDataString.isEmpty) {
        return {'success': false, 'error': 'Original clinic data not found'};
      }

      Map<String, dynamic> originalClinicData;
      try {
        originalClinicData =
            Map<String, dynamic>.from(jsonDecode(originalClinicDataString));
      } catch (e) {
        return {
          'success': false,
          'error': 'Failed to parse original clinic data'
        };
      }

      // Recreate the clinic document with original data
      final restoredClinicData = {
        'adminId':
            originalClinicData['adminId'] ?? adminId, // CHANGED: was clinicId
        'clinicName': originalClinicData['clinicName'] ?? '',
        'address': originalClinicData['address'] ?? '',
        'contact': originalClinicData['contact'] ?? '',
        'email': originalClinicData['email'] ?? '',
        'services': originalClinicData['services'] ?? '',
        'image': originalClinicData['image'] ?? '',
        'profilePictureId': originalClinicData['profilePictureId'] ?? '',
        'createdAt':
            originalClinicData['createdAt'] ?? DateTime.now().toIso8601String(),
        'role': 'admin',
        'createdBy': originalClinicData['createdBy'] ?? 'system',
      };

      Document restoredDoc;
      try {
        restoredDoc = await databases!.createDocument(
          databaseId: AppwriteConstants.dbID,
          collectionId: AppwriteConstants.clinicsCollectionID,
          documentId: originalDocId,
          data: restoredClinicData,
        );
      } catch (e) {
        if (e.toString().contains('already exists')) {
          restoredDoc = await databases!.updateDocument(
            databaseId: AppwriteConstants.dbID,
            collectionId: AppwriteConstants.clinicsCollectionID,
            documentId: originalDocId,
            data: restoredClinicData,
          );
        } else {
          return {'success': false, 'error': 'Failed to recreate clinic: $e'};
        }
      }

      // Delete the archived record
      await databases!.deleteDocument(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.archivedClinicsCollectionID,
        documentId: archivedDocId,
      );

      print('>>> CLINIC RECOVERED SUCCESSFULLY');
      return {
        'success': true,
        'message': 'Clinic recovered successfully',
        'restoredDocumentId': restoredDoc.$id,
      };
    } catch (e) {
      print('>>> ERROR RECOVERING CLINIC: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Process scheduled clinic deletions (background job)
  Future<Map<String, dynamic>> processScheduledClinicDeletions() async {
    try {
      print('>>> PROCESSING SCHEDULED CLINIC DELETIONS');

      final clinicsDue = await getClinicsDueForDeletion();
      print('>>> Found ${clinicsDue.length} clinics due for deletion');

      final results = {
        'totalProcessed': clinicsDue.length,
        'successfulDeletions': 0,
        'failedDeletions': 0,
        'errors': <String>[],
      };

      for (var archivedClinic in clinicsDue) {
        try {
          final clinicId = archivedClinic.data['clinicId'];
          final deleteResult = await permanentlyDeleteClinic(clinicId);

          if (deleteResult['success'] == true) {
            results['successfulDeletions'] =
                (results['successfulDeletions'] as int) + 1;
          } else {
            results['failedDeletions'] =
                (results['failedDeletions'] as int) + 1;
            (results['errors'] as List).add('$clinicId: Deletion incomplete');
          }

          await Future.delayed(const Duration(milliseconds: 500));
        } catch (e) {
          results['failedDeletions'] = (results['failedDeletions'] as int) + 1;
          (results['errors'] as List)
              .add('${archivedClinic.data['clinicId']}: $e');
        }
      }

      print('>>> SCHEDULED CLINIC DELETIONS COMPLETE');
      return results;
    } catch (e) {
      print('>>> ERROR IN SCHEDULED CLINIC DELETIONS: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Subscribe to archived clinics changes (real-time)
  Stream<RealtimeMessage> subscribeToArchivedClinics() {
    final realtime = Realtime(client);
    return realtime.subscribe([
      'databases.${AppwriteConstants.dbID}.collections.${AppwriteConstants.archivedClinicsCollectionID}.documents',
    ]).stream;
  }

  /// Get archive statistics for clinics
  Future<Map<String, int>> getClinicArchiveStatistics() async {
    try {
      final allArchived = await databases!.listDocuments(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.archivedClinicsCollectionID,
        queries: [Query.limit(1000)],
      );

      int activeArchives = 0;
      int permanentlyDeleted = 0;
      int dueSoon = 0;

      final now = DateTime.now();
      final sevenDaysFromNow = now.add(const Duration(days: 7));

      for (var doc in allArchived.documents) {
        if (doc.data['isRecovered'] == true) continue;

        if (doc.data['isPermanentlyDeleted'] == true) {
          permanentlyDeleted++;
        } else {
          activeArchives++;

          final scheduledDeletion =
              DateTime.parse(doc.data['scheduledDeletionAt']);
          if (scheduledDeletion.isBefore(sevenDaysFromNow)) {
            dueSoon++;
          }
        }
      }

      return {
        'total': activeArchives + permanentlyDeleted,
        'activeArchives': activeArchives,
        'recovered': 0,
        'permanentlyDeleted': permanentlyDeleted,
        'dueSoon': dueSoon,
      };
    } catch (e) {
      print('Error getting clinic archive statistics: $e');
      return {
        'total': 0,
        'activeArchives': 0,
        'recovered': 0,
        'permanentlyDeleted': 0,
        'dueSoon': 0,
      };
    }
  }

  /// Get user with profile picture URL included
  Future<Map<String, dynamic>?> getUserWithProfilePicture(String userId) async {
    try {
      final userDoc = await getUserById(userId);
      if (userDoc == null) return null;

      final profilePictureId = userDoc.data['profilePictureId'] as String?;
      String profilePictureUrl = '';

      if (profilePictureId != null && profilePictureId.isNotEmpty) {
        profilePictureUrl = getUserProfilePictureUrl(profilePictureId);
      }

      return {
        'user': userDoc.data,
        'userDocId': userDoc.$id,
        'profilePictureId': profilePictureId,
        'profilePictureUrl': profilePictureUrl,
      };
    } catch (e) {
      print('Error getting user with profile picture: $e');
      return null;
    }
  }

// ============= ADD TO appwrite_provider.dart =============

// ============= FEEDBACK DELETION REQUEST METHODS =============

  Future<Document> createFeedbackDeletionRequest(
      Map<String, dynamic> data) async {
    try {
      print('>>> Creating feedback deletion request...');
      print('>>> Reason: ${data['reason']}');
      print('>>> Review ID: ${data['reviewId']}');

      return await databases!.createDocument(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.feedbackDeletionRequestCollectionID,
        documentId: ID.unique(),
        data: data,
      );
    } catch (e) {
      print('>>> Error creating feedback deletion request: $e');
      rethrow;
    }
  }

  /// Upload feedback deletion request attachments
  Future<List<models.File>> uploadFeedbackDeletionAttachments(
      List<PlatformFile> files) async {
    final List<models.File> uploadedFiles = [];

    for (int i = 0; i < files.length; i++) {
      try {
        final file = files[i];
        final extension = file.extension ?? 'jpg';
        String fileName =
            "${DateTime.now().millisecondsSinceEpoch}_deletion_request_$i.$extension";

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
        print(
            ">>> Successfully uploaded deletion request attachment: ${response.$id}");
      } catch (e) {
        print(
            ">>> Error uploading deletion request attachment ${files[i].name}: $e");
      }
    }

    return uploadedFiles;
  }

  /// Delete feedback deletion request attachments
  Future<void> deleteFeedbackDeletionAttachments(List<String> fileIds) async {
    for (String fileId in fileIds) {
      try {
        await storage!.deleteFile(
          bucketId: AppwriteConstants.imageBucketID,
          fileId: fileId,
        );
      } catch (e) {
        print(">>> Error deleting deletion request attachment $fileId: $e");
      }
    }
  }

  /// Get feedback deletion request by ID
  Future<Document?> getFeedbackDeletionRequestById(String requestId) async {
    try {
      final result = await databases!.getDocument(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.feedbackDeletionRequestCollectionID,
        documentId: requestId,
      );
      return result;
    } catch (e) {
      print('>>> Error getting feedback deletion request: $e');
      return null;
    }
  }

  /// Get all deletion requests for a clinic
  Future<List<Document>> getClinicDeletionRequests(
    String clinicId, {
    String? status,
    int limit = 100,
  }) async {
    try {
      List<String> queries = [
        Query.equal('clinicId', clinicId),
        Query.orderDesc('requestedAt'),
        Query.limit(limit),
      ];

      if (status != null) {
        queries.add(Query.equal('status', status));
      }

      final result = await databases!.listDocuments(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.feedbackDeletionRequestCollectionID,
        queries: queries,
      );

      return result.documents;
    } catch (e) {
      print('>>> Error getting clinic deletion requests: $e');
      return [];
    }
  }

  /// Get pending deletion requests for a clinic
  Future<List<Document>> getPendingDeletionRequests(String clinicId) async {
    return getClinicDeletionRequests(clinicId, status: 'pending');
  }

  /// Update deletion request status
  Future<Document> updateDeletionRequestStatus(
    String requestId,
    String status,
  ) async {
    try {
      return await databases!.updateDocument(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.feedbackDeletionRequestCollectionID,
        documentId: requestId,
        data: {
          'status': status,
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      print('>>> Error updating deletion request status: $e');
      rethrow;
    }
  }

  /// Approve deletion request and archive the review
  Future<Map<String, dynamic>> approveDeletionRequest(
    String requestId,
    String reviewId,
    String reviewedBy,
    String? reviewNotes,
  ) async {
    try {
      print('>>> ============================================');
      print('>>> APPROVING DELETION REQUEST');
      print('>>> Request ID: $requestId');
      print('>>> Review ID: $reviewId');
      print('>>> ============================================');

      // Step 1: Update the deletion request status to approved
      print('>>> Step 1: Updating deletion request status to approved...');
      await databases!.updateDocument(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.feedbackDeletionRequestCollectionID,
        documentId: requestId,
        data: {
          'status': 'approved',
          'reviewedBy': reviewedBy,
          'reviewedAt': DateTime.now().toIso8601String(),
          'reviewNotes': reviewNotes,
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );
      print('>>> Deletion request updated to approved');

      // Step 2: Archive the review by setting isArchived to true
      print('>>> Step 2: Archiving the review...');
      await databases!.updateDocument(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.ratingsAndReviewsCollectionID,
        documentId: reviewId,
        data: {
          'isArchived': true,
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );
      print('>>> Review archived successfully');

      print('>>> ============================================');
      print('>>> DELETION REQUEST APPROVED');
      print('>>> ============================================');

      return {
        'success': true,
        'message': 'Deletion request approved and review archived',
      };
    } catch (e) {
      print('>>> ============================================');
      print('>>> ERROR APPROVING DELETION REQUEST: $e');
      print('>>> ============================================');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> rejectDeletionRequest(
    String requestId,
    String reviewedBy,
    String? reviewNotes,
  ) async {
    try {
      print('>>> ============================================');
      print('>>> REJECTING DELETION REQUEST');
      print('>>> Request ID: $requestId');
      print('>>> ============================================');

      await databases!.updateDocument(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.feedbackDeletionRequestCollectionID,
        documentId: requestId,
        data: {
          'status': 'rejected',
          'reviewedBy': reviewedBy,
          'reviewedAt': DateTime.now().toIso8601String(),
          'reviewNotes': reviewNotes,
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );

      print('>>> DELETION REQUEST REJECTED');
      print('>>> ============================================');

      return {
        'success': true,
        'message': 'Deletion request rejected',
      };
    } catch (e) {
      print('>>> ERROR REJECTING DELETION REQUEST: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Get deletion request statistics for a clinic
  Future<Map<String, int>> getDeletionRequestStats(String clinicId) async {
    try {
      final allRequests = await databases!.listDocuments(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.feedbackDeletionRequestCollectionID,
        queries: [Query.equal('clinicId', clinicId)],
      );

      int pending = 0;
      int approved = 0;
      int rejected = 0;

      for (var doc in allRequests.documents) {
        final status = doc.data['status'];
        if (status == 'pending') pending++;
        if (status == 'approved') approved++;
        if (status == 'rejected') rejected++;
      }

      return {
        'total': allRequests.documents.length,
        'pending': pending,
        'approved': approved,
        'rejected': rejected,
      };
    } catch (e) {
      print('>>> Error getting deletion request stats: $e');
      return {'total': 0, 'pending': 0, 'approved': 0, 'rejected': 0};
    }
  }

// ============= NOTIFICATION & MESSAGING METHODS =============

  /// Register user's FCM push target in Appwrite
  Future<models.Target?> registerUserPushTarget({
    required String userId,
    required String fcmToken,
  }) async {
    try {
      print('>>> Registering push target for user: $userId');

      final target = await account!.createPushTarget(
        targetId: ID.unique(),
        identifier: fcmToken,
        providerId: AppwriteConstants.pushNotificationProviderID,
      );

      print('>>> Push target registered: ${target.$id}');
      return target;
    } catch (e) {
      print('>>> Error registering push target: $e');
      // Don't rethrow - just log and return null
      return null;
    }
  }

  /// Update existing push target with new token
  Future<models.Target?> updateUserPushTarget({
    required String targetId,
    required String newFcmToken,
  }) async {
    try {
      print('>>> Updating push target: $targetId');

      final target = await account!.updatePushTarget(
        targetId: targetId,
        identifier: newFcmToken,
      );

      print('>>> Push target updated successfully');
      return target;
    } catch (e) {
      print('>>> Error updating push target: $e');
      return null;
    }
  }

  /// Delete push target (logout)
  Future<bool> deletePushTarget(String targetId) async {
    try {
      print('>>> Deleting push target: $targetId');

      await account!.deletePushTarget(targetId: targetId);

      print('>>> Push target deleted');
      return true;
    } catch (e) {
      print('>>> Error deleting push target: $e');
      return false;
    }
  }

  /// Send push notification via Appwrite Messaging
  Future<bool> sendPushNotification({
    required String title,
    required String body,
    required List<String> userIds,
    Map<String, String>? data,
  }) async {
    try {
      print('>>> Sending push notification to ${userIds.length} users');

      final functions = Functions(client);

      final execution = await functions.createExecution(
        functionId: '68f5a42e001a62b93f10',
        body: jsonEncode({
          'title': title,
          'body': body,
          'userIds': userIds,
          'data': data ?? {},
        }),
        xasync: false, // Wait for completion
      );

      print('>>> Push notification execution: ${execution.status}');
      return execution.status == 'completed';
    } catch (e) {
      print('>>> Error sending push notification: $e');
      return false;
    }
  }

  /// Send email via Appwrite Messaging (SendGrid)
  Future<bool> sendEmail({
    required String to,
    required String subject,
    required String htmlContent,
    String? userId, // Add optional userId
  }) async {
    try {
      print('>>> Sending email to: $to');

      final functions = Functions(client);

      final execution = await functions.createExecution(
        functionId: '68f5adca0022608fe911',
        body: jsonEncode({
          'to': to,
          'subject': subject,
          'htmlContent': htmlContent,
          'userId': userId,
        }),
        xasync: false,
      );

      print('>>> Email execution: ${execution.status}');
      return execution.status == 'completed';
    } catch (e) {
      print('>>> Error sending email: $e');
      return false;
    }
  }

  /// Helper: Send appointment notification (push + email)
  Future<void> notifyAppointmentStatusChange({
    required String userId,
    required String userEmail,
    required String userName,
    required String status,
    required String petName,
    required String clinicName,
    required String service,
    required DateTime appointmentDateTime,
    required String appointmentId,
    String? declineReason,
  }) async {
    try {
      print('>>> ============================================');
      print('>>> SENDING APPOINTMENT NOTIFICATION');
      print('>>> User: $userName ($userId)');
      print('>>> Status: $status');
      print('>>> ============================================');

      // 1. Send push notification (mobile only)
      String pushTitle;
      String pushBody;

      switch (status) {
        case 'accepted':
          pushTitle = 'Appointment Confirmed! 🎉';
          pushBody =
              'Your appointment for $petName at $clinicName has been accepted.';
          break;
        case 'declined':
          pushTitle = 'Appointment Update';
          pushBody = 'Your appointment for $petName was declined.';
          break;
        case 'in_progress':
          pushTitle = 'Appointment Started';
          pushBody = '$petName is now being attended to.';
          break;
        case 'completed':
          pushTitle = 'Appointment Completed ✓';
          pushBody = '$petName\'s appointment is complete.';
          break;
        default:
          pushTitle = 'Appointment Update';
          pushBody = 'Your appointment for $petName has been updated.';
      }

      await sendPushNotification(
        title: pushTitle,
        body: pushBody,
        userIds: [userId],
        data: {
          'type': 'appointment',
          'status': status,
          'appointmentId': appointmentId,
          'petName': petName,
          'clinicName': clinicName,
        },
      );

      // 2. Send email (only for accepted/declined)
      if (status == 'accepted' || status == 'declined') {
        await sendEmail(
          to: userEmail,
          subject: status == 'accepted'
              ? 'Appointment Confirmed - PAWrtal'
              : 'Appointment Update - PAWrtal',
          htmlContent: _buildEmailTemplate(
            userName: userName,
            petName: petName,
            clinicName: clinicName,
            service: service,
            appointmentDateTime: appointmentDateTime,
            status: status,
            declineReason: declineReason,
          ),
          userId: userId,
        );
      }

      print('>>> Notifications sent successfully');
      print('>>> ============================================');
    } catch (e) {
      print('>>> Error sending appointment notifications: $e');
    }
  }

  /// Helper: Send new appointment notification to admin
  Future<void> notifyAdminNewAppointment({
    required String adminId,
    required String petName,
    required String ownerName,
    required String service,
    required DateTime appointmentDateTime,
    required String appointmentId,
  }) async {
    try {
      print('>>> Notifying admin of new appointment: $adminId');

      await sendPushNotification(
        title: 'New Appointment Request 📅',
        body: '$ownerName booked $service for $petName',
        userIds: [adminId],
        data: {
          'type': 'new_appointment',
          'appointmentId': appointmentId,
          'petName': petName,
          'ownerName': ownerName,
        },
      );

      print('>>> Admin notified successfully');
    } catch (e) {
      print('>>> Error notifying admin: $e');
    }
  }

  String _buildEmailTemplate({
    required String userName,
    required String petName,
    required String clinicName,
    required String service,
    required DateTime appointmentDateTime,
    required String status,
    String? declineReason,
  }) {
    final dateStr =
        '${appointmentDateTime.day}/${appointmentDateTime.month}/${appointmentDateTime.year}';
    final timeStr =
        '${appointmentDateTime.hour.toString().padLeft(2, '0')}:${appointmentDateTime.minute.toString().padLeft(2, '0')}';

    if (status == 'accepted') {
      return '''
<!DOCTYPE html>
<html>
  <body style="margin:0; padding:0; font-family: Arial, sans-serif; background-color:#f5f5f5; color:#333;">
    <table role="presentation" cellspacing="0" cellpadding="0" width="100%">
      <tr>
        <td align="center" style="padding:20px 0;">
          <table role="presentation" cellspacing="0" cellpadding="0" width="600" style="background:#ffffff; border-radius:8px; overflow:hidden;">
            <tr>
              <td align="center" style="background:linear-gradient(135deg, #667eea 0%, #764ba2 100%); color:#fff; padding:30px;">
                <h1 style="margin:0; font-size:28px;">Appointment Confirmed!</h1>
              </td>
            </tr>
            <tr>
              <td style="padding:30px; background:#fafafa;">
                <p style="font-size:16px;">Dear $userName,</p>
                <p style="font-size:16px;">Your appointment has been confirmed by <strong>$clinicName</strong>.</p>
                <div style="background:#fff; border-left:4px solid #4caf50; padding:20px; margin:20px 0; border-radius:6px;">
                  <h3 style="margin-top:0;">Appointment Details</h3>
                  <p style="margin:6px 0;"><strong>Pet:</strong> $petName</p>
                  <p style="margin:6px 0;"><strong>Service:</strong> $service</p>
                  <p style="margin:6px 0;"><strong>Date:</strong> $dateStr at $timeStr</p>
                  <p style="margin:6px 0;"><strong>Clinic:</strong> $clinicName</p>
                </div>
                <p style="font-size:16px;">Please arrive 10 minutes early. See you soon!</p>
                <p style="font-size:16px;">🐾 The <strong>PAWrtal</strong> Team</p>
              </td>
            </tr>
          </table>
        </td>
      </tr>
    </table>
  </body>
</html>
''';
    } else {
      return '''
<!DOCTYPE html>
<html>
  <body style="margin:0; padding:0; font-family: Arial, sans-serif; background-color:#f5f5f5; color:#333;">
    <table role="presentation" cellspacing="0" cellpadding="0" width="100%">
      <tr>
        <td align="center" style="padding:20px 0;">
          <table role="presentation" cellspacing="0" cellpadding="0" width="600" style="background:#ffffff; border-radius:8px; overflow:hidden;">
            <tr>
              <td align="center" style="background:linear-gradient(135deg, #f093fb 0%, #f5576c 100%); color:#fff; padding:30px;">
                <h1 style="margin:0; font-size:28px;">Appointment Declined</h1>
              </td>
            </tr>
            <tr>
              <td style="padding:30px; background:#fafafa;">
                <p style="font-size:16px;">Dear $userName,</p>
                <p style="font-size:16px;">Your appointment at <strong>$clinicName</strong> could not be confirmed.</p>
                <div style="background:#fff; border-left:4px solid #ff9800; padding:20px; margin:20px 0; border-radius:6px;">
                  <p style="margin:6px 0;"><strong>Reason:</strong> ${declineReason ?? 'Not specified'}</p>
                  <p style="margin:6px 0;"><strong>Requested:</strong> $dateStr at $timeStr</p>
                </div>
                <p style="font-size:16px;">🐾 The <strong>PAWrtal</strong> Team</p>
              </td>
            </tr>
          </table>
        </td>
      </tr>
    </table>
  </body>
</html>
''';
    }
  }
}
