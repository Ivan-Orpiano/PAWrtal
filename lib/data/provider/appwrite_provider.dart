import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:capstone_app/pages/utils/appwrite_constant.dart';
import 'package:flutter/material.dart';

class AppWriteProvider{
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
    final response = await account!.create(
      userId: map["userId"], 
      email: map["email"], 
      password: map["password"], 
      name: map["name"]
    );

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

    Future<models.Session> login(Map map) async {
    final response = await account!.createEmailSession(
      email: map["email"], 
      password: map["password"], 
    );
    return response;
  }

  Future<dynamic> logout(String sessionId) async {
    final response = await account!.deleteSession(
      sessionId: sessionId
    );
    return response;
  }

  Future<models.File> uploadStaffImage(String imagePath) {
    String fileName = "${DateTime.now().millisecondsSinceEpoch}.${imagePath.split('.').last}";

      final response = storage!.createFile(
        bucketId: AppwriteConstants.staffBucketID,
        fileId: ID.unique(),
        file: InputFile.fromPath(path:imagePath, filename: fileName));

        return response;
  }

  Future<dynamic> deleteStaffImage(String fileId) {
      final response = storage!.deleteFile(
        bucketId: AppwriteConstants.staffBucketID,
        fileId: fileId,
        );

        return response;
  }

  Future<models.Document> createStaff(Map map) async {
    final response = databases!.createDocument(
      databaseId: AppwriteConstants.dbID, 
      collectionId: AppwriteConstants.staffCollectionID, 
      documentId: ID.unique(), 
      data: {
        "name": map["name"],
        "department": map["department"],
        "createdBy": map["createdBy"],
        "image": map["image"],
        "createdAt": map["createdAt"]
      });
      return response;
  }

  Future<models.DocumentList> getStaff() async {
    final response = databases!.listDocuments(
      databaseId: AppwriteConstants.dbID, 
      collectionId: AppwriteConstants.staffCollectionID, 
    );
    return response;
  }

  Future<models.Document> updateStaff(Map map) async {
    final response = databases!.updateDocument(
      databaseId: AppwriteConstants.dbID, 
      collectionId: AppwriteConstants.staffCollectionID,
      documentId: map["documentId"],
      data: {
        "name": map["name"],
        "department": map["department"],
        "createdBy": map["createdBy"],
        "image": map["image"],

      });
    return response;

  }

}