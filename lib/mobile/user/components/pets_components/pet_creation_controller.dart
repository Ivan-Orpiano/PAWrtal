import 'dart:io';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/data/models/pet_model.dart';
import 'package:capstone_app/mobile/user/components/pets_components/pets_controller.dart';
import 'package:capstone_app/utils/appwrite_constant.dart';
import 'package:capstone_app/utils/custom_snack_bar.dart';
import 'package:capstone_app/utils/full_screen_dialog_loader.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:uuid/uuid.dart';

class PetCreationController extends GetxController {
  final AuthRepository authRepository;
  final Pet? existingPet;
  PetCreationController(this.authRepository, {this.existingPet});

  final formKey = GlobalKey<FormState>();
  final _getStorage = GetStorage();

  final nameController = TextEditingController();
  final typeController = TextEditingController();
  final breedController = TextEditingController();
  final colorController = TextEditingController();
  final notesController = TextEditingController();
  final weightController = TextEditingController();
  final genderController = TextEditingController();

  var imageFile = Rxn<File>();
  var imageUrl = ''.obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    if (existingPet != null) {
      nameController.text = existingPet!.name;
      typeController.text = existingPet!.type;
      breedController.text = existingPet!.breed;
      colorController.text = existingPet!.color ?? '';
      notesController.text = existingPet!.notes ?? '';
      weightController.text = existingPet!.weight?.toString() ?? '';
      imageUrl.value = existingPet!.image ?? '';
      genderController.text = existingPet!.gender ?? '';
    }
  }

  void pickImage(File file) {
    imageFile.value = file;
  }

  Future<void> createPet() async {
    if (!formKey.currentState!.validate()) return;

    try {
      FullScreenDialogLoader.showDialog();
      String? imageId;
      String? finalImageUrl;

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
        gender: genderController.text.trim(),
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

      // Navigate to root and refresh pets list
      Get.until((route) => route.isFirst);
      Get.find<PetsController>().fetchPets();
    } catch (e) {
      FullScreenDialogLoader.cancelDialog();
      CustomSnackBar.showErrorSnackBar(
        context: Get.overlayContext,
        title: "Error",
        message: "Failed to create pet: $e",
      );
    }
  }

  Future<void> updatePet() async {
    if (!formKey.currentState!.validate() || existingPet == null) return;

    try {
      FullScreenDialogLoader.showDialog();

      String? newImageId;
      String? finalImageUrl = existingPet!.image;

      // Upload new image if one was picked
      if (imageFile.value != null) {
        final imageResponse = await authRepository.uploadImage(imageFile.value!.path);
        newImageId = imageResponse.$id;
        finalImageUrl =
            '${AppwriteConstants.endPoint}/storage/buckets/${AppwriteConstants.imageBucketID}/files/$newImageId/view?project=${AppwriteConstants.projectID}';

        // Delete old image
        if ((existingPet!.image ?? '').isNotEmpty) {
          final oldFileId = _extractFileIdFromUrl(existingPet!.image!);
          if (oldFileId != null) {
            await authRepository.deleteImage(oldFileId);
          }
        }
      }

      final updatedPet = Pet(
        petId: existingPet!.petId,
        userId: existingPet!.userId,
        name: nameController.text.trim(),
        type: typeController.text.trim(),
        breed: breedController.text.trim(),
        color: colorController.text.trim(),
        notes: notesController.text.trim(),
        weight: double.tryParse(weightController.text.trim()),
        gender: genderController.text.trim(),
        image: finalImageUrl,
        createdAt: existingPet!.createdAt,
        documentId: existingPet!.documentId,
      );

      await authRepository.updatePet(updatedPet);

      FullScreenDialogLoader.cancelDialog();
      CustomSnackBar.showSuccessSnackBar(
        context: Get.overlayContext,
        title: "Success",
        message: "Pet updated successfully",
      );

      // Navigate to root and refresh pets list
      Get.until((route) => route.isFirst);
      Get.find<PetsController>().fetchPets();
    } catch (e) {
      FullScreenDialogLoader.cancelDialog();
      CustomSnackBar.showErrorSnackBar(
        context: Get.overlayContext,
        title: "Error",
        message: "Failed to update pet: $e",
      );
    }
  }

  String? _extractFileIdFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      final index = segments.indexOf('files');
      if (index != -1 && index + 1 < segments.length) {
        return segments[index + 1];
      }
    } catch (_) {}
    return null;
  }

  @override
  void onClose() {
    nameController.dispose();
    typeController.dispose();
    breedController.dispose();
    colorController.dispose();
    notesController.dispose();
    weightController.dispose();
    genderController.dispose();
    super.onClose();
  }
}
