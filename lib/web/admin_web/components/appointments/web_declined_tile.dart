import 'package:flutter/material.dart';
import 'package:capstone_app/web/admin_web/pages/admin_web_appointments.dart';
import 'web_appointment_details.dart';
import 'package:intl/intl.dart';

class WebDeclinedTile extends StatefulWidget {
  final Appointment appointment;
  final bool showDate;

  const WebDeclinedTile(
      {super.key, required this.appointment, required this.showDate});

  @override
  State<WebDeclinedTile> createState() => _WebDeclinedTileState();
}

class _WebDeclinedTileState extends State<WebDeclinedTile> {
  void _showPopup(BuildContext context) {
    final a = widget.appointment;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: SizedBox(
          height: 800,
          width: 500,
          child: WebAppointmentDetails(
            appointmentData: {
              'owner': a.owner,
              'petName': a.petName,
              'breed': a.breed,
              'service': a.service,
              'time': a.time,
              'date': a.date.toIso8601String(),
              'status': 'declined',
              'imageUrl': a.imageUrl,
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.appointment;

    return Padding(
      padding: const EdgeInsets.all(10),
      child: InkWell(
        onTap: () => _showPopup(context),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xffF2F5FF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: CircleAvatar(
                    radius: 30.0,
                    backgroundImage: AssetImage(a.imageUrl),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        a.owner,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text("Pet Name: ${a.petName}"),
                      Text("Breed: ${a.breed}"),
                      Text("Service: ${a.service}"),
                      Text("Time: ${a.time}"),
                      if (widget.showDate)
                        Text("Date: ${DateFormat('MMMM d, y').format(a.date)}"),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
