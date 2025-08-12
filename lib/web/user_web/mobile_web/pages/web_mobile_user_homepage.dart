import 'package:capstone_app/mobile/user/pages/pawmap.dart';
import 'package:capstone_app/web/user_web/desktop_web/pages/web_maps.dart';
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
          child: Image.asset(
            'lib/images/PAWrtal_logo.png',
            scale: 2.5,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
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
                bottom: 24 + 73 - 28,
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
  Widget _navButton (Icon icon, int index) {
    return IconButton(
      onPressed:  () => {widget.onItemSelected(index)},
      icon: icon,
      iconSize: 30,
      color: widget.selectedIndex == index ? Colors.black : Colors.grey,
    );
  }
}

class NotchedNavbarPainter extends CustomPainter {
  final NotchedShape shape = const CircularNotchedRectangle();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final Rect host = Rect.fromLTWH(0, 0, size.width, size.height);

    const double notchRadius = 35;
    final Offset notchCenter = Offset(size.width / 2, 0);
    final Rect guest = Rect.fromCircle(center: notchCenter, radius: notchRadius);

    final Path path = shape.getOuterPath(host, guest);

    final RRect rounded = RRect.fromRectAndCorners(
      host,
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: const Radius.circular(16),
      bottomRight: const Radius.circular(16)
    );
    final Path roundedPath = Path()..addRRect(rounded);

    final Path combined = Path.combine(PathOperation.intersect, path, roundedPath);

    canvas.drawShadow(
      combined,
      Colors.grey.shade400,
      8.0,
      true,
    );

    canvas.drawPath(combined, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}