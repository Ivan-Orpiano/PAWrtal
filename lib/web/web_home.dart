import 'package:capstone_app/web/user_web/desktop_web/pages/web_user_home_page.dart';
import 'package:capstone_app/web/user_web/mobile_web/pages/web_mobile_user_homepage.dart';
import 'package:capstone_app/web/responsive_layout.dart';
import 'package:capstone_app/web/user_web/tablet_web/pages/web_tablet_user_homepage.dart';
import 'package:flutter/material.dart';

class WebHome extends StatefulWidget {
  const WebHome({super.key});

  @override
  State<WebHome> createState() => _WebHomeState();
}

class _WebHomeState extends State<WebHome> {
  int _selectedIndex = 0;

  void _onItemSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ResponsiveLayout(
        mobileBody: () => WebMobileUserHomepage(
          selectedIndex: _selectedIndex,
          onItemSelected: _onItemSelected,
        ),
        tabletBody : () => WebTabletUserHomepage(
          selectedIndex: _selectedIndex,
          onItemSelected: _onItemSelected,
        ),
        desktopBody: () =>  WebUserHomePage(
          selectedIndex: _selectedIndex,
          onItemSelected: _onItemSelected
        ),
      )
    );
  }
}