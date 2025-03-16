import 'package:capstone_app/user_web/components/appbar_components/notification_icon_web.dart';
import 'package:capstone_app/user_web/components/appbar_components/profile_icon_web.dart';
import 'package:capstone_app/user_web/pages/appointments_web_page.dart';
import 'package:capstone_app/user_web/pages/dashboard_web_page.dart';
import 'package:capstone_app/user_web/pages/messages_web_page.dart';
import 'package:capstone_app/user_web/pages/pets_web_page.dart';
import 'package:flutter/material.dart';

class WebUserHomePage extends StatefulWidget {
  const WebUserHomePage({super.key});

  @override
  State<WebUserHomePage> createState() => _WebUserHomePageState();
}

class _WebUserHomePageState extends State<WebUserHomePage> {

  int _selectedIndex = 0;
  bool _isExpanded = false;

    final List<Widget> _pages = const [
    DashboardWebPage(),
    AppointmentsWebPage(),
    MessagesWebPage(),
    PetsWebPage(),
  ];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.menu_rounded),
              onPressed: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
            ),
            const SizedBox(width: 10),
            InkWell(
              onTap: () {},
              child: Image.asset(
                'lib/images/PAWrtal_logo.png',
                height: 50,
              ),
            ),
            Expanded(
              child: Center(
                child: SizedBox(
                  width: 400,
                  child: TextField(
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search_rounded),
                      hintText: "Search",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: const [
          NotificationIconWeb(),
          ProfileIconWeb(),
        ],
      ),
      body: Row(
        children: [
          NavigationRail(
            useIndicator: true,
            extended: _isExpanded,
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: _isExpanded ? NavigationRailLabelType.none : NavigationRailLabelType.none,
            indicatorShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(
                  Icons.dashboard_rounded
                ),
                selectedIcon: Icon(
                  Icons.dashboard,
                  color: Colors.blue
                ),
                label: Text(
                  "Dashboard"
                ),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.calendar_today_rounded),
                selectedIcon: Icon(
                  Icons.calendar_today, 
                  color: Colors.blue
                ),
                label: Text(
                  "Appointments"
                ),
              ),
              NavigationRailDestination(
                icon: Icon(
                  Icons.message_rounded
                ),
                selectedIcon: Icon(
                  Icons.message, color: Colors.blue
                ),
                label: Text(
                  "Messages"
                ),
              ),
              NavigationRailDestination(
                icon: Icon(
                  Icons.pets_rounded
                ),
                selectedIcon: Icon(
                  Icons.pets, 
                  color: Colors.blue
                ),
                label: Text(
                  "Pets"
                ),
              ),
            ],
          ),
          const VerticalDivider(
            thickness: 1, width: 1,
          ),
          Expanded(
            child: _pages[_selectedIndex],
          ),
        ],
      ),
    );
  }
}