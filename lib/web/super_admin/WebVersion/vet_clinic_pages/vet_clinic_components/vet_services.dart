import 'package:flutter/material.dart';

class VetServices extends StatelessWidget {
  const VetServices({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Icon(
          Icons.health_and_safety_outlined,
          size: 26,
        ),
        SizedBox(width: 12),
        Text(
          'Placeholder',
          style: TextStyle(
            fontSize: 18,
            color: Colors.black54
          ),
        )   
      ],
    );
  }
}