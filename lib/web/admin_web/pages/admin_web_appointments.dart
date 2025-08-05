import 'package:flutter/material.dart';
import 'package:capstone_app/web/admin_web/components/appointments/web_accepted_tile.dart';
import 'package:capstone_app/web/admin_web/components/appointments/web_pending_tile.dart';
import 'package:capstone_app/web/admin_web/components/appointments/web_declined_tile.dart';

class Appointment {
  final String owner;
  final String petName;
  final String breed;
  final String service;
  final String time;
  final String imageUrl;
  final DateTime date;
  final bool isCompleted;

  Appointment({
    required this.owner,
    required this.petName,
    required this.breed,
    required this.service,
    required this.time,
    required this.imageUrl,
    required this.date,
    this.isCompleted = false,
  });
}

List<Appointment> appointments = [];

class AdminWebAppointments extends StatefulWidget {
  const AdminWebAppointments({super.key});

  @override
  State<AdminWebAppointments> createState() => _AdminWebAppointmentsState();
}

class _AdminWebAppointmentsState extends State<AdminWebAppointments> {
  String selectedTag = 'Today';

  final List<String> tags = ['Today', 'Date', 'Completed'];

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
    {
      'owner': 'Pet Owner C',
      'petName': 'Charlie',
      'breed': 'Labrador',
      'service': 'Deworming',
      'time': '1:00 PM - 1:30 PM',
      'imageUrl': 'assets/profile.png',
    },
    {
      'owner': 'Pet Owner D',
      'petName': 'Max',
      'breed': 'Husky',
      'service': 'Check-up',
      'time': '11:00 AM - 11:30 AM',
      'imageUrl': 'assets/profile.png',
    },
  ];

  List<Appointment> accepted = [
    Appointment(
      owner: 'Pet Owner A',
      date: DateTime.now(),
      petName: 'Kobe',
      breed: 'Shih Tzu',
      service: 'Nail Trimming',
      time: '3:00 PM - 3:30 PM',
      imageUrl: 'assets/profile.png',
    ),
  ];
  List<Appointment> pending = [
    Appointment(
      owner: 'Pet Owner 1',
      date: DateTime.now(),
      petName: 'Cerberus',
      breed: 'Chihuahua',
      service: 'Grooming',
      time: '10:00 AM - 10:30 AM',
      imageUrl: 'assets/profile.png',
    ),
    Appointment(
      owner: 'Pet Owner 2',
      date: DateTime.now().add(Duration(days: 1)),
      petName: 'Rex',
      breed: 'Bulldog',
      service: 'Vaccination',
      time: '11:00 AM - 11:30 AM',
      imageUrl: 'assets/profile.png',
    ),
    Appointment(
      owner: 'Pet Owner 3',
      date: DateTime.now().add(Duration(days: 2)),
      petName: 'Milo',
      breed: 'Poodle',
      service: 'Check-up',
      time: '12:00 PM - 12:30 PM',
      imageUrl: 'assets/profile.png',
    ),
    Appointment(
      owner: 'Pet Owner 4',
      date: DateTime.now().add(Duration(days: 3)),
      petName: 'Luna',
      breed: 'Beagle',
      service: 'Surgery',
      time: '1:00 PM - 1:30 PM',
      imageUrl: 'assets/profile.png',
    ),
    Appointment(
      owner: 'Pet Owner 5',
      date: DateTime.now().add(Duration(days: 4)),
      petName: 'Simba',
      breed: 'Golden Retriever',
      service: 'Dental Cleaning',
      time: '2:00 PM - 2:30 PM',
      imageUrl: 'assets/profile.png',
    ),
  ];
  List<Appointment> declined = [
    Appointment(
      owner: 'Pet Owner X',
      date: DateTime.now(),
      petName: 'Nala',
      breed: 'Persian Cat',
      service: 'Deworming',
      time: '4:00 PM - 4:30 PM',
      imageUrl: 'assets/profile.png',
    ),
  ];

  void acceptAppointment(Appointment appointment) {
    setState(() {
      pending.remove(appointment);
      accepted.add(appointment);
    });
  }

  void declineAppointment(Appointment appointment) {
    setState(() {
      pending.remove(appointment);
      declined.add(appointment);
    });
  }

  Widget buildTagsFilter() {
    return Row(
      children: tags.map((tag) {
        final bool isSelected = tag == selectedTag;
        return Padding(
          padding: const EdgeInsets.only(right: 12),
          child: ChoiceChip(
            label: Text(tag),
            selected: isSelected,
            onSelected: (_) {
              setState(() {
                selectedTag = tag;
              });
            },
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: buildTagsFilter(),
              ),
            ),
            Expanded(
              child: selectedTag == 'Completed'
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: GridView.count(
                        crossAxisCount: 4,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 2.8,
                        children: completedAppointments.map((appointment) {
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey, width: 1),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  backgroundImage: AssetImage(
                                    appointment['imageUrl'] ??
                                        'lib/images/pfp.jpg',
                                  ),
                                  radius: 30,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        appointment['owner']!,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                          'Pet Name: ${appointment['petName']}'),
                                      Text('Breed: ${appointment['breed']}'),
                                      Text(
                                          'Service: ${appointment['service']}'),
                                      Text('Time: ${appointment['time']}'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              children: [
                                const TabHeader(
                                    title: 'Accepted',
                                    backgroundColor: Colors.green),
                                Expanded(
                                  child: ListView.builder(
                                    itemCount: accepted.where((a) {
                                      if (selectedTag == 'Today') {
                                        final now = DateTime.now();
                                        return a.date.year == now.year &&
                                            a.date.month == now.month &&
                                            a.date.day == now.day;
                                      }
                                      return true;
                                    }).length,
                                    itemBuilder: (context, index) {
                                      final filtered = accepted.where((a) {
                                        if (selectedTag == 'Today') {
                                          final now = DateTime.now();
                                          return a.date.year == now.year &&
                                              a.date.month == now.month &&
                                              a.date.day == now.day;
                                        }
                                        return true;
                                      }).toList();
                                      final item = filtered[index];
                                      return WebAcceptedTile(
                                        showDate: selectedTag != 'Today',
                                        appointment: item,
                                        onComplete: () => setState(() {
                                          accepted.removeWhere((a) =>
                                              a.owner == item.owner &&
                                              a.petName == item.petName &&
                                              a.breed == item.breed &&
                                              a.service == item.service &&
                                              a.time == item.time);
                                          completedAppointments.add({
                                            'owner': item.owner,
                                            'petName': item.petName,
                                            'breed': item.breed,
                                            'service': item.service,
                                            'time': item.time,
                                            'imageUrl': item.imageUrl,
                                          });
                                        }),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              children: [
                                const TabHeader(
                                    title: 'Pending',
                                    backgroundColor: Colors.yellow,
                                    textColor: Colors.black),
                                Expanded(
                                  child: ListView.builder(
                                    itemCount: pending.where((a) {
                                      if (selectedTag == 'Today') {
                                        final now = DateTime.now();
                                        return a.date.year == now.year &&
                                            a.date.month == now.month &&
                                            a.date.day == now.day;
                                      }
                                      return true;
                                    }).length,
                                    itemBuilder: (context, index) {
                                      final filtered = pending.where((a) {
                                        if (selectedTag == 'Today') {
                                          final now = DateTime.now();
                                          return a.date.year == now.year &&
                                              a.date.month == now.month &&
                                              a.date.day == now.day;
                                        }
                                        return true;
                                      }).toList();
                                      final item = filtered[index];
                                      return WebPendingTile(
                                        showDate: selectedTag != 'Today',
                                        appointment: item,
                                        onAccept: () => acceptAppointment(item),
                                        onDecline: () =>
                                            declineAppointment(item),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              children: [
                                const TabHeader(
                                    title: 'Declined',
                                    backgroundColor: Colors.red),
                                Expanded(
                                  child: ListView.builder(
                                    itemCount: declined.where((a) {
                                      if (selectedTag == 'Today') {
                                        final now = DateTime.now();
                                        return a.date.year == now.year &&
                                            a.date.month == now.month &&
                                            a.date.day == now.day;
                                      }
                                      return true;
                                    }).length,
                                    itemBuilder: (context, index) {
                                      final filtered = declined.where((a) {
                                        if (selectedTag == 'Today') {
                                          final now = DateTime.now();
                                          return a.date.year == now.year &&
                                              a.date.month == now.month &&
                                              a.date.day == now.day;
                                        }
                                        return true;
                                      }).toList();
                                      final item = filtered[index];
                                      return WebDeclinedTile(
                                        showDate: selectedTag != 'Today',
                                        appointment: item,
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class TabHeader extends StatelessWidget {
  final String title;
  final Color backgroundColor;
  final Color textColor;
  const TabHeader(
      {super.key,
      required this.title,
      this.backgroundColor = const Color(0xFF628BBE),
      this.textColor = Colors.white});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        ),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}
