import 'package:flutter/material.dart';

class WebAppointmentPetDetails extends StatefulWidget {
  final Map<String, dynamic> petData;

  const WebAppointmentPetDetails({super.key, required this.petData});

  @override
  State<WebAppointmentPetDetails> createState() =>
      _WebAppointmentPetDetailsState();
}

class _WebAppointmentPetDetailsState extends State<WebAppointmentPetDetails> {
  @override
  Widget build(BuildContext context) {
    final pet = widget.petData;

    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 30),
                  child: AlertDialog(
                    insetPadding: const EdgeInsets.symmetric(horizontal: 100),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    title: const Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: Text("Pet Details"),
                    ),
                    content: SizedBox(
                      height: 500,
                      width: 500,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Pet Name: ${pet['name'] ?? 'N/A'}"),
                          Text("Species: ${pet['species'] ?? 'N/A'}"),
                          Text("Breed: ${pet['breed'] ?? 'N/A'}"),
                          Text("Service: ${pet['service'] ?? 'N/A'}"),
                          Text("Time: ${pet['time'] ?? 'N/A'}"),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text("Close"),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 125,
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 30,
                    backgroundImage: AssetImage("lib/images/paw.png"),
                  ),
                ),
              ],
            );
          },
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 100, 124, 151),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 45,
                backgroundImage: AssetImage("lib/images/kapitankalbo1.png"),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Name: ${pet['name'] ?? ''}",
                        style: const TextStyle(color: Colors.white)),
                    Text("Breed: ${pet['breed'] ?? ''}",
                        style: const TextStyle(color: Colors.white)),
                    Text("Service: ${pet['service'] ?? ''}",
                        style: const TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
