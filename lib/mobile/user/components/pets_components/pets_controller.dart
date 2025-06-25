import 'package:capstone_app/utils/user_session_service.dart';
import 'package:get/get.dart';
import 'package:capstone_app/data/models/pet_model.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:get_storage/get_storage.dart';
import 'package:capstone_app/utils/custom_snack_bar.dart';

class PetsController extends GetxController {
  final AuthRepository authRepository;
  final UserSessionService session;

  PetsController({required this.authRepository, required this.session});

  RxList<Pet> pets = <Pet>[].obs;
  RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchUserPets();
  }

  void fetchUserPets() async {
    isLoading.value = true;
    try {
      final userId = session.userId;
      if (userId == null) {
        // Show error or navigate to login
        CustomSnackBar.showErrorSnackBar(
          context: Get.overlayContext,
          title: "Error",
          message: "User not logged in. Please log in to view your pets.",
        );
        return;
      }
      final petDocs = await authRepository.getUserPets(userId);
      pets.value = petDocs.map((doc) => Pet.fromMap(doc.data)).toList();
    } catch (e) {
      CustomSnackBar.showErrorSnackBar(
        context: Get.overlayContext,
        title: "Error",
        message: "Failed to fetch pets: $e",
      );
    } finally {
      isLoading.value = false;
    }
  }
}
