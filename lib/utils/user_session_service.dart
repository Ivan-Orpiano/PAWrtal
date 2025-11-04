import 'package:get_storage/get_storage.dart';
import 'package:uuid/uuid.dart';

class UserSessionService {
  final _storage = GetStorage();
  final _uuid = Uuid();

  String get userId => _storage.read("userId") ?? '';
  String get userName => _storage.read("userName") ?? "Unknown User";
  String get userEmail => _storage.read("email") ?? "";
  String get userRole => _storage.read("role") ?? "user";
  String get userPhone => _storage.read("phone") ?? "";
  
  // NEW: Session token for cross-tab synchronization
  String? get sessionToken => _storage.read('sessionToken');
  DateTime? get sessionTimestamp {
    final timestamp = _storage.read('sessionTimestamp');
    return timestamp != null ? DateTime.parse(timestamp) : null;
  }

  T? read<T>(String key) => _storage.read(key);
  void write(String key, dynamic value) => _storage.write(key, value);

  void saveUserId(String id) => _storage.write('userId', id);

  /// NEW: Generate and save a unique session token
  String generateSessionToken() {
    final token = _uuid.v4();
    _storage.write('sessionToken', token);
    _storage.write('sessionTimestamp', DateTime.now().toIso8601String());
    print('>>> Session token generated: ${token.substring(0, 10)}...');
    return token;
  }

  /// NEW: Validate session token
  bool isSessionValid(String token) {
    final storedToken = sessionToken;
    return storedToken != null && storedToken == token;
  }

  /// NEW: Clear session token
  void clearSessionToken() {
    _storage.remove('sessionToken');
    _storage.remove('sessionTimestamp');
  }

  Future<void> clearSession() async {
    await _storage.erase();
  }

  void debugSession() {
    print('=== USER SESSION DEBUG ===');
    print('User ID: $userId');
    print('Session Token: ${sessionToken?.substring(0, 10) ?? 'NULL'}');
    print('Session Timestamp: $sessionTimestamp');
    print('Session Keys: ${_storage.getKeys()}');
    print('Session Values: ${_storage.getValues()}');
    print('==========================');
  }

  bool get isLoggedIn => userId.isNotEmpty;
  Iterable<String> getKeys() => _storage.getKeys();
  Iterable<dynamic> getValues() => _storage.getValues();
}