import 'package:capstone_app/user/pages/notification_page.dart';
import 'package:flutter/material.dart';

class MyNotifButton extends StatelessWidget {
  const MyNotifButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 25),
      child: IconButton(
        icon: const Icon(Icons.notifications_rounded),
        onPressed: () {
          Navigator.push(
          context,
            MaterialPageRoute(
              builder: (context) => const NotificationPage()
            )
          );
        },
      ),
    );
  }
}