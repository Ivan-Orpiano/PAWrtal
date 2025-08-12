import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class WebUserHomeController extends GetxController {
  final GetStorage _getStorage = GetStorage();
  
  final selectedIndex = 0.obs;

  void onItemSelected(int index) {
    selectedIndex.value = index;
  }

  String get userName {
    return _getStorage.read("userName") ?? "User";
  }

  String get userEmail {
    return _getStorage.read("email") ?? "";
  }

  String get userId {
    return _getStorage.read("userId") ?? "";
  }

  String get userRole {
    return _getStorage.read("role") ?? "user";
  }

  @override
  void onInit() {
    super.onInit();
    // Ensure selectedIndex starts at 0
    selectedIndex.value = 0;
  }
}