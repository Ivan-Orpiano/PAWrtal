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
  
  runApp(kIsWeb ? const WebMain() : const MobileMain());
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