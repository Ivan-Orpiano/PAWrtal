import 'package:flutter/material.dart';

class WebAppointmentsPage extends StatefulWidget {
  const WebAppointmentsPage({super.key});

  @override
  State<WebAppointmentsPage> createState() => _AppointmentsWebPageState();
}

class _AppointmentsWebPageState extends State<WebAppointmentsPage> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        "Appointments"
      ),
    );
  }
}