import 'package:capstone_app/data/models/appointment_model.dart';
import 'package:capstone_app/web/admin_web/components/appointments/web_appointment_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class WebAppointmentModal extends StatelessWidget {
  final Appointment appointment;

  const WebAppointmentModal({
    super.key,
    required this.appointment,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<WebAppointmentController>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: isMobile ? screenWidth * 0.95 : 800,
        height: isMobile ? MediaQuery.of(context).size.height * 0.85 : 700,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(controller),
            const SizedBox(height: 24),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                child: isMobile ? _buildMobileLayout(controller) : _buildDesktopLayout(controller),
              ),
            ),
            
            // Actions
            const SizedBox(height: 24),
            _buildActionSection(context, controller),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(WebAppointmentController controller) {
    return Row(
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
              Text(
                'Owner: ${controller.getOwnerName(appointment.userId)}',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
        const SizedBox(width: 16),
        IconButton(
          onPressed: () => Navigator.of(Get.context!).pop(),
          icon: const Icon(Icons.close),
          iconSize: 24,
        ),
      ],
    );
  }

  Widget _buildMobileLayout(WebAppointmentController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAppointmentDetails(),
        const SizedBox(height: 24),
        _buildWorkflowProgress(),
        const SizedBox(height: 24),
        if (appointment.hasMedicalRecord) ...[
          _buildMedicalInformation(),
          const SizedBox(height: 24),
        ],
        if (appointment.vitals != null) ...[
          _buildVitalsSection(),
          const SizedBox(height: 24),
        ],
      ],
    );
  }

  Widget _buildDesktopLayout(WebAppointmentController controller) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left column
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAppointmentDetails(),
              const SizedBox(height: 24),
              _buildWorkflowProgress(),
            ],
          ),
        ),
        const SizedBox(width: 24),
        // Right column
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (appointment.hasMedicalRecord) ...[
                _buildMedicalInformation(),
                const SizedBox(height: 24),
              ],
              if (appointment.vitals != null) ...[
                _buildVitalsSection(),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAppointmentDetails() {
    return Container(
      padding: const EdgeInsets.all(20),
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
          const SizedBox(height: 16),
          _buildDetailRow(
            Icons.schedule,
            'Scheduled Time',
            DateFormat('EEEE, MMMM dd, yyyy • hh:mm a').format(appointment.dateTime),
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            Icons.medical_services,
            'Service',
            appointment.service,
          ),
          if (appointment.notes != null) ...[
            const SizedBox(height: 12),
            _buildDetailRow(
              Icons.note,
              'Notes',
              appointment.notes!,
            ),
          ],
          if (appointment.totalCost != null) ...[
            const SizedBox(height: 12),
            _buildDetailRow(
              Icons.attach_money,
              'Total Cost',
              '₱${appointment.totalCost!.toStringAsFixed(2)}',
            ),
          ],
          if (appointment.isPaid) ...[
            const SizedBox(height: 12),
            _buildDetailRow(
              Icons.payment,
              'Payment Status',
              'PAID (${appointment.paymentMethod?.toUpperCase() ?? 'UNKNOWN'})',
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
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWorkflowProgress() {
    return Container(
      padding: const EdgeInsets.all(20),
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
          const SizedBox(height: 20),
          
          // Timeline
          _buildTimelineItem(
            'Appointment Scheduled',
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
          
          // Show timing statistics
          if (appointment.waitingTime != null || appointment.serviceDuration != null) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              'Timing Statistics',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 81, 115, 153),
              ),
            ),
            const SizedBox(height: 12),
            if (appointment.waitingTime != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.access_time, size: 18, color: Colors.orange[700]),
                    const SizedBox(width: 8),
                    Text(
                      'Waiting time: ${_formatDuration(appointment.waitingTime!)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.orange[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            if (appointment.serviceDuration != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.timer, size: 18, color: Colors.green[700]),
                    const SizedBox(width: 8),
                    Text(
                      'Service duration: ${_formatDuration(appointment.serviceDuration!)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.green[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
                height: 20,
                color: isCompleted ? color : Colors.grey[300],
              ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isCompleted ? color : Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: isCompleted
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 20,
                color: isCompleted ? color : Colors.grey[300],
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isCompleted ? color : Colors.grey[600],
                  ),
                ),
                if (timestamp != null)
                  Text(
                    DateFormat('MMM dd, yyyy • hh:mm a').format(timestamp),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[500],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMedicalInformation() {
    return Container(
      padding: const EdgeInsets.all(20),
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
          const SizedBox(height: 16),
          
          if (appointment.diagnosis != null) ...[
            _buildMedicalRow('Diagnosis', appointment.diagnosis!),
            const SizedBox(height: 12),
          ],
          
          if (appointment.treatment != null) ...[
            _buildMedicalRow('Treatment', appointment.treatment!),
            const SizedBox(height: 12),
          ],
          
          if (appointment.prescription != null) ...[
            _buildMedicalRow('Prescription', appointment.prescription!),
            const SizedBox(height: 12),
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
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.teal[700],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
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
      padding: const EdgeInsets.all(20),
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
          const SizedBox(height: 16),
          
          // Vitals grid
          GridView.count(
            crossAxisCount: 2,
            childAspectRatio: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
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
            const SizedBox(height: 16),
            _buildMedicalRow('Additional Notes', vitals['additionalNotes']),
          ],
        ],
      ),
    );
  }

  Widget _buildVitalCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[100]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: Colors.red[600]),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.red[700],
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionSection(BuildContext context, WebAppointmentController controller) {
    switch (appointment.status) {
      case 'pending':
        return Row(
          children: [
            Expanded(
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
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
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
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        );

      case 'accepted':
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  controller.markNoShow(appointment);
                },
                icon: const Icon(Icons.person_off),
                label: const Text('No Show'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange,
                  side: const BorderSide(color: Colors.orange),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
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
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        );

      case 'completed':
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _printMedicalRecord(),
                icon: const Icon(Icons.print),
                label: const Text('Print Record'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue,
                  side: const BorderSide(color: Colors.blue),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            if (!appointment.isPaid) ...[
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () => _showPaymentDialog(context, controller),
                  icon: const Icon(Icons.payment),
                  label: const Text('Process Payment'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ],
        );

      default:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Close'),
              ),
            ),
          ],
        );
    }
  }

  void _showPaymentDialog(BuildContext context, WebAppointmentController controller) {
    final amountController = TextEditingController(
      text: appointment.totalCost?.toString() ?? '',
    );
    String paymentMethod = 'cash';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Process Payment',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 81, 115, 153),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount (₱)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              StatefulBuilder(
                builder: (context, setState) => DropdownButtonFormField<String>(
                  value: paymentMethod,
                  decoration: const InputDecoration(
                    labelText: 'Payment Method',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'cash', child: Text('Cash')),
                    DropdownMenuItem(value: 'card', child: Text('Card')),
                    DropdownMenuItem(value: 'gcash', child: Text('GCash')),
                  ],
                  onChanged: (value) => setState(() => paymentMethod = value!),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {
                      if (amountController.text.isNotEmpty) {
                        controller.processPayment(
                          appointment,
                          double.parse(amountController.text),
                          paymentMethod,
                        );
                        Navigator.pop(context); // Close payment dialog
                        Navigator.pop(Get.context!); // Close main modal
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text('Process', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _printMedicalRecord() {
    Navigator.pop(Get.context!);
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
      case 'declined':
        return Colors.red;
      case 'no_show':
        return Colors.red.shade700;
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
      case 'declined':
        return 'DECLINED';
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