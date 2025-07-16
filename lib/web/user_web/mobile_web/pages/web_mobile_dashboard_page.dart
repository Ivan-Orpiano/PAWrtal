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
        children: [
          const Row(
            children: [
              Expanded(child: WebSearchBar(width: 300)),
              SizedBox(width: 16),
              WebFilter()
            ],
          ),
          const SizedBox(height: 16),
          //const WebTags(),
          const SizedBox(height: 16),
          LayoutBuilder(
              builder: (context, constraints) {
              double screenWidth = constraints.maxWidth;
              const double spacing = 25;
              const double minTileWidth = 200;
              int tilesPerRow = (screenWidth / (minTileWidth + spacing)).floor();
              tilesPerRow = tilesPerRow.clamp(1, 7); 
              double tileWidth = (screenWidth - (spacing * (tilesPerRow - 1))) / tilesPerRow;
              return Wrap(
                spacing: spacing,
                runSpacing: 10,
                children: List.generate(20, (index) => WebDashboardTile(tileWidth: tileWidth, tileHeight: tileWidth * 1.4,),
                ),
              );
            },
          ),
        ],
      )
    );
  }
}