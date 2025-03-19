import 'package:capstone_app/mobile/admin/components/appointment_tiles/accepted_tile.dart';
import 'package:flutter/material.dart';

class AcceptedPage extends StatefulWidget {
  const AcceptedPage({super.key});

  @override
  State<AcceptedPage> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<AcceptedPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 230, 230, 230),
      body: ListView(
        children: const [
          SizedBox(
            height: 15,
          ),
          AcceptedTile(),
          AcceptedTile(),
          AcceptedTile(),
        ],
      ),
    );
  }
}
