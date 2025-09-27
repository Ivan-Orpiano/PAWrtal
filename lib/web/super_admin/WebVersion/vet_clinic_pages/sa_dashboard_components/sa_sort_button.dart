import 'package:flutter/material.dart';

class SuperAdminSortButton extends StatelessWidget {
  const SuperAdminSortButton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      height: 50,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color.fromRGBO(248, 253, 255, 1),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade400,
              blurRadius: 2,
              spreadRadius: 1,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          icon: const Icon(Icons.sort_rounded),
          onPressed: () {},
          iconSize: 26,
        ),
      ),
    );
  }
}
