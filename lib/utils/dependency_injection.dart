// lib/init/dependency_injection.dart
import 'package:capstone_app/notifications/controllers/admin_notification_controller.dart';
import 'package:capstone_app/mobile/admin/controllers/admin_messaging_controller.dart';
import 'package:capstone_app/mobile/user/components/dashboard_components/dashboard_controller.dart';
import 'package:capstone_app/mobile/user/controllers/user_messaging_controller.dart';
import 'package:capstone_app/notifications/controllers/user_notification_controller.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:capstone_app/utils/user_session_service.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/data/provider/appwrite_provider.dart';
import 'package:capstone_app/web/super_admin/WebVersion/services/archive_service.dart';

Future<void> initializeDependencies() async {
  await GetStorage.init();

  Get.put(GetStorage());
  Get.put(UserSessionService());
  Get.put(AuthRepository(AppWriteProvider()));

  Get.put(AppWriteProvider());
  Get.put(AuthRepository(Get.find<AppWriteProvider>()));
  Get.put(
    ArchiveService(Get.find<AuthRepository>()),
    permanent: true,
  );
  print('>>> ✓ Archive Service initialized and running');

  Get.put(DashboardController());
  Get.put(MessagingController());
  Get.put(AdminMessagingController());

  // final adminNotificationController = Get.put(
  //   NotificationController(
  //     authRepository: Get.find<AuthRepository>(),
  //     session: Get.find<UserSessionService>(),
  //   ),
  //   permanent: true,
  // );

  // final userNotificationController = Get.put(
  //   UserNotificationController(
  //     authRepository: Get.find<AuthRepository>(),
  //     session: Get.find<UserSessionService>(),
  //   ),
  //   tag: 'user',
  //   permanent: true,
  // );

  // Future.delayed(const Duration(milliseconds: 500), () async {
  //   try {
  //     final storage = GetStorage();
  //     final userRole = storage.read('role') as String?;

  //     print('>>> Loading notifications for role: $userRole');

  //     if (userRole == 'admin' || userRole == 'staff') {
  //       print('>>> Loading admin notifications...');
  //       await adminNotificationController.loadNotifications(refresh: true);
  //       print(
  //           '>>> Admin notifications loaded: ${adminNotificationController.notifications.length}');
  //     } else if (userRole == 'user' || userRole == 'customer') {
  //       print('>>> Loading user notifications...');
  //       await userNotificationController.loadNotifications(refresh: true);
  //       print(
  //           '>>> User notifications loaded: ${userNotificationController.notifications.length}');
  //     } else {
  //       print('>>> No role found, loading both controllers...');
  //       // Load both just in case
  //       await Future.wait([
  //         adminNotificationController.loadNotifications(refresh: true),
  //         userNotificationController.loadNotifications(refresh: true),
  //       ]);
  //     }

  //     print('>>> ✓ Notification system fully initialized');
  //   } catch (e) {
  //     print('>>> ERROR initializing notifications: $e');
  //   }
  // });
}
