import 'dart:io';
import 'package:capstone_app/mobile/user/components/pets_components/pet_creation_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class PetCardCreation extends StatelessWidget {
  PetCardCreation({super.key});

  final PetCreationController controller = Get.put(
    PetCreationController(Get.find()), // Assumes AuthRepository is registered in Get
  );

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      controller.pickImage(File(pickedFile.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 120,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Get.back(),
        ),
        title: const Text("Create Pet Card"),
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
                  final image = controller.imageFile.value;
                  return Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: image != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(image, fit: BoxFit.cover),
                          )
                        : const Icon(Icons.add_a_photo, size: 50),
                  );
                }),
              ),
              const SizedBox(height: 20),
              _buildTextField(controller.nameController, "Pet Name"),
              _buildTextField(controller.typeController, "Type (e.g. Dog, Cat)"),
              _buildTextField(controller.breedController, "Breed"),
              _buildTextField(controller.colorController, "Color"),
              _buildTextField(controller.notesController, "Notes", maxLines: 3),
              _buildTextField(controller.weightController, "Weight (kg)", isNumber: true),
              const SizedBox(height: 20),
              Obx(() => ElevatedButton.icon(
                    onPressed: controller.isLoading.value ? null : controller.createPet,
                    icon: const Icon(Icons.pets),
                    label: controller.isLoading.value
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Save Pet"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
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
