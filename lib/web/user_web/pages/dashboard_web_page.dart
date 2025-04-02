import 'package:capstone_app/mobile/user/components/dashboard_components/tags.dart';
import 'package:capstone_app/web/user_web/components/dashboard_components/dashboard_tile_web.dart';
import 'package:flutter/material.dart';

class WebDashboardPage extends StatefulWidget {
  const WebDashboardPage({super.key});

  @override
  State<WebDashboardPage> createState() => _WebDashboardPageState();
}

class _WebDashboardPageState extends State<WebDashboardPage> {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.only(left: 60, right: 60),
      children: const [
        MyTags(),
        Padding(
          padding: EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Wrap(
              direction: Axis.horizontal,
              spacing: 20,
              runSpacing: 30,
              children: [
                DashboardTileWeb(),
              ],
            ),
          ),
        ),
      ]
    );
  }
}