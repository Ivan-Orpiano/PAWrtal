import 'package:capstone_app/web/admin_web/components/clinic/clinic_settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:capstone_app/web/user_web/desktop_web/components/clinic_page_components/web_ratings_and_reviews.dart';

class AdminClinicPreview extends StatefulWidget {
  final ClinicSettingsController controller;

  const AdminClinicPreview({super.key, required this.controller});

  @override
  State<AdminClinicPreview> createState() => _AdminClinicPreviewState();
}

class _AdminClinicPreviewState extends State<AdminClinicPreview> {
  final ScrollController _scrollController = ScrollController();
  final MapController _mapController = MapController();

  // Edit mode states
  bool _editingAddress = false;
  bool _editingEmail = false;
  bool _editingContact = false;
  bool _editingDescription = false;

  // Temporary controllers for inline editing
  final TextEditingController _tempAddressController = TextEditingController();
  final TextEditingController _tempEmailController = TextEditingController();
  final TextEditingController _tempContactController = TextEditingController();
  final TextEditingController _tempDescriptionController =
      TextEditingController();

  // Track original values for change detection
  String _originalAddress = '';
  String _originalEmail = '';
  String _originalContact = '';
  String _originalDescription = '';

  // For appointment panel display
  DateTime? _selectedDate;
  bool _showFullDescription = false;

  // GlobalKey for reviews section
  final reviewsEndKey = GlobalKey();

  @override
  void dispose() {
    _scrollController.dispose();
    _tempAddressController.dispose();
    _tempEmailController.dispose();
    _tempContactController.dispose();
    _tempDescriptionController.dispose();
    super.dispose();
  }

  double getResponsivePadding(double screenWidth) {
    const double minScreen = 1100;
    const double maxScreen = 1920;
    const double minPadding = 16;
    const double maxPadding = 380;

    if (screenWidth <= minScreen) return minPadding;
    if (screenWidth >= maxScreen) return maxPadding;

    double t = (screenWidth - minScreen) / (maxScreen - minScreen);
    return minPadding + t * (maxPadding - minPadding);
  }

  double getLeftSideWidth(double screenWidth) {
    final horizontalPadding = getResponsivePadding(screenWidth) * 2;
    const spacingBetween = 125;
    final appointmentPanelWidth = 420.0;

    final availableWidth = screenWidth -
        horizontalPadding -
        spacingBetween -
        appointmentPanelWidth;
    return availableWidth.clamp(400.0, double.infinity);
  }

  void _startEditing(String field) {
    setState(() {
      switch (field) {
        case 'address':
          _originalAddress = widget.controller.addressController.text;
          _tempAddressController.text = _originalAddress;
          _editingAddress = true;
          break;
        case 'email':
          _originalEmail = widget.controller.emailController.text;
          _tempEmailController.text = _originalEmail;
          _editingEmail = true;
          break;
        case 'contact':
          _originalContact = widget.controller.contactController.text;
          // Extract only the digits after "09" if present
          String contactValue = _originalContact;
          if (contactValue.startsWith('09') && contactValue.length == 11) {
            _tempContactController.text = contactValue.substring(2);
          } else {
            _tempContactController.text = '';
          }
          _editingContact = true;
          break;
        case 'description':
          _originalDescription = widget.controller.descriptionController.text;
          _tempDescriptionController.text = _originalDescription;
          _editingDescription = true;
          break;
      }
    });
  }

  bool _hasUnsavedChanges(String field) {
    switch (field) {
      case 'address':
        return _tempAddressController.text != _originalAddress;
      case 'email':
        return _tempEmailController.text != _originalEmail;
      case 'contact':
        return '09${_tempContactController.text}' != _originalContact;
      case 'description':
        return _tempDescriptionController.text != _originalDescription;
      default:
        return false;
    }
  }

  Future<void> _saveEdit(String field) async {
    // Validate contact field
    if (field == 'contact') {
      if (_tempContactController.text.length != 9) {
        _showSnackBar('Contact number must be 11 digits (09 + 9 digits)',
            isError: true);
        return;
      }
      widget.controller.contactController.text =
          '09${_tempContactController.text}';
      setState(() => _editingContact = false);
    } else {
      switch (field) {
        case 'address':
          widget.controller.addressController.text =
              _tempAddressController.text;
          setState(() => _editingAddress = false);
          break;
        case 'email':
          widget.controller.emailController.text = _tempEmailController.text;
          setState(() => _editingEmail = false);
          break;
        case 'description':
          widget.controller.descriptionController.text =
              _tempDescriptionController.text;
          setState(() => _editingDescription = false);
          break;
      }
    }

    await widget.controller.saveClinicBasicInfo();
  }

  Future<void> _cancelEdit(String field) async {
    if (_hasUnsavedChanges(field)) {
      final shouldDiscard = await _showDiscardDialog();
      if (shouldDiscard != true) return;
    }

    setState(() {
      switch (field) {
        case 'address':
          _editingAddress = false;
          break;
        case 'email':
          _editingEmail = false;
          break;
        case 'contact':
          _editingContact = false;
          break;
        case 'description':
          _editingDescription = false;
          break;
      }
    });
  }

  Future<bool?> _showDiscardDialog() {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Unsaved Changes'),
          content: const Text(
              'You have unsaved changes. Do you want to discard them?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child:
                  const Text('Discard', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showServicesEditDialog() {
    // Store original services state
    final originalServices =
        List<String>.from(widget.controller.selectedServices);
    final tempSelectedServices = List<String>.from(originalServices);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final TextEditingController customServiceController =
                TextEditingController();

            bool hasChanges() {
              if (tempSelectedServices.length != originalServices.length)
                return true;
              for (var service in tempSelectedServices) {
                if (!originalServices.contains(service)) return true;
              }
              for (var service in originalServices) {
                if (!tempSelectedServices.contains(service)) return true;
              }
              return false;
            }

            Future<void> handleClose() async {
              if (hasChanges()) {
                final shouldDiscard = await _showDiscardDialog();
                if (shouldDiscard == true) {
                  // Revert to original services
                  widget.controller.selectedServices
                      .assignAll(originalServices);
                  if (context.mounted) Navigator.pop(context);
                }
              } else {
                Navigator.pop(context);
              }
            }

            return WillPopScope(
              onWillPop: () async {
                if (hasChanges()) {
                  final shouldDiscard = await _showDiscardDialog();
                  if (shouldDiscard == true) {
                    widget.controller.selectedServices
                        .assignAll(originalServices);
                    return true;
                  }
                  return false;
                }
                return true;
              },
              child: Dialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                child: Container(
                  width: 700,
                  constraints: const BoxConstraints(maxHeight: 600),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text("Edit Services",
                              style: TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.bold)),
                          const Spacer(),
                          IconButton(
                              onPressed: handleClose,
                              icon: const Icon(Icons.close)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text("Select services your clinic offers:",
                          style: TextStyle(fontSize: 16)),
                      const SizedBox(height: 16),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: widget.controller.availableServices
                                    .map((service) {
                                  return FilterChip(
                                    label: Text(service),
                                    selected:
                                        tempSelectedServices.contains(service),
                                    onSelected: (selected) {
                                      setDialogState(() {
                                        if (selected) {
                                          tempSelectedServices.add(service);
                                        } else {
                                          tempSelectedServices.remove(service);
                                        }
                                      });
                                    },
                                    selectedColor:
                                        const Color.fromARGB(255, 81, 115, 153)
                                            .withOpacity(0.2),
                                    checkmarkColor:
                                        const Color.fromARGB(255, 81, 115, 153),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 24),
                              const Text("Add custom service:",
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              TextField(
                                controller: customServiceController,
                                maxLength: 50,
                                decoration: const InputDecoration(
                                  labelText: "Service name",
                                  hintText: "Enter custom service...",
                                  border: OutlineInputBorder(),
                                  counterText: "",
                                ),
                                onSubmitted: (value) {
                                  if (value.trim().isNotEmpty &&
                                      !tempSelectedServices
                                          .contains(value.trim())) {
                                    setDialogState(() {
                                      tempSelectedServices.add(value.trim());
                                      customServiceController.clear();
                                    });
                                  }
                                },
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: () {
                                  if (customServiceController.text
                                          .trim()
                                          .isNotEmpty &&
                                      !tempSelectedServices.contains(
                                          customServiceController.text
                                              .trim())) {
                                    setDialogState(() {
                                      tempSelectedServices.add(
                                          customServiceController.text.trim());
                                      customServiceController.clear();
                                    });
                                  }
                                },
                                icon: const Icon(Icons.add),
                                label: const Text("Add Service"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      const Color.fromARGB(255, 81, 115, 153),
                                  foregroundColor: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 24),
                              if (tempSelectedServices.isEmpty)
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: Colors.orange.withOpacity(0.3)),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.warning, color: Colors.orange),
                                      SizedBox(width: 8),
                                      Expanded(
                                          child: Text(
                                              "Please select at least one service")),
                                    ],
                                  ),
                                )
                              else
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        "Selected Services (${tempSelectedServices.length}):",
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16)),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children:
                                          tempSelectedServices.map((service) {
                                        return Chip(
                                          label: Text(service),
                                          onDeleted: () => setDialogState(() =>
                                              tempSelectedServices
                                                  .remove(service)),
                                          deleteIcon:
                                              const Icon(Icons.close, size: 18),
                                          backgroundColor: const Color.fromARGB(
                                                  255, 81, 115, 153)
                                              .withOpacity(0.1),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                              onPressed: handleClose,
                              child: const Text("Cancel")),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () async {
                              // Apply changes
                              widget.controller.selectedServices
                                  .assignAll(tempSelectedServices);
                              await widget.controller.saveClinicSettings();
                              if (context.mounted) Navigator.pop(context);
                            },
                            icon: const Icon(Icons.save),
                            label: const Text("Save Services"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color.fromARGB(255, 81, 115, 153),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = getResponsivePadding(screenWidth);

    return Obx(() {
      final clinic = widget.controller.clinic.value;
      final settings = widget.controller.clinicSettings.value;

      if (clinic == null) {
        return const Center(child: CircularProgressIndicator());
      }

      return SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            // Info banner
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding, vertical: 16),
              color: Colors.blue.shade50,
              child: Row(
                children: [
                  Icon(Icons.visibility, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Preview Mode - This is how customers see your clinic. Click edit icons to update basic information.",
                      style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Clinic name and gallery
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(clinic.clinicName,
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildGalleryPreview(),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Two column layout: Left content + Appointment panel
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left content
                  SizedBox(
                    width: getLeftSideWidth(screenWidth),
                    child: _buildLeftContent(),
                  ),

                  const SizedBox(width: 125),

                  // Appointment panel (display only)
                  SizedBox(
                    width: 420,
                    child: _buildAppointmentPanel(settings),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 64),

            // Location section
            _buildLocationSection(),

            const SizedBox(height: 64),
          ],
        ),
      );
    });
  }

  Widget _buildLeftContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildClinicHeader(),
        const SizedBox(height: 32),
        _buildAboutSection(widget.controller.clinicSettings.value),
        const SizedBox(height: 32),
        _buildServicesSection(),

        // Ratings and Reviews Section
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: SizedBox(
            width: double.infinity,
            child: Divider(
              height: 1,
              thickness: 0.5,
            ),
          ),
        ),
        if (widget.controller.clinic.value?.documentId != null)
          WebRatingsAndReviews(
            reviewsEndKey: reviewsEndKey,
            clinicId: widget.controller.clinic.value!.documentId!,
          ),
      ],
    );
  }

  Widget _buildGalleryPreview() {
    return Obx(() {
      final images = widget.controller.galleryImages;

      if (images.isEmpty) {
        return Container(
          height: 520,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.photo_library, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text("No gallery images",
                    style: TextStyle(fontSize: 18, color: Colors.grey[600])),
              ],
            ),
          ),
        );
      }

      return SizedBox(
        height: 520,
        child: Row(
          children: [
            Flexible(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    bottomLeft: Radius.circular(20)),
                child: Image.network(images[0],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (_, __, ___) =>
                        Container(color: Colors.grey.shade200)),
              ),
            ),
            if (images.length > 1) const SizedBox(width: 12),
            if (images.length > 1)
              Flexible(
                flex: 2,
                child: Column(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        child: Image.network(images[1],
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (_, __, ___) =>
                                Container(color: Colors.grey.shade200)),
                      ),
                    ),
                    if (images.length > 2) const SizedBox(height: 10),
                    if (images.length > 2)
                      Expanded(
                        child: ClipRRect(
                          child: Image.network(images[2],
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (_, __, ___) =>
                                  Container(color: Colors.grey.shade200)),
                        ),
                      ),
                  ],
                ),
              ),
            if (images.length > 3) const SizedBox(width: 12),
            if (images.length > 3)
              Flexible(
                flex: 2,
                child: Column(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(20)),
                        child: Image.network(images[3],
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (_, __, ___) =>
                                Container(color: Colors.grey.shade200)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                            bottomRight: Radius.circular(20)),
                        child: images.length > 4
                            ? Image.network(images[4],
                                fit: BoxFit.cover,
                                width: double.infinity,
                                errorBuilder: (_, __, ___) =>
                                    Container(color: Colors.grey.shade200))
                            : Container(color: Colors.grey.shade200),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildClinicHeader() {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: widget.controller.clinic.value!.image.isNotEmpty
              ? Image.network(widget.controller.clinic.value!.image,
                  height: 40,
                  width: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Image.asset(
                      'lib/images/test_image.jpg',
                      height: 40,
                      width: 40,
                      fit: BoxFit.cover))
              : Image.asset('lib/images/test_image.jpg',
                  height: 40, width: 40, fit: BoxFit.cover),
        ),
        const SizedBox(width: 18),
        Expanded(
            child: Text(widget.controller.clinic.value!.clinicName,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 16))),
      ],
    );
  }

  Widget _buildAboutSection(settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text('About this veterinary clinic',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 22)),
        ),
        if (settings != null) _buildStatusBanner(settings),
        _buildContactInfoSection(),
        const SizedBox(height: 16),
        if (settings != null) _buildOperatingHours(settings),
        const SizedBox(height: 16),
        _buildDescriptionSection(),
      ],
    );
  }

  Widget _buildStatusBanner(settings) {
    final isOpen = settings.isOpen;
    final isOpenNow = settings.isOpenNow();

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (!isOpen) {
      statusColor = Colors.red;
      statusText = "Currently Closed";
      statusIcon = Icons.cancel;
    } else if (!isOpenNow) {
      statusColor = Colors.orange;
      statusText = "Closed Now";
      statusIcon = Icons.schedule;
    } else {
      statusColor = Colors.green;
      statusText = "Open Today";
      statusIcon = Icons.check_circle;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(statusText,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: statusColor)),
                if (isOpen) ...[
                  const SizedBox(height: 4),
                  Text("Hours: ${settings.getTodayHours()}",
                      style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _buildEditableInfoRow(
            icon: Icons.location_on_outlined,
            label: 'Address',
            value: widget.controller.addressController.text,
            isEditing: _editingAddress,
            controller: _tempAddressController,
            maxLength: 200,
            onEdit: () => _startEditing('address'),
            onSave: () => _saveEdit('address'),
            onCancel: () => _cancelEdit('address'),
          ),
          const SizedBox(height: 8),
          _buildEditableInfoRow(
            icon: Icons.phone_outlined,
            label: 'Contact',
            value: widget.controller.contactController.text,
            isEditing: _editingContact,
            controller: _tempContactController,
            maxLength: 9,
            keyboardType: TextInputType.phone,
            onEdit: () => _startEditing('contact'),
            onSave: () => _saveEdit('contact'),
            onCancel: () => _cancelEdit('contact'),
            isContact: true,
          ),
          const SizedBox(height: 8),
          _buildEditableInfoRow(
            icon: Icons.email_outlined,
            label: 'Email',
            value: widget.controller.emailController.text,
            isEditing: _editingEmail,
            controller: _tempEmailController,
            maxLength: 40,
            keyboardType: TextInputType.emailAddress,
            onEdit: () => _startEditing('email'),
            onSave: () => _saveEdit('email'),
            onCancel: () => _cancelEdit('email'),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isEditing,
    required TextEditingController controller,
    required int maxLength,
    required VoidCallback onEdit,
    required VoidCallback onSave,
    required VoidCallback onCancel,
    TextInputType keyboardType = TextInputType.text,
    bool isContact = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700)),
                  const Spacer(),
                  if (!isEditing)
                    IconButton(
                      icon: Icon(Icons.edit,
                          size: 16, color: Colors.blue.shade600),
                      onPressed: onEdit,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              if (isEditing)
                Row(
                  children: [
                    Expanded(
                      child: isContact
                          ? Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 12),
                                  decoration: BoxDecoration(
                                    border:
                                        Border.all(color: Colors.grey[400]!),
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(4),
                                      bottomLeft: Radius.circular(4),
                                    ),
                                    color: Colors.grey[200],
                                  ),
                                  child: const Text('09',
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500)),
                                ),
                                Expanded(
                                  child: TextField(
                                    controller: controller,
                                    maxLength: maxLength,
                                    maxLengthEnforcement:
                                        MaxLengthEnforcement.enforced,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly
                                    ],
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.only(
                                          topRight: Radius.circular(4),
                                          bottomRight: Radius.circular(4),
                                        ),
                                      ),
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      counterText: "", // Hide counter
                                    ),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ),
                              ],
                            )
                          : TextField(
                              controller: controller,
                              maxLength: maxLength,
                              maxLengthEnforcement:
                                  MaxLengthEnforcement.enforced,
                              keyboardType: keyboardType,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                counterText: "", // Hide counter
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: onSave),
                    IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: onCancel),
                  ],
                )
              else
                Text(value.isNotEmpty ? value : 'Not provided',
                    style: TextStyle(
                        fontSize: 15,
                        color: value.isNotEmpty
                            ? Colors.black87
                            : Colors.grey.shade500)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOperatingHours(settings) {
    final operatingHours = settings.operatingHours;
    final days = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday'
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.access_time, color: Colors.grey[600], size: 20),
              const SizedBox(width: 8),
              Text('Operating Hours',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700])),
            ],
          ),
          const SizedBox(height: 12),
          ...days.map((day) {
            final dayData = operatingHours[day];
            final isOpen = dayData?['isOpen'] ?? false;
            final openTime = dayData?['openTime'] ?? '';
            final closeTime = dayData?['closeTime'] ?? '';

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: Text(day.capitalize!,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700])),
                  ),
                  Text(
                    isOpen ? '$openTime - $closeTime' : 'Closed',
                    style: TextStyle(
                        fontSize: 14,
                        color: isOpen ? Colors.black87 : Colors.grey[500]),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection() {
    final description = widget.controller.descriptionController.text.isNotEmpty
        ? widget.controller.descriptionController.text
        : "This veterinary clinic provides comprehensive pet care services.";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Description',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const Spacer(),
            if (!_editingDescription)
              IconButton(
                icon: Icon(Icons.edit, size: 16, color: Colors.blue.shade600),
                onPressed: () => _startEditing('description'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (_editingDescription)
          Column(
            children: [
              TextField(
                controller: _tempDescriptionController,
                maxLength: 1000,
                maxLines: 6,
                maxLengthEnforcement: MaxLengthEnforcement.enforced,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  counterText:
                      "${_tempDescriptionController.text.length}/1000", // Keep counter for description
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                      onPressed: () => _cancelEdit('description'),
                      child: const Text('Cancel')),
                  ElevatedButton.icon(
                    onPressed: () => _saveEdit('description'),
                    icon: const Icon(Icons.check),
                    label: const Text('Save'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white),
                  ),
                ],
              ),
            ],
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _showFullDescription || description.length <= 300
                    ? description
                    : '${description.substring(0, 300)}...',
                style: const TextStyle(fontSize: 16, height: 1.5),
                textAlign: TextAlign.justify,
              ),
              if (description.length > 300)
                InkWell(
                  onTap: () => setState(
                      () => _showFullDescription = !_showFullDescription),
                  child: Row(
                    children: [
                      Text(
                        _showFullDescription ? "Show less" : "Show more",
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline),
                      ),
                      Icon(
                          _showFullDescription
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_right_rounded,
                          size: 24),
                    ],
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildServicesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: SizedBox(
              width: double.infinity,
              child: Divider(height: 1, thickness: 0.5)),
        ),
        Row(
          children: [
            const Text('Services offered',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 22)),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _showServicesEditDialog,
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('Edit Services'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 81, 115, 153),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Obx(() {
          if (widget.controller.selectedServices.isEmpty) {
            return Container(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.medical_services_outlined,
                        size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text("No services listed",
                        style:
                            TextStyle(fontSize: 16, color: Colors.grey[600])),
                  ],
                ),
              ),
            );
          }

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 10,
            ),
            itemCount: widget.controller.selectedServices.length,
            itemBuilder: (context, index) {
              final service = widget.controller.selectedServices[index];
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 81, 115, 153)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.health_and_safety_outlined,
                        size: 20,
                        color: Color.fromARGB(255, 81, 115, 153),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        service,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        }),
      ],
    );
  }

  Widget _buildAppointmentPanel(settings) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 4),
              spreadRadius: 2)
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFF5173B8),
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20), topRight: Radius.circular(20)),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Book Appointment',
                      style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Select Date',
                    style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800])),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12)),
                  child: TableCalendar(
                    focusedDay: _selectedDate ?? DateTime.now(),
                    firstDay: DateTime.now(),
                    lastDay: DateTime.now()
                        .add(Duration(days: settings?.maxAdvanceBooking ?? 30)),
                    selectedDayPredicate: (day) =>
                        isSameDay(day, _selectedDate),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() => _selectedDate = selectedDay);
                    },
                    calendarStyle: CalendarStyle(
                      todayDecoration: BoxDecoration(
                          color: const Color(0xFF5173B8).withOpacity(0.3),
                          shape: BoxShape.circle),
                      selectedDecoration: const BoxDecoration(
                          color: Color(0xFF5173B8), shape: BoxShape.circle),
                      outsideDaysVisible: false,
                    ),
                    headerStyle: HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle: GoogleFonts.inter(
                          fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                    enabledDayPredicate: (day) => !day.isBefore(
                        DateTime.now().subtract(const Duration(days: 1))),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Time',
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700])),
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  child: const Text('Select time',
                      style: TextStyle(color: Colors.grey)),
                ),
                const SizedBox(height: 16),
                Text('Service',
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700])),
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  child: const Text('Choose service',
                      style: TextStyle(color: Colors.grey)),
                ),
                const SizedBox(height: 16),
                Text('Select Pet',
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700])),
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  child: const Row(
                    children: [
                      Icon(Icons.pets, size: 20, color: Colors.grey),
                      SizedBox(width: 8),
                      Text('Choose your pet',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Book Appointment',
                        style: GoogleFonts.inter(
                            color: Colors.grey[600],
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    final settings = widget.controller.clinicSettings.value;
    final location = settings?.location;

    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: getResponsivePadding(MediaQuery.of(context).size.width)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: SizedBox(
                width: double.infinity,
                child: Divider(height: 1, thickness: 0.5)),
          ),
          const Text("Location",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w600)),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.location_on, color: Colors.red.shade600, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(widget.controller.addressController.text,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 500,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade300)),
            child: location == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.location_off,
                            size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text("Location not set",
                            style: TextStyle(
                                fontSize: 18, color: Colors.grey[600])),
                      ],
                    ),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter:
                            LatLng(location['lat']!, location['lng']!),
                        initialZoom: 15,
                        maxZoom: 19,
                        minZoom: 10,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              "https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png",
                          subdomains: const ['a', 'b', 'c', 'd'],
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: LatLng(location['lat']!, location['lng']!),
                              width: 40,
                              height: 40,
                              child: Icon(Icons.location_on,
                                  color: Colors.red.shade600, size: 40),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
