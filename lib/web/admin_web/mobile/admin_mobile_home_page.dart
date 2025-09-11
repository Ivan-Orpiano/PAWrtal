import 'package:capstone_app/web/admin_web/pages/admin_web_appointments.dart';
import 'package:capstone_app/web/admin_web/pages/admin_web_clinicpage.dart';
import 'package:capstone_app/web/admin_web/pages/admin_web_dashboard.dart';
import 'package:capstone_app/web/admin_web/pages/admin_web_messages.dart';
import 'package:capstone_app/web/admin_web/pages/admin_web_staffs.dart';
import 'package:flutter/material.dart';

class AdminMobileHomePage extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final bool canAccessStaffs;

  const AdminMobileHomePage({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.canAccessStaffs,
  });

  @override
  State<AdminMobileHomePage> createState() => _AdminMobileHomePageState();
}

class _AdminMobileHomePageState extends State<AdminMobileHomePage> {
  List<Widget> get _pages {
    List<Widget> basePages = const [
      AdminWebDashboard(),
      AdminWebClinicpage(),
      AdminWebAppointments(),
      AdminWebMessages(),
      AdminWebStaffs(),
    ];

    // if (widget.canAccessStaffs) {
    //   basePages.add(const AdminWebStaffs());
    // }

    return basePages;
  }

  List<IconData> get _navigationIcons {
    List<IconData> baseIcons = [
      Icons.dashboard,
      Icons.local_hospital,
      Icons.calendar_today,
      Icons.message,
    ];

    if (widget.canAccessStaffs) {
      baseIcons.add(Icons.people);
    }

    return baseIcons;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: Colors.grey[400],
            height: 1,
          ),
        ),
        title: InkWell(
          onTap: () => widget.onItemSelected(0),
          child: Image.asset(
            'lib/images/PAWrtal_logo.png',
            height: 35,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              // TODO: Implement notifications
            },
            icon: const Icon(Icons.notifications),
          ),
          IconButton(
            onPressed: () {
              // TODO: Show profile menu
            },
            icon: const Icon(Icons.account_circle),
          ),
        ],
      ),
      body: _pages[widget.selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: widget.selectedIndex,
          onTap: widget.onItemSelected,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color.fromARGB(255, 81, 115, 153),
          unselectedItemColor: Colors.grey,
          backgroundColor: Colors.white,
          elevation: 0,
          items: _navigationIcons.asMap().entries.map((entry) {
            int index = entry.key;
            IconData icon = entry.value;
            return BottomNavigationBarItem(
              icon: Icon(icon),
              label: _getLabelForIndex(index),
            );
          }).toList(),
        ),
      ),
    );
  }

  String _getLabelForIndex(int index) {
    switch (index) {
      case 0:
        return "Dashboard";
      case 1:
        return "Clinic";
      case 2:
        return "Appointments";
      case 3:
        return "Messages";
      case 4:
        return "Staffs";
      default:
        return "Unknown";
    }
  }
}
