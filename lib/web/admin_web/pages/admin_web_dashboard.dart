import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/utils/user_session_service.dart';
import 'package:capstone_app/data/models/appointment_model.dart';
import 'package:capstone_app/web/admin_web/components/dashboard/admin_dashboard_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class AdminWebDashboard extends StatefulWidget {
  const AdminWebDashboard({super.key});

  @override
  State<AdminWebDashboard> createState() => _AdminWebDashboardState();
}

class _AdminWebDashboardState extends State<AdminWebDashboard> {
  @override
  void initState() {
    super.initState();
    
    // Initialize controller if not already registered
    if (!Get.isRegistered<AdminDashboardController>()) {
      Get.put(AdminDashboardController(
        authRepository: Get.find<AuthRepository>(),
        session: Get.find<UserSessionService>(),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AdminDashboardController>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final isTablet = screenWidth < 1200 && screenWidth >= 768;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: () => controller.refreshDashboard(),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                _buildHeader(controller, isMobile),
                const SizedBox(height: 24),
                
                // Quick Stats Cards
                _buildQuickStats(controller, isMobile, isTablet),
                const SizedBox(height: 32),
                
                // Main Content Grid
                if (isMobile)
                  _buildMobileLayout(controller)
                else if (isTablet)
                  _buildTabletLayout(controller)
                else
                  _buildDesktopLayout(controller),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildHeader(AdminDashboardController controller, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color.fromARGB(255, 81, 115, 153),
            Colors.blue.shade400,
          ],
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.dashboard, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      controller.clinicData.value?.clinicName ?? 'Veterinary Dashboard',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isMobile ? 20 : 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      DateFormat('EEEE, MMMM dd, yyyy').format(DateTime.now()),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: isMobile ? 14 : 16,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isMobile) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.attach_money, color: Colors.white, size: 24),
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
                      const SizedBox(height: 8),
                      // Real-time status indicator
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: controller.isRealTimeConnected.value 
                                  ? Colors.green 
                                  : Colors.orange,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            controller.connectionStatus,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          if (isMobile) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.attach_money, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    "Today's Revenue: ₱${controller.todayRevenue.toStringAsFixed(0)}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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

  Widget _buildQuickStats(AdminDashboardController controller, bool isMobile, bool isTablet) {
    final stats = [
      {
        'title': 'Today\'s Appointments',
        'value': controller.todayAppointments.length.toString(),
        'subtitle': 'Scheduled today',
        'icon': Icons.event_available,
        'color': Colors.blue,
        'onTap': () => controller.navigateToAppointments('today'),
      },
      {
        'title': 'Pending Review',
        'value': controller.pendingCount.toString(),
        'subtitle': 'Need approval',
        'icon': Icons.pending_actions,
        'color': Colors.orange,
        'onTap': () => controller.navigateToAppointments('pending'),
      },
      {
        'title': 'This Month',
        'value': controller.monthlyStats['thisMonth']?.toString() ?? '0',
        'subtitle': 'Total appointments',
        'icon': Icons.calendar_month,
        'color': Colors.purple,
        'onTap': () => controller.navigateToAppointments(),
      },
      {
        'title': 'Completed',
        'value': controller.completedCount.toString(),
        'subtitle': 'Successfully treated',
        'icon': Icons.check_circle,
        'color': Colors.green,
        'onTap': () => controller.navigateToAppointments('completed'),
      },
    ];

    if (isMobile) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildStatCard(stats[0])),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard(stats[1])),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildStatCard(stats[2])),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard(stats[3])),
            ],
          ),
        ],
      );
    } else if (isTablet) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildStatCard(stats[0])),
              const SizedBox(width: 16),
              Expanded(child: _buildStatCard(stats[1])),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildStatCard(stats[2])),
              const SizedBox(width: 16),
              Expanded(child: _buildStatCard(stats[3])),
            ],
          ),
        ],
      );
    } else {
      return Row(
        children: stats.map((stat) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: _buildStatCard(stat),
            ),
          );
        }).toList(),
      );
    }
  }

  Widget _buildStatCard(Map<String, dynamic> stat) {
    return InkWell(
      onTap: stat['onTap'],
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: stat['color'].withOpacity(0.2)),
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
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: stat['color'].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(stat['icon'], color: stat['color'], size: 20),
                ),
                const Spacer(),
                Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              stat['value'],
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: stat['color'],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              stat['title'],
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            Text(
              stat['subtitle'],
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout(AdminDashboardController controller) {
    return Column(
      children: [
        _buildTodaySchedule(controller, true),
        const SizedBox(height: 24),
        _buildRecentMessages(controller, true),
        const SizedBox(height: 24),
        _buildUpcomingAppointments(controller, true),
      ],
    );
  }

  Widget _buildTabletLayout(AdminDashboardController controller) {
    return Column(
      children: [
        _buildTodaySchedule(controller, false),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildRecentMessages(controller, false)),
            const SizedBox(width: 24),
            Expanded(child: _buildUpcomingAppointments(controller, false)),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(AdminDashboardController controller) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  _buildTodaySchedule(controller, false),
                  const SizedBox(height: 24),
                  _buildUpcomingAppointments(controller, false),
                ],
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  _buildAppointmentCalendar(controller),
                  const SizedBox(height: 24),
                  _buildRecentMessages(controller, false),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTodaySchedule(AdminDashboardController controller, bool isMobile) {
    return _buildDashboardCard(
      title: 'Today\'s Schedule',
      subtitle: '${controller.todayAppointments.length} appointments',
      icon: Icons.today,
      child: controller.todayAppointments.isEmpty
          ? _buildEmptyState('No appointments scheduled for today', Icons.event_available)
          : Column(
              children: controller.todayAppointments.take(5).map((appointment) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildAppointmentItem(controller, appointment, isMobile),
                );
              }).toList(),
            ),
      actionLabel: 'View All',
      onAction: () => controller.navigateToAppointments('today'),
    );
  }

  Widget _buildAppointmentItem(AdminDashboardController controller, Appointment appointment, bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getStatusColor(appointment.status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _getStatusColor(appointment.status).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _getStatusColor(appointment.status),
              borderRadius: BorderRadius.circular(25),
            ),
            child: const Icon(Icons.pets, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.getPetName(appointment.petId),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  controller.getOwnerName(appointment.userId),
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                Text(
                  appointment.service,
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                DateFormat('hh:mm a').format(appointment.dateTime),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _getStatusColor(appointment.status),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _getStatusDisplayText(appointment.status),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (appointment.status == 'pending') ...[
                const SizedBox(height: 8),
                SizedBox(
                  height: 24,
                  child: ElevatedButton(
                    onPressed: () => controller.quickAcceptAppointment(appointment),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 24),
                    ),
                    child: const Text('Accept', 
                      style: TextStyle(fontSize: 10, color: Colors.white)),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentMessages(AdminDashboardController controller, bool isMobile) {
    return _buildDashboardCard(
      title: 'Recent Messages',
      subtitle: '${controller.recentMessages.length} unread',
      icon: Icons.message,
      child: controller.recentMessages.isEmpty
          ? _buildEmptyState('No recent messages', Icons.message)
          : Column(
              children: controller.recentMessages.take(3).map((message) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildMessageItem(message, isMobile),
                );
              }).toList(),
            ),
      actionLabel: 'View All',
      onAction: () => controller.navigateToMessages(),
    );
  }

  Widget _buildMessageItem(Map<String, dynamic> message, bool isMobile) {
    final isUnread = !message['isRead'];
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isUnread ? Colors.blue.withOpacity(0.1) : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isUnread ? Colors.blue.withOpacity(0.3) : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isUnread ? Colors.blue : Colors.grey,
            radius: 20,
            child: Text(
              message['senderName'][0].toUpperCase(),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        message['senderName'],
                        style: TextStyle(
                          fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Text(
                      DateFormat('hh:mm a').format(message['time']),
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  message['message'],
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 13,
                  ),
                ),
                if (message['petName'] != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Pet: ${message['petName']}',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isUnread)
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUpcomingAppointments(AdminDashboardController controller, bool isMobile) {
    return _buildDashboardCard(
      title: 'Upcoming Appointments',
      subtitle: 'Next ${controller.upcomingAppointments.length} scheduled',
      icon: Icons.schedule,
      child: controller.upcomingAppointments.isEmpty
          ? _buildEmptyState('No upcoming appointments', Icons.event_available)
          : Column(
              children: controller.upcomingAppointments.map((appointment) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildUpcomingAppointmentItem(controller, appointment, isMobile),
                );
              }).toList(),
            ),
      actionLabel: 'View All',
      onAction: () => controller.navigateToAppointments(),
    );
  }

  Widget _buildUpcomingAppointmentItem(AdminDashboardController controller, Appointment appointment, bool isMobile) {
    final daysDifference = appointment.dateTime.difference(DateTime.now()).inDays;
    final isToday = daysDifference == 0;
    final isTomorrow = daysDifference == 1;
    
    String dateLabel;
    if (isToday) {
      dateLabel = 'Today';
    } else if (isTomorrow) {
      dateLabel = 'Tomorrow';
    } else {
      dateLabel = DateFormat('MMM dd').format(appointment.dateTime);
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isToday ? Colors.orange : Colors.green,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  dateLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  DateFormat('hh:mm a').format(appointment.dateTime),
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.getPetName(appointment.petId),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  controller.getOwnerName(appointment.userId),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    appointment.service,
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCalendar(AdminDashboardController controller) {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    
    return _buildDashboardCard(
      title: 'Appointment Calendar',
      subtitle: 'Monthly overview',
      icon: Icons.calendar_month,
      child: TableCalendar<Appointment>(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: controller.selectedDate.value,
        calendarFormat: CalendarFormat.month,
        eventLoader: (day) {
          return controller.calendarAppointments[DateTime(day.year, day.month, day.day)] ?? [];
        },
        startingDayOfWeek: StartingDayOfWeek.monday,
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          weekendTextStyle: const TextStyle(color: Colors.red),
          holidayTextStyle: const TextStyle(color: Colors.red),
          // Style for disabled past days
          disabledTextStyle: TextStyle(
            color: Colors.grey.shade400,
            decoration: TextDecoration.lineThrough,
          ),
          // Style for today
          todayTextStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          todayDecoration: BoxDecoration(
            color: const Color.fromARGB(255, 81, 115, 153),
            shape: BoxShape.circle,
          ),
          // Style for selected day
          selectedTextStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          selectedDecoration: BoxDecoration(
            color: Colors.blue.shade600,
            shape: BoxShape.circle,
          ),
          // Style for days with events
          markerDecoration: BoxDecoration(
            color: Colors.green.shade400,
            shape: BoxShape.circle,
          ),
          markerMargin: const EdgeInsets.symmetric(horizontal: 1),
          markersMaxCount: 3,
        ),
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        enabledDayPredicate: (day) {
          // Disable past days (before today)
          final dayDate = DateTime(day.year, day.month, day.day);
          return !dayDate.isBefore(todayDate);
        },
        onDaySelected: (selectedDay, focusedDay) {
          // Only allow selection of today or future dates
          final selectedDate = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
          if (!selectedDate.isBefore(todayDate)) {
            controller.setSelectedDate(selectedDay);
          }
        },
        selectedDayPredicate: (day) {
          return isSameDay(controller.selectedDate.value, day);
        },
        // Custom builders for better control
        calendarBuilders: CalendarBuilders(
          disabledBuilder: (context, day, focusedDay) {
            return Container(
              margin: const EdgeInsets.all(4),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.shade200,
              ),
              child: Text(
                '${day.day}',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 14,
                ),
              ),
            );
          },
          markerBuilder: (context, day, events) {
            if (events.isNotEmpty) {
              final dayDate = DateTime(day.year, day.month, day.day);
              final isPastDay = dayDate.isBefore(todayDate);
              
              return Positioned(
                bottom: 1,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isPastDay ? Colors.grey.shade400 : Colors.green.shade400,
                  ),
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                ),
              );
            }
            return null;
          },
        ),
      ),
    );
  }

  Widget _buildDashboardCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
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
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 81, 115, 153).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: const Color.fromARGB(255, 81, 115, 153),
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
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (actionLabel != null && onAction != null)
                TextButton(
                  onPressed: onAction,
                  child: Text(actionLabel),
                ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            icon,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
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
      default:
        return Colors.grey;
    }
  }

  String _getStatusDisplayText(String status) {
    switch (status) {
      case 'pending':
        return 'PENDING';
      case 'accepted':
        return 'SCHEDULED';
      case 'in_progress':
        return 'IN PROGRESS';
      case 'completed':
        return 'COMPLETED';
      case 'declined':
        return 'DECLINED';
      default:
        return status.toUpperCase();
    }
  }
}