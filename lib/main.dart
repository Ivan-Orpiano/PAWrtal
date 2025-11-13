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

import 'package:capstone_app/utils/migrations/verified_names_migration.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  NotificationService().initializeNotifications();

  await GetStorage.init();

  await initializeDependencies();

  await _initializeSecurity();

  await _runMigrationIfNeeded();
  await _syncAuthNameIfLoggedIn();

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

Future<void> _runMigrationIfNeeded() async {
  final storage = GetStorage();
  final migrationCompleted =
      storage.read('verified_names_migration_completed') ?? false;

  if (!migrationCompleted) {
    print('🔄 Running verified names migration...');

    try {
      final authRepository = Get.find<AuthRepository>();
      final databases = authRepository.appWriteProvider.databases!;

      final result = await runVerifiedNamesMigration(databases);

      if (result.isSuccessful || result.successRate >= 90.0) {
        await storage.write('verified_names_migration_completed', true);
        await storage.write(
            'verified_names_migration_date', DateTime.now().toIso8601String());
        print('✅ Migration completed and marked as done');
      } else {
        print(
            '⚠️  Migration completed with some failures (${result.successRate.toStringAsFixed(1)}% success).');
        print('   Review logs and consider re-running.');
      }
    } catch (e) {
      print('❌ Migration error: $e');
      print('   Migration will retry on next app launch.');
    }
  } else {
    final migrationDate = storage.read('verified_names_migration_date');
    print(
        'ℹ️  Verified names migration already completed ${migrationDate != null ? "on $migrationDate" : ""}');
  }
}

Future<void> _syncAuthNameIfLoggedIn() async {
  try {
    final authRepository = Get.find<AuthRepository>();
    final user = await authRepository.appWriteProvider.getUser();

    if (user != null) {
      print('🔄 User already logged in, syncing auth name...');
      await authRepository.syncAuthNameOnLogin(user.$id);
    }
  } catch (e) {
    print('ℹ️  No active session or error syncing: $e');
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
