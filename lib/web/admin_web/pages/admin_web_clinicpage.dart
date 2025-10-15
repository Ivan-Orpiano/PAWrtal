import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/utils/user_session_service.dart';
import 'package:capstone_app/web/admin_web/components/clinic/clinic_settings_controller.dart';
import 'package:capstone_app/web/admin_web/components/clinic/admin_pin_maps_page.dart';
import 'package:capstone_app/web/admin_web/components/clinic/admin_clinic_preview.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AdminWebClinicpage extends StatefulWidget {
  const AdminWebClinicpage({super.key});

  @override
  State<AdminWebClinicpage> createState() => _AdminWebClinicpageState();
}

class _AdminWebClinicpageState extends State<AdminWebClinicpage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late ClinicSettingsController controller;
  bool _showEditingPage = false; // Toggle between preview and editing

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: 3, vsync: this); // Gallery, Schedule, Settings

    // Initialize controller
    controller = Get.put(ClinicSettingsController(
      authRepository: Get.find<AuthRepository>(),
      session: Get.find<UserSessionService>(),
    ));
  }

  @override
  void dispose() {
    _tabController.dispose();
    Get.delete<ClinicSettingsController>();
    super.dispose();
  }

  void _toggleView() {
    setState(() {
      _showEditingPage = !_showEditingPage;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return Stack(
          children: [
            // Main content - either preview or editing page
            if (!_showEditingPage) _buildPreviewPage() else _buildEditingPage(),

            // Floating action button (only show on preview)
            if (!_showEditingPage)
              Positioned(
                bottom: 32,
                right: 32,
                child: FloatingActionButton.extended(
                  onPressed: _toggleView,
                  backgroundColor: const Color.fromARGB(255, 81, 115, 153),
                  icon: const Icon(Icons.edit, color: Colors.white),
                  label: const Text(
                    'Edit Settings',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }

  Widget _buildPreviewPage() {
    return AdminClinicPreview(controller: controller);
  }

  Widget _buildEditingPage() {
    return Column(
      children: [
        // Header with back button and clinic status
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Back button
              IconButton(
                onPressed: _toggleView,
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Back to Preview',
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      controller.clinic.value?.clinicName ?? "Clinic Settings",
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Manage gallery, schedule, and advanced settings",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              // Clinic status toggle
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: controller.clinicStatusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: controller.clinicStatusColor.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          controller.isClinicOpen.value
                              ? Icons.check_circle
                              : Icons.cancel,
                          color: controller.clinicStatusColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Clinic Status: ${controller.clinicStatusText}",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: controller.clinicStatusColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Switch(
                      value: controller.isClinicOpen.value,
                      onChanged: (value) => controller.toggleClinicStatus(),
                      activeColor: Colors.green,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Tab bar
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: const Color.fromARGB(255, 81, 115, 153),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color.fromARGB(255, 81, 115, 153),
            tabs: const [
              Tab(text: "Gallery"),
              Tab(text: "Schedule"),
              Tab(text: "Settings"),
            ],
          ),
        ),

        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildGalleryTab(),
              _buildScheduleTab(),
              _buildSettingsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGalleryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildSectionCard(
            title: "Clinic Gallery",
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      "Upload images of your clinic to show customers",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: controller.isSaving.value
                          ? null
                          : controller.addGalleryImages,
                      icon: const Icon(Icons.add_photo_alternate),
                      label: const Text("Add Images"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color.fromARGB(255, 81, 115, 153),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Obx(() {
                  if (controller.galleryImages.isEmpty) {
                    return Container(
                      height: 200,
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
                            Text("No images uploaded yet"),
                            Text("Click 'Add Images' to get started"),
                          ],
                        ),
                      ),
                    );
                  }

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 1,
                    ),
                    itemCount: controller.galleryImages.length,
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
                                controller.galleryImages[index],
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    color: Colors.grey[200],
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        value: loadingProgress
                                                    .expectedTotalBytes !=
                                                null
                                            ? loadingProgress
                                                    .cumulativeBytesLoaded /
                                                loadingProgress
                                                    .expectedTotalBytes!
                                            : null,
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[200],
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.error,
                                            color: Colors.red),
                                        const SizedBox(height: 4),
                                        Text(
                                          "Failed to load",
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.red[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: InkWell(
                              onTap: () => controller.removeGalleryImage(index),
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
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildSectionCard(
            title: "Operating Hours",
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Set your clinic's operating hours for each day",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 16),
                Obx(() {
                  final days = [
                    'monday',
                    'tuesday',
                    'wednesday',
                    'thursday',
                    'friday',
                    'saturday',
                    'sunday'
                  ];
                  return Column(
                    children: days.map((day) {
                      final dayData = controller.operatingHours[day] ??
                          {
                            'isOpen': false,
                            'openTime': '09:00',
                            'closeTime': '17:00'
                          };
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 100,
                              child: Text(
                                day.capitalize!,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Switch(
                              value: dayData['isOpen'] ?? false,
                              onChanged: (value) {
                                final newData =
                                    Map<String, dynamic>.from(dayData);
                                newData['isOpen'] = value;
                                controller.updateOperatingHours(day, newData);
                              },
                            ),
                            const SizedBox(width: 16),
                            if (dayData['isOpen'] == true) ...[
                              Expanded(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _buildTimeField(
                                        value: dayData['openTime'] ?? '09:00',
                                        label: "Open",
                                        onChanged: (time) {
                                          final newData =
                                              Map<String, dynamic>.from(
                                                  dayData);
                                          newData['openTime'] = time;
                                          controller.updateOperatingHours(
                                              day, newData);
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildTimeField(
                                        value: dayData['closeTime'] ?? '17:00',
                                        label: "Close",
                                        onChanged: (time) {
                                          final newData =
                                              Map<String, dynamic>.from(
                                                  dayData);
                                          newData['closeTime'] = time;
                                          controller.updateOperatingHours(
                                              day, newData);
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ] else ...[
                              const Expanded(
                                child: Text(
                                  "Closed",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }).toList(),
                  );
                }),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: controller.isSaving.value
                          ? null
                          : controller.saveClinicSettings,
                      icon: controller.isSaving.value
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save),
                      label: Text(controller.isSaving.value
                          ? "Saving..."
                          : "Save Schedule"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color.fromARGB(255, 81, 115, 153),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
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
                            "Default Appointment Duration",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Obx(() => DropdownButtonFormField<int>(
                                value: controller.appointmentDuration.value,
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
                                    controller.appointmentDuration.value =
                                        value;
                                  }
                                },
                              )),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Maximum Advance Booking",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Obx(() => DropdownButtonFormField<int>(
                                value: controller.maxAdvanceBooking.value,
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
                                    controller.maxAdvanceBooking.value = value;
                                  }
                                },
                              )),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller.emergencyContactController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: "Emergency Contact",
                          prefixIcon: Icon(Icons.emergency),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller.specialInstructionsController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: "Special Instructions for Customers",
                    prefixIcon: Icon(Icons.info),
                    hintText:
                        "Any special instructions or notes for customers...",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    children: [
                      Obx(() => SwitchListTile(
                            title: const Text("Auto-accept Appointments"),
                            subtitle: const Text(
                                "Automatically approve new appointment requests"),
                            value: controller.autoAcceptAppointments.value,
                            onChanged: (value) {
                              controller.autoAcceptAppointments.value = value;
                            },
                            activeColor:
                                const Color.fromARGB(255, 81, 115, 153),
                          )),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: controller.isSaving.value
                          ? null
                          : controller.saveClinicSettings,
                      icon: controller.isSaving.value
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save),
                      label: Text(controller.isSaving.value
                          ? "Saving..."
                          : "Save Settings"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color.fromARGB(255, 81, 115, 153),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionCard(
            title: "Clinic Location",
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Pin your clinic's location on the map so customers can find you easily",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 16),
                Obx(() => AdminPinMapsPage(
                      currentLocation: controller.selectedLocation.value,
                      onLocationSelected: (location) {
                        controller.selectedLocation.value = location;
                      },
                    )),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: controller.isSaving.value
                          ? null
                          : controller.saveClinicSettings,
                      icon: controller.isSaving.value
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save),
                      label: Text(controller.isSaving.value
                          ? "Saving..."
                          : "Save Location"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color.fromARGB(255, 81, 115, 153),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
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
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
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
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          child,
        ],
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
}
