import 'package:flutter/material.dart';

class VetProfileDescription extends StatelessWidget {
  const VetProfileDescription({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Text(
                'About this veterinary clinic',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 22
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.only( bottom: 8),
          child: Text(
            "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Etiam ullamcorper tempus nulla, non lobortis sem vulputate at. Nulla consequat dolor risus, quis auctor nisi rutrum at. Vestibulum ac urna sed erat sagittis blandit eget quis nunc. Morbi tristique fermentum nunc eget vehicula. Nulla ac volutpat ex, quis efficitur augue. Nulla sit amet risus sit amet erat feugiat blandit facilisis a libero. Duis ultrices enim sed libero commodo, vel luctus augue imperdiet. Praesent non orci sed augue cursus ultrices. Suspendisse et.",
            textAlign: TextAlign.justify,
            style: TextStyle(
              fontSize: 16,
            ),
          ),
        ),
        Row(
          children: [
            Text(
              "Show more",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline
              ),
            ),
            Icon(
              Icons.keyboard_arrow_right_rounded,
              size: 24,
            ),
          ],
        ),
      ],
    );
  }
}