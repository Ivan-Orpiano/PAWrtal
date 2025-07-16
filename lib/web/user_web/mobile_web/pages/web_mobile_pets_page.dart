import 'package:flutter/material.dart';

class WebMobilePetsPage extends StatefulWidget {
  const WebMobilePetsPage({super.key});

  @override
  State<WebMobilePetsPage> createState() => _WebMobilePetsPageState();
}

class _WebMobilePetsPageState extends State<WebMobilePetsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          "pets"
        ),
      ),
    );
  }
}