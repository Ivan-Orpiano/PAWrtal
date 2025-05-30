import 'package:flutter/material.dart';

class WebDeclinedTile extends StatefulWidget {
  const WebDeclinedTile({super.key});

  @override
  State<WebDeclinedTile> createState() => _WebDeclinedTileState();
}

class _WebDeclinedTileState extends State<WebDeclinedTile> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
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
    );
  }
}
