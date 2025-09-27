import 'package:capstone_app/web/responsive_layout.dart';
import 'package:capstone_app/web/user_web/desktop_web/pages/web_clinic_page.dart';
import 'package:capstone_app/web/user_web/mobile_web/pages/web_mobile_clinic_page.dart';
import 'package:capstone_app/web/user_web/tablet_web/pages/web_tablet_clinic_page.dart';
import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:flutter/material.dart';

class WebClinicPageHandlerUpdated extends StatefulWidget {
  final Clinic clinic;
  
  const WebClinicPageHandlerUpdated({super.key, required this.clinic});

  @override
  State<WebClinicPageHandlerUpdated> createState() => _WebClinicPageHandlerUpdatedState();
}

class _WebClinicPageHandlerUpdatedState extends State<WebClinicPageHandlerUpdated> {
  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      desktopBody: () => WebClinicPageUpdated(clinic: widget.clinic),
      tabletBody: () => WebTabletClinicPageUpdated(clinic: widget.clinic),
      mobileBody: () => WebMobileClinicPage(clinic: widget.clinic),
    );
  }
}