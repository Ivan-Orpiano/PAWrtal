import 'package:capstone_app/web/admin_web/components/appointments/web_appointment_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class WebAppointmentStats extends StatelessWidget {
  const WebAppointmentStats({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<WebAppointmentController>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final isTablet = screenWidth < 1200 && screenWidth >= 768;

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with date and revenue
          _buildHeader(controller),
          const SizedBox(height: 20),
          
          // Stats cards
          if (isMobile)
            _buildMobileStatsGrid(controller)
          else if (isTablet)
            _buildTabletStatsGrid(controller)
          else
            _buildDesktopStatsGrid(controller),
        ],
      ),
    );
  }

  Widget _buildHeader(WebAppointmentController controller) {
    return Obx(() => Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color.fromARGB(255, 81, 115, 153),
            Colors.blue.shade400,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEEE, MMMM dd, yyyy').format(DateTime.now()),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Today's Overview",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${controller.appointmentStats['today']} appointments today",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.attach_money,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(height: 8),
                Text(
                  '₱${controller.todayRevenue.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Today's Revenue",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ));
  }

  Widget _buildMobileStatsGrid(WebAppointmentController controller) {
    return Obx(() {
      final stats = controller.appointmentStats;
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildStatCard('Total', stats['total']!, Icons.calendar_today, Colors.blue)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('Pending', stats['pending']!, Icons.pending, Colors.orange)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildStatCard('Scheduled', stats['scheduled']!, Icons.schedule, Colors.green)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('In Progress', stats['in_progress']!, Icons.medical_services, Colors.purple)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildStatCard('Completed', stats['completed']!, Icons.check_circle, Colors.teal)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('Declined', stats['declined']!, Icons.cancel, Colors.red)),
            ],
          ),
        ],
      );
    });
  }

  Widget _buildTabletStatsGrid(WebAppointmentController controller) {
    return Obx(() {
      final stats = controller.appointmentStats;
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildStatCard('Total', stats['total']!, Icons.calendar_today, Colors.blue)),
              const SizedBox(width: 16),
              Expanded(child: _buildStatCard('Pending', stats['pending']!, Icons.pending, Colors.orange)),
              const SizedBox(width: 16),
              Expanded(child: _buildStatCard('Scheduled', stats['scheduled']!, Icons.schedule, Colors.green)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildStatCard('In Progress', stats['in_progress']!, Icons.medical_services, Colors.purple)),
              const SizedBox(width: 16),
              Expanded(child: _buildStatCard('Completed', stats['completed']!, Icons.check_circle, Colors.teal)),
              const SizedBox(width: 16),
              Expanded(child: _buildStatCard('Declined', stats['declined']!, Icons.cancel, Colors.red)),
            ],
          ),
        ],
      );
    });
  }

  Widget _buildDesktopStatsGrid(WebAppointmentController controller) {
    return Obx(() {
      final stats = controller.appointmentStats;
      return Row(
        children: [
          Expanded(child: _buildStatCard('Total Appointments', stats['total']!, Icons.calendar_today, Colors.blue, isDesktop: true)),
          const SizedBox(width: 20),
          Expanded(child: _buildStatCard('Pending Review', stats['pending']!, Icons.pending, Colors.orange, isDesktop: true)),
          const SizedBox(width: 20),
          Expanded(child: _buildStatCard('Scheduled', stats['scheduled']!, Icons.schedule, Colors.green, isDesktop: true)),
          const SizedBox(width: 20),
          Expanded(child: _buildStatCard('In Progress', stats['in_progress']!, Icons.medical_services, Colors.purple, isDesktop: true)),
          const SizedBox(width: 20),
          Expanded(child: _buildStatCard('Completed', stats['completed']!, Icons.check_circle, Colors.teal, isDesktop: true)),
          const SizedBox(width: 20),
          Expanded(child: _buildStatCard('Declined', stats['declined']!, Icons.cancel, Colors.red, isDesktop: true)),
        ],
      );
    });
  }

  Widget _buildStatCard(String title, int value, IconData icon, Color color, {bool isDesktop = false}) {
    final controller = Get.find<WebAppointmentController>();
    return Container(
      padding: EdgeInsets.all(isDesktop ? 20 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: isDesktop ? 24 : 20,
                ),
              ),
              if (value > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Active',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: isDesktop ? 16 : 12),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: isDesktop ? 32 : 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: isDesktop ? 14 : 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          if (isDesktop && value > 0) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: value / (controller.appointmentStats['total']! > 0 ? controller.appointmentStats['total']! : 1),
              backgroundColor: color.withOpacity(0.2),
              color: color,
              minHeight: 3,
            ),
          ],
        ],
      ),
    );
  }
}

class WebAppointmentQuickActions extends StatelessWidget {
  const WebAppointmentQuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 81, 115, 153),
            ),
          ),
          const SizedBox(height: 12),
          if (isMobile)
            _buildMobileQuickActions()
          else
            _buildDesktopQuickActions(),
        ],
      ),
    );
  }

  Widget _buildMobileQuickActions() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildQuickActionCard('Emergency\nCheck-in', Icons.emergency, Colors.red, () => _showEmergencyDialog())),
            const SizedBox(width: 12),
            Expanded(child: _buildQuickActionCard('Walk-in\nPatient', Icons.person_add, Colors.blue, () => _showWalkInDialog())),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildQuickActionCard('Schedule\nFollow-up', Icons.event_repeat, Colors.purple, () => _showFollowUpDialog())),
            const SizedBox(width: 12),
            Expanded(child: _buildQuickActionCard('Medical\nRecords', Icons.medical_information, Colors.teal, () => _showMedicalRecordsDialog())),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopQuickActions() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildQuickActionCard('Emergency Check-in', Icons.emergency, Colors.red, () => _showEmergencyDialog()),
          const SizedBox(width: 12),
          _buildQuickActionCard('Add Walk-in Patient', Icons.person_add, Colors.blue, () => _showWalkInDialog()),
          const SizedBox(width: 12),
          _buildQuickActionCard('Schedule Follow-up', Icons.event_repeat, Colors.purple, () => _showFollowUpDialog()),
          const SizedBox(width: 12),
          _buildQuickActionCard('View Medical Records', Icons.medical_information, Colors.teal, () => _showMedicalRecordsDialog()),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 140,
        height: 100,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Quick action methods
  void _showEmergencyDialog() {
    Get.snackbar(
      'Emergency Check-in',
      'Emergency check-in feature will be implemented',
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }

  void _showWalkInDialog() {
    Get.snackbar(
      'Walk-in Patient',
      'Walk-in patient registration feature will be implemented',
      backgroundColor: Colors.blue,
      colorText: Colors.white,
    );
  }

  void _showFollowUpDialog() {
    Get.snackbar(
      'Schedule Follow-up',
      'Follow-up scheduling feature will be implemented',
      backgroundColor: Colors.purple,
      colorText: Colors.white,
    );
  }

  void _showMedicalRecordsDialog() {
    Get.snackbar(
      'Medical Records',
      'Medical records viewer will be implemented',
      backgroundColor: Colors.teal,
      colorText: Colors.white,
    );
  }
}