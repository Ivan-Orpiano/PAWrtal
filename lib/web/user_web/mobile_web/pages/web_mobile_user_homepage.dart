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
        toolbarHeight: 80,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true, 
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: Colors.grey[400],
            height: 1,
          ),
        ),
        title: InkWell(
          child: Image.asset(
            'lib/images/PAWrtal_logo.png',
            scale: 2.5,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications),
          )
        ],
      ),
      drawer: const Drawer(),
    );
  }
}