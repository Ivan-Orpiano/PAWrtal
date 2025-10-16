import 'package:capstone_app/data/models/appointment_model.dart';
import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/mobile/user/components/appointment_tabs/components/mobile_rating_dialog.dart';
import 'package:capstone_app/data/models/pet_model.dart';
import 'package:capstone_app/mobile/user/components/appointment_tabs/components/appointment_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class EnhancedAppointmentDetailsPage extends StatelessWidget {
  final Appointment appointment;
  final Clinic? clinic;
  final Pet? pet;

  const EnhancedAppointmentDetailsPage({
    super.key,
    required this.appointment,
    this.clinic,
    this.pet,
  });

  Color _getStatusColor() {
    switch (appointment.status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'in_progress':
        return Colors.purple;
      case 'completed':
        return Colors.green;
      case 'declined':
      case 'no_show':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon() {
    switch (appointment.status.toLowerCase()) {
      case 'pending':
        return Icons.pending_actions;
      case 'accepted':
        return Icons.event_available;
      case 'in_progress':
        return Icons.medical_services;
      case 'completed':
        return Icons.check_circle;
      case 'declined':
        return Icons.cancel;
      case 'no_show':
        return Icons.person_off;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<EnhancedUserAppointmentController>();

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Appointment Details',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey[100],
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Enhanced status banner with progress
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _getStatusColor().withOpacity(0.1),
                          _getStatusColor().withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _getStatusColor().withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _getStatusColor().withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                _getStatusIcon(),
                                color: _getStatusColor(),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    controller.getUserFriendlyStatus(appointment),
                                    style: TextStyle(
                                      color: _getStatusColor(),
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    controller.getAppointmentStage(appointment),
                                    style: TextStyle(
                                      color: _getStatusColor(),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Progress indicator
                        if (appointment.status != 'declined' && appointment.status != 'no_show') ...[
                          Row(
                            children: [
                              Text(
                                'Progress',
                                style: TextStyle(
                                  color: _getStatusColor(),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${(controller.getAppointmentProgress(appointment) * 100).toInt()}%',
                                style: TextStyle(
                                  color: _getStatusColor(),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: controller.getAppointmentProgress(appointment),
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(_getStatusColor()),
                            minHeight: 6,
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Basic appointment details
                  _buildDetailSection('Appointment Information', [
                    _buildDetailRow(Icons.local_hospital, 'Clinic', clinic?.clinicName ?? 'Unknown Clinic'),
                    _buildDetailRow(Icons.location_on, 'Address', clinic?.address ?? 'Address not available'),
                    _buildDetailRow(Icons.medical_services, 'Service', appointment.service),
                    _buildDetailRow(Icons.pets, 'Pet', pet?.name ?? appointment.petId),
                    if (pet != null)
                      _buildDetailRow(Icons.category, 'Pet Details', '${pet!.type} • ${pet!.breed}'),
                    _buildDetailRow(Icons.calendar_today, 'Date', DateFormat('EEEE, MMMM dd, yyyy').format(appointment.dateTime)),
                    _buildDetailRow(Icons.access_time, 'Time', DateFormat('h:mm a').format(appointment.dateTime)),
                  ]),
                  
                  // Treatment timeline for active/completed appointments
                  if (appointment.status == 'in_progress' || appointment.status == 'completed')
                    _buildTreatmentTimeline(),
                  
                  // Medical record for completed appointments
                  if (appointment.status == 'completed' && appointment.hasMedicalRecord)
                    _buildMedicalRecordSection(),
                  
                  // Payment information for completed appointments
                  if (appointment.status == 'completed' && appointment.totalCost != null)
                    _buildPaymentSection(),
                  
                  // Booking information
                  _buildDetailSection('Booking Information', [
                    _buildDetailRow(Icons.event, 'Booked on', DateFormat('MMM dd, yyyy • h:mm a').format(appointment.createdAt)),
                    if (appointment.updatedAt != appointment.createdAt)
                      _buildDetailRow(Icons.update, 'Last updated', DateFormat('MMM dd, yyyy • h:mm a').format(appointment.updatedAt)),
                  ]),
                  
                  if (appointment.notes != null && appointment.notes!.isNotEmpty)
                    _buildDetailSection('Notes', [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          appointment.notes!,
                          style: const TextStyle(fontSize: 14, height: 1.5),
                        ),
                      ),
                    ]),
                  
                  const SizedBox(height: 24),
                  
                  // Action buttons
                  _buildActionButtons(context, controller),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 81, 115, 153).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              color: const Color.fromARGB(255, 81, 115, 153),
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTreatmentTimeline() {
    return _buildDetailSection('Treatment Timeline', [
      _buildTimelineItem(
        'Appointment Scheduled',
        DateFormat('MMM dd, h:mm a').format(appointment.createdAt),
        Icons.event_available,
        Colors.blue,
        isCompleted: true,
      ),
      if (appointment.checkedInAt != null)
        _buildTimelineItem(
          'Patient Checked In',
          DateFormat('MMM dd, h:mm a').format(appointment.checkedInAt!),
          Icons.login,
          Colors.orange,
          isCompleted: true,
        ),
      if (appointment.serviceStartedAt != null)
        _buildTimelineItem(
          'Treatment Started',
          DateFormat('MMM dd, h:mm a').format(appointment.serviceStartedAt!),
          Icons.medical_services,
          Colors.purple,
          isCompleted: true,
        ),
      if (appointment.serviceCompletedAt != null)
        _buildTimelineItem(
          'Treatment Completed',
          DateFormat('MMM dd, h:mm a').format(appointment.serviceCompletedAt!),
          Icons.check_circle,
          Colors.green,
          isCompleted: true,
        ),
    ]);
  }

  Widget _buildTimelineItem(String title, String time, IconData icon, Color color, {bool isCompleted = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isCompleted ? color.withOpacity(0.2) : Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: isCompleted ? color : Colors.grey[400],
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: isCompleted ? Colors.grey[800] : Colors.grey[500],
                  ),
                ),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 12,
                    color: isCompleted ? Colors.grey[600] : Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
          if (isCompleted)
            Icon(
              Icons.check_circle,
              color: color,
              size: 16,
            ),
        ],
      ),
    );
  }

  Widget _buildMedicalRecordSection() {
    return _buildDetailSection('Medical Record', [
      if (appointment.diagnosis != null)
        _buildDetailRow(Icons.medical_information, 'Diagnosis', appointment.diagnosis!),
      if (appointment.treatment != null)
        _buildDetailRow(Icons.healing, 'Treatment', appointment.treatment!),
      if (appointment.prescription != null)
        _buildDetailRow(Icons.medication, 'Prescription', appointment.prescription!),
      if (appointment.vetNotes != null)
        _buildDetailRow(Icons.note_alt, 'Veterinary Notes', appointment.vetNotes!),
      if (appointment.vitals != null)
        _buildVitalsSection(),
      if (appointment.followUpInstructions != null)
        _buildDetailRow(Icons.assignment, 'Follow-up Instructions', appointment.followUpInstructions!),
    ]);
  }

  Widget _buildVitalsSection() {
    final vitals = appointment.vitals!;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.favorite,
                  color: Colors.red,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Vital Signs',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                if (vitals['temperature'] != null)
                  _buildVitalRow('Temperature', '${vitals['temperature']}°C', Icons.thermostat),
                if (vitals['weight'] != null)
                  _buildVitalRow('Weight', '${vitals['weight']} kg', Icons.monitor_weight),
                if (vitals['heartRate'] != null)
                  _buildVitalRow('Heart Rate', '${vitals['heartRate']} bpm', Icons.favorite),
                if (vitals['bloodPressure'] != null)
                  _buildVitalRow('Blood Pressure', vitals['bloodPressure'], Icons.bloodtype),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVitalRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.red[600]),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSection() {
    return _buildDetailSection('Payment Information', [
      _buildDetailRow(Icons.attach_money, 'Total Cost', '₱${appointment.totalCost!.toStringAsFixed(2)}'),
      _buildDetailRow(
        appointment.isPaid ? Icons.check_circle : Icons.pending,
        'Payment Status',
        appointment.isPaid ? 'Paid' : 'Pending',
      ),
      if (appointment.paymentMethod != null)
        _buildDetailRow(Icons.payment, 'Payment Method', appointment.paymentMethod!.toUpperCase()),
    ]);
  }

  Widget _buildActionButtons(BuildContext context, EnhancedUserAppointmentController controller) {
    return FutureBuilder<bool>(
      future: Get.find<AuthRepository>().hasUserReviewedAppointment(appointment.documentId!),
      builder: (context, snapshot) {
        final hasReviewed = snapshot.data ?? false;
        
        return Column(
          children: [
            // Rating & Review button for completed appointments
            if (appointment.status == 'completed')
              SizedBox(
                width: double.infinity,
                child: hasReviewed
                    ? Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green.shade600,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Review Submitted',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ElevatedButton.icon(
                        onPressed: () => _showRatingDialog(context),
                        icon: const Icon(Icons.rate_review),
                        label: const Text('Rate & Review'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber.shade50,
                          foregroundColor: Colors.amber.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.amber.shade200),
                          ),
                        ),
                      ),
              ),
            
            if (appointment.status == 'completed') const SizedBox(height: 12),
            
            // Cancel button for eligible appointments
            if (controller.canCancelAppointment(appointment))
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showCancelDialog(context, controller),
                  icon: const Icon(Icons.cancel_outlined),
                  label: Text(appointment.status == 'pending'
                      ? 'Cancel Request'
                      : 'Cancel Appointment'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: appointment.status == 'pending'
                        ? Colors.orange.shade50
                        : Colors.red.shade50,
                    foregroundColor: appointment.status == 'pending'
                        ? Colors.orange.shade700
                        : Colors.red.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: appointment.status == 'pending'
                            ? Colors.orange.shade200
                            : Colors.red.shade200,
                      ),
                    ),
                  ),
                ),
              ),
            
            if (controller.canCancelAppointment(appointment))
              const SizedBox(height: 12),
            
            // Contact clinic button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showContactOptions(context),
                icon: const Icon(Icons.phone),
                label: const Text('Contact Clinic'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 81, 115, 153),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

    void _showRatingDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => MobileRatingDialog(
        appointment: appointment,
        clinic: clinic,
        pet: pet,
      ),
    );
    
    // If review was submitted, refresh the UI
    if (result == true) {
      // Close the appointment details bottom sheet
      Navigator.pop(context);
      // Refresh appointments
      Get.find<EnhancedUserAppointmentController>().fetchAppointments();
    }
  }

  void _showCancelDialog(BuildContext context, EnhancedUserAppointmentController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Appointment'),
        content: const Text('Are you sure you want to cancel this appointment? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep Appointment'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              controller.cancelPendingAppointment(appointment.documentId!);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cancel Appointment', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showContactOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Contact ${clinic?.clinicName ?? 'Clinic'}',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 81, 115, 153).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.phone, color: Color.fromARGB(255, 81, 115, 153)),
              ),
              title: const Text('Call Clinic'),
              subtitle: Text(clinic?.contact ?? 'Phone not available'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement phone call functionality
                Get.snackbar('Info', 'Phone call feature will be implemented');
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 81, 115, 153).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.email, color: Color.fromARGB(255, 81, 115, 153)),
              ),
              title: const Text('Send Email'),
              subtitle: Text(clinic?.email ?? 'Email not available'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement email functionality
                Get.snackbar('Info', 'Email feature will be implemented');
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // void _showRescheduleDialog(BuildContext context) {
  //   showDialog(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  //       title: const Text('Request Reschedule'),
  //       content: const Text('Would you like to request a reschedule for this appointment? The clinic will be notified and will contact you with available time slots.'),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(context),
  //           child: const Text('Cancel'),
  //         ),
  //         ElevatedButton(
  //           onPressed: () {
  //             Navigator.pop(context);
  //             // TODO: Implement reschedule request functionality
  //             Get.snackbar(
  //               'Request Sent',
  //               'Your reschedule request has been sent to the clinic.',
  //               backgroundColor: Colors.green,
  //               colorText: Colors.white,
  //             );
  //           },
  //           style: ElevatedButton.styleFrom(
  //             backgroundColor: const Color.fromARGB(255, 81, 115, 153),
  //           ),
  //           child: const Text('Send Request', style: TextStyle(color: Colors.white)),
  //         ),
  //       ],
  //     ),
  //   );
  // }
}