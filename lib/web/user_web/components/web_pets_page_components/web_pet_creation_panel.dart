import 'package:capstone_app/data/models/pet_model.dart';
import 'package:capstone_app/mobile/user/components/pets_components/pet_creation_controller.dart';
import 'package:capstone_app/web/user_web/services/web_image_picker_service.dart';
import 'package:capstone_app/web/user_web/services/web_snack_bar_service.dart';
import 'package:flutter/material.dart';
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
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? "Edit Pet" : "Add New Pet",
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      widget.onSuccess?.call();
                    },
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Form(
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

                        if (_selectedImage?.isWeb == true &&
                            _selectedImage?.bytes != null) {
                          // Show web-picked image
                          imageWidget = ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.memory(_selectedImage!.bytes!,
                                fit: BoxFit.cover),
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
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFF3498DB).withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.add_a_photo,
                                  size: 30,
                                  color: Color(0xFF3498DB),
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                "Click to add photo",
                                style: TextStyle(
                                  color: Color(0xFF3498DB),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          );
                        }

                        return Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
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
                            "Pet Name *",
                            Icons.pets,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            controller.typeController,
                            "Type (e.g. Dog, Cat) *",
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
                            "Breed *",
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
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Gender",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF2C3E50),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  value:
                                      controller.genderController.text.isEmpty
                                          ? null
                                          : controller.genderController.text,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide:
                                          BorderSide(color: Colors.grey[300]!),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                          color: Color(0xFF3498DB), width: 2),
                                    ),
                                    fillColor: Colors.grey[50],
                                    filled: true,
                                    contentPadding: const EdgeInsets.all(16),
                                    prefixIcon: Icon(Icons.person_outline,
                                        color: Colors.grey[500]),
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                        value: 'Male', child: Text('Male')),
                                    DropdownMenuItem(
                                        value: 'Female', child: Text('Female')),
                                  ],
                                  onChanged: (value) {
                                    controller.genderController.text =
                                        value ?? '';
                                  },
                                ),
                              ],
                            ),
                          ),
                        ), // Empty space
                      ],
                    ),

                    _buildTextField(
                      controller.notesController,
                      "Notes",
                      Icons.notes,
                      maxLines: 3,
                    ),

                    const SizedBox(height: 32),

                    // Action Buttons
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: Obx(() => ElevatedButton(
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
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3498DB),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: controller.isLoading.value
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    isEditing ? "Update Pet" : "Save Pet",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          )),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Color(0xFF3498DB), width: 2),
              ),
              fillColor: Colors.grey[50],
              filled: true,
              contentPadding: const EdgeInsets.all(16),
              prefixIcon: Icon(icon, color: Colors.grey[500]),
            ),
            validator: (value) {
              if (label.contains('*') && (value == null || value.isEmpty)) {
                return "Please enter ${label.replaceAll(' *', '')}";
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    Get.delete<PetCreationController>(
        tag: widget.existingPet?.petId ?? 'web_new');
    super.dispose();
  }
}
