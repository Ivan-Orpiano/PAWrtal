import 'package:capstone_app/mobile/admin/components/appointment_tiles/pending_tile.dart';
import 'package:flutter/material.dart';

class PendingPage extends StatefulWidget {
  const PendingPage({super.key});

  @override
  State<PendingPage> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<PendingPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 230, 230, 230),
      body: ListView(
        children: const [
          SizedBox(
            height: 15,
          ),
          PendingTile(),
          PendingTile(),
          PendingTile(),
          PendingTile(),
          PendingTile(),
        ],
      ),
    );
  }
}
