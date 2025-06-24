import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:capstone_app/mobile/user/pages/messages_next_page.dart';
import 'package:capstone_app/mobile/user/pages/schedule_appointment.dart';
import 'package:flutter/material.dart';

class DashboardNextPage extends StatelessWidget {
  final Clinic clinic;

  const DashboardNextPage({super.key, required this.clinic});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 248, 253, 255),
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        toolbarHeight: 50,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.keyboard_arrow_left_rounded),
            iconSize: 30,
          ),
        ),
        title: const Text("3.2 KM"), // You can calculate distance later
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.favorite_border),
          )
        ],
      ),
      body: ListView(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // CLINIC IMAGE
              Padding(
                padding: const EdgeInsets.only(top: 15),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: clinic.image.isNotEmpty
                      ? Image.network(
                          clinic.image,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        )
                      : Image.asset(
                          'lib/images/test_image.jpg',
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                ),
              ),
              const SizedBox(height: 30),

              // CLINIC NAME
              Padding(
                padding: const EdgeInsets.only(left: 25),
                child: Text(
                  clinic.clinicName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 28,
                    color: Color.fromARGB(255, 81, 115, 153),
                  ),
                ),
              ),

              // CLINIC ADDRESS
              Padding(
                padding: const EdgeInsets.only(left: 25),
                child: Text(
                  clinic.address,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // DESCRIPTION TITLE
              const Padding(
                padding: EdgeInsets.only(left: 25),
                child: Text(
                  "Description",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),

              // CLINIC DESCRIPTION
              Padding(
                padding: const EdgeInsets.only(left: 25, right: 25),
                child: Text(
                  clinic.description.isNotEmpty
                      ? clinic.description
                      : "No description provided.",
                  style: const TextStyle(fontSize: 14),
                ),
              ),

              const SizedBox(height: 25),

              // LOCATION TITLE
              const Padding(
                padding: EdgeInsets.only(left: 25),
                child: Text(
                  "Location",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ],
          ),
        ],
      ),

      // BOTTOM BUTTONS
      bottomNavigationBar: SizedBox(
        width: double.infinity,
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(
                    left: 20, top: 20, bottom: 20, right: 10),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 75, vertical: 15),
                    backgroundColor: const Color.fromARGB(255, 81, 115, 153),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ScheduleAppointment(clinic: clinic),
                      ),
                    );
                  },
                  child: const Text(
                    "Make an Appointment",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.only(top: 20, bottom: 20, right: 10),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                  backgroundColor: const Color.fromARGB(255, 81, 115, 153),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: () {
                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(
                  //     builder: (context) => MessagesNextPage(clinic: clinic),
                  //   ),
                  // );
                },
                child: const Icon(
                  Icons.message_rounded,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
