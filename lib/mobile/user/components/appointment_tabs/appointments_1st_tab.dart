import 'package:capstone_app/mobile/user/components/appointment_tabs/components/appointment_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class APFirstTab extends StatelessWidget {
  const APFirstTab({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AppointmentController>();

    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final appointments = controller.pending;

      if (appointments.isEmpty) {
        return const Center(child: Text("No pending appointments."));
      }

      return ListView.builder(
        itemCount: appointments.length,
        itemBuilder: (context, index) {
          final appt = appointments[index];
          return ListTile(
            title: Text(appt.service),
            subtitle: Text("Status: ${appt.status}"),
          );
        },
      );
    });
  }
}
