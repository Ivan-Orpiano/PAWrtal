import 'package:capstone_app/web/user_web/mobile_web/pages/web_mobile_schedule_appointment.dart';
import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:capstone_app/mobile/user/pages/pawmap.dart';
import 'package:flutter/material.dart';

class WebMobileClinicPage extends StatefulWidget {
  final Clinic clinic;

  const WebMobileClinicPage({super.key, required this.clinic});

  @override
  State<WebMobileClinicPage> createState() => _WebMobileClinicPageState();
}

class _WebMobileClinicPageState extends State<WebMobileClinicPage> {
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
                  child: widget.clinic.image.isNotEmpty
                      ? Image.network(
                          widget.clinic.image,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (context, error, stackTrace) {
                            return Image.asset(
                              'lib/images/test_image.jpg',
                              fit: BoxFit.cover,
                              width: double.infinity,
                            );
                          },
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
                  widget.clinic.clinicName,
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
                  widget.clinic.address,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // CONTACT INFO
              Padding(
                padding: const EdgeInsets.only(left: 25),
                child: Row(
                  children: [
                    const Icon(Icons.phone,
                        color: Color.fromARGB(255, 81, 115, 153)),
                    const SizedBox(width: 8),
                    Text(
                      widget.clinic.contact,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 15),

              // EMAIL INFO
              Padding(
                padding: const EdgeInsets.only(left: 25),
                child: Row(
                  children: [
                    const Icon(Icons.email,
                        color: Color.fromARGB(255, 81, 115, 153)),
                    const SizedBox(width: 8),
                    Text(
                      widget.clinic.email,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // SERVICES TITLE
              const Padding(
                padding: EdgeInsets.only(left: 25),
                child: Text(
                  "Services",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),

              // CLINIC SERVICES
              Padding(
                padding: const EdgeInsets.only(left: 25, right: 25),
                child: Text(
                  widget.clinic.services.isNotEmpty
                      ? widget.clinic.services
                      : "No services listed.",
                  style: const TextStyle(fontSize: 14),
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
                  widget.clinic.description.isNotEmpty
                      ? widget.clinic.description
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

              // LOCATION BUTTON
              Padding(
                padding: const EdgeInsets.only(left: 25, right: 25, top: 10),
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const Pawmap(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.location_on, color: Colors.white),
                  label: const Text(
                    "View on Map",
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 81, 115, 153),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 100), // Space for bottom buttons
            ],
          ),
        ],
      ),

      // BOTTOM BUTTONS
      bottomNavigationBar: Container(
        color: const Color.fromARGB(255, 248, 253, 255),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(
                        left: 20, top: 20, bottom: 20, right: 10),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 75, vertical: 15),
                        backgroundColor:
                            const Color.fromARGB(255, 81, 115, 153),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => WebMobileScheduleAppointment(
                                clinic: widget.clinic),
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
                      const EdgeInsets.only(top: 20, bottom: 20, right: 20),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 25, vertical: 15),
                      backgroundColor: const Color.fromARGB(255, 81, 115, 153),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: () {
                      // TODO: Navigate to messaging
                      // This would be similar to your mobile app's MessagesNextPage
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Messaging coming soon!"),
                        ),
                      );
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
        ),
      ),
    );
  }
}
