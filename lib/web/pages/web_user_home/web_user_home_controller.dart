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
}