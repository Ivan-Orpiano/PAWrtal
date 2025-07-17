import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:capstone_app/web/admin_web/pages/admin_web_appointments.dart';
import 'web_appointment_details.dart';

class WebPendingTile extends StatefulWidget {
  final Appointment appointment;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final bool showDate;

  const WebPendingTile({
    super.key,
    required this.appointment,
    required this.onAccept,
    required this.onDecline,
    required this.showDate,
  });

  @override
  State<WebPendingTile> createState() => _WebPendingTileState();
}

class _WebPendingTileState extends State<WebPendingTile> {
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
          width: 800,
          child: WebAppointmentDetails(
            appointmentData: {
              'owner': a.owner,
              'petName': a.petName,
              'breed': a.breed,
              'service': a.service,
              'time': a.time,
              'date': a.date.toIso8601String(),
              'status': 'pending',
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
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30.0,
                      backgroundImage: AssetImage(a.imageUrl),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          a.owner,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text('Pet Name: ${a.petName}'),
                        Text('Breed: ${a.breed}'),
                        Text('Service: ${a.service}'),
                        Text('Time: ${a.time}'),
                        if (widget.showDate)
                          Text(
                              'Date: ${DateFormat('MMMM d, y').format(a.date)}'),
                      ],
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      onPressed: widget.onAccept,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.all(16),
                        backgroundColor: Colors.green,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: widget.onDecline,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.all(16),
                        backgroundColor: Colors.red,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
