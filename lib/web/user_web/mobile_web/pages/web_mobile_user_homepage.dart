import 'package:capstone_app/mobile/user/pages/pawmap.dart';
import 'package:capstone_app/web/user_web/mobile_web/pages/web_mobile_appointments_page.dart';
import 'package:capstone_app/web/user_web/mobile_web/pages/web_mobile_dashboard_page.dart';
import 'package:capstone_app/web/user_web/mobile_web/pages/web_mobile_messages_page.dart';
import 'package:capstone_app/web/user_web/mobile_web/pages/web_mobile_pets_page.dart';
import 'package:flutter/material.dart';

class WebMobileUserHomepage extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const WebMobileUserHomepage({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected
  });

  @override
  State<WebMobileUserHomepage> createState() => _WebMobileUserHomePageState();
}

class _WebMobileUserHomePageState extends State<WebMobileUserHomepage> {

  final List<Widget> _pages = const [
    WebMobileDashboardPage(),
    WebMobileAppointmentsPage(),
    WebMobileMessagesPage(),
    WebMobilePetsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
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
          onTap: () {
            // Fixed: Call onItemSelected(0) to go to home
            widget.onItemSelected(0);
          },
          child: Image.asset(
            'lib/images/PAWrtal_logo.png',
            scale: 2.5,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              // TODO: Implement notifications
            },
            icon: const Icon(Icons.notifications),
          ),
          const SizedBox(width: 8)
        ],
      ),
      drawer: const Drawer(),
      body: Stack(
        children: [
          Scaffold(
            body: _pages[widget.selectedIndex],
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
                  heroTag: "webMobLoc",
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
                    Icons.location_pin,
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
      onPressed: () => widget.onItemSelected(index),
      icon: icon,
      iconSize: 30,
      color: widget.selectedIndex == index ? Colors.black : Colors.grey,
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

    // Draw the plain white navbar (no shadow)
    canvas.drawPath(finalPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}