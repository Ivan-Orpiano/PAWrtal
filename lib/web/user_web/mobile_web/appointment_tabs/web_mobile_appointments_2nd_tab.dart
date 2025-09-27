import 'package:capstone_app/mobile/user/components/appointment_tabs/components/appointment_controller.dart';
import 'package:capstone_app/web/user_web/mobile_web/components/web_mobile_appointment_tile.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WebMobileActiveTab extends StatelessWidget {
  const WebMobileActiveTab({super.key});

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

      final appointments = controller.accepted;
      final todayAppointments = controller.todayAppointments.where((a) => 
        a.status == 'accepted' || a.status == 'in_progress').toList();

      if (appointments.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
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
                    Icons.check_circle_outline,
                    size: 64,
                    color: Colors.green[600],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  "No Active Appointments",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Confirmed and ongoing appointments will appear here",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }

      // Group appointments by status for better organization
      final groupedAppointments = <Map<String, dynamic>>[
        {'title': 'Today\'s Appointments', 'appointments': todayAppointments, 'color': Colors.blue},
        {'title': 'Confirmed Appointments', 'appointments': controller.upcoming, 'color': Colors.green},
        {'title': 'In Treatment', 'appointments': controller.inProgress, 'color': Colors.purple},
        {'title': 'Recently Completed', 'appointments': controller.completed, 'color': Colors.teal},
      ];

      return RefreshIndicator(
        onRefresh: controller.fetchAppointments,
        color: const Color.fromARGB(255, 81, 115, 153),
        child: CustomScrollView(
          slivers: [
            // Stats header
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color.fromARGB(255, 81, 115, 153), Colors.blue.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.event_available,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Active Appointments',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '${appointments.length} appointment${appointments.length != 1 ? 's' : ''} • ${todayAppointments.length} today',
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
            ),
            
            // Grouped appointments
            ...groupedAppointments.map((group) {
              final appointments = group['appointments'] as List;
              if (appointments.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
              
              return SliverList(
                delegate: SliverChildListDelegate([
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Icon(
                          _getGroupIcon(group['title'] as String),
                          color: group['color'] as Color,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${group['title']} (${appointments.length})',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: group['color'],
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...appointments.map((appointment) => WebMobileAppointmentTile(appointment: appointment)).toList(),
                  const SizedBox(height: 8),
                ]),
              );
            }).toList(),
            
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
          ],
        ),
      );
    });
  }

  IconData _getGroupIcon(String title) {
    switch (title) {
      case 'Today\'s Appointments':
        return Icons.today;
      case 'Confirmed Appointments':
        return Icons.event_available;
      case 'In Treatment':
        return Icons.medical_services;
      case 'Recently Completed':
        return Icons.check_circle;
      default:
        return Icons.event;
    }
  }
}