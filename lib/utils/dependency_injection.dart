// lib/init/dependency_injection.dart
import 'package:capstone_app/notifications/controllers/notification_controller.dart';
import 'package:capstone_app/mobile/admin/controllers/admin_messaging_controller.dart';
import 'package:capstone_app/mobile/user/components/dashboard_components/dashboard_controller.dart';
import 'package:capstone_app/mobile/user/controllers/messaging_controller.dart';
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
  Get.put(NotificationController(
    authRepository: Get.find<AuthRepository>(),
    session: Get.find<UserSessionService>(),
  ));
 
}
