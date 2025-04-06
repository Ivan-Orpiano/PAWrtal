import 'package:capstone_app/mobile/user/pages/pawmap.dart';
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
    return Scaffold(
      body: ListView(
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
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: SizedBox(
          height: 50,
          width: 120,
          child: FloatingActionButton.extended(
            backgroundColor: Colors.white,
            label: const Text(
              "Show Map",
              style: TextStyle(
                color: Colors.black
              ),
            ),
            icon: const Icon(
              Icons.map_rounded,
              color: Colors.black,
            ),
            onPressed: () {
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(
              //     builder: (context) => const Pawmap(),
              //   )
              // );
            },
          ),
        ),
      ),
    );
  }
}