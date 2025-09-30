// appointment_workflow_modal.dart
import 'package:capstone_app/data/models/appointment_model.dart';
import 'package:capstone_app/mobile/admin/controllers/enhanced_clinic_appointment_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class AppointmentWorkflowModal extends StatelessWidget {
  final Appointment appointment;
  final String workflowStage;

  const AppointmentWorkflowModal({
    super.key,
    required this.appointment,
    required this.workflowStage,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<EnhancedClinicAppointmentController>();

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Modal content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with pet info
                  _buildHeader(controller),
                  const SizedBox(height: 24),
                  
                  // Appointment details
                  _buildAppointmentDetails(),
                  const SizedBox(height: 24),
                  
                  // Workflow progress
                  _buildWorkflowProgress(),
                  const SizedBox(height: 24),
                  
                  // Medical information (if available)
                  if (appointment.hasMedicalRecord) ...[
                    _buildMedicalInformation(),
                    const SizedBox(height: 24),
                  ],
                  
                  // Vitals (if available)
                  if (appointment.vitals != null) ...[
                    _buildVitalsSection(),
                    const SizedBox(height: 24),
                  ],
                  
                  // Action buttons
                  _buildActionButtons(context, controller),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(EnhancedClinicAppointmentController controller) {
    return Row(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            gradient: LinearGradient(
              colors: _getStatusGradient(appointment.status),
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Icon(
            Icons.pets,
            color: Colors.white,
            size: 40,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                controller.getPetName(appointment.petId),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 81, 115, 153),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Owner: ${controller.getOwnerName(appointment.userId)}',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${controller.getPetType(appointment.petId)} • ${controller.getPetBreed(appointment.petId)}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getStatusColor(appointment.status).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _getStatusColor(appointment.status).withOpacity(0.3),
            ),
          ),
          child: Text(
            _getStatusDisplayText(appointment.status),
            style: TextStyle(
              color: _getStatusColor(appointment.status),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppointmentDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Appointment Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 81, 115, 153),
            ),
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            Icons.schedule,
            'Scheduled Time',
            DateFormat('EEEE, MMMM dd, yyyy • hh:mm a').format(appointment.dateTime),
          ),
          const SizedBox(height: 8),
          _buildDetailRow(
            Icons.medical_services,
            'Service',
            appointment.service,
          ),
          if (appointment.notes != null) ...[
            const SizedBox(height: 8),
            _buildDetailRow(
              Icons.note,
              'Notes',
              appointment.notes!,
            ),
          ],
          if (appointment.totalCost != null) ...[
            const SizedBox(height: 8),
            _buildDetailRow(
              Icons.attach_money,
              'Cost',
              '₱${appointment.totalCost!.toStringAsFixed(2)}',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          flex: 1,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWorkflowProgress() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Workflow Progress',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 81, 115, 153),
            ),
          ),
          const SizedBox(height: 16),
          
          // Timeline
          _buildTimelineItem(
            'Scheduled',
            appointment.status != 'pending',
            Colors.blue,
            appointment.createdAt,
            isFirst: true,
          ),
          _buildTimelineItem(
            'Patient Arrived',
            appointment.hasArrived,
            Colors.orange,
            appointment.checkedInAt,
          ),
          _buildTimelineItem(
            'Treatment Started',
            appointment.hasServiceStarted,
            Colors.purple,
            appointment.serviceStartedAt,
          ),
          _buildTimelineItem(
            'Service Completed',
            appointment.hasServiceCompleted,
            Colors.green,
            appointment.serviceCompletedAt,
            isLast: true,
          ),
          
          // Show waiting times
          if (appointment.waitingTime != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.orange[700]),
                  const SizedBox(width: 8),
                  Text(
                    'Waiting time: ${_formatDuration(appointment.waitingTime!)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          if (appointment.serviceDuration != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.timer, size: 16, color: Colors.green[700]),
                  const SizedBox(width: 8),
                  Text(
                    'Service duration: ${_formatDuration(appointment.serviceDuration!)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimelineItem(
    String title,
    bool isCompleted,
    Color color,
    DateTime? timestamp, {
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Row(
      children: [
        Column(
          children: [
            if (!isFirst)
              Container(
                width: 2,
                height: 16,
                color: isCompleted ? color : Colors.grey[300],
              ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isCompleted ? color : Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: isCompleted
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 16,
                color: isCompleted ? color : Colors.grey[300],
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: isCompleted ? color : Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              if (timestamp != null)
                Text(
                  DateFormat('MMM dd, hh:mm a').format(timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMedicalInformation() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.teal[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.medical_information, color: Colors.teal[700]),
              const SizedBox(width: 8),
              const Text(
                'Medical Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          if (appointment.diagnosis != null) ...[
            _buildMedicalRow('Diagnosis', appointment.diagnosis!),
            const SizedBox(height: 8),
          ],
          
          if (appointment.treatment != null) ...[
            _buildMedicalRow('Treatment', appointment.treatment!),
            const SizedBox(height: 8),
          ],
          
          if (appointment.prescription != null) ...[
            _buildMedicalRow('Prescription', appointment.prescription!),
            const SizedBox(height: 8),
          ],
          
          if (appointment.vetNotes != null) ...[
            _buildMedicalRow('Veterinary Notes', appointment.vetNotes!),
          ],
        ],
      ),
    );
  }

  Widget _buildMedicalRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.teal[700],
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildVitalsSection() {
    if (appointment.vitals == null) return const SizedBox.shrink();
    
    final vitals = appointment.vitals!;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.favorite, color: Colors.red[700]),
              const SizedBox(width: 8),
              const Text(
                'Vital Signs',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Vitals grid
          GridView.count(
            crossAxisCount: 2,
            childAspectRatio: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              if (vitals['temperature'] != null)
                _buildVitalCard('Temperature', '${vitals['temperature']}°C', Icons.thermostat),
              if (vitals['weight'] != null)
                _buildVitalCard('Weight', '${vitals['weight']}kg', Icons.monitor_weight),
              if (vitals['heartRate'] != null)
                _buildVitalCard('Heart Rate', '${vitals['heartRate']} bpm', Icons.favorite),
              if (vitals['bloodPressure'] != null)
                _buildVitalCard('Blood Pressure', '${vitals['bloodPressure']}', Icons.bloodtype),
            ],
          ),
          
          if (vitals['additionalNotes'] != null) ...[
            const SizedBox(height: 8),
            _buildMedicalRow('Additional Notes', vitals['additionalNotes']),
          ],
        ],
      ),
    );
  }

  Widget _buildVitalCard(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[100]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: Colors.red[600]),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.red[700],
              fontSize: 12,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, EnhancedClinicAppointmentController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 81, 115, 153),
            ),
          ),
          const SizedBox(height: 12),
          
          // Action buttons based on status
          _getActionButtons(context, controller),
        ],
      ),
    );
  }

  Widget _getActionButtons(BuildContext context, EnhancedClinicAppointmentController controller) {
    switch (appointment.status) {
      case 'pending':
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  controller.acceptAppointment(appointment);
                },
                icon: const Icon(Icons.check),
                label: const Text('Accept Appointment'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  controller.declineAppointment(appointment);
                },
                icon: const Icon(Icons.close),
                label: const Text('Decline'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        );

      case 'accepted':
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  controller.checkInPatient(appointment);
                },
                icon: const Icon(Icons.login),
                label: const Text('Check In Patient'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  controller.markNoShow(appointment);
                },
                icon: const Icon(Icons.person_off),
                label: const Text('Mark as No Show'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange,
                  side: const BorderSide(color: Colors.orange),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        );

      case 'in_progress':
        return Column(
          children: [
            if (!appointment.hasServiceStarted) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    controller.startService(appointment);
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start Service'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showVitalsDialog(context, controller),
                icon: const Icon(Icons.favorite),
                label: const Text('Record Vitals'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            
            if (appointment.hasServiceStarted) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showCompleteServiceDialog(context, controller),
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Complete Service'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ],
        );

      case 'completed':
        return Column(
          children: [
            if (!appointment.isPaid) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showPaymentDialog(context, controller),
                  icon: const Icon(Icons.payment),
                  label: const Text('Process Payment'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _printMedicalRecord(context),
                icon: const Icon(Icons.print),
                label: const Text('Print Medical Record'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue,
                  side: const BorderSide(color: Colors.blue),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        );

      default:
        return const Text('No actions available');
    }
  }

  // Helper methods for dialogs
  void _showVitalsDialog(BuildContext context, EnhancedClinicAppointmentController controller) {
    // Implement vitals dialog similar to the one in patient_workflow_tile.dart
    Navigator.pop(context); // Close modal first
    // Then show vitals dialog
  }

  void _showCompleteServiceDialog(BuildContext context, EnhancedClinicAppointmentController controller) {
    // Implement complete service dialog similar to the one in patient_workflow_tile.dart
    Navigator.pop(context); // Close modal first
    // Then show complete service dialog
  }

  void _showPaymentDialog(BuildContext context, EnhancedClinicAppointmentController controller) {
    // Implement payment dialog similar to the one in patient_workflow_tile.dart
    Navigator.pop(context); // Close modal first
    // Then show payment dialog
  }

  void _printMedicalRecord(BuildContext context) {
    Navigator.pop(context);
    Get.snackbar('Info', 'Medical record printing feature will be implemented');
  }

  // Helper methods
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

  String _getStatusDisplayText(String status) {
    switch (status) {
      case 'pending':
        return 'PENDING REVIEW';
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

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else {
      return '${duration.inMinutes}m';
    }
  }
}