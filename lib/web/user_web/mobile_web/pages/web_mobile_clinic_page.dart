import 'package:flutter/material.dart';

class WebMobileClinicPage extends StatefulWidget {
  const WebMobileClinicPage({super.key});

  @override
  State<WebMobileClinicPage> createState() => _WebMobileClinicPageState();
}

class _WebMobileClinicPageState extends State<WebMobileClinicPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          "Mobile"
        ),
      ),
    );
  }
}