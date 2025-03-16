import 'package:capstone_app/user/pages/messages_next_page.dart';
import 'package:capstone_app/user/pages/schedule_appointment.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DashboardNextPage extends StatelessWidget {
  const DashboardNextPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:  const Color.fromARGB(255, 248, 253, 255),
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        toolbarHeight: 50,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.keyboard_arrow_left_rounded),
            iconSize: 30,
          ),
        ),
        title: const Text("3.2 KM"),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.favorite_border), // Replace with your LikeButton
          )
        ],
      ),
      body: ListView(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 15),
                child: AspectRatio(
                  aspectRatio: 16/9,
                  child: Image.asset(
                    'lib/images/test_image.jpg',
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
              ),
              const SizedBox (
                height: 30,
              ),
              const Padding(
                padding: EdgeInsets.only(left: 25),
                child: Text(
                  "Qualipaws",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 28,
                    color: Color.fromARGB(255, 81, 115, 153),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left:25),
                child: Text(
                  "Diyan lang sa tabi tabi",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade700
                  ),
                ),
              ),
              const SizedBox(
                height: 25,
              ),
              const Padding(
                padding:  EdgeInsets.only(left: 25),
                child: Text(
                  "Description",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 25),
                child: Text(
                  "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Praesent volutpat ex viverra velit varius sagittis.",
                  style: TextStyle(
                    fontSize: 14
                  ),
                ),
              ),  
              const SizedBox(
                height: 25,
              ),
              const Padding(
                padding: EdgeInsets.only(left: 25),
                child: Text(
                  "Location",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18
                  ),
                ),
              )
            ]
          ),
        ],
      ),
      bottomNavigationBar: SizedBox(
        width: double.infinity,
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 20, top: 20, bottom: 20, right: 10),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 75, vertical: 15),
                    backgroundColor: const Color.fromARGB(255, 81, 115, 153),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)
                      )
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ScheduleAppointment(),
                        )
                      );
                    },
                    child: const Text(
                      "Make an Appointment",
                      style: TextStyle(
                        color: Colors.white
                      ),
                    ),
                  ),
                ),
            ),
              Padding(
                padding: const EdgeInsets.only(top: 20, bottom: 20, right: 10),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                    backgroundColor: const Color.fromARGB(255, 81, 115, 153),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)
                    )
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MessagesNextPage()
                      )
                    );
                  },
                  child: const Icon(
                    Icons.message_rounded,
                    color: Colors.white,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}