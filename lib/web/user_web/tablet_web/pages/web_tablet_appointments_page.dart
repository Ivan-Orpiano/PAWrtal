import 'package:capstone_app/web/user_web/desktop_web/pages/web_appointments_page.dart';
import 'package:flutter/material.dart';

class WebTabletAppointmentsPage extends StatefulWidget {
  const WebTabletAppointmentsPage({super.key});

  @override
  State<WebTabletAppointmentsPage> createState() => _WebTabletAppointmentsPageState();
}

class _WebTabletAppointmentsPageState extends State<WebTabletAppointmentsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 238, 238, 238),
            body: Container(
        padding: const EdgeInsets.only(left: 65, right: 65, top: 16),
        child: Column(
          children: [
            appointmentBar(),
            const SizedBox(height: 16),
            const Expanded(
              child: Row(
                children: [
                  AppointmentPending(),
                  SizedBox(width: 16),
                  AppointmentAccepted(),
                  SizedBox(width: 16),
                  AppointmentDeclined()
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}