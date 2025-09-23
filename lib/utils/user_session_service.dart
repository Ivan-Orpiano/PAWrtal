import 'package:get_storage/get_storage.dart';

class UserSessionService {
  final _storage = GetStorage();

  String get userId => _storage.read("userId") ?? '';

  void saveUserId(String id) => _storage.write('userId', id);

  void clearSession() => _storage.erase();

  // Add debugging method
  void debugSession() {
    print('=== USER SESSION DEBUG ===');
    print('User ID: $userId');
    print('Session Keys: ${_storage.getKeys()}');
    print('Session Values: ${_storage.getValues()}');
    print('==========================');
  }

  // Check if user is logged in
  bool get isLoggedIn => userId.isNotEmpty;
}