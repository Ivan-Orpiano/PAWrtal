import 'dart:io';
import 'dart:typed_data';
import 'package:capstone_app/data/models/pet_model.dart';
import 'package:capstone_app/mobile/user/components/pets_components/pet_creation_controller.dart';
import 'package:capstone_app/web/user_web/services/web_image_picker_service.dart';
import 'package:capstone_app/web/user_web/services/web_snack_bar_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class WebPetCreationPanel extends StatefulWidget {
  final Pet? existingPet;
  final VoidCallback? onSuccess;

  const WebPetCreationPanel({
    super.key,
    this.existingPet,
    this.onSuccess,
  });

  @override
  State<WebPetCreationPanel> createState() => _WebPetCreationPanelState();
}

class _WebPetCreationPanelState extends State<WebPetCreationPanel> {
  late final PetCreationController controller;
  ImagePickerResult? _selectedImage;

  @override
  void initState() {
    super.initState();
    controller = Get.put(
      PetCreationController(Get.find(), existingPet: widget.existingPet),
      tag: widget.existingPet?.petId ?? 'web_new',
    );
  }

  Future<void> _pickImage() async {
    try {
      final result = await WebImagePickerService.pickImage();
      if (result != null) {
        setState(() {
          _selectedImage = result;
        });
        
        // For mobile/desktop compatibility, create a temporary file
        if (result.isFile && result.file != null) {
          controller.pickImage(result.file!);
        } else if (result.isWeb && result.bytes != null) {
          // For web, we'll handle this differently in the controller
          // You might need to update your PetCreationController to handle Uint8List
          // For now, we'll store the image result and handle it during save
        }
      }
    } catch (e) {
      WebSnackBarService.showError(
        title: "Error",
        message: "Failed to pick image: $e",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingPet != null;
    
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row(
          //   children: [
          //     Icon(
          //       Icons.pets,
          //       color: Colors.indigo,
          //       size: 24,
          //     ),
          //     const SizedBox(width: 12),
          //     Text(
          //       isEditing ? "Edit Pet" : "Add New Pet",
          //       style: const TextStyle(
          //         fontSize: 20,
          //         fontWeight: FontWeight.bold,
          //       ),
          //     ),
          //   ],
          // ),
          // const SizedBox(height: 24),
          
          Expanded(
            child: SingleChildScrollView(
              child: Form(
                key: controller.formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image Section
                    GestureDetector(
                      onTap: _pickImage,
                      child: Obx(() {
                        final file = controller.imageFile.value;
                        final url = controller.imageUrl.value;

                        Widget imageWidget;
                        
                        if (_selectedImage?.isWeb == true && _selectedImage?.bytes != null) {
                          // Show web-picked image
                          imageWidget = ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.memory(_selectedImage!.bytes!, fit: BoxFit.cover),
                          );
                        } else if (file != null) {
                          // Show file-picked image (desktop/mobile)
                          imageWidget = ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(file, fit: BoxFit.cover),
                          );
                        } else if (url.isNotEmpty) {
                          // Show existing image from URL
                          imageWidget = ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(url, fit: BoxFit.cover),
                          );
                        } else {
                          // Show placeholder
                          imageWidget = Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_a_photo,
                                size: 50,
                                color: Colors.indigo.shade400,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Click to add photo",
                                style: TextStyle(
                                  color: Colors.indigo.shade600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          );
                        }

                        return Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.indigo.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.indigo.shade200),
                          ),
                          child: imageWidget,
                        );
                      }),
                    ),
                    const SizedBox(height: 20),

                    // Form Fields
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller.nameController,
                            "Pet Name",
                            Icons.pets,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            controller.typeController,
                            "Type (e.g. Dog, Cat)",
                            Icons.category,
                          ),
                        ),
                      ],
                    ),
                    
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller.breedController,
                            "Breed",
                            Icons.pets_outlined,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            controller.colorController,
                            "Color",
                            Icons.palette,
                          ),
                        ),
                      ],
                    ),

                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller.weightController,
                            "Weight (kg)",
                            Icons.monitor_weight,
                            isNumber: true,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(child: Container()), // Empty space
                      ],
                    ),

                    _buildTextField(
                      controller.notesController,
                      "Notes",
                      Icons.notes,
                      maxLines: 3,
                    ),

                    const SizedBox(height: 24),

                    // Action Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            // Clear the right panel or navigate back
                            widget.onSuccess?.call();
                          },
                          child: const Text("Cancel"),
                        ),
                        const SizedBox(width: 12),
                        Obx(() => ElevatedButton.icon(
                          onPressed: controller.isLoading.value
                              ? null
                              : () async {
                                  if (isEditing) {
                                    await controller.updatePet();
                                  } else {
                                    await controller.createPet();
                                  }
                                  widget.onSuccess?.call();
                                },
                          icon: controller.isLoading.value
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.save),
                          label: Text(isEditing ? "Update Pet" : "Save Pet"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        )),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
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
          prefixIcon: Icon(icon, color: Colors.indigo),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.indigo, width: 2),
          ),
        ),
        validator: (value) =>
            value == null || value.isEmpty ? "Please enter $label" : null,
      ),
    );
  }

  @override
  void dispose() {
    Get.delete<PetCreationController>(tag: widget.existingPet?.petId ?? 'web_new');
    super.dispose();
  }
}