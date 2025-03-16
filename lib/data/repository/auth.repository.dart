import 'package:capstone_app/data/provider/appwrite_provider.dart';
import 'package:appwrite/models.dart' as models;

class AuthRepository {

  final AppWriteProvider appWriteProvider;
  AuthRepository(this.appWriteProvider);

  Future<models.User> signup(Map map) => appWriteProvider.signup(map);
  Future<models.Session> login(Map map) => appWriteProvider.login(map);
  Future<dynamic> logout(String sessionId) => appWriteProvider.logout(sessionId);

  Future<models.File> uploadStaffImage(String imagePath) => appWriteProvider.uploadStaffImage(imagePath);
  Future<dynamic> deleteStaffImage(String fileID) => appWriteProvider.deleteStaffImage(fileID);
  Future<models.Document> createStaff(Map map) => appWriteProvider.createStaff(map);
  Future<models.DocumentList> getStaff() => appWriteProvider.getStaff();
  Future<models.Document> updateStaff(Map map) => appWriteProvider.updateStaff(map);
}