import 'package:capstone_app/web/tablet_web/pages/web_tablet_user_homepage.dart';
import 'package:flutter/material.dart';

class TabletBody extends StatefulWidget {
  const TabletBody({super.key});

  @override
  State<TabletBody> createState() => _TabletBodyState();
}

class _TabletBodyState extends State<TabletBody> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: WebTabletUserHomepage(),
    );
  }
}