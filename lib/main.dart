import 'package:capstone_app/firebase_options.dart';
import 'package:capstone_app/mobile/mobile_main.dart';
import 'package:capstone_app/notification/services/notification_service.dart';
import 'package:capstone_app/utils/dependency_injection.dart';
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

  runApp(kIsWeb ? const WebMain() : const MobileMain());
}

/// Initialize security features
Future<void> _initializeSecurity() async {

  final storage = GetStorage();

  // Initialize security monitoring
  final violations = storage.read<List>('security_violations') ?? [];

  // Check for expired sessions
  // await _checkExpiredSessions();

  // Clean up old security data (older than 30 days)
  // await SessionManager.cleanupOldData();

}

/// Check and clean up expired sessions
Future<void> _checkExpiredSessions() async {
  final storage = GetStorage();

  final sessionId = storage.read('sessionId');
  if (sessionId == null) {
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
      if (difference > 360) {
        await storage.erase();
      } else {
      }
    } catch (e) {
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

  Widget build(BuildContext context) {
    return const GetMaterialApp(
      debugShowCheckedModeBanner: false,
    );
  }
}
