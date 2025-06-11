import 'package:capstone_app/web/desktop_body.dart';
import 'package:capstone_app/web/mobile_body.dart';
import 'package:capstone_app/web/responsive_layout.dart';
import 'package:flutter/material.dart';

class WebHome extends StatefulWidget {
  const WebHome({super.key});

  @override
  State<WebHome> createState() => _WebHomeState();
}

class _WebHomeState extends State<WebHome> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: ResponsiveLayout(
        mobileBody: MobileBody(),
        desktopBody: DesktopBody(),
      )
    );
  }
}