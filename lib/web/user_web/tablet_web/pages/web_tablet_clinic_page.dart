import 'package:capstone_app/web/user_web/desktop_web/pages/web_clinic_page.dart';
import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:flutter/material.dart';

class WebTabletClinicPageUpdated extends StatefulWidget {
  final Clinic clinic;
  
  const WebTabletClinicPageUpdated({super.key, required this.clinic});

  @override
  State<WebTabletClinicPageUpdated> createState() => _WebTabletClinicPageUpdatedState();
}

class _WebTabletClinicPageUpdatedState extends State<WebTabletClinicPageUpdated> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WebClinicPageUpdated(clinic: widget.clinic),
    );
  }
}