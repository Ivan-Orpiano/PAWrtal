import 'dart:async';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:capstone_app/utils/user_session_service.dart';
import 'package:capstone_app/pages/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:capstone_app/data/provider/appwrite_provider.dart';
import 'package:appwrite/appwrite.dart';

class SessionSyncService extends GetxService {
  final GetStorage _storage = GetStorage();
  Timer? _pollingTimer;
  StreamSubscription<RealtimeMessage>? _realtimeSubscription;
  
  String? _currentSessionToken;
  String? _currentUserId;
  DateTime? _lastSyncCheck;
  
  // Polling interval (check every 2 seconds)
  static const Duration _pollingInterval = Duration(seconds: 2);
  
  // Flag to prevent multiple logout dialogs
  bool _isHandlingSessionConflict = false;

  @override
  void onInit() {
    super.onInit();
    print('>>> ============================================');
    print('>>> SESSION SYNC SERVICE INITIALIZED');
    print('>>> ============================================');
  }

  /// Start monitoring session changes
  Future<void> startMonitoring({
    required String userId,
    required String sessionToken,
  }) async {
    try {
      print('>>> ============================================');
      print('>>> STARTING SESSION MONITORING');
      print('>>> User ID: $userId');
      print('>>> Session Token: ${sessionToken.substring(0, 10)}...');
      print('>>> ============================================');

      _currentUserId = userId;
      _currentSessionToken = sessionToken;
      _lastSyncCheck = DateTime.now();

      // Start polling GetStorage for session changes
      _startStoragePolling();

      // Subscribe to Appwrite Realtime for server-side session changes
      _subscribeToRealtimeSessionChanges(userId);

      print('>>> Session monitoring active');
    } catch (e) {
      print('>>> Error starting session monitoring: $e');
    }
  }

  /// Start polling GetStorage for session changes
  void _startStoragePolling() {
    // Cancel existing timer
    _pollingTimer?.cancel();

    print('>>> Starting storage polling (every ${_pollingInterval.inSeconds}s)');

    _pollingTimer = Timer.periodic(_pollingInterval, (timer) {
      _checkSessionValidity();
    });
  }

  /// Check if current session is still valid
  void _checkSessionValidity() {
    try {
      // Skip if already handling a conflict
      if (_isHandlingSessionConflict) {
        return;
      }

      final storedSessionToken = _storage.read('sessionToken');
      final storedUserId = _storage.read('userId');

      // CRITICAL: Session mismatch detected
      if (_currentSessionToken != null && 
          storedSessionToken != _currentSessionToken) {
        
        print('>>> ============================================');
        print('>>> âš ï¸ SESSION CONFLICT DETECTED!');
        print('>>> Current Token: ${_currentSessionToken?.substring(0, 10)}...');
        print('>>> Stored Token: ${storedSessionToken?.substring(0, 10) ?? 'NULL'}');
        print('>>> ============================================');

        _handleSessionConflict();
      }

      // CRITICAL: User ID mismatch detected
      if (_currentUserId != null && storedUserId != _currentUserId) {
        print('>>> ============================================');
        print('>>> âš ï¸ USER ID CONFLICT DETECTED!');
        print('>>> Current User: $_currentUserId');
        print('>>> Stored User: $storedUserId');
        print('>>> ============================================');

        _handleSessionConflict();
      }

      _lastSyncCheck = DateTime.now();
    } catch (e) {
      print('>>> Error checking session validity: $e');
    }
  }

  /// Subscribe to Appwrite Realtime for session changes
  void _subscribeToRealtimeSessionChanges(String userId) {
    try {
      print('>>> Subscribing to Appwrite Realtime session changes...');

      final appWriteProvider = Get.find<AppWriteProvider>();
      final realtime = Realtime(appWriteProvider.client);

      // Subscribe to account events
      _realtimeSubscription = realtime
          .subscribe(['account'])
          .stream
          .listen((message) {
            print('>>> Realtime event received: ${message.events}');

            // Check for session deletion/logout events
            if (message.events.contains('account.sessions.*.delete')) {
              print('>>> Session deleted on server - logging out');
              _handleSessionConflict();
            }
          });

      print('>>> Realtime subscription active');
    } catch (e) {
      print('>>> Error subscribing to realtime: $e');
      // Don't fail if realtime subscription fails - polling will still work
    }
  }

  /// Handle session conflict (force logout)
  void _handleSessionConflict() {
    // Prevent multiple simultaneous conflict handlers
    if (_isHandlingSessionConflict) {
      return;
    }

    _isHandlingSessionConflict = true;

    print('>>> ============================================');
    print('>>> HANDLING SESSION CONFLICT');
    print('>>> Force logging out this session');
    print('>>> ============================================');

    // Stop monitoring
    stopMonitoring();

    // Clear session data
    _storage.erase();

    // Navigate to login and show message
    Future.delayed(Duration.zero, () {
      try {
        Get.offAllNamed(Routes.login);
        
        Get.snackbar(
          'Session Changed',
          'You have been logged out because your account was accessed from another location.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.orange.shade700,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
          isDismissible: true,
        );
      } finally {
        _isHandlingSessionConflict = false;
      }
    });
  }

  /// Stop monitoring session changes
  void stopMonitoring() {
    print('>>> Stopping session monitoring');

    _pollingTimer?.cancel();
    _pollingTimer = null;

    _realtimeSubscription?.cancel();
    _realtimeSubscription = null;

    _currentSessionToken = null;
    _currentUserId = null;
    _lastSyncCheck = null;
  }

  /// Broadcast session change (for logout)
  void broadcastSessionChange({
    required String event,
    Map<String, dynamic>? data,
  }) {
    try {
      print('>>> ============================================');
      print('>>> BROADCASTING SESSION CHANGE');
      print('>>> Event: $event');
      print('>>> Data: $data');
      print('>>> ============================================');

      // Update GetStorage to trigger polling detection in other tabs
      final timestamp = DateTime.now().toIso8601String();
      
      _storage.write('lastSessionEvent', {
        'event': event,
        'timestamp': timestamp,
        'data': data,
      });

      print('>>> Session change broadcasted');
    } catch (e) {
      print('>>> Error broadcasting session change: $e');
    }
  }

  /// Get session monitoring status
  Map<String, dynamic> getMonitoringStatus() {
    return {
      'isMonitoring': _pollingTimer != null && _pollingTimer!.isActive,
      'hasRealtimeSubscription': _realtimeSubscription != null,
      'currentSessionToken': _currentSessionToken?.substring(0, 10),
      'currentUserId': _currentUserId,
      'lastSyncCheck': _lastSyncCheck?.toIso8601String(),
    };
  }

  @override
  void onClose() {
    print('>>> Closing SessionSyncService');
    stopMonitoring();
    super.onClose();
  }
}