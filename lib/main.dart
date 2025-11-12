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
  print('🔒 Initializing security features...');

  final storage = GetStorage();

  // Initialize security monitoring
  final violations = storage.read<List>('security_violations') ?? [];
  print('📋 Found ${violations.length} security violations in history');

  // REMOVED: Automatic session timeout check
  // This was causing issues with logout and FCM token cleanup
  // Users will be logged out only when they explicitly log out
  // or when they close the app completely

  print('✅ Security initialization complete');
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