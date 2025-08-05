import 'package:capstone_app/web/user_web/components/data.dart';
import 'package:capstone_app/web/user_web/desktop_web/components/dashboard_components/web_dashboard_tile.dart';
import 'package:capstone_app/web/user_web/desktop_web/components/dashboard_components/web_filter.dart';
import 'package:capstone_app/web/user_web/desktop_web/components/dashboard_components/web_search_bar.dart';
import 'package:capstone_app/web/user_web/desktop_web/components/dashboard_components/web_tags.dart';
import 'package:flutter/material.dart';

class WebMobileDashboardPage extends StatefulWidget {
  const WebMobileDashboardPage({super.key});

  @override
  State<WebMobileDashboardPage> createState() => _WebMobileDashboardPageState();
}

class _WebMobileDashboardPageState extends State<WebMobileDashboardPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        children: const [
          Row(
            children: [
              Expanded(child: WebSearchBar(width: 300)),
              SizedBox(width: 16),
              WebFilter()
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              WebTags(),
            ],
          ),
          SizedBox(height: 16),
          DashboardTiles()
        ],
      )
    );
  }
}