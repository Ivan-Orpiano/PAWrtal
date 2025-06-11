import 'package:capstone_app/mobile/user/pages/pawmap.dart';
import 'package:capstone_app/web/user_web/components/dashboard_components/web_dashboard_tile.dart';
import 'package:capstone_app/web/user_web/components/dashboard_components/web_filter.dart';
import 'package:capstone_app/web/user_web/components/dashboard_components/web_search_bar.dart';
import 'package:capstone_app/web/user_web/components/dashboard_components/web_tags.dart';
import 'package:capstone_app/web/user_web/pages/web_maps.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class WebDashboardPage extends StatefulWidget {
  const WebDashboardPage({super.key});

  @override
  State<WebDashboardPage> createState() => _WebDashboardPageState();
}

class _WebDashboardPageState extends State<WebDashboardPage> {

  bool _showMap = false;

  Widget _buildMapView() {
    return const SizedBox(
      height: 770,
      child: WebMaps()
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: ListView(
      padding: const EdgeInsets.only(left: 65, right: 65, top: 16),
        children:  [
        const Row(
          children: [
            WebTags(),
            SizedBox(width: 12),
            WebFilter(),
            WebSearchBar(),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 8, top: 16),
          child: _showMap ? _buildMapView() : 
          const SingleChildScrollView(
            child: Wrap(
              direction: Axis.horizontal,
              spacing: 25,
              runSpacing: 40,
              children: [
                WebDashboardTile(),
                WebDashboardTile(),
                WebDashboardTile(),
                WebDashboardTile(),
                WebDashboardTile(),
                WebDashboardTile(),
              ],
            ),
          )
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
            label: _showMap ? const Text("Show List", style: TextStyle(color: Colors.black),) 
            : const Text("Show Maps", style: TextStyle(color: Colors.black),
            ),
            icon: _showMap ? const Icon(Icons.list_rounded, color: Colors.black) 
            : const Icon(Icons.map_rounded, color: Colors.black,),
            onPressed: () {
              setState(() {
                _showMap = !_showMap;
              });
            },
          ),
        ),
      ),
    );
  }
}