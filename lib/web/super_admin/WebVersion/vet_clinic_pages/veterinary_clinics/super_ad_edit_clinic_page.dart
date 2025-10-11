import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:capstone_app/data/models/clinic_settings_model.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/utils/image_helper.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:appwrite/appwrite.dart';

class SuperAdminEditClinicPage extends StatefulWidget {
  final Clinic clinic;
  final ClinicSettings? settings;

  const SuperAdminEditClinicPage({
    super.key,
    required this.clinic,
    this.settings,
  });

  @override
  State<SuperAdminEditClinicPage> createState() =>
      _SuperAdminEditClinicPageState();
}

class _SuperAdminEditClinicPageState extends State<SuperAdminEditClinicPage>
    with TickerProviderStateMixin {
  final AuthRepository authRepository = Get.find<AuthRepository>();
  late TabController _tabController;

  // Controllers for basic info
  late TextEditingController clinicNameController;
  late TextEditingController addressController;
  late TextEditingController contactController;
  late TextEditingController emailController;
  late TextEditingController descriptionController;

  // Settings controllers
  late TextEditingController emergencyContactController;
  late TextEditingController specialInstructionsController;

  bool isSaving = false;
  bool isLoadingImage = false;
  String? newMainImageId;
  List<String> galleryImages = [];
  List<String> removedGalleryImages = [];

  // Services
  List<String> selectedServices = [];
  final List<String> availableServices = [
    'Vaccination',
    'Surgery',
    'Dental Care',
    'Grooming',
    'Emergency Care',
    'Consultation',
    'Laboratory',
    'X-Ray',
    'Ultrasound',
    'Pet Boarding',
  ];

  // Operating hours
  Map<String, Map<String, dynamic>> operatingHours = {};

  // Settings
  int appointmentDuration = 30;
  int maxAdvanceBooking = 30;
  bool autoAcceptAppointments = false;
  bool isOpen = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeControllers();
    _initializeData();
  }

  void _initializeControllers() {
    clinicNameController =
        TextEditingController(text: widget.clinic.clinicName);
    addressController = TextEditingController(text: widget.clinic.address);
    contactController = TextEditingController(text: widget.clinic.contact);
    emailController = TextEditingController(text: widget.clinic.email);
    descriptionController =
        TextEditingController(text: widget.clinic.description);
    emergencyContactController = TextEditingController(
      text: widget.settings?.emergencyContact ?? '',
    );
    specialInstructionsController = TextEditingController(
      text: widget.settings?.specialInstructions ?? '',
    );
  }

  void _initializeData() {
    // Services
    if (widget.clinic.services.isNotEmpty) {
      selectedServices = widget.clinic.services
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }

    // Settings
    if (widget.settings != null) {
      galleryImages = List.from(widget.settings!.gallery);
      operatingHours = Map.from(widget.settings!.operatingHours);
      appointmentDuration = widget.settings!.appointmentDuration;
      maxAdvanceBooking = widget.settings!.maxAdvanceBooking;
      autoAcceptAppointments = widget.settings!.autoAcceptAppointments;
      isOpen = widget.settings!.isOpen;
    } else {
      operatingHours = _getDefaultOperatingHours();
    }
  }

  Map<String, Map<String, dynamic>> _getDefaultOperatingHours() {
    return {
      'monday': {'isOpen': true, 'openTime': '09:00', 'closeTime': '17:00'},
      'tuesday': {'isOpen': true, 'openTime': '09:00', 'closeTime': '17:00'},
      'wednesday': {'isOpen': true, 'openTime': '09:00', 'closeTime': '17:00'},
      'thursday': {'isOpen': true, 'openTime': '09:00', 'closeTime': '17:00'},
      'friday': {'isOpen': true, 'openTime': '09:00', 'closeTime': '17:00'},
      'saturday': {'isOpen': true, 'openTime': '09:00', 'closeTime': '15:00'},
      'sunday': {'isOpen': false, 'openTime': '09:00', 'closeTime': '17:00'},
    };
  }

  @override
  void dispose() {
    _tabController.dispose();
    clinicNameController.dispose();
    addressController.dispose();
    contactController.dispose();
    emailController.dispose();
    descriptionController.dispose();
    emergencyContactController.dispose();
    specialInstructionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 248, 253, 255),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 248, 253, 255),
        elevation: 2,
        shadowColor: const Color.fromRGBO(81, 115, 153, 0.1),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color.fromRGBO(81, 115, 153, 1)),
          onPressed: () => _handleBackPress(),
        ),
        title: const Text(
          'Edit Clinic',
          style: TextStyle(
            color: Color.fromRGBO(81, 115, 153, 1),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: isSaving ? null : _saveAllChanges,
            icon: isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: Text(isSaving ? 'Saving...' : 'Save All'),
            style: TextButton.styleFrom(
              foregroundColor: const Color.fromRGBO(81, 115, 153, 1),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color.fromRGBO(81, 115, 153, 1),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color.fromRGBO(81, 115, 153, 1),
          tabs: const [
            Tab(text: "Basic Info"),
            Tab(text: "Services & Hours"),
            Tab(text: "Settings"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBasicInfoTab(),
          _buildServicesAndHoursTab(),
          _buildSettingsTab(),
        ],
      ),
    );
  }

  Widget _buildBasicInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildSectionCard(
            title: "Clinic Image",
            child: Column(
              children: [
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: newMainImageId != null
                        ? Image.network(
                            getPetImageUrl(newMainImageId!),
                            fit: BoxFit.cover,
                          )
                        : widget.clinic.image.isNotEmpty
                            ? Image.network(
                                getPetImageUrl(widget.clinic.image),
                                fit: BoxFit.cover,
                              )
                            : Center(
                                child: Icon(
                                  Icons.image,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                              ),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: isLoadingImage ? null : _pickMainImage,
                  icon: isLoadingImage
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.upload),
                  label: Text(isLoadingImage ? 'Uploading...' : 'Change Image'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(81, 115, 153, 1),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionCard(
            title: "Basic Information",
            child: Column(
              children: [
                _buildTextField(
                  controller: clinicNameController,
                  label: "Clinic Name",
                  icon: Icons.business,
                  required: true,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: emailController,
                  label: "Email",
                  icon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                  required: true,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: addressController,
                  label: "Address",
                  icon: Icons.location_on,
                  required: true,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: contactController,
                  label: "Contact Number",
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                  required: true,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: descriptionController,
                  label: "Description",
                  icon: Icons.description,
                  maxLines: 4,
                  hint: "Tell customers about your clinic...",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesAndHoursTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildSectionCard(
            title: "Services Offered",
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: availableServices.map((service) {
                    final isSelected = selectedServices.contains(service);
                    return FilterChip(
                      label: Text(service),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            selectedServices.add(service);
                          } else {
                            selectedServices.remove(service);
                          }
                        });
                      },
                      selectedColor: const Color.fromRGBO(81, 115, 153, 0.2),
                      checkmarkColor: const Color.fromRGBO(81, 115, 153, 1),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                if (selectedServices.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange),
                        SizedBox(width: 8),
                        Text("Please select at least one service"),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionCard(
            title: "Operating Hours",
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text(
                    "Clinic Open for Appointments",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text("Toggle to accept/reject appointments"),
                  value: isOpen,
                  onChanged: (value) {
                    setState(() {
                      isOpen = value;
                    });
                  },
                  activeColor: const Color.fromRGBO(81, 115, 153, 1),
                ),
                const Divider(height: 24),
                ...operatingHours.entries.map((entry) {
                  final day = entry.key;
                  final hours = entry.value;
                  final dayIsOpen = hours['isOpen'] as bool;
                  final openTime = hours['openTime'] as String;
                  final closeTime = hours['closeTime'] as String;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                day.substring(0, 1).toUpperCase() +
                                    day.substring(1),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Switch(
                              value: dayIsOpen,
                              onChanged: (value) {
                                setState(() {
                                  operatingHours[day]!['isOpen'] = value;
                                });
                              },
                              activeColor:
                                  const Color.fromRGBO(81, 115, 153, 1),
                            ),
                          ],
                        ),
                        if (dayIsOpen) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTimeField(
                                  value: openTime,
                                  label: "Open",
                                  onChanged: (time) {
                                    setState(() {
                                      operatingHours[day]!['openTime'] = time;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildTimeField(
                                  value: closeTime,
                                  label: "Close",
                                  onChanged: (time) {
                                    setState(() {
                                      operatingHours[day]!['closeTime'] = time;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionCard(
            title: "Clinic Gallery",
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      "Current Images (${galleryImages.length})",
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: _pickGalleryImages,
                      icon: const Icon(Icons.add_photo_alternate),
                      label: const Text("Add Images"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromRGBO(81, 115, 153, 1),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (galleryImages.isEmpty)
                  Container(
                    height: 150,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.photo_library,
                              size: 48, color: Colors.grey),
                          SizedBox(height: 8),
                          Text("No images uploaded"),
                        ],
                      ),
                    ),
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 1,
                    ),
                    itemCount: galleryImages.length,
                    itemBuilder: (context, index) {
                      return Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(7),
                              child: Image.network(
                                getPetImageUrl(galleryImages[index]),
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: InkWell(
                              onTap: () => _removeGalleryImage(index),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildSectionCard(
            title: "Appointment Settings",
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Default Duration",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<int>(
                            value: appointmentDuration,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              suffixText: "minutes",
                            ),
                            items: [15, 30, 45, 60, 90].map((duration) {
                              return DropdownMenuItem(
                                value: duration,
                                child: Text("$duration minutes"),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  appointmentDuration = value;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Max Advance Booking",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<int>(
                            value: maxAdvanceBooking,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              suffixText: "days",
                            ),
                            items: [7, 14, 30, 60, 90].map((days) {
                              return DropdownMenuItem(
                                value: days,
                                child: Text("$days days"),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  maxAdvanceBooking = value;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: emergencyContactController,
                  label: "Emergency Contact",
                  icon: Icons.emergency,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: specialInstructionsController,
                  label: "Special Instructions",
                  icon: Icons.info,
                  maxLines: 3,
                  hint: "Any special instructions for customers...",
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: SwitchListTile(
                    title: const Text("Auto-accept Appointments"),
                    subtitle: const Text(
                      "Automatically approve new appointment requests",
                    ),
                    value: autoAcceptAppointments,
                    onChanged: (value) {
                      setState(() {
                        autoAcceptAppointments = value;
                      });
                    },
                    activeColor: const Color.fromRGBO(81, 115, 153, 1),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(81, 115, 153, 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color.fromRGBO(81, 115, 153, 1),
            ),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    String? hint,
    bool required = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: required ? "$label *" : label,
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon) : null,
        border: const OutlineInputBorder(),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Color.fromRGBO(81, 115, 153, 1)),
        ),
      ),
    );
  }

  Widget _buildTimeField({
    required String value,
    required String label,
    required Function(String) onChanged,
  }) {
    return TextField(
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: const Icon(Icons.access_time),
      ),
      controller: TextEditingController(text: value),
      onTap: () async {
        final TimeOfDay? time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(
            hour: int.parse(value.split(':')[0]),
            minute: int.parse(value.split(':')[1]),
          ),
        );
        if (time != null) {
          final formattedTime =
              '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
          onChanged(formattedTime);
        }
      },
    );
  }

  Future<void> _pickMainImage() async {
    try {
      setState(() {
        isLoadingImage = true;
      });

      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        // Upload image
        final uploadedFile = await authRepository.uploadImage(
          file.bytes != null
              ? InputFile.fromBytes(bytes: file.bytes!, filename: file.name)
              : InputFile.fromPath(path: file.path!, filename: file.name),
        );

        setState(() {
          newMainImageId = uploadedFile.$id;
        });

        _showSuccessSnackbar('Image uploaded successfully');
      }
    } catch (e) {
      _showErrorSnackbar('Error uploading image: ${e.toString()}');
    } finally {
      setState(() {
        isLoadingImage = false;
      });
    }
  }

  Future<void> _pickGalleryImages() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          isLoadingImage = true;
        });

        final uploadedFiles = await authRepository.uploadClinicGalleryImages(
          result.files,
        );

        setState(() {
          galleryImages.addAll(uploadedFiles.map((f) => f.$id));
          isLoadingImage = false;
        });

        _showSuccessSnackbar('${uploadedFiles.length} images uploaded');
      }
    } catch (e) {
      setState(() {
        isLoadingImage = false;
      });
      _showErrorSnackbar('Error uploading images: ${e.toString()}');
    }
  }

  void _removeGalleryImage(int index) {
    final imageId = galleryImages[index];
    setState(() {
      removedGalleryImages.add(imageId);
      galleryImages.removeAt(index);
    });
  }

  Future<void> _saveAllChanges() async {
    // Validation
    if (clinicNameController.text.trim().isEmpty) {
      _showErrorSnackbar('Clinic name is required');
      return;
    }
    if (selectedServices.isEmpty) {
      _showErrorSnackbar('Please select at least one service');
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      // Update clinic basic info
      final clinicData = {
        'clinicName': clinicNameController.text.trim(),
        'address': addressController.text.trim(),
        'contact': contactController.text.trim(),
        'email': emailController.text.trim(),
        'description': descriptionController.text.trim(),
        'services': selectedServices.join(', '),
        'image': newMainImageId ?? widget.clinic.image,
      };

      await authRepository.updateClinic(
        widget.clinic.documentId!,
        clinicData,
      );

      // Update or create settings
      if (widget.settings != null) {
        final settingsData = {
          'clinicId': widget.clinic.documentId!,
          'isOpen': isOpen,
          'operatingHours': operatingHours,
          'gallery': galleryImages,
          'services': selectedServices,
          'appointmentDuration': appointmentDuration,
          'maxAdvanceBooking': maxAdvanceBooking,
          'emergencyContact': emergencyContactController.text.trim(),
          'specialInstructions': specialInstructionsController.text.trim(),
          'autoAcceptAppointments': autoAcceptAppointments,
        };

        await authRepository.updateClinicSettings(
          widget.settings!.copyWith(
            isOpen: isOpen,
            operatingHours: operatingHours,
            gallery: galleryImages,
            services: selectedServices,
            appointmentDuration: appointmentDuration,
            maxAdvanceBooking: maxAdvanceBooking,
            emergencyContact: emergencyContactController.text.trim(),
            specialInstructions: specialInstructionsController.text.trim(),
            autoAcceptAppointments: autoAcceptAppointments,
          ),
        );
      }

      // Delete removed gallery images
      if (removedGalleryImages.isNotEmpty) {
        await authRepository.deleteClinicGalleryImages(removedGalleryImages);
      }

      _showSuccessSnackbar('Clinic updated successfully');

      // Wait a bit for realtime to propagate, then go back
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showErrorSnackbar('Error saving changes: ${e.toString()}');
    } finally {
      setState(() {
        isSaving = false;
      });
    }
  }

  void _handleBackPress() {
    if (isSaving) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color.fromARGB(255, 248, 253, 255),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Discard Changes?'),
        content: const Text(
          'You have unsaved changes. Are you sure you want to discard them?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
            ),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 5),
      ),
    );
  }
}
