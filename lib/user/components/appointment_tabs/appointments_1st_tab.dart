import 'package:capstone_app/user/components/appointment_tabs/components/pending_tile.dart';
import 'package:flutter/material.dart';

class APFirstTab extends StatefulWidget {
  const APFirstTab({super.key});

  @override
  State<APFirstTab> createState() => _APFirstTabState();
}

class _APFirstTabState extends State<APFirstTab> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 248, 253, 255),
      body: ListView(
        children: const [
          MyPendingTile()
        ],
      ),
    );
  }
}