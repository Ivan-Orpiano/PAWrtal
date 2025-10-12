import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/mobile/user/components/appointment_tabs/appointments_1st_tab.dart';
import 'package:capstone_app/mobile/user/components/appointment_tabs/appointments_2nd_tab.dart';
import 'package:capstone_app/mobile/user/components/appointment_tabs/appointments_3rd_tab.dart';
import 'package:capstone_app/mobile/user/components/appointment_tabs/appointments_4th_tab.dart';
import 'package:capstone_app/mobile/user/components/appointment_tabs/components/appointment_controller.dart';
import 'package:capstone_app/utils/user_session_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class EnhancedAppointmentPage extends StatefulWidget {
  const EnhancedAppointmentPage({super.key});

  @override
  State<EnhancedAppointmentPage> createState() => _EnhancedAppointmentPageState();
}

class _EnhancedAppointmentPageState extends State<EnhancedAppointmentPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 0;

  final List<TabData> _tabs = [
    TabData(
      icon: Icons.event_available_rounded,
      text: "Upcoming",
      color: Colors.blue,
    ),
    TabData(
      icon: Icons.pending_rounded,
      text: "Pending",
      color: Colors.orange,
    ),
    TabData(
      icon: Icons.check_circle_rounded,
      text: "Completed",
      color: Colors.green,
    ),
    TabData(
      icon: Icons.history_rounded,
      text: "History",
      color: Colors.grey,
    ),
  ];

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedIndex = _tabController.index;
        });
      }
    });

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
                              "${stats['upcoming']}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                            Text(
                              "Upcoming",
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
                  // Custom Dynamic Tab Bar
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
                    child: Obx(() {
                      final stats = controller.userStats;
                      return Row(
                        children: List.generate(4, (index) {
                          final isSelected = _selectedIndex == index;
                          final tab = _tabs[index];
                          int count = 0;
                          
                          switch (index) {
                            case 0:
                              count = stats['upcoming'] ?? 0;
                              break;
                            case 1:
                              count = stats['pending'] ?? 0;
                              break;
                            case 2:
                              count = stats['completed'] ?? 0;
                              break;
                            case 3:
                              count = stats['history'] ?? 0;
                              break;
                          }

                          return Expanded(
                            flex: isSelected ? 3 : 1,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              child: InkWell(
                                onTap: () {
                                  _tabController.animateTo(index);
                                  setState(() {
                                    _selectedIndex = index;
                                  });
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: isSelected
                                        ? LinearGradient(
                                            colors: [
                                              const Color.fromARGB(255, 81, 115, 153),
                                              Colors.blue.shade400,
                                            ],
                                          )
                                        : null,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: isSelected
                                      ? Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              tab.icon,
                                              size: 18,
                                              color: Colors.white,
                                            ),
                                            const SizedBox(width: 6),
                                            Flexible(
                                              child: Text(
                                                tab.text,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.white,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (count > 0) ...[
                                              const SizedBox(width: 4),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 6,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  count.toString(),
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: tab.color,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        )
                                      : Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            Icon(
                                              tab.icon,
                                              size: 20,
                                              color: const Color.fromARGB(255, 81, 115, 153)
                                                  .withOpacity(0.6),
                                            ),
                                            if (count > 0)
                                              Positioned(
                                                right: 0,
                                                top: 0,
                                                child: Container(
                                                  padding: const EdgeInsets.all(4),
                                                  decoration: BoxDecoration(
                                                    color: tab.color,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  constraints: const BoxConstraints(
                                                    minWidth: 16,
                                                    minHeight: 16,
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      count > 9 ? '9+' : count.toString(),
                                                      style: const TextStyle(
                                                        fontSize: 8,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                          );
                        }),
                      );
                    }),
                  ),
                  
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: const [
                        EnhancedAPFirstTab(),  // Upcoming
                        EnhancedAPSecondTab(), // Pending
                        EnhancedAPThirdTab(),  // Completed
                        EnhancedAPFourthTab(), // History
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
}

class TabData {
  final IconData icon;
  final String text;
  final Color color;

  TabData({
    required this.icon,
    required this.text,
    required this.color,
  });
}