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
      body: EnhancedWebAppointmentsPage(),
    );
  }
}