import 'package:capstone_app/web/user_web/mobile_web/appointment_tabs/web_mobile_appointments_1st_tab.dart';
import 'package:capstone_app/web/user_web/mobile_web/appointment_tabs/web_mobile_appointments_2nd_tab.dart';
import 'package:capstone_app/web/user_web/mobile_web/appointment_tabs/web_mobile_appointments_3rd_tab.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:capstone_app/mobile/user/components/appointment_tabs/components/appointment_controller.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/utils/user_session_service.dart';

class WebMobileAppointmentsPage extends StatefulWidget {
  const WebMobileAppointmentsPage({super.key});

  @override
  State<WebMobileAppointmentsPage> createState() => _WebMobileAppointmentsPageState();
}

class _WebMobileAppointmentsPageState extends State<WebMobileAppointmentsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Initialize or get existing controller
    if (!Get.isRegistered<EnhancedUserAppointmentController>()) {
      Get.put(EnhancedUserAppointmentController(
        authRepository: Get.find<AuthRepository>(),
        session: Get.find<UserSessionService>(),
      ));
    } else {
      Get.find<EnhancedUserAppointmentController>().fetchAppointments();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<EnhancedUserAppointmentController>();
    
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 81, 115, 153),
      body: Column(
        children: [
          // Enhanced Header with stats
          Container(
            padding: const EdgeInsets.only(top: 50, bottom: 20, left: 20, right: 20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "My Appointments",
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 28,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Obx(() {
                          final stats = controller.userStats;
                          return Text(
                            "${stats['total']} total • ${stats['today']} today",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          );
                        }),
                      ],
                    ),
                    // Quick stats
                    Obx(() {
                      final stats = controller.userStats;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            Text(
                              "${stats['pending']}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                            Text(
                              "Pending",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
          
          Expanded(
            child: Container(
              width: double.maxFinite,
              height: double.maxFinite,
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 230, 230, 230),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(25),
                  topRight: Radius.circular(25),
                ),
              ),
              child: Column(
                children: [
                  // Enhanced Tab Bar
                  Container(
                    margin: const EdgeInsets.only(top: 20, left: 16, right: 16),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: TabBar(
                      controller: _tabController,
                      dividerColor: Colors.transparent,
                      labelColor: Colors.white,
                      unselectedLabelColor: const Color.fromARGB(255, 81, 115, 153),
                      indicatorColor: Colors.transparent,
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicator: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color.fromARGB(255, 81, 115, 153),
                            Colors.blue.shade400,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      tabs: [
                        Obx(() => _buildTab(
                          Icons.pending_rounded,
                          "Pending",
                          controller.userStats['pending'] ?? 0,
                          Colors.orange,
                        )),
                        Obx(() => _buildTab(
                          Icons.check_rounded,
                          "Active",
                          controller.userStats['upcoming'] ?? 0,
                          Colors.green,
                        )),
                        Obx(() => _buildTab(
                          Icons.cancel_rounded,
                          "Issues",
                          controller.declined.length,
                          Colors.red,
                        )),
                      ],
                    ),
                  ),
                  
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: const [
                        WebMobilePendingTab(),
                        WebMobileActiveTab(),
                        WebMobileIssuesTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(IconData icon, String text, int count, Color countColor) {
    return Tab(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: IntrinsicWidth(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16),
              const SizedBox(width: 4),
              Flexible(child: Text(text, style: const TextStyle(fontSize: 12))),
              if (count > 0) ...[
                const SizedBox(width: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: countColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    count.toString(),
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

