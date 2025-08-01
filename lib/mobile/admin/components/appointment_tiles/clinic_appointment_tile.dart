// clinic_appointment_tile.dart - FIXED VERSION
import 'package:capstone_app/data/models/appointment_model.dart';
import 'package:capstone_app/mobile/admin/components/appointment_tabs/clinic_appointment_controller.dart';
import 'package:capstone_app/mobile/admin/pages/appointment_details_modal.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class ClinicAppointmentTile extends StatelessWidget {
  final Appointment appointment;
  final bool showActions;

  const ClinicAppointmentTile({
    super.key,
    required this.appointment,
    this.showActions = false,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ClinicAppointmentController>();

    return Padding(
      padding: const EdgeInsets.only(top: 10, left: 16, right: 16),
      child: InkWell(
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => AppointmentDetailsModal(appointment: appointment),
          );
        },
        child: Container(
          width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
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
                Row(
                  children: [
                    // Pet/Owner Avatar
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        gradient: LinearGradient(
                          colors: [
                            const Color.fromARGB(255, 81, 115, 153),
                            Colors.blue.shade300,
                          ],
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
                    // Appointment Details - FIXED: Use Flexible instead of Expanded
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Owner Name
                          Text(
                            controller.getOwnerName(appointment.userId),
                            style: const TextStyle(
                              color: Color.fromARGB(255, 81, 115, 153),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          // Date & Time
                          Row(
                            mainAxisSize: MainAxisSize.min, // FIXED: Added this
                            children: [
                              const Icon(
                                Icons.schedule,
                                size: 14,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Flexible( // FIXED: Wrapped with Flexible
                                child: Text(
                                  DateFormat('MMM dd, yyyy • hh:mm a').format(appointment.dateTime),
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          // Pet Info
                          Text(
                            'Pet: ${controller.getPetName(appointment.petId)}',
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          // Breed
                          Text(
                            'Breed: ${controller.getPetBreed(appointment.petId)}',
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          // Service
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 81, 115, 153).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              appointment.service,
                              style: const TextStyle(
                                color: Color.fromARGB(255, 81, 115, 153),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12), // FIXED: Added spacing
                    // Action Buttons or Status Badge
                    if (showActions && appointment.status == 'pending')
                      _buildActionButtons(context, controller)
                    else
                      _buildStatusBadge(appointment.status),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, ClinicAppointmentController controller) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Accept Button
        Container(
          width: 40,
          height: 40,
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [Colors.green, Colors.green.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.3),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            onPressed: () => _showConfirmDialog(
              context,
              'Accept Appointment',
              'Are you sure you want to accept this appointment?',
              () => controller.acceptAppointment(appointment),
            ),
            icon: const Icon(Icons.check, color: Colors.white, size: 20),
          ),
        ),
        // Decline Button
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [Colors.red, Colors.red.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.3),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            onPressed: () => _showConfirmDialog(
              context,
              'Decline Appointment',
              'Are you sure you want to decline this appointment?',
              () => controller.declineAppointment(appointment),
            ),
            icon: const Icon(Icons.close, color: Colors.white, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(status),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return Colors.green;
      case 'declined':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  void _showConfirmDialog(
    BuildContext context,
    String title,
    String content,
    VoidCallback onConfirm,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 81, 115, 153),
            ),
          ),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onConfirm();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 81, 115, 153),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Confirm',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}