import 'package:flutter/material.dart';

class WebMobileUserHomepage extends StatefulWidget {
  const WebMobileUserHomepage({super.key});

  @override
  State<WebMobileUserHomepage> createState() => _WebMobileUserHomePageState();
}

class _WebMobileUserHomePageState extends State<WebMobileUserHomepage> {
  int _selectedIndex = 0;

    final List<Widget> _pages = [

    ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
      ),
    );
  }
}