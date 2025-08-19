import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/mobile/user/components/general_components/app_bar.dart';
import 'package:capstone_app/mobile/user/components/general_components/drawer.dart';
import 'package:capstone_app/mobile/user/pages/appointment_page.dart';
import 'package:capstone_app/mobile/user/pages/dashboard_page.dart';
//import 'package:capstone_app/mobile/user/pages/maps.dart';
import 'package:capstone_app/mobile/user/pages/messages_page.dart';
import 'package:capstone_app/mobile/user/pages/pawmap.dart';
import 'package:capstone_app/mobile/user/pages/pets_page.dart';
import 'package:flutter/material.dart';
import 'package:capstone_app/pages/user_home/user_home_controller.dart';
import 'package:get/get.dart';

class UserHomePage extends StatefulWidget {
  const UserHomePage({super.key});

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  final UserHomeController controller =
      UserHomeController(Get.find<AuthRepository>());

  int _currentIndex = 0;

  final List<Widget> _pages = const [
    DashboardPage(),
    EnhancedAppointmentPage(),
    Messages(),
    PetsPage()
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        body: _pages[_currentIndex],
        appBar: const MyAppBar(),
        drawer: const MyDrawer(),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: FloatingActionButton(
          heroTag: "btn1",
          shape: const CircleBorder(),
          isExtended: true,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const Pawmap()),
            );
          },
          child: const Icon(Icons.location_on_rounded),
        ),
        bottomNavigationBar: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          height: 90,
          notchMargin: 10.0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: const Icon(Icons.home_rounded),
                onPressed: () {
                  setState(() {
                    _currentIndex = 0;
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.calendar_month_rounded),
                onPressed: () {
                  setState(() {
                    _currentIndex = 1;
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.message_rounded),
                onPressed: () {
                  setState(() {
                    _currentIndex = 2;
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.pets_rounded),
                onPressed: () {
                  setState(() {
                    _currentIndex = 3;
                  });
                },
              )
            ],
          ),
        ));
  }
}
