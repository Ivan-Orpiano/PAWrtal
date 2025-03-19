import 'package:flutter/material.dart';

class MessagesWebPage extends StatefulWidget {
  const MessagesWebPage({super.key});

  @override
  State<MessagesWebPage> createState() => _MessagesWebPageState();
}

class _MessagesWebPageState extends State<MessagesWebPage> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        "Messages"
      ),
    );
  }
}