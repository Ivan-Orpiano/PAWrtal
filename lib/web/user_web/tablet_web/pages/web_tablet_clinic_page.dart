import 'package:flutter/material.dart';

class WebTabletClinicPage extends StatefulWidget {
  const WebTabletClinicPage({super.key});

  @override
  State<WebTabletClinicPage> createState() => _WebTabletClinicPageState();
}

class _WebTabletClinicPageState extends State<WebTabletClinicPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          "Tablet"
        ),
      ),
    );
  }
}