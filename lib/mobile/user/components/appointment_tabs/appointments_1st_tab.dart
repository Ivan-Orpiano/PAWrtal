import 'package:capstone_app/mobile/user/components/appointment_tabs/components/appointment_controller.dart';
import 'package:capstone_app/mobile/user/components/appointment_tabs/components/appointment_tile.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class APFirstTab extends StatelessWidget {
  const APFirstTab({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AppointmentController>();

    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Color.fromARGB(255, 81, 115, 153),
              ),
              SizedBox(height: 16),
              Text(
                'Loading appointments...',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        );
      }

      final appointments = controller.pending;

      if (appointments.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.pending_actions,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                "No pending appointments",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Your pending appointments will appear here",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: controller.fetchAppointments,
        color: const Color.fromARGB(255, 81, 115, 153),
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(top: 8, bottom: 16),
          itemCount: appointments.length,
          itemBuilder: (context, index) {
            final appointment = appointments[index];
            // TODO: You'll need to fetch clinic and pet data based on IDs
            return AppointmentTile(
              appointment: appointment,
              // clinic: null, // Fetch clinic data using appointment.clinicId
              // petName: null, // Fetch pet name using appointment.petId
            );
          },
        ),
      );
    });
  }
}