import 'package:capstone_app/data/models/appointment_model.dart';
import 'package:capstone_app/web/admin_web/components/appointments/web_appointment_controller.dart';
import 'package:capstone_app/web/admin_web/components/appointments/web_appointment_modal.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

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
    final isTablet = screenWidth < 1200 && screenWidth >= 768;
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
          child: isMobile ? _buildMobileLayout(controller) : _buildDesktopLayout(controller, isTablet),
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

  Widget _buildDesktopLayout(WebAppointmentController controller, bool isTablet) {
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
                  Icon(Icons.medical_services, size: 16, color: Colors.grey[600]),
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
          flex: isTablet ? 2 : 3,
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
      child: const Icon(
        Icons.pets,
        color: Colors.white,
        size: 24,
      ),
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
        _buildProgressDot('Scheduled', appointment.status != 'pending', Colors.blue),
        _buildProgressLine(appointment.hasArrived),
        _buildProgressDot('Arrived', appointment.hasArrived, Colors.orange),
        _buildProgressLine(appointment.hasServiceStarted),
        _buildProgressDot('Treatment', appointment.hasServiceStarted, Colors.purple),
        _buildProgressLine(appointment.hasServiceCompleted),
        _buildProgressDot('Complete', appointment.hasServiceCompleted, Colors.green),
      ],
    );
  }

  Widget _buildProgressDot(String label, bool isActive, Color color) {
    return Tooltip(
      message: label,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: isActive ? color : Colors.grey[300],
          borderRadius: BorderRadius.circular(4),
        ),
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

  Widget _buildActionButtons(WebAppointmentController controller, {bool isMobile = false}) {
    final buttonHeight = isMobile ? 32.0 : 36.0;
    final fontSize = isMobile ? 11.0 : 12.0;
    
    switch (appointment.status) {
      case 'pending':
        return Row(
          children: [
            Expanded(
              child: SizedBox(
                height: buttonHeight,
                child: OutlinedButton(
                  onPressed: () => _showConfirmDialog(
                    'Decline Appointment',
                    'Are you sure you want to decline this appointment?',
                    () => controller.declineAppointment(appointment),
                  ),
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
                  onPressed: () => controller.acceptAppointment(appointment),
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
        // Only show action buttons if appointment is today
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
                  onPressed: () => controller.markNoShow(appointment),
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
                  onPressed: () => controller.checkInPatient(appointment),
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
                    onPressed: () => controller.startService(appointment),
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
                    child: Text('Complete', style: TextStyle(fontSize: fontSize)),
                  ),
                ),
              ),
            ],
          ],
        );

      case 'completed':
      case 'cancelled':
      case 'declined':
        return SizedBox(
          height: buttonHeight,
          child: OutlinedButton(
            onPressed: () => _showAppointmentDetails(Get.context!),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey,
              side: const BorderSide(color: Colors.grey),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: Text('View Details', style: TextStyle(fontSize: fontSize)),
          ),
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

  void _showConfirmDialog(String title, String content, VoidCallback onConfirm) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 81, 115, 153),
            ),
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showVitalsDialog(WebAppointmentController controller) {
    final tempController = TextEditingController();
    final weightController = TextEditingController();
    final bpController = TextEditingController();
    final hrController = TextEditingController();
    final notesController = TextEditingController();

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Record Vital Signs',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 81, 115, 153),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: tempController,
                      decoration: const InputDecoration(
                        labelText: 'Temperature (°C)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: weightController,
                      decoration: const InputDecoration(
                        labelText: 'Weight (kg)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: bpController,
                      decoration: const InputDecoration(
                        labelText: 'Blood Pressure',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: hrController,
                      decoration: const InputDecoration(
                        labelText: 'Heart Rate (bpm)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Additional Notes',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {
                      if (tempController.text.isNotEmpty && weightController.text.isNotEmpty) {
                        final vitals = {
                          'temperature': double.parse(tempController.text),
                          'weight': double.parse(weightController.text),
                          'bloodPressure': bpController.text.isNotEmpty ? bpController.text : null,
                          'heartRate': hrController.text.isNotEmpty ? int.parse(hrController.text) : null,
                          'additionalNotes': notesController.text.isNotEmpty ? notesController.text : null,
                          'recordedAt': DateTime.now().toIso8601String(),
                        };

                        final updatedAppointment = appointment.copyWith(
                          vitals: vitals,
                          updatedAt: DateTime.now(),
                        );

                        controller.updateFullAppointment(updatedAppointment);
                        Get.back();
                        Get.snackbar("Success", "Vital signs recorded!");
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 81, 115, 153),
                    ),
                    child: const Text('Save', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCompleteServiceDialog(WebAppointmentController controller) {
    final diagnosisController = TextEditingController();
    final treatmentController = TextEditingController();
    final prescriptionController = TextEditingController();
    final notesController = TextEditingController();

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 600,
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Complete Service',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 81, 115, 153),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Leave fields empty to set as "N/A"',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: diagnosisController,
                  decoration: const InputDecoration(
                    labelText: 'Diagnosis (Optional)',
                    border: OutlineInputBorder(),
                    hintText: 'Leave empty for N/A',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: treatmentController,
                  decoration: const InputDecoration(
                    labelText: 'Treatment (Optional)',
                    border: OutlineInputBorder(),
                    hintText: 'Leave empty for N/A',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: prescriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Prescription (Optional)',
                    border: OutlineInputBorder(),
                    hintText: 'Leave empty for N/A',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Veterinary Notes (Optional)',
                    border: OutlineInputBorder(),
                    hintText: 'Leave empty for N/A',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Get.back(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () {
                        controller.completeServiceWithRecord(
                          appointment: appointment,
                          diagnosis: diagnosisController.text.isEmpty ? null : diagnosisController.text,
                          treatment: treatmentController.text.isEmpty ? null : treatmentController.text,
                          prescription: prescriptionController.text.isEmpty ? null : prescriptionController.text,
                          vetNotes: notesController.text.isEmpty ? null : notesController.text,
                        );
                        Get.back();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: const Text('Complete Service', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
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