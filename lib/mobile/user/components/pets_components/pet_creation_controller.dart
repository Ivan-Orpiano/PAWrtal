import 'dart:io';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/data/models/pet_model.dart';
import 'package:capstone_app/utils/appwrite_constant.dart';
import 'package:capstone_app/utils/custom_snack_bar.dart';
import 'package:capstone_app/utils/full_screen_dialog_loader.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:uuid/uuid.dart';

class PetCreationController extends GetxController {
  final AuthRepository authRepository;
  PetCreationController(this.authRepository);

  final formKey = GlobalKey<FormState>();
  final GetStorage _getStorage = GetStorage();

  final nameController = TextEditingController();
  final typeController = TextEditingController();
  final breedController = TextEditingController();
  final colorController = TextEditingController();
  final notesController = TextEditingController();
  final weightController = TextEditingController();

  var imageFile = Rxn<File>();
  var imageUrl = ''.obs;
  var isLoading = false.obs;

  void pickImage(File file) {
    imageFile.value = file;
  }

  Future<void> createPet() async {
    if (!formKey.currentState!.validate()) return;

    try {
      FullScreenDialogLoader.showDialog();

      String? imageId;
      String? finalImageUrl;

      // Upload image if available
      if (imageFile.value != null) {
        final imageResponse = await authRepository.uploadImage(imageFile.value!.path);
        imageId = imageResponse.$id;
        finalImageUrl =
            '${AppwriteConstants.endPoint}/storage/buckets/${AppwriteConstants.imageBucketID}/files/$imageId/view?project=${AppwriteConstants.projectID}';
      }

      final petId = const Uuid().v4();
      final pet = Pet(
        petId: petId,
        userId: _getStorage.read("userId"),
        name: nameController.text.trim(),
        type: typeController.text.trim(),
        breed: breedController.text.trim(),
        color: colorController.text.trim(),
        image: finalImageUrl,
        notes: notesController.text.trim(),
        weight: double.tryParse(weightController.text.trim()),
        createdAt: DateTime.now().toIso8601String(),
        documentId: '',
      );

      await authRepository.createPet(pet.toMap());

      FullScreenDialogLoader.cancelDialog();
      CustomSnackBar.showSuccessSnackBar(
        context: Get.overlayContext,
        title: "Success",
        message: "Pet created successfully",
      );

      Get.back(); // or refresh pet list
    } catch (e) {
      FullScreenDialogLoader.cancelDialog();
      CustomSnackBar.showErrorSnackBar(
        context: Get.overlayContext,
        title: "Error",
        message: "Failed to create pet: $e",
      );
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    typeController.dispose();
    breedController.dispose();
    colorController.dispose();
    notesController.dispose();
    weightController.dispose();
    super.onClose();
  }
}
