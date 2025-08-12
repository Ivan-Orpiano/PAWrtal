import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              AppointmentTabTitle(
                icon: Icons.pending_rounded,
                text: "Pending",
                color: Colors.grey.shade200
              ),
              AppointmentTile(color: Colors.grey.shade200)
            ],
          ),
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
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              AppointmentTabTitle(
                icon: Icons.check_rounded,
                text: "Accepted",
                color: Colors.green.shade100
              ),
              AppointmentTile(color: Colors.green.shade100)
            ],
          ),
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
        child:  Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              AppointmentTabTitle(
                icon: Icons.cancel_rounded,
                text: "Declined",
                color: Colors.red.shade100
              ),
              AppointmentTile(color: Colors.red.shade100)
            ],
          ),
        ),
      ),
    );
  }
}

class AppointmentTabTitle extends StatefulWidget {
  final Color color;
  final IconData icon;
  final String text;

  const AppointmentTabTitle({
    super.key,
    required this.color,
    required this.icon,
    required this.text
  });

  @override
  State<AppointmentTabTitle> createState() => _AppointmentTabTitleState();
}

class _AppointmentTabTitleState extends State<AppointmentTabTitle> {
  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Container(
          width: 100,
          height: 50,
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              width: 1,
              color: Colors.black
            )
          ),
          child:  Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 5),
                child: Icon(
                  widget.icon
                ),
              ),
              Text(
                widget.text,
                style: const TextStyle(
                  fontWeight: FontWeight.bold
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class AppointmentTile extends StatefulWidget {
  final Color color;

  const AppointmentTile({
    super.key,
    required this.color
  });

  @override
  State<AppointmentTile> createState() => _AppointmentTileState();
}

class _AppointmentTileState extends State<AppointmentTile> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => _buildWebAppointmentDialog()
        );
      },
      child: Flexible(
        child: Container(
          padding: const EdgeInsets.all(16),
          height: 200,
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(20)
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    flex: 4,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        'lib/images/test_image.jpg',
                        width: 85,
                        height: 85,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 7,
                    children: [
                      const Text(
                        "Clinic name",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.medical_services_outlined,
                            size: 22,
                            color: Colors.grey.shade700
                          ),
                          const SizedBox(width: 5,),
                          Text(
                            "Purpose of appointment", 
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700
                            ),
                          )
                        ],
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.pets_rounded,
                            size: 22,
                            color: Colors.grey.shade700
                          ),
                          const SizedBox(width: 5,),
                          Text(
                            "Name of pet", 
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700
                            ),
                          )
                        ],
                      )
                    ],
                  )
                ],
              ),
              const SizedBox(
                height: 16,
              ),
              Container(
                height: 67,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    width: 2,
                    color: Colors.black,
                  )
                ),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  child: const Row(
                    spacing: 8,
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "December 1 2025",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            "3 :00 AM - 4 : 00 AM",
                            style: TextStyle(
                              fontSize: 12
                            ),
                          )
                        ],
                      )
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildWebAppointmentDialog() {
  return Dialog(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    ),
    child: Container(
      width: 550,
      height: 700,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.hardEdge,
      child: const SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                'Appointment Details',
                style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}