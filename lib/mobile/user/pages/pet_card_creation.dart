import 'dart:io';
import 'package:capstone_app/data/models/pet_model.dart';
import 'package:capstone_app/mobile/user/components/pets_components/pet_creation_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class PetCardCreation extends StatelessWidget {
  final Pet? existingPet;
  PetCardCreation({super.key, this.existingPet}) {
    controller = Get.put(
      PetCreationController(Get.find(), existingPet: existingPet),
      tag: existingPet?.petId ?? 'new',
    );
  }

  late final PetCreationController controller;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      controller.pickImage(File(pickedFile.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = existingPet != null;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 120,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Get.back(result: true),
        ),
        title: Text(isEditing ? "Edit Pet" : "Create Pet"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: controller.formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Obx(() {
                  final file = controller.imageFile.value;
                  final url = controller.imageUrl.value;

                  return Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: file != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(file, fit: BoxFit.cover),
                          )
                        : (url.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(url, fit: BoxFit.cover))
                            : const Icon(Icons.add_a_photo, size: 50)),
                  );
                }),
              ),
              const SizedBox(height: 20),
              _buildTextField(controller.nameController, "Pet Name"),
              _buildTextField(
                  controller.typeController, "Type (e.g. Dog, Cat)"),
              _buildTextField(controller.breedController, "Breed"),
              _buildTextField(controller.colorController, "Color"),
              _buildTextField(controller.notesController, "Notes", maxLines: 3),
              _buildTextField(controller.weightController, "Weight (kg)",
                  isNumber: true),
              const SizedBox(height: 20),
              Obx(() => ElevatedButton.icon(
                    onPressed: controller.isLoading.value
                        ? null
                        : (isEditing
                            ? controller.updatePet
                            : controller.createPet),
                    icon: const Icon(Icons.pets),
                    label: controller.isLoading.value
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(isEditing ? "Update Pet" : "Save Pet"),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool isNumber = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) =>
            value == null || value.isEmpty ? "Please enter $label" : null,
      ),
    );
  }
}
