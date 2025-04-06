import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:capstone_app/pages/utils/appwrite_constant.dart';
import 'package:flutter/material.dart';

enum AuthStatus {
  uninitialized,
  authenticated,
  unauthenticated,
}

class AppWriteProvider {
  Client client = Client();

  Account? account;
  Storage? storage;
  Databases? databases;

  AppWriteProvider() {
    client
        .setEndpoint(AppwriteConstants.endPoint)
        .setProject(AppwriteConstants.projectID)
        .setSelfSigned(status: true);

    account = Account(client);
    storage = Storage(client);
    databases = Databases(client);
  }

  Future<models.User> signup(Map map) async {
    try {
      debugPrint('Calling signup with user data: $map');

      if (account == null) throw Exception('Account is not initialized');

      final response = await account!.create(
          userId: map["userId"],
          email: map["email"],
          password: map["password"],
          name: map["name"]);

      //   await account!.updatePrefs(prefs: {
      //   "role": map["role"] ?? "customer",
      //   "verified": false, // user must complete verification
      // });

      // ignore: unnecessary_null_comparison
      if (response == null) {
        throw Exception('Signup failed: response is null');
      }

      debugPrint('Signup response: $response');
      return response;
    } catch (e) {
      debugPrint('Signup error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> login(Map map) async {
    final session = await account!.createEmailSession(
      email: map["email"],
      password: map["password"],
    );

    final user = await account!.get();
    final role = user.prefs.data["role"] ?? "customer";

    return {
      "session": session,
      "role": role,
    };
  }

  Future<bool> signInWithGoogle() async {
    try{
      final response = await account?.createOAuth2Session(provider: "google", scopes: [
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

  Future<models.User?> getUser() async {
    try {
      final user = await account!.get();
      return user;
    } catch (e) {
      return null;
    }
  }

  Future<dynamic> logout(String sessionId) async {
    final response = await account!.deleteSession(sessionId: sessionId);
    return response;
  }

  Future<models.File> uploadStaffImage(String imagePath) {
    String fileName =
        "${DateTime.now().millisecondsSinceEpoch}.${imagePath.split('.').last}";

    final response = storage!.createFile(
        bucketId: AppwriteConstants.staffBucketID,
        fileId: ID.unique(),
        file: InputFile.fromPath(path: imagePath, filename: fileName));

    return response;
  }

  Future<dynamic> deleteStaffImage(String fileId) async {
    await storage!.deleteFile(
      bucketId: AppwriteConstants.staffBucketID,
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
}
