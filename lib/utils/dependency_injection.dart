// lib/init/dependency_injection.dart
import 'package:capstone_app/mobile/admin/controllers/admin_messaging_controller.dart';
import 'package:capstone_app/mobile/user/components/dashboard_components/dashboard_controller.dart';
import 'package:capstone_app/mobile/user/controllers/user_messaging_controller.dart';
import 'package:capstone_app/notification/services/appointment_reminder_service.dart';
import 'package:capstone_app/notification/services/in_app_notification_service.dart';
import 'package:capstone_app/notification/services/notification_preferences_service.dart';
import 'package:capstone_app/notification/services/notification_service.dart';
import 'package:capstone_app/web/pages/web_user_home/web_user_home_controller.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:capstone_app/utils/user_session_service.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/data/provider/appwrite_provider.dart';
import 'package:capstone_app/web/super_admin/WebVersion/services/user_archive_service.dart';
import 'package:capstone_app/web/super_admin/WebVersion/services/clinic_archive_service.dart';

Future<void> initializeDependencies() async {
  await GetStorage.init();

  // 1
  if (!Get.isRegistered<GetStorage>()) {
    Get.put(GetStorage(), 
    permanent: true);
  }

  // 2
  Get.put(AppWriteProvider(), 
  permanent: true);

  // 3
  Get.put(AuthRepository(Get.find<AppWriteProvider>()), 
  permanent: true);

  // 4
  Get.put(UserSessionService(), 
  permanent: true);

  // 5
  Get.put(
    ArchiveService(Get.find<AuthRepository>()),
    permanent: true,
  );
  Get.put(
    ClinicArchiveService(Get.find<AuthRepository>()),
    permanent: true,
  );

  // final authRepo = Get.find<AuthRepository>();
  // Get.put(AuthRepository(AppWriteProvider()));

  // 6
  final notificationService = NotificationService();
  await notificationService.initializeNotifications();
  Get.put(notificationService, permanent: true);
  Get.put(
    InAppNotificationService(
      authRepository: Get.find<AuthRepository>(),
      session: Get.find<UserSessionService>(),
    ),
    permanent: true,
  );
  // Register Notification Preferences Service
  Get.put(
    NotificationPreferencesService(
      authRepository: Get.find<AuthRepository>(),
    ),
    permanent: true,
  );
  Get.put(
    AppointmentReminderService(
      authRepository: Get.find<AuthRepository>(),
      notificationPrefsService: Get.find<NotificationPreferencesService>(),
      appWriteProvider: Get.find<AppWriteProvider>(),
    ),
    permanent: true,
  );

  // 7
  Get.put(DashboardController());
  Get.put(MessagingController());
  Get.put(AdminMessagingController());
  // ADD THIS LINE - Register WebUserHomeController globally
  Get.put(WebUserHomeController(), permanent: true);

  // 8
  await Get.find<AuthRepository>()
      .appWriteProvider
      .migrateReviewsArchiveField();
  await Get.find<AuthRepository>().migrateFeedbackArchiveField();
}
