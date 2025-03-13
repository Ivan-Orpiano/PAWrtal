import 'package:flutter/material.dart';

class AppointmentsWebPage extends StatefulWidget {
  const AppointmentsWebPage({super.key});

  @override
  State<AppointmentsWebPage> createState() => _AppointmentsWebPageState();
}

class _AppointmentsWebPageState extends State<AppointmentsWebPage> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        "Appointments"
      ),
    );
  }
}