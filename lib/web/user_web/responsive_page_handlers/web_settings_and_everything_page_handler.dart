import 'package:capstone_app/mobile/user/pages/settings_and_everything_page.dart';
import 'package:capstone_app/web/responsive_layout.dart';
import 'package:capstone_app/web/user_web/desktop_web/pages/web_settings_and_everything_page.dart';
import 'package:flutter/material.dart';

class WebSettingsAndEverythingPageHandler extends StatelessWidget {
  final int initialIndex;
  
  const WebSettingsAndEverythingPageHandler({
    super.key, 
    this.initialIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      desktopBody: () => WebSettingsAndEverythingPage(initialIndex: initialIndex),
      tabletBody: () => WebSettingsAndEverythingPage(initialIndex: initialIndex),
      mobileBody: () => SettingsAndEverythingPage(initialIndex: initialIndex),
    );
  }
}