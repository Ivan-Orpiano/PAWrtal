import 'package:capstone_app/data/models/appointment_model.dart';
import 'package:capstone_app/web/admin_web/components/appointments/admin_web_appointment_controller.dart';
import 'package:capstone_app/web/admin_web/components/appointments/web_appointment_modal.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:capstone_app/web/admin_web/components/appointments/dialogs/vaccination_completion_dialog.dart';

class WebAppointmentTile extends StatelessWidget {
  final Appointment appointment;
  final bool isSelected;

  const WebAppointmentTile({
    super.key,
    required this.appointment,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<WebAppointmentController>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Container(
      margin: EdgeInsets.only(
        bottom: isMobile ? 8 : 12,
        left: isMobile ? 8 : 16,
        right: isMobile ? 8 : 16,
      ),
      child: InkWell(
        onTap: () => _showAppointmentDetails(context),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color.fromARGB(255, 81, 115, 153)
                  : _getStatusBorderColor(appointment.status),
              width: isSelected ? 2 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.08),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: isMobile
              ? _buildMobileLayout(controller)
              : _buildDesktopLayout(controller),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(WebAppointmentController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildPetAvatar(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    controller.getPetName(appointment.petId),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 81, 115, 153),
                    ),
                  ),
                  Text(
                    controller.getOwnerName(appointment.userId),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            _buildStatusBadge(),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(Icons.schedule, size: 14, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              DateFormat('MMM dd • hh:mm a').format(appointment.dateTime),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(width: 12),
            Icon(Icons.medical_services, size: 14, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                appointment.service,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildProgressIndicator(),
        const SizedBox(height: 12),
        _buildActionButtons(controller, isMobile: true),
      ],
    );
  }

  Widget _buildDesktopLayout(WebAppointmentController controller) {
    return Row(
      children: [
        _buildPetAvatar(),
        const SizedBox(width: 16),
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      controller.getPetName(appointment.petId),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 81, 115, 153),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildStatusBadge(),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Owner: ${controller.getOwnerName(appointment.userId)}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${controller.getPetType(appointment.petId)} • ${controller.getPetBreed(appointment.petId)}',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      DateFormat('MMM dd, yyyy').format(appointment.dateTime),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    DateFormat('hh:mm a').format(appointment.dateTime),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.medical_services,
                      size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      appointment.service,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          flex: 3,
          child: Column(
            children: [
              _buildProgressIndicator(),
              const SizedBox(height: 12),
              _buildActionButtons(controller),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPetAvatar() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        gradient: LinearGradient(
          colors: _getStatusGradient(appointment.status),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Icon(Icons.pets, color: Colors.white, size: 24),
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(appointment.status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStatusColor(appointment.status).withOpacity(0.3),
        ),
      ),
      child: Text(
        _getStatusDisplayText(appointment.status),
        style: TextStyle(
          color: _getStatusColor(appointment.status),
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildProgressDot(appointment.status != 'pending', Colors.blue),
        _buildProgressLine(appointment.hasArrived),
        _buildProgressDot(appointment.hasArrived, Colors.orange),
        _buildProgressLine(appointment.hasServiceStarted),
        _buildProgressDot(appointment.hasServiceStarted, Colors.purple),
        _buildProgressLine(appointment.hasServiceCompleted),
        _buildProgressDot(appointment.hasServiceCompleted, Colors.green),
      ],
    );
  }

  Widget _buildProgressDot(bool isActive, Color color) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? color : Colors.grey[300],
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildProgressLine(bool isActive) {
    return Container(
      width: 16,
      height: 2,
      color: isActive ? Colors.green : Colors.grey[300],
    );
  }

  Widget _buildActionButtons(WebAppointmentController controller,
      {bool isMobile = false}) {
    final buttonHeight = isMobile ? 32.0 : 36.0;
    final fontSize = isMobile ? 11.0 : 12.0;

    final isPastAccepted =
        appointment.isPast && appointment.status == 'accepted';

    if (isPastAccepted) {
      return Row(
        children: [
          Expanded(
            child: SizedBox(
              height: buttonHeight,
              child: OutlinedButton(
                onPressed: () => controller.confirmMarkNoShow(appointment),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange,
                  side: const BorderSide(color: Colors.orange),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child:
                    Text('Mark No Show', style: TextStyle(fontSize: fontSize)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: SizedBox(
              height: buttonHeight,
              child: ElevatedButton(
                onPressed: () => _showCompleteServiceDialog(controller),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: Text('Complete', style: TextStyle(fontSize: fontSize)),
              ),
            ),
          ),
        ],
      );
    }

    switch (appointment.status) {
      case 'pending':
        return Row(
          children: [
            Expanded(
              child: SizedBox(
                height: buttonHeight,
                child: OutlinedButton(
                  onPressed: () => _showDeclineDialog(controller),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: Text('Decline', style: TextStyle(fontSize: fontSize)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: SizedBox(
                height: buttonHeight,
                child: ElevatedButton(
                  onPressed: () =>
                      controller.confirmAcceptAppointment(appointment),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: Text('Accept', style: TextStyle(fontSize: fontSize)),
                ),
              ),
            ),
          ],
        );

      case 'accepted':
        if (!appointment.isToday) {
          return SizedBox(
            height: buttonHeight,
            child: OutlinedButton(
              onPressed: () => _showAppointmentDetails(Get.context!),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blue,
                side: const BorderSide(color: Colors.blue),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: Text('View Details', style: TextStyle(fontSize: fontSize)),
            ),
          );
        }

        return Row(
          children: [
            Expanded(
              child: SizedBox(
                height: buttonHeight,
                child: OutlinedButton(
                  onPressed: () => controller.confirmMarkNoShow(appointment),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange,
                    side: const BorderSide(color: Colors.orange),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: Text('No Show', style: TextStyle(fontSize: fontSize)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: SizedBox(
                height: buttonHeight,
                child: ElevatedButton(
                  onPressed: () =>
                      controller.confirmCheckInPatient(appointment),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: Text('Check In', style: TextStyle(fontSize: fontSize)),
                ),
              ),
            ),
          ],
        );

      case 'in_progress':
        return Row(
          children: [
            if (!appointment.hasServiceStarted)
              Expanded(
                child: SizedBox(
                  height: buttonHeight,
                  child: ElevatedButton(
                    onPressed: () =>
                        controller.confirmStartService(appointment),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: Text('Start', style: TextStyle(fontSize: fontSize)),
                  ),
                ),
              ),
            if (appointment.hasServiceStarted) ...[
              Expanded(
                child: SizedBox(
                  height: buttonHeight,
                  child: OutlinedButton(
                    onPressed: () => _showVitalsDialog(controller),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: Text('Vitals', style: TextStyle(fontSize: fontSize)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: buttonHeight,
                  child: ElevatedButton(
                    onPressed: () => _showCompleteServiceDialog(controller),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child:
                        Text('Complete', style: TextStyle(fontSize: fontSize)),
                  ),
                ),
              ),
            ],
          ],
        );

      default:
        return SizedBox(
          height: buttonHeight,
          child: OutlinedButton(
            onPressed: () => _showAppointmentDetails(Get.context!),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey,
              side: const BorderSide(color: Colors.grey),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: Text('View', style: TextStyle(fontSize: fontSize)),
          ),
        );
    }
  }

  void _showAppointmentDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => WebAppointmentModal(appointment: appointment),
    );
  }

  void _showDeclineDialog(WebAppointmentController controller) {
    String selectedReason = '';
    final customReasonController = TextEditingController();
    bool hasChanges = false; // Track if user made changes

    final predefinedReasons = [
      'Time slot already booked',
      'Clinic at full capacity',
      'Service not available',
      'Emergency override needed',
      'Insufficient information provided',
      'Other (specify below)',
    ];

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(24),
          child: StatefulBuilder(
            builder: (context, setState) {
              return WillPopScope(
                onWillPop: () async {
                  if (hasChanges) {
                    return await _showDiscardChangesDialog(context);
                  }
                  return true;
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.cancel,
                              color: Colors.red, size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Decline Appointment',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Please select or provide a reason for declining:',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 16),
                    ...predefinedReasons.map((reason) {
                      return RadioListTile<String>(
                        title:
                            Text(reason, style: const TextStyle(fontSize: 14)),
                        value: reason,
                        groupValue: selectedReason,
                        onChanged: (value) {
                          setState(() {
                            selectedReason = value!;
                            hasChanges = true;
                          });
                        },
                        activeColor: const Color.fromARGB(255, 81, 115, 153),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      );
                    }),
                    const SizedBox(height: 16),
                    TextField(
                      controller: customReasonController,
                      decoration: InputDecoration(
                        labelText: 'Custom reason (optional)',
                        hintText: 'Enter additional details...',
                        border: const OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      maxLength: 200,
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          hasChanges = true;
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            if (hasChanges) {
                              _showDiscardChangesDialog(context)
                                  .then((discard) {
                                if (discard == true) {
                                  customReasonController.dispose();
                                  Get.back();
                                }
                              });
                            } else {
                              customReasonController.dispose();
                              Get.back();
                            }
                          },
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: selectedReason.isEmpty
                              ? null
                              : () {
                                  String finalReason = selectedReason;
                                  if (customReasonController.text.isNotEmpty) {
                                    finalReason = selectedReason ==
                                            'Other (specify below)'
                                        ? customReasonController.text
                                        : '$selectedReason - ${customReasonController.text}';
                                  }

                                  customReasonController.dispose();
                                  Get.back();
                                  controller.declineAppointment(
                                      appointment, finalReason);
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: const Text('Decline Appointment',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showVitalsDialog(WebAppointmentController controller) {
    // Controllers
    final tempController = TextEditingController();
    final weightController = TextEditingController();
    final bpController = TextEditingController();
    final hrController = TextEditingController();

    // Form key for validation
    final formKey = GlobalKey<FormState>();

    // Pre-fill with pending vitals if they exist
    final pendingVitals = controller.getPendingVitals(appointment.documentId!);
    if (pendingVitals != null) {
      if (pendingVitals['temperature'] != null) {
        tempController.text = pendingVitals['temperature'].toString();
      }
      if (pendingVitals['weight'] != null) {
        weightController.text = pendingVitals['weight'].toString();
      }
      if (pendingVitals['bloodPressure'] != null) {
        bpController.text = pendingVitals['bloodPressure'].toString();
      }
      if (pendingVitals['heartRate'] != null) {
        hrController.text = pendingVitals['heartRate'].toString();
      }
    }

    // Validation functions
    String? validateTemperature(String? value) {
      if (value == null || value.isEmpty) return null;

      final temp = double.tryParse(value);
      if (temp == null) {
        return 'Enter a valid number';
      }
      if (temp < 0 || temp > 50) {
        return 'Temperature must be 0-50°C';
      }
      return null;
    }

    String? validateWeight(String? value) {
      if (value == null || value.isEmpty) return null;

      final weight = double.tryParse(value);
      if (weight == null) {
        return 'Enter a valid number';
      }
      if (weight < 0 || weight > 500) {
        return 'Weight must be 0-500kg';
      }
      return null;
    }

    String? validateHeartRate(String? value) {
      if (value == null || value.isEmpty) return null;

      final hr = int.tryParse(value);
      if (hr == null) {
        return 'Enter a valid whole number';
      }
      if (hr < 0 || hr > 300) {
        return 'Heart rate must be 0-300 bpm';
      }
      return null;
    }

    String? validateBloodPressure(String? value) {
      if (value == null || value.isEmpty) return null;

      final bpPattern = RegExp(r'^\d{2,3}\/\d{2,3}');

      if (!bpPattern.hasMatch(value)) {
        return 'Format: 120/80';
      }
      return null;
    }

    // Helper method to check if any field has data
    bool hasVitalData() {
      return tempController.text.isNotEmpty ||
          weightController.text.isNotEmpty ||
          bpController.text.isNotEmpty ||
          hrController.text.isNotEmpty;
    }

    // Show dialog
    showDialog(
      context: Get.context!,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 500,
            constraints: const BoxConstraints(maxHeight: 700),
            padding: const EdgeInsets.all(24),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.favorite,
                              color: Colors.red, size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Record Vital Signs',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 81, 115, 153),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          icon: const Icon(Icons.close),
                          tooltip: 'Close',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: Colors.blue[700], size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Vitals will be saved when you complete the service.',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.blue[700]),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Temperature and Weight
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: tempController,
                            decoration: InputDecoration(
                              labelText: 'Temperature (°C)',
                              border: const OutlineInputBorder(),
                              hintText: '36.0 - 40.0',
                              helperText: 'Range: 0-50°C',
                              helperStyle: TextStyle(
                                  fontSize: 11, color: Colors.grey[600]),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            validator: validateTemperature,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: weightController,
                            decoration: InputDecoration(
                              labelText: 'Weight (kg)',
                              border: const OutlineInputBorder(),
                              hintText: '5.0 - 50.0',
                              helperText: 'Range: 0-500kg',
                              helperStyle: TextStyle(
                                  fontSize: 11, color: Colors.grey[600]),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            validator: validateWeight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Blood Pressure and Heart Rate
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: bpController,
                            decoration: InputDecoration(
                              labelText: 'Blood Pressure',
                              border: const OutlineInputBorder(),
                              hintText: '120/80',
                              helperText: 'Format: 120/80',
                              helperStyle: TextStyle(
                                  fontSize: 11, color: Colors.grey[600]),
                            ),
                            validator: validateBloodPressure,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: hrController,
                            decoration: InputDecoration(
                              labelText: 'Heart Rate (bpm)',
                              border: const OutlineInputBorder(),
                              hintText: '60 - 100',
                              helperText: 'Range: 0-300 bpm',
                              helperStyle: TextStyle(
                                  fontSize: 11, color: Colors.grey[600]),
                            ),
                            keyboardType: TextInputType.number,
                            validator: validateHeartRate,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Action Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: () {
                            // Validate form
                            if (!formKey.currentState!.validate()) {
                              Get.snackbar(
                                "Invalid Input",
                                "Please fix the errors before recording vitals",
                                backgroundColor: Colors.orange,
                                colorText: Colors.white,
                                icon: const Icon(Icons.warning,
                                    color: Colors.white),
                              );
                              return;
                            }

                            // Check that at least one field is filled
                            if (!hasVitalData()) {
                              Get.snackbar(
                                "Required",
                                "Please enter at least one vital sign",
                                backgroundColor: Colors.orange,
                                colorText: Colors.white,
                              );
                              return;
                            }

                            // Build vitals map
                            final vitals = <String, dynamic>{};

                            if (tempController.text.isNotEmpty) {
                              vitals['temperature'] =
                                  double.parse(tempController.text);
                            }

                            if (weightController.text.isNotEmpty) {
                              vitals['weight'] =
                                  double.parse(weightController.text);
                            }

                            if (bpController.text.isNotEmpty) {
                              vitals['bloodPressure'] = bpController.text;
                            }

                            if (hrController.text.isNotEmpty) {
                              vitals['heartRate'] =
                                  int.parse(hrController.text);
                            }

                            vitals['recordedAt'] =
                                DateTime.now().toIso8601String();

                            // Store locally
                            controller.recordVitalsLocally(appointment, vitals);

                            // Close dialog AFTER storing
                            Navigator.of(dialogContext).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromARGB(255, 81, 115, 153),
                          ),
                          child: const Text('Record Vitals',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ).then((_) {
      // Dispose controllers after dialog closes
      tempController.dispose();
      weightController.dispose();
      bpController.dispose();
      hrController.dispose();
    });
  }

// Helper widget to build vital info rows in the discard dialog
  // Widget _buildVitalInfoRow(String label, String value) {
  //   return Padding(
  //     padding: const EdgeInsets.only(bottom: 6),
  //     child: Row(
  //       children: [
  //         Icon(Icons.check_circle, size: 14, color: Colors.orange[700]),
  //         const SizedBox(width: 8),
  //         Text(
  //           '$label: ',
  //           style: const TextStyle(
  //             fontSize: 13,
  //             fontWeight: FontWeight.w600,
  //           ),
  //         ),
  //         Text(
  //           value,
  //           style: const TextStyle(
  //             fontSize: 13,
  //             fontWeight: FontWeight.normal,
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  void _showCompleteServiceDialog(WebAppointmentController controller) {
    if (controller.isVaccinationService(appointment.service)) {
      Get.dialog(
        VaccinationCompletionDialog(appointment: appointment),
        barrierDismissible: false,
      );
      return;
    }

    final diagnosisController = TextEditingController();
    final treatmentController = TextEditingController();
    final prescriptionController = TextEditingController();
    final notesController = TextEditingController();
    bool hasChanges = false;

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 600,
          padding: const EdgeInsets.all(24),
          child: StatefulBuilder(
            builder: (context, setState) {
              return WillPopScope(
                onWillPop: () async {
                  if (hasChanges) {
                    return await _showDiscardChangesDialog(context);
                  }
                  return true;
                },
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.check_circle,
                                color: Colors.green, size: 24),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Complete Service',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromARGB(255, 81, 115, 153),
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Fill in the medical information',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline,
                                color: Colors.orange[700], size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Diagnosis and Treatment are required',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: diagnosisController,
                        decoration: const InputDecoration(
                          labelText: 'Diagnosis *',
                          border: OutlineInputBorder(),
                          hintText: 'Enter diagnosis',
                        ),
                        maxLines: 2,
                        onChanged: (value) {
                          if (value.isNotEmpty) hasChanges = true;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: treatmentController,
                        decoration: const InputDecoration(
                          labelText: 'Treatment *',
                          border: OutlineInputBorder(),
                          hintText: 'Enter treatment provided',
                        ),
                        maxLines: 2,
                        onChanged: (value) {
                          if (value.isNotEmpty) hasChanges = true;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: prescriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Prescription (Optional)',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                        onChanged: (value) {
                          if (value.isNotEmpty) hasChanges = true;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: notesController,
                        decoration: const InputDecoration(
                          labelText: 'Veterinary Notes (Optional)',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        onChanged: (value) {
                          if (value.isNotEmpty) hasChanges = true;
                        },
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              if (hasChanges) {
                                _showDiscardChangesDialog(context)
                                    .then((discard) {
                                  if (discard == true) {
                                    diagnosisController.dispose();
                                    treatmentController.dispose();
                                    prescriptionController.dispose();
                                    notesController.dispose();
                                    Get.back();
                                  }
                                });
                              } else {
                                diagnosisController.dispose();
                                treatmentController.dispose();
                                prescriptionController.dispose();
                                notesController.dispose();
                                Get.back();
                              }
                            },
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: () {
                              if (diagnosisController.text.trim().isEmpty) {
                                Get.snackbar('Required', 'Enter diagnosis',
                                    backgroundColor: Colors.orange,
                                    colorText: Colors.white);
                                return;
                              }
                              if (treatmentController.text.trim().isEmpty) {
                                Get.snackbar('Required', 'Enter treatment',
                                    backgroundColor: Colors.orange,
                                    colorText: Colors.white);
                                return;
                              }

                              controller.completeServiceWithRecord(
                                appointment: appointment,
                                diagnosis: diagnosisController.text.trim(),
                                treatment: treatmentController.text.trim(),
                                prescription: prescriptionController.text
                                        .trim()
                                        .isNotEmpty
                                    ? prescriptionController.text.trim()
                                    : null,
                                vetNotes: notesController.text.trim().isNotEmpty
                                    ? notesController.text.trim()
                                    : null,
                              );

                              diagnosisController.dispose();
                              treatmentController.dispose();
                              prescriptionController.dispose();
                              notesController.dispose();
                              Get.back();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                            child: const Text('Complete Service',
                                style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // NEW HELPER METHOD - Add to WebAppointmentTile class
  Future<bool> _showDiscardChangesDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text(
            'Discard Changes?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          content: const Text(
            'You have unsaved changes. Are you sure you want to discard them? This action cannot be undone.',
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text(
                'Continue Editing',
                style: TextStyle(color: Color.fromARGB(255, 81, 115, 153)),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text(
                'Discard Changes',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  List<Color> _getStatusGradient(String status) {
    switch (status) {
      case 'pending':
        return [Colors.orange, Colors.orange.shade300];
      case 'accepted':
        return [Colors.blue, Colors.blue.shade300];
      case 'in_progress':
        return [Colors.purple, Colors.purple.shade300];
      case 'completed':
        return [Colors.green, Colors.green.shade300];
      case 'cancelled':
        return [Colors.grey, Colors.grey.shade300];
      case 'declined':
        return [Colors.red, Colors.red.shade300];
      default:
        return [Colors.grey, Colors.grey.shade300];
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'in_progress':
        return Colors.purple;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.grey;
      case 'declined':
        return Colors.red;
      case 'no_show':
        return Colors.red.shade700;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusBorderColor(String status) {
    return _getStatusColor(status).withOpacity(0.3);
  }

  String _getStatusDisplayText(String status) {
    switch (status) {
      case 'pending':
        return 'PENDING';
      case 'accepted':
        return 'SCHEDULED';
      case 'in_progress':
        return 'IN PROGRESS';
      case 'completed':
        return 'COMPLETED';
      case 'cancelled':
        return 'CANCELLED';
      case 'declined':
        return 'DECLINED';
      case 'no_show':
        return 'NO SHOW';
      default:
        return status.toUpperCase();
    }
  }
}
