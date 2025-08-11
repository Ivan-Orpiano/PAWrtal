import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WebAppointmentsPage extends StatefulWidget {
  const WebAppointmentsPage({super.key});

  @override
  State<WebAppointmentsPage> createState() => _AppointmentsWebPageState();
}

class _AppointmentsWebPageState extends State<WebAppointmentsPage> {
  @override
  Widget build(BuildContext context) {

  DateTime now = DateTime.now();
  String formattedDate = DateFormat('yyyy/MM/dd').format(now);

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 238, 238, 238),
      body: Container(
        padding: const EdgeInsets.only(left: 65, right: 65, top: 16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20)
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Date Today: $formattedDate",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18
                    ),
                  ),
                  const Text(
                    "Appointments Today: 1",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 18
                    ),
                  ),
                  const Row(
                    children: [
                      Text(
                        "Pending: 1",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12
                        ),
                      ),
                      VerticalDivider(indent: 10, endIndent: 10, width: 7.5,),
                      Text(
                        "Accepted: 1",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12
                        ),
                      ),
                      VerticalDivider(indent: 10, endIndent: 10, width: 7.5,),
                      Text(
                        "Rejected: 1",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Expanded(
              child: Row(
                children: [
                  AppointmentPending(),
                  SizedBox(width: 16,),
                  AppointmentAccepted(),
                  SizedBox(width: 16  ,),
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

class AppointmentPending extends StatefulWidget {
  const AppointmentPending({super.key});

  @override
  State<AppointmentPending> createState() => _AppointmentPendingState();
}

class _AppointmentPendingState extends State<AppointmentPending> {
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 760,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20)
        ),
      ),
    );
  }
}

class AppointmentAccepted extends StatefulWidget {
  const AppointmentAccepted({super.key});

  @override
  State<AppointmentAccepted> createState() => _AppointmentAcceptedState();
}

class _AppointmentAcceptedState extends State<AppointmentAccepted> {
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 760,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20)
        ),
      ),
    );
  }
}

class AppointmentDeclined extends StatefulWidget {
  const AppointmentDeclined({super.key});

  @override
  State<AppointmentDeclined> createState() => _AppointmentDeclinedState();
}

class _AppointmentDeclinedState extends State<AppointmentDeclined> {
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 760,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20)
        ),
      ),
    );
  }
}