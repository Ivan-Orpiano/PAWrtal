import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

class GnavBar extends StatelessWidget {
  void Function(int)? onTabChange;
  GnavBar({super.key, required this.onTabChange});

  @override
  Widget build(BuildContext context) {
    return GNav(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
        color: Colors.black,
        backgroundColor: const Color.fromARGB(255, 248, 253, 255),
        activeColor: const Color.fromARGB(255, 81, 115, 153),
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        onTabChange: (value) => onTabChange!(value),
        tabs: const [
          GButton(
            icon: Icons.home,
            text: "",
          ),
          GButton(
            icon: Icons.list,
            text: "",
          ),
          GButton(
            icon: Icons.message,
            text: "",
          ),
          GButton(
            icon: Icons.add,
            text: "",
          ),
        ]);
  }
}
