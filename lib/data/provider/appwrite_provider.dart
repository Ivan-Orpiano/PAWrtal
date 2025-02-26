import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:capstone_app/pages/utils/appwrite_constant.dart';
import 'package:flutter/material.dart';

class AppWriteProvider{
  Client client = Client();

  Account? account;
  
  AppWriteProvider() {
    client
      .setEndpoint(AppwriteConstants.endPoint)
      .setProject(AppwriteConstants.projectID)
      .setSelfSigned(status: true);
    account = Account(client);
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
}