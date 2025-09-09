import 'package:capstone_app/mobile/user/components/appointment_tabs/components/appointment_controller.dart';
import 'package:capstone_app/mobile/user/components/appointment_tabs/components/appointment_tile.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EnhancedAPThirdTab extends StatelessWidget {
  const EnhancedAPThirdTab({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<EnhancedUserAppointmentController>();

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

      final appointments = controller.declined;

      if (appointments.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.sentiment_satisfied,
                  size: 64,
                  color: Colors.green[600],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "Great! No Cancelled Here",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Declined or missed appointments will appear here",
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

      return RefreshIndicator(
        onRefresh: controller.fetchAppointments,
        color: const Color.fromARGB(255, 81, 115, 153),
        child: Column(
          children: [
            // Header
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red, Colors.red.shade300],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.cancel_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Declined & Missed',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '${appointments.length} appointment${appointments.length != 1 ? 's' : ''} were not completed',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 16),
                itemCount: appointments.length,
                itemBuilder: (context, index) {
                  final appointment = appointments[index];
                  return EnhancedUserAppointmentTile(appointment: appointment);
                },
              ),
            ),
          ],
        ),
      );
    });
  }
}