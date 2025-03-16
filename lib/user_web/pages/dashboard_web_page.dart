import 'package:capstone_app/user/components/dashboard_components/tags.dart';
import 'package:capstone_app/user_web/components/dashboard_components/dashboard_tile_web.dart';
import 'package:flutter/material.dart';

class DashboardWebPage extends StatefulWidget {
  const DashboardWebPage({super.key});

  @override
  State<DashboardWebPage> createState() => _DashboardWebPageState();
}

class _DashboardWebPageState extends State<DashboardWebPage> {
  @override
  Widget build(BuildContext context) {
    return ListView(
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