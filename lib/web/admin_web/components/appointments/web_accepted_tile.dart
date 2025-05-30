import 'package:flutter/material.dart';
import 'web_appointment_details.dart';

class WebAcceptedTile extends StatefulWidget {
  const WebAcceptedTile({super.key});

  @override
  State<WebAcceptedTile> createState() => _WebAcceptedTileState();
}

class _WebAcceptedTileState extends State<WebAcceptedTile> {
  void _showPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: SizedBox(
          height: 800,
          width: 800,
          child: const WebAppointmentDetails(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: InkWell(
        onTap: () => _showPopup(context),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Color(0xffF2F5FF),
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
                    backgroundImage: AssetImage("lib/images/pfp.jpg"),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Pet Owner",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text("Pet Name: Cerberus"),
                      Text("Breed: Chihuahua"),
                      Text("Service: Grooming"),
                      Text("Time: 10:00 AM - 10:30 AM"),
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
