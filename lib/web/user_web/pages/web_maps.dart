import 'package:flutter/material.dart';

class WebMaps extends StatefulWidget {
  const WebMaps({super.key});

  @override
  State<WebMaps> createState() => _WebMapsState();
}

class _WebMapsState extends State<WebMaps> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          "Map to kunware wahahahah 😈😈😈😈😈",
          style: TextStyle(
            fontSize: 20
          ),
        ),
        Center(
          child: Image.asset(
            "lib/images/kapitankalbo.png",
            scale: 0.5,
          ),
        ),
      ],
    );
  }
}