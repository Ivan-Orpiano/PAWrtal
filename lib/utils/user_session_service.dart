import 'package:get_storage/get_storage.dart';

class UserSessionService {
  final _storage = GetStorage();

  String get userId => _storage.read("userId") ?? '';

  void saveUserId(String id) => _storage.write('userId', id);

  void clearSession() => _storage.erase();
}
