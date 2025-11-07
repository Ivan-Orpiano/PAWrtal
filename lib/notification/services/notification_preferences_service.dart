import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';

class NotificationPreferences {
  final bool pushNotificationsEnabled;
  final bool emailNotificationsEnabled;

  NotificationPreferences({
    this.pushNotificationsEnabled = true,
    this.emailNotificationsEnabled = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'pushNotificationsEnabled': pushNotificationsEnabled,
      'emailNotificationsEnabled': emailNotificationsEnabled,
    };
  }

  factory NotificationPreferences.fromMap(Map<String, dynamic> map) {
    return NotificationPreferences(
      pushNotificationsEnabled: map['pushNotificationsEnabled'] ?? true,
      emailNotificationsEnabled: map['emailNotificationsEnabled'] ?? true,
    );
  }

  NotificationPreferences copyWith({
    bool? pushNotificationsEnabled,
    bool? emailNotificationsEnabled,
  }) {
    return NotificationPreferences(
      pushNotificationsEnabled: pushNotificationsEnabled ?? this.pushNotificationsEnabled,
      emailNotificationsEnabled: emailNotificationsEnabled ?? this.emailNotificationsEnabled,
    );
  }
}

class NotificationPreferencesService extends GetxService {
  final AuthRepository authRepository;
  final GetStorage _storage = GetStorage();

  NotificationPreferencesService({required this.authRepository});

  // Observable preferences
  var preferences = NotificationPreferences().obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadPreferences();
  }

  /// Load notification preferences from database
  Future<void> loadPreferences() async {
    try {
      isLoading.value = true;
      
      final userId = _storage.read('userId') as String?;
      if (userId == null || userId.isEmpty) {
        print('>>> No user logged in, using default preferences');
        return;
      }

      print('>>> Loading notification preferences for user: $userId');

      // Get user document
      final userDocId = _storage.read('userDocumentId') as String?;
      if (userDocId == null || userDocId.isEmpty) {
        print('>>> User document ID not found, using default preferences');
        return;
      }

      final userDoc = await authRepository.getUserById(userDocId);
      if (userDoc == null) {
        print('>>> User document not found');
        return;
      }

      // Extract preferences from user document
      final pushEnabled = userDoc.data['pushNotificationsEnabled'] ?? true;
      final emailEnabled = userDoc.data['emailNotificationsEnabled'] ?? true;

      preferences.value = NotificationPreferences(
        pushNotificationsEnabled: pushEnabled,
        emailNotificationsEnabled: emailEnabled,
      );

      print('>>> Preferences loaded:');
      print('>>>   Push: $pushEnabled');
      print('>>>   Email: $emailEnabled');

    } catch (e) {
      print('>>> Error loading notification preferences: $e');
      // Use default preferences on error
      preferences.value = NotificationPreferences();
    } finally {
      isLoading.value = false;
    }
  }

  /// Update push notification preference
  Future<bool> updatePushNotificationPreference(bool enabled) async {
    try {
      isLoading.value = true;
      print('>>> Updating push notification preference to: $enabled');

      final userDocId = _storage.read('userDocumentId') as String?;
      if (userDocId == null || userDocId.isEmpty) {
        throw Exception('User document ID not found');
      }

      // Update in database
      await authRepository.updateUserProfile(
        documentId: userDocId,
        fields: {
          'pushNotificationsEnabled': enabled,
        },
      );

      // Update local state
      preferences.value = preferences.value.copyWith(
        pushNotificationsEnabled: enabled,
      );

      print('>>> ✅ Push notification preference updated');
      return true;

    } catch (e) {
      print('>>> ❌ Error updating push notification preference: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Update email notification preference
  Future<bool> updateEmailNotificationPreference(bool enabled) async {
    try {
      isLoading.value = true;
      print('>>> Updating email notification preference to: $enabled');

      final userDocId = _storage.read('userDocumentId') as String?;
      if (userDocId == null || userDocId.isEmpty) {
        throw Exception('User document ID not found');
      }

      // Update in database
      await authRepository.updateUserProfile(
        documentId: userDocId,
        fields: {
          'emailNotificationsEnabled': enabled,
        },
      );

      // Update local state
      preferences.value = preferences.value.copyWith(
        emailNotificationsEnabled: enabled,
      );

      print('>>> ✅ Email notification preference updated');
      return true;

    } catch (e) {
      print('>>> ❌ Error updating email notification preference: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Check if push notifications are enabled for current user
  bool get isPushEnabled => preferences.value.pushNotificationsEnabled;

  /// Check if email notifications are enabled for current user
  bool get isEmailEnabled => preferences.value.emailNotificationsEnabled;

  /// Get preferences for a specific user (used by admin when sending notifications)
  Future<NotificationPreferences> getPreferencesForUser(String userDocumentId) async {
    try {
      print('>>> Getting notification preferences for user: $userDocumentId');

      final userDoc = await authRepository.getUserById(userDocumentId);
      if (userDoc == null) {
        print('>>> User not found, using default preferences');
        return NotificationPreferences();
      }

      final pushEnabled = userDoc.data['pushNotificationsEnabled'] ?? true;
      final emailEnabled = userDoc.data['emailNotificationsEnabled'] ?? true;

      return NotificationPreferences(
        pushNotificationsEnabled: pushEnabled,
        emailNotificationsEnabled: emailEnabled,
      );

    } catch (e) {
      print('>>> Error getting user preferences: $e');
      return NotificationPreferences(); // Default to enabled on error
    }
  }

  /// Clear preferences (on logout)
  void clearPreferences() {
    preferences.value = NotificationPreferences();
    print('>>> Notification preferences cleared');
  }
}