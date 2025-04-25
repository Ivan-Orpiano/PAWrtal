import 'package:capstone_app/web/user_web/components/appbar_components/web_notification_icon.dart';
import 'package:capstone_app/web/user_web/components/appbar_components/web_profile_icon.dart';
import 'package:capstone_app/web/user_web/pages/web_appointments_page.dart';
import 'package:capstone_app/web/user_web/pages/web_dashboard_page.dart';
import 'package:capstone_app/web/user_web/pages/web_messages_page.dart';
import 'package:capstone_app/web/user_web/pages/web_pets_page.dart';
import 'package:flutter/material.dart';

class WebUserHomePage extends StatefulWidget {
  const WebUserHomePage({super.key});

  @override
  State<WebUserHomePage> createState() => _WebUserHomePageState();
}

class _WebUserHomePageState extends State<WebUserHomePage> {

  int _selectedIndex = 0;

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
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        centerTitle: true,
        leadingWidth: 220,
        toolbarHeight: 80,
        elevation: 1,
        shadowColor: Colors.grey.shade400,
        leading: Padding(
          padding: const EdgeInsets.only(left: 75),
          child: InkWell(
            onTap: () {
              setState(() {
              _selectedIndex = 0;
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

            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                setState(() {
                  _selectedIndex = 0;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                child: Text(
                  "Home",
                  style: TextStyle(
                    fontSize: 18,
                    color: _selectedIndex == 0 ? Colors.black : Colors.grey
                  ),
                ),
              ),
            ),

            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                setState(() {
                  _selectedIndex = 1;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                child: Text(
                  "Appointments",
                  style: TextStyle(
                    fontSize: 18,
                    color: _selectedIndex == 1 ? Colors.black : Colors.grey
                  ),
                ),
              ),
            ),

            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                setState(() {
                  _selectedIndex = 2;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                child: Text(
                  "Messages",
                  style: TextStyle(
                    fontSize: 18,
                    color: _selectedIndex == 2 ? Colors.black : Colors.grey
                  ),
                ),
              ),
            ),

            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                setState(() {
                  _selectedIndex = 3;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                child: Text(
                  "Pets",
                  style: TextStyle(
                    fontSize: 18,
                    color: _selectedIndex == 3 ? Colors.black : Colors.grey
                  ),
                ),
              ),
            ),
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
      body: _pages[_selectedIndex],
    );
  }
}