import 'package:capstone_app/data/provider/appwrite_provider.dart';
import 'package:appwrite/models.dart' as models;

class AuthRepository {
  final AppWriteProvider appWriteProvider;
  AuthRepository(this.appWriteProvider);

  Future<models.User> signup(Map map) => appWriteProvider.signup(map);
  Future<models.Document> createUser(Map map) =>
      appWriteProvider.createUser(map);
  Future<Map<String, dynamic>> login(Map map) => appWriteProvider.login(map);
  Future<dynamic> logout(String sessionId) =>
      appWriteProvider.logout(sessionId);

  Future<models.User?> getUser() => appWriteProvider.getUser();

  Future<models.File> uploadImage(String imagePath) =>
      appWriteProvider.uploadImage(imagePath);
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

  Future<models.Document?> getStaffByClinicId(String clinicId) =>
      appWriteProvider.getStaffByClinicId(clinicId);

  Future<models.Document?> getUserById(String userId) =>
      appWriteProvider.getUserById(userId);

  Future<models.Document> createPet(Map map) => appWriteProvider.createPet(map);

  Future<List<models.Document>> getUserPets(String userId) =>
      appWriteProvider.getUserPets(userId);
}
