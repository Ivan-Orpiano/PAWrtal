import 'package:capstone_app/web/user_web/desktop_web/user_web/components/appbar_components/web_notification_icon.dart';
import 'package:capstone_app/web/user_web/desktop_web/user_web/components/appbar_components/web_profile_icon.dart';
import 'package:capstone_app/web/user_web/desktop_web/user_web/pages/web_appointments_page.dart';
import 'package:capstone_app/web/user_web/desktop_web/user_web/pages/web_dashboard_page.dart';
import 'package:capstone_app/web/user_web/desktop_web/user_web/pages/web_messages_page.dart';
import 'package:capstone_app/web/user_web/desktop_web/user_web/pages/web_pets_page.dart';
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
    WebAppointmentsPage(),
    WebMessagesPage(),
    WebPetsPage(),
  ];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
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
          padding: const EdgeInsets.only(left:75),
          child: InkWell(
            onTap: () {
              setState(() {
              widget.onItemSelected;
              });
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
            padding: EdgeInsets.only(right: 60),
            child: Row(
              children: [
                WebNotificationIcon(),
                WebProfileIcon(),
              ],
            ),
          )
        ],
      ),
      body: _pages[widget.selectedIndex],
    );
  }
  Widget _navButton (String label, int index) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => widget.onItemSelected(index),
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 18,
            color: widget.selectedIndex == index ? Colors.black : Colors.grey
          ),
        ),
      ),
    );
  }
}   