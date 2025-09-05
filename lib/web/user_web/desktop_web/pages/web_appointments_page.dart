import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class WebAppointmentsPage extends StatefulWidget {
  const WebAppointmentsPage({super.key});

  @override
  State<WebAppointmentsPage> createState() => _AppointmentsWebPageState();
}

class _AppointmentsWebPageState extends State<WebAppointmentsPage> {
  int selectedTabIndex = 0; // 0: Pending, 1: Accepted, 2: Declined
  final double tabletWidth = 1100;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isTablet = constraints.maxWidth < tabletWidth;
        
        return Scaffold(
          backgroundColor: const Color(0xFFEEEEEE),
          body: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 20 : 65,
              vertical: 16
            ),
            child: Column(
              children: [
                _buildAppointmentBar(),
                const SizedBox(height: 16),
                if (isTablet) _buildTabletView() else _buildDesktopView(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktopView() {
    return const Expanded(
      child: Row(
        children: [
          AppointmentPending(),
          SizedBox(width: 16),
          AppointmentAccepted(),
          SizedBox(width: 16),
          AppointmentDeclined()
        ],
      ),
    );
  }

  Widget _buildTabletView() {
    return Expanded(
      child: Column(
        children: [
          _buildTabSelector(),
          const SizedBox(height: 16),
          Expanded(
            child: _buildSelectedTab(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSelector() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildTabButton(0, Icons.pending_rounded, "Pending", Colors.grey),
          _buildTabButton(1, Icons.check_rounded, "Accepted", Colors.green),
          _buildTabButton(2, Icons.cancel_rounded, "Declined", Colors.red),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, IconData icon, String text, Color color) {
    bool isSelected = selectedTabIndex == index;
    
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedTabIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isSelected ? Border.all(color: color, width: 2) : null,
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: isSelected ? Colors.black : Colors.grey.shade600,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  text,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.black : Colors.grey.shade700,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedTab() {
    switch (selectedTabIndex) {
      case 0:
        return const AppointmentPending();
      case 1:
        return const AppointmentAccepted();
      case 2:
        return const AppointmentDeclined();
      default:
        return const AppointmentPending();
    }
  }

  Widget _buildAppointmentBar() {
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('MMM dd, yyyy').format(now);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          bool isCompact = constraints.maxWidth < 600;
          
          if (isCompact) {
            return Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfoCard(Icons.calendar_today, "Today", formattedDate),
                    _buildInfoCard(Icons.event_note, "Appointments", "3"),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatusChip("Pending", "1", Colors.grey),
                    _buildStatusChip("Accepted", "1", Colors.green),
                    _buildStatusChip("Declined", "1", Colors.red),
                  ],
                ),
              ],
            );
          }
          
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoCard(Icons.calendar_today, "Today", formattedDate),
              _buildInfoCard(Icons.event_note, "Total Appointments", "3"),
              Row(
                children: [
                  _buildStatusChip("Pending", "1", Colors.grey),
                  const SizedBox(width: 12),
                  _buildStatusChip("Accepted", "1", Colors.green),
                  const SizedBox(width: 12),
                  _buildStatusChip("Declined", "1", Colors.red),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.blue, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusChip(String label, String count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            "$label: $count",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class AppointmentPending extends StatefulWidget {
  const AppointmentPending({super.key});

  @override
  State<AppointmentPending> createState() => _AppointmentPendingState();
}

class _AppointmentPendingState extends State<AppointmentPending> {
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              AppointmentTabTitle(
                icon: Icons.pending_actions_rounded,
                text: "Pending",
                color: Colors.grey.shade100,
                iconColor: Colors.black,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: const [
                    AppointmentTile(
                      color: Color.fromARGB(255, 224, 224, 224),
                      icon: Icons.pending_actions_rounded,
                      text: "PENDING",
                      statusColor: Colors.black,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AppointmentAccepted extends StatefulWidget {
  const AppointmentAccepted({super.key});

  @override
  State<AppointmentAccepted> createState() => _AppointmentAcceptedState();
}

class _AppointmentAcceptedState extends State<AppointmentAccepted> {
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              AppointmentTabTitle(
                icon: Icons.check_circle_rounded,
                text: "Accepted",
                color: Colors.green.shade100,
                iconColor: Colors.black,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children:  [
                    AppointmentTile(
                      color: Color(0xFFC8E6C9),
                      icon: Icons.check_circle_outline,
                      text: "ACCEPTED",
                      statusColor: Colors.black,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AppointmentDeclined extends StatefulWidget {
  const AppointmentDeclined({super.key});

  @override
  State<AppointmentDeclined> createState() => _AppointmentDeclinedState();
}

class _AppointmentDeclinedState extends State<AppointmentDeclined> {
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              AppointmentTabTitle(
                icon: Icons.cancel_rounded,
                text: "Declined",
                color: Colors.red.shade100,
                iconColor: Colors.black,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: const [
                    AppointmentTile(
                      color: Color(0xFFFFCDD2),
                      icon: Icons.cancel_outlined,
                      text: "DECLINED",
                      statusColor: Colors.black,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AppointmentTabTitle extends StatelessWidget {
  final Color color;
  final Color iconColor;
  final IconData icon;
  final String text;

  const AppointmentTabTitle({
    super.key,
    required this.color,
    required this.iconColor,
    required this.icon,
    required this.text
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: iconColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: iconColor
            ),
          ),
        ],
      ),
    );
  }
}

class AppointmentTile extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;
  final Color statusColor;

  const AppointmentTile({
    super.key,
    required this.text,
    required this.icon,
    required this.color,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => _buildAppointmentDialog(context)
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, size: 16, color: statusColor),
                          const SizedBox(width: 6),
                          Text(
                            text,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.keyboard_arrow_right_rounded,
                      color: Colors.grey.shade400,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey.shade200,
                        child: const Icon(
                          Icons.local_hospital,
                          size: 40,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Sunny Paws Veterinary Clinic",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.medical_services_outlined,
                                size: 16,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "Annual Vaccination",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.pets_rounded,
                                size: 16,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "Max (Golden Retriever)",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withOpacity(0.1)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        color: Colors.blue.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "December 15, 2024",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.blue.shade700,
                            ),
                          ),
                          Text(
                            "10:00 AM - 11:00 AM",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget _buildAppointmentDialog(BuildContext context) {
  return Dialog(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    ),
    child: Container(
      width: 550,
      height: 700,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                const Text(
                  'Appointment Details',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Add your appointment details content here
                  Center(
                    child: Text(
                      'Detailed appointment information will go here',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}