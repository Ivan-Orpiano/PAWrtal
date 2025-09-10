import 'package:flutter/material.dart';

class SuperAdminSearchBar extends StatelessWidget {
  const SuperAdminSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(top: 10, left: 10, right: 10),
        child: Container(
          decoration: BoxDecoration(
              color: const Color.fromRGBO(248, 253, 255, 1),
              borderRadius: BorderRadius.circular(50),
              boxShadow: [
                BoxShadow(
                    color: Colors.grey.shade400,
                    blurRadius: 2,
                    spreadRadius: 1,
                    offset: const Offset(0, 2))
              ]),
          child: const Padding(
            padding: EdgeInsets.only(top: 5, left: 10, right: 10, bottom: 2),
            child: TextField(
              decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: "Search",
                  prefixIcon: Icon(Icons.search)),
            ),
          ),
        ),
      ),
    );
  }
}
