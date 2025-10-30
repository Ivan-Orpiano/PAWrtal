import 'package:capstone_app/firebase_options.dart';
import 'package:capstone_app/mobile/mobile_main.dart';
import 'package:capstone_app/notification/services/notification_service.dart';
import 'package:capstone_app/utils/dependency_injection.dart';
import 'package:capstone_app/utils/mobile_oauth_handler.dart';
import 'package:capstone_app/web/web_main.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:capstone_app/utils/session_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  NotificationService().initializeNotifications();

  await GetStorage.init();

  await initializeDependencies();

  await _initializeSecurity();

  if (!kIsWeb) {
    await MobileOAuthHandler.initialize();
    print('>>> Mobile OAuth handler initialized');
  }

  runApp(kIsWeb ? const WebMain() : const MobileMain());
}

/// Initialize security features
Future<void> _initializeSecurity() async {
  print('>>> ============================================');
  print('>>> INITIALIZING SECURITY FEATURES');
  print('>>> Platform: ${kIsWeb ? "WEB" : "MOBILE"}');
  print('>>> ============================================');

  final storage = GetStorage();

  // Initialize security monitoring
  final violations = storage.read<List>('security_violations') ?? [];
  print('>>> Loaded ${violations.length} previous security violations');

  // Check for expired sessions
  await _checkExpiredSessions();

  // Clean up old security data (older than 30 days)
  await SessionManager.cleanupOldData();

  print('>>> Security initialization complete');
  print('>>> ============================================');
}

/// Check and clean up expired sessions
Future<void> _checkExpiredSessions() async {
  final storage = GetStorage();

  final sessionId = storage.read('sessionId');
  if (sessionId == null) {
    print('>>> No active session found');
    return;
  }

  // Check session timestamp
  final sessionTimestamp = storage.read('sessionTimestamp');
  if (sessionTimestamp != null) {
    try {
      final lastActivity = DateTime.parse(sessionTimestamp);
      final now = DateTime.now();
      final difference = now.difference(lastActivity).inMinutes;

      // If session older than 60 minutes, clear it
      if (difference > 60) {
        print('>>> Session expired (${difference} minutes old)');
        print('>>> Clearing expired session...');
        await storage.erase();
      } else {
        print('>>> Active session found (${difference} minutes old)');
      }
    } catch (e) {
      print('>>> Error checking session: $e');
    }
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void dispose() {
    // Cleanup OAuth handler
    if (!kIsWeb) {
      MobileOAuthHandler.dispose();
    }
    super.dispose();
  }

  Widget build(BuildContext context) {
    return const GetMaterialApp(
      debugShowCheckedModeBanner: false,
    );
  }
}
