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
      appBar: const MyAppBar(),
      drawer: const MyDrawer(),
      body: Stack(
        children: [
          Scaffold(
            body: _pages[_currentIndex],
          ),
          Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Positioned(
                bottom: 24, // floating above bottom
                left: 24,
                right: 24,
                child: CustomPaint(
                  painter: NotchedNavbarPainter(),
                  child: SizedBox(
                    height: 70,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _navButton(const Icon(Icons.home_rounded), 0),
                        _navButton(const Icon(Icons.calendar_month_rounded), 1),
                        const SizedBox(width: 30,),
                        _navButton(const Icon(Icons.message_rounded), 2),
                        _navButton(const Icon(Icons.pets_rounded), 3),
                      ]
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 24 + 60 - 28,
                child: FloatingActionButton(  
                  backgroundColor: Colors.white,
                  heroTag: "userHomeLoc",
                  shape: const CircleBorder(),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const Pawmap(),
                      )
                    );
                  },
                  child: const Icon(
                    Icons.location_on_rounded,
                    color: Colors.black,
                  ),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _navButton(Icon icon, int index) {
    return IconButton(
      onPressed: () {
        setState(() {
          _currentIndex = index;
        });
      },
      icon: icon,
      iconSize: 30,
      color: _currentIndex == index ? Colors.black : Colors.grey,
    );
  }
}

class NotchedNavbarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.grey.shade100
      ..style = PaintingStyle.fill;

    // Main rounded rectangle background
    final Path path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(35),
      ));

    // Circular notch in the center
    const double notchRadius = 35;
    final double notchCenter = size.width / 2;
    const double notchTop = -25;

    final Path notchPath = Path()
      ..addOval(Rect.fromCircle(
        center: Offset(notchCenter, notchTop + notchRadius),
        radius: notchRadius,
      ));

    // Cut the notch out of the rectangle
    final Path finalPath = Path.combine(
      PathOperation.difference,
      path,
      notchPath,
    );

    // Draw the plain navbar
    canvas.drawPath(finalPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}