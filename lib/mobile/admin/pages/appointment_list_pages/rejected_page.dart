import 'package:capstone_app/mobile/admin/components/appointment_tiles/rejected_tile.dart';
import 'package:flutter/material.dart';

class RejectedPage extends StatefulWidget {
  const RejectedPage({super.key});

  @override
  State<RejectedPage> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<RejectedPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 230, 230, 230),
      body: ListView(
        children: const [
          SizedBox(
            height: 15,
          ),
          RejectedTile(),
          RejectedTile(),
          RejectedTile(),
        ],
      ),
    );
  }
}
