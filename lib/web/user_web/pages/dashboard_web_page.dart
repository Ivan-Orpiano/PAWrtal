import 'package:capstone_app/web/user_web/components/dashboard_components/dashboard_tile_web.dart';
import 'package:capstone_app/web/user_web/components/dashboard_components/web_tags.dart';
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
      padding: const EdgeInsets.only(left: 60, right: 60, top: 16),
      children: const [
        WebTags(),
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