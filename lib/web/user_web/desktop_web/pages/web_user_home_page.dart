import 'package:capstone_app/notifications/components/user_notification_panel.dart';
import 'package:capstone_app/web/user_web/desktop_web/components/appbar_components/user_web_notification_icon.dart';
import 'package:capstone_app/web/user_web/desktop_web/components/appbar_components/user_web_profile_icon.dart';
import 'package:capstone_app/web/user_web/desktop_web/pages/web_appointments_page.dart';
import 'package:capstone_app/web/user_web/desktop_web/pages/web_dashboard_page.dart';
import 'package:capstone_app/web/user_web/desktop_web/pages/web_messages_page.dart';
import 'package:capstone_app/web/user_web/desktop_web/pages/web_pets_page.dart';
import 'package:flutter/material.dart';

class WebUserHomePage extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const WebUserHomePage({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected
  });

  @override
  State<WebUserHomePage> createState() => _WebUserHomePageState();
}

class _WebUserHomePageState extends State<WebUserHomePage> {

  final List<Widget> _pages = const [
    WebDashboardPage(),
    EnhancedWebAppointmentsPage(),
    WebMessagesPage(),
    WebPetsPage(),
  ];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        leadingWidth: 220,
        toolbarHeight: 80,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: Colors.grey.shade400,
            height: 1,
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 75),
          child: InkWell(
            onTap: () {
              // Fixed: Call onItemSelected(0) to go to home
              widget.onItemSelected(0);
            },
            child: Image.asset(
              'lib/images/PAWrtal_logo.png',
            ),
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _navButton("Home", 0),
            _navButton("Appointments", 1),
            _navButton("Messages", 2),
            _navButton("Pets", 3),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 65),
            child: Row(
              children: [
                UserNotificationButton(),
                WebProfileIcon(),
              ],
            ),
          )
        ],
      ),
      body: _pages[widget.selectedIndex],
    );
  }

  Widget _navButton(String label, int index) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => widget.onItemSelected(index),
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 18,
            color: widget.selectedIndex == index ? Colors.black : Colors.grey,
          ),
        ),
      ),
    );
  }
}