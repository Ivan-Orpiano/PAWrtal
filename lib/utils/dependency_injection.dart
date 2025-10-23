// lib/init/dependency_injection.dart
import 'package:capstone_app/mobile/admin/controllers/admin_messaging_controller.dart';
import 'package:capstone_app/mobile/user/components/dashboard_components/dashboard_controller.dart';
import 'package:capstone_app/mobile/user/controllers/user_messaging_controller.dart';
import 'package:capstone_app/notification/services/in_app_notification_service.dart';
import 'package:capstone_app/notification/services/notification_service.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:capstone_app/utils/user_session_service.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/data/provider/appwrite_provider.dart';
import 'package:capstone_app/web/super_admin/WebVersion/services/user_archive_service.dart';
import 'package:capstone_app/web/super_admin/WebVersion/services/clinic_archive_service.dart';

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

  Get.put(
    ClinicArchiveService(Get.find<AuthRepository>()),
    permanent: true,
  );
  print('>>> ✓ Clinic Archive Service initialized and running');

  final notificationService = NotificationService();
  await notificationService.initializeNotifications();
  Get.put(notificationService, permanent: true);
  print('>>> ✓ Notification Service initialized');

  Get.put(
    InAppNotificationService(
      authRepository: Get.find<AuthRepository>(),
      session: Get.find<UserSessionService>(),
    ),
    permanent: true,
  );
  print('>>> ✓ In-App Notification Service registered (will initialize after login)');

  Get.put(DashboardController());
  Get.put(MessagingController());
  Get.put(AdminMessagingController());
  
}
