import 'package:flutter/material.dart';

final List<Map<String, String>> completedAppointments = [
  {
    'owner': 'Pet Owner A',
    'petName': 'Kobe',
    'breed': 'Shih Tzu',
    'service': 'Nail Trimming',
    'time': '3:00 PM - 3:30 PM',
    'imageUrl': 'assets/profile.png',
  },
  {
    'owner': 'Pet Owner B',
    'petName': 'Bella',
    'breed': 'Pug',
    'service': 'Vaccination',
    'time': '2:00 PM - 2:30 PM',
    'imageUrl': 'assets/profile.png',
  },
];

class WebCompletedAppointments extends StatefulWidget {
  const WebCompletedAppointments({super.key});

  @override
  State<WebCompletedAppointments> createState() =>
      _WebCompletedAppointmentsState();
}

class _WebCompletedAppointmentsState extends State<WebCompletedAppointments> {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: completedAppointments.length,
      itemBuilder: (context, index) {
        final appointment = completedAppointments[index];
        return Padding(
          padding: const EdgeInsets.all(10),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xffF2F5FF),
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
