import 'package:capstone_app/web/responsive_layout.dart';
import 'package:capstone_app/web/user_web/desktop_web/user_web/pages/web_clinic_page.dart';
import 'package:capstone_app/web/user_web/mobile_web/pages/web_mobile_clinic_page.dart';
import 'package:capstone_app/web/user_web/tablet_web/pages/web_tablet_clinic_page.dart';
import 'package:flutter/material.dart';

class WebClinicPageHandler extends StatefulWidget {
  const WebClinicPageHandler({super.key});

  @override
  State<WebClinicPageHandler> createState() => _WebClinicPageHandlerState();
}

class _WebClinicPageHandlerState extends State<WebClinicPageHandler> {
  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      desktopBody: () => const WebClinicPage(),
      tabletBody: () => const WebTabletClinicPage(),
      mobileBody: () => const WebMobileClinicPage(),
    );
  }
}