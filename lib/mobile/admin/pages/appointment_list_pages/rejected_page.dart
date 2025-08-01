import 'package:capstone_app/mobile/admin/components/appointment_tabs/clinic_appointment_controller.dart';
import 'package:capstone_app/mobile/admin/components/appointment_tiles/clinic_appointment_tile.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RejectedPage extends StatelessWidget {
  const RejectedPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ClinicAppointmentController>();

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 230, 230, 230),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: CircularProgressIndicator());
        }

        final declinedAppointments = controller.declined;

        if (declinedAppointments.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () => controller.refreshAppointments(),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: declinedAppointments.length,
            itemBuilder: (context, index) {
              final appointment = declinedAppointments[index];
              return ClinicAppointmentTile(
                appointment: appointment,
                showActions: false, // No actions needed, just show status
              );
            },
          ),
        );
      }),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cancel_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Declined Appointments',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Declined appointments will appear here.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}