import 'package:flutter/material.dart';

class PetsNextPage extends StatefulWidget {
  const PetsNextPage({super.key});

  @override
  State<PetsNextPage> createState() => _PetsNextPageState();
}

class _PetsNextPageState extends State<PetsNextPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_left_rounded),
          iconSize: 30,
          onPressed: () {
            Navigator.pop(context);
            
          },
        ),
      ),
    );
  }
}