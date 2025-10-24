import 'package:capstone_app/data/models/appointment_model.dart';
import 'package:capstone_app/web/admin_web/components/appointments/admin_web_appointment_controller.dart';
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
            _buildHeader(controller),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: isMobile
                    ? _buildMobileLayout(controller)
                    : _buildDesktopLayout(controller),
              ),
            ),
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
        // Add link to view medical record if completed
        if (appointment.status == 'completed') ...[
          _buildMedicalRecordLink(),
          const SizedBox(height: 24),
        ],
      ],
    );
  }

  Widget _buildDesktopLayout(WebAppointmentController controller) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        // REMOVED: Medical information section
        // Medical data is now in MedicalRecord, not Appointment
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Add link to view medical record if completed
              if (appointment.status == 'completed') ...[
                _buildMedicalRecordLink(),
                const SizedBox(height: 24),
              ],
              // Keep workflow stats
              if (appointment.waitingTime != null ||
                  appointment.serviceDuration != null) ...[
                _buildTimingStatistics(),
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
            DateFormat('EEEE, MMMM dd, yyyy • hh:mm a')
                .format(appointment.dateTime),
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
        ],
      ),
    );
  }

  Widget _buildMedicalRecordLink() {
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
                'Medical Record',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'This appointment has been completed. Medical records including diagnosis, treatment, and vital signs are available in the Medical Records section.',
            style: TextStyle(fontSize: 14, color: Colors.black87),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              // Navigate to medical records screen
              Get.back(); // Close modal
              // You'll need to implement navigation to medical records
              // filtered by this appointment ID
            },
            icon: const Icon(Icons.arrow_forward),
            label: const Text('View Medical Record'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimingStatistics() {
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
          if (appointment.waitingTime != null ||
              appointment.serviceDuration != null) ...[
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
                    Icon(Icons.access_time,
                        size: 18, color: Colors.orange[700]),
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

  Widget _buildActionSection(
      BuildContext context, WebAppointmentController controller) {
    switch (appointment.status) {
      case 'pending':
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _showDeclineDialogModal(controller);
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
                  controller.confirmAcceptAppointment(appointment);
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
        if (!appointment.isToday) {
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

        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  controller.confirmMarkNoShow(appointment);
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
                  controller.confirmCheckInPatient(appointment);
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
      case 'cancelled':
      case 'declined':
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

  // ============= HELPER METHODS =============

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

  void _showDeclineDialogModal(WebAppointmentController controller) {
    String selectedReason = '';
    final customReasonController = TextEditingController();
    bool hasChanges = false;

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
                    return await _showDiscardChangesDialog(Get.context!);
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
                            customReasonController.dispose();
                            Get.back();
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

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else {
      return '${duration.inMinutes}m';
    }
  }
}
