import 'package:capstone_app/utils/user_session_service.dart';
import 'package:get/get.dart';
import 'package:capstone_app/data/models/pet_model.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/web/user_web/services/web_snack_bar_service.dart';
import 'package:flutter/material.dart';

class WebPetsController extends GetxController {
  final AuthRepository authRepository;
  final UserSessionService session;

  WebPetsController({required this.authRepository, required this.session});

  RxList<Pet> pets = <Pet>[].obs;
  RxBool isLoading = false.obs;
  RxString searchQuery = ''.obs;
  Rx<Pet?> selectedPet = Rx<Pet?>(null);

  @override
  void onInit() {
    super.onInit();
    fetchUserPets();
  }

  // Filtered pets based on search query
  List<Pet> get filteredPets {
    if (searchQuery.value.isEmpty) {
      return pets;
    }
    return pets.where((pet) => 
      pet.name.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
      pet.type.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
      pet.breed.toLowerCase().contains(searchQuery.value.toLowerCase())
    ).toList();
  }

  Future<void> fetchUserPets() async {
    isLoading.value = true;
    try {
      final userId = session.userId;
      if (userId.isEmpty) {
        WebSnackBarService.showError(
          title: "Error",
          message: "User not logged in. Please log in to view your pets.",
        );
        return;
      }
      final petDocs = await authRepository.getUserPets(userId);
      pets.value = petDocs.map((doc) => Pet.fromMap(doc.data)).toList();
    } catch (e) {
      WebSnackBarService.showError(
        title: "Error",
        message: "Failed to fetch pets: $e",
      );
    } finally {
      isLoading.value = false;
    }
  }

  void selectPet(Pet pet) {
    selectedPet.value = pet;
  }

  void clearSelection() {
    selectedPet.value = null;
  }

  void updateSearchQuery(String query) {
    searchQuery.value = query;
  }

  Future<void> deletePet(Pet pet) async {
    try {
      // Delete image if exists
      if (pet.image != null && pet.image!.isNotEmpty) {
        final imageId = pet.image!.split('/files/')[1].split('/')[0];
        await authRepository.deleteImage(imageId);
      }

      // Delete pet
      await authRepository.deletePet(pet.documentId!);

      // Remove from local list
      pets.removeWhere((p) => p.documentId == pet.documentId);

      // Clear selection if deleted pet was selected
      if (selectedPet.value?.documentId == pet.documentId) {
        clearSelection();
      }

      WebSnackBarService.showSuccess(
        title: "Success",
        message: "${pet.name} has been deleted successfully",
      );
    } catch (e) {
      WebSnackBarService.showError(
        title: "Error",
        message: "Failed to delete pet: $e",
      );
    }
  }

  void refreshPets() {
    fetchUserPets();
  }
}