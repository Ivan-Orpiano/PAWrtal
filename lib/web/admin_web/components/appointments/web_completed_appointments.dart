import 'package:flutter/material.dart';

class WebCompletedAppointments extends StatefulWidget {
  final List<Map<String, String>> completedAppointments;

  const WebCompletedAppointments(
      {super.key, required this.completedAppointments});

  @override
  State<WebCompletedAppointments> createState() =>
      _WebCompletedAppointmentsState();
}

class _WebCompletedAppointmentsState extends State<WebCompletedAppointments> {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: widget.completedAppointments.length,
      itemBuilder: (context, index) {
        final appointment = widget.completedAppointments[index];
        return Padding(
          padding: const EdgeInsets.all(10),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey, width: 1),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      backgroundImage: AssetImage(appointment['imageUrl']!),
                      radius: 30,
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        appointment['owner']!,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text('Pet Name: ${appointment['petName']}'),
                      Text('Breed: ${appointment['breed']}'),
                      Text('Service: ${appointment['service']}'),
                      Text('Time: ${appointment['time']}'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
