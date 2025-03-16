import 'package:flutter/material.dart';

class PetsWebPage extends StatefulWidget {
  const PetsWebPage({super.key});

  @override
  State<PetsWebPage> createState() => _PetsWebPageState();
}

class _PetsWebPageState extends State<PetsWebPage> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        "Pets"
      ),
    );
  }
}