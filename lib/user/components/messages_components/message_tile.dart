import 'package:capstone_app/user/pages/messages_next_page.dart';
import 'package:flutter/material.dart';

class MyMessageTile extends StatelessWidget {
  const MyMessageTile({super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const MessagesNextPage()
          )
          
        );
      },
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(50),
              child: Image.asset(
                "lib/images/pfp.jpg",
                height: 75,
                width: 75,
              ),
            ),
          ),
          const Padding (
            padding: EdgeInsets.only(left: 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text (
                  "Name of person/clinic/anything",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 5),
                  child: Text(
                    "You: pa appoint yung malupit",
                    style: TextStyle(
                      fontSize: 15
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}