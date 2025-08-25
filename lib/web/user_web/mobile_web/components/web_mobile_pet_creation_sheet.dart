import 'dart:io';
import 'package:capstone_app/data/models/pet_model.dart';
import 'package:capstone_app/mobile/user/components/pets_components/pet_creation_controller.dart';
import 'package:capstone_app/web/user_web/services/web_image_picker_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

class WebMobilePetCreationSheet extends StatefulWidget {
  final Pet? existingPet;
  
  const WebMobilePetCreationSheet({
    super.key,
    this.existingPet,
  });

  @override
  State<WebMobilePetCreationSheet> createState() => _WebMobilePetCreationSheetState();
}

class _WebMobilePetCreationSheetState extends State<WebMobilePetCreationSheet> {
  late final PetCreationController controller;
  final ImagePicker _picker = ImagePicker();
  ImagePickerResult? _selectedWebImage;

  @override
  void initState() {
    super.initState();
    controller = Get.put(
      PetCreationController(Get.find(), existingPet: widget.existingPet),
      tag: widget.existingPet?.petId ?? 'web_mobile_new',
    );
  }

  Future<void> _pickImage() async {
    if (kIsWeb) {
      // Use web image picker for web platform
      try {
        final result = await WebImagePickerService.pickImage();
        if (result != null) {
          setState(() {
            _selectedWebImage = result;
          });
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to pick image: $e")),
        );
      }
    } else {
      // Use standard image picker for mobile
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        controller.pickImage(File(pickedFile.path));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingPet != null;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Container(
      height: screenHeight * 0.95,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          toolbarHeight: 60,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            isEditing ? "Edit Pet" : "Add Pet",
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.black87,
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: controller.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Selection
                GestureDetector(
                  onTap: _pickImage,
                  child: Obx(() {
                    Widget imageWidget;

                    if (kIsWeb && _selectedWebImage?.bytes != null) {
                      // Web image display
                      imageWidget = ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          _selectedWebImage!.bytes!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      );
                    } else if (!kIsWeb && controller.imageFile.value != null) {
                      // Mobile file image display
                      imageWidget = ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          controller.imageFile.value!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      );
                    } else if (controller.imageUrl.value.isNotEmpty) {
                      // Existing image from URL
                      imageWidget = ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          controller.imageUrl.value,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      );
                    } else {
                      // Placeholder
                      imageWidget = Container(
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade200, style: BorderStyle.solid),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_a_photo,
                              size: 50,
                              color: Colors.blue.shade400,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Add Photo",
                              style: GoogleFonts.inter(
                                color: Colors.blue.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return Container(
                      height: 200,
                      width: double.infinity,
                      child: imageWidget,
                    );
                  }),
                ),
                
                const SizedBox(height: 24),

                // Form Fields
                _buildTextField(
                  controller.nameController,
                  "Pet Name",
                  Icons.pets,
                  "Enter your pet's name",
                ),
                
                _buildTextField(
                  controller.typeController,
                  "Type",
                  Icons.category,
                  "e.g., Dog, Cat, Bird",
                ),
                
                _buildTextField(
                  controller.breedController,
                  "Breed",
                  Icons.pets_outlined,
                  "Enter breed",
                ),
                
                _buildTextField(
                  controller.colorController,
                  "Color",
                  Icons.palette,
                  "Enter color (optional)",
                  required: false,
                ),
                
                _buildTextField(
                  controller.weightController,
                  "Weight (kg)",
                  Icons.monitor_weight,
                  "Enter weight",
                  isNumber: true,
                  required: false,
                ),
                
                _buildTextField(
                  controller.notesController,
                  "Notes",
                  Icons.note_alt,
                  "Additional notes (optional)",
                  maxLines: 3,
                  required: false,
                ),

                const SizedBox(height: 32),

                // Action Button
                Obx(() => SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: controller.isLoading.value
                        ? null
                        : () async {
                            if (isEditing) {
                              await controller.updatePet();
                            } else {
                              await controller.createPet();
                            }
                            Navigator.pop(context, true);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 81, 115, 153),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
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
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.pets, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                isEditing ? "Update Pet" : "Save Pet",
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                  ),
                )),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController textController,
    String label,
    IconData icon,
    String hint, {
    bool isNumber = false,
    int maxLines = 1,
    bool required = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: textController,
        maxLines: maxLines,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: Colors.blue.shade600),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color.fromARGB(255, 81, 115, 153),
              width: 2,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        validator: required
            ? (value) => value == null || value.trim().isEmpty
                ? "Please enter ${label.toLowerCase()}"
                : null
            : null,
      ),
    );
  }

  @override
  void dispose() {
    Get.delete<PetCreationController>(
      tag: widget.existingPet?.petId ?? 'web_mobile_new',
    );
    super.dispose();
  }
}