import 'package:capstone_app/data/models/appointment_model.dart';
import 'package:capstone_app/mobile/admin/components/appointment_tabs/enhanced_clinic_appointment_controller.dart';
import 'package:capstone_app/mobile/admin/pages/appointment_list.dart';
import 'package:capstone_app/mobile/admin/pages/modals/appointment_workflow_modal.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class PatientWorkflowTile extends StatelessWidget {
  final Appointment appointment;
  final String workflowStage; // 'pending', 'scheduled', 'in_progress', 'completed'

  const PatientWorkflowTile({
    super.key,
    required this.appointment,
    required this.workflowStage,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<EnhancedClinicAppointmentController>();

    return Padding(
      padding: const EdgeInsets.only(top: 10, left: 16, right: 16),
      child: InkWell(
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => AppointmentWorkflowModal(
              appointment: appointment,
              workflowStage: workflowStage,
            ),
          );
        },
        child: Container(
          width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _getStatusBorderColor(appointment.status),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Main Info Row
                Row(
                  children: [
                    // Status Indicator & Avatar
                    Stack(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            gradient: LinearGradient(
                              colors: _getStatusGradient(appointment.status),
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: const Icon(
                            Icons.pets,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        // Status dot
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: _getStatusColor(appointment.status),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    
                    // Appointment Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Pet Name & Owner
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
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(appointment.status).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _getStatusDisplayText(appointment.status),
                                  style: TextStyle(
                                    color: _getStatusColor(appointment.status),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          
                          // Owner name
                          Text(
                            'Owner: ${controller.getOwnerName(appointment.userId)}',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          
                          const SizedBox(height: 2),
                          
                          // Time & Service
                          Row(
                            children: [
                              Icon(
                                Icons.schedule,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                DateFormat('MMM dd • hh:mm a').format(appointment.dateTime),
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Icon(
                                Icons.medical_services,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  appointment.service,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 8),
                          
                          // Progress Indicators
                          _buildProgressIndicators(appointment),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Action Buttons Based on Status
                _buildActionButtons(context, controller, appointment),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicators(Appointment appointment) {
    return Row(
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
    return Column(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: isActive ? color : Colors.grey[300],
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 8,
            color: isActive ? color : Colors.grey[400],
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressLine(bool isActive) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 16),
        color: isActive ? Colors.green : Colors.grey[300],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, EnhancedClinicAppointmentController controller, Appointment appointment) {
    switch (appointment.status) {
      case 'pending':
        return Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'Decline',
                Icons.close,
                Colors.red,
                () => _showConfirmDialog(
                  context,
                  'Decline Appointment',
                  'Are you sure you want to decline this appointment?',
                  () => controller.declineAppointment(appointment),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: _buildActionButton(
                'Accept',
                Icons.check,
                Colors.green,
                () => _showConfirmDialog(
                  context,
                  'Accept Appointment',
                  'Accept this appointment for ${controller.getPetName(appointment.petId)}?',
                  () => controller.acceptAppointment(appointment),
                ),
              ),
            ),
          ],
        );

      case 'accepted':
        return Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'No Show',
                Icons.person_off,
                Colors.orange,
                () => controller.markNoShow(appointment),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: _buildActionButton(
                'Check In Patient',
                Icons.login,
                Colors.blue,
                () => controller.checkInPatient(appointment),
              ),
            ),
          ],
        );

      case 'in_progress':
        return Row(
          children: [
            if (!appointment.hasServiceStarted)
              Expanded(
                child: _buildActionButton(
                  'Start Service',
                  Icons.play_arrow,
                  Colors.purple,
                  () => controller.startService(appointment),
                ),
              ),
            if (appointment.hasServiceStarted) ...[
              Expanded(
                child: _buildActionButton(
                  'Add Vitals',
                  Icons.favorite,
                  Colors.red,
                  () => _showVitalsDialog(context, controller, appointment),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: _buildActionButton(
                  'Complete Service',
                  Icons.check_circle,
                  Colors.green,
                  () => _showCompleteServiceDialog(context, controller, appointment),
                ),
              ),
            ],
          ],
        );

      case 'completed':
        return Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'View Record',
                Icons.medical_information,
                Colors.teal,
                () => _showMedicalRecordDialog(context, appointment),
              ),
            ),
            const SizedBox(width: 8),
            if (!appointment.isPaid)
              Expanded(
                child: _buildActionButton(
                  'Process Payment',
                  Icons.payment,
                  Colors.green,
                  () => _showPaymentDialog(context, controller, appointment),
                ),
              ),
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildActionButton(String text, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 2,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Dialog Methods
  void _showConfirmDialog(BuildContext context, String title, String content, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onConfirm();
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  void _showVitalsDialog(BuildContext context, EnhancedClinicAppointmentController controller, Appointment appointment) {
    final tempController = TextEditingController();
    final weightController = TextEditingController();
    final bpController = TextEditingController();
    final hrController = TextEditingController();
    final rrController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Record Vital Signs'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: tempController,
                decoration: const InputDecoration(labelText: 'Temperature (°C)'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: weightController,
                decoration: const InputDecoration(labelText: 'Weight (kg)'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: bpController,
                decoration: const InputDecoration(labelText: 'Blood Pressure'),
              ),
              TextField(
                controller: hrController,
                decoration: const InputDecoration(labelText: 'Heart Rate (bpm)'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: rrController,
                decoration: const InputDecoration(labelText: 'Respiratory Rate'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(labelText: 'Additional Notes'),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (tempController.text.isNotEmpty && weightController.text.isNotEmpty) {
                controller.addVitalSigns(
                  appointment: appointment,
                  temperature: double.parse(tempController.text),
                  weight: double.parse(weightController.text),
                  bloodPressure: bpController.text.isNotEmpty ? bpController.text : null,
                  heartRate: hrController.text.isNotEmpty ? int.parse(hrController.text) : null,
                  respiratoryRate: rrController.text.isNotEmpty ? int.parse(rrController.text) : null,
                  additionalNotes: notesController.text.isNotEmpty ? notesController.text : null,
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showCompleteServiceDialog(BuildContext context, EnhancedClinicAppointmentController controller, Appointment appointment) {
    final diagnosisController = TextEditingController();
    final treatmentController = TextEditingController();
    final prescriptionController = TextEditingController();
    final notesController = TextEditingController();
    final costController = TextEditingController();
    final followUpController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Service'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: diagnosisController,
                  decoration: const InputDecoration(labelText: 'Diagnosis *'),
                  maxLines: 2,
                ),
                TextField(
                  controller: treatmentController,
                  decoration: const InputDecoration(labelText: 'Treatment *'),
                  maxLines: 2,
                ),
                TextField(
                  controller: prescriptionController,
                  decoration: const InputDecoration(labelText: 'Prescription'),
                  maxLines: 2,
                ),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(labelText: 'Veterinary Notes'),
                  maxLines: 3,
                ),
                TextField(
                  controller: costController,
                  decoration: const InputDecoration(labelText: 'Total Cost (₱)'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: followUpController,
                  decoration: const InputDecoration(labelText: 'Follow-up Instructions'),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (diagnosisController.text.isNotEmpty && treatmentController.text.isNotEmpty) {
                controller.completeServiceWithRecord(
                  appointment: appointment,
                  diagnosis: diagnosisController.text,
                  treatment: treatmentController.text,
                  prescription: prescriptionController.text.isNotEmpty ? prescriptionController.text : null,
                  vetNotes: notesController.text.isNotEmpty ? notesController.text : null,
                  totalCost: costController.text.isNotEmpty ? double.parse(costController.text) : null,
                  followUpInstructions: followUpController.text.isNotEmpty ? followUpController.text : null,
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Complete'),
          ),
        ],
      ),
    );
  }

  void _showMedicalRecordDialog(BuildContext context, Appointment appointment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Medical Record'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Service: ${appointment.service}', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (appointment.diagnosis != null) ...[
                const Text('Diagnosis:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(appointment.diagnosis!),
                const SizedBox(height: 8),
              ],
              if (appointment.treatment != null) ...[
                const Text('Treatment:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(appointment.treatment!),
                const SizedBox(height: 8),
              ],
              if (appointment.prescription != null) ...[
                const Text('Prescription:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(appointment.prescription!),
                const SizedBox(height: 8),
              ],
              if (appointment.vetNotes != null) ...[
                const Text('Veterinary Notes:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(appointment.vetNotes!),
                const SizedBox(height: 8),
              ],
              if (appointment.vitals != null) ...[
                const Text('Vitals:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Temperature: ${appointment.vitals!['temperature']}°C'),
                Text('Weight: ${appointment.vitals!['weight']}kg'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPaymentDialog(BuildContext context, EnhancedClinicAppointmentController controller, Appointment appointment) {
    final amountController = TextEditingController(text: appointment.totalCost?.toString() ?? '');
    String paymentMethod = 'cash';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Process Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              decoration: const InputDecoration(labelText: 'Amount (₱)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: paymentMethod,
              decoration: const InputDecoration(labelText: 'Payment Method'),
              items: const [
                DropdownMenuItem(value: 'cash', child: Text('Cash')),
                DropdownMenuItem(value: 'card', child: Text('Card')),
                DropdownMenuItem(value: 'gcash', child: Text('GCash')),
              ],
              onChanged: (value) => paymentMethod = value!,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (amountController.text.isNotEmpty) {
                controller.processPayment(
                  appointment,
                  double.parse(amountController.text),
                  paymentMethod,
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Process'),
          ),
        ],
      ),
    );
  }

  // Helper Methods
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
      case 'no_show':
        return Colors.red;
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
      case 'no_show':
        return 'NO SHOW';
      default:
        return status.toUpperCase();
    }
  }
}