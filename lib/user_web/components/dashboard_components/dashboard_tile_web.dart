import 'package:flutter/material.dart';

class DashboardTileWeb extends StatefulWidget {
  const DashboardTileWeb({super.key});

  @override
  State<DashboardTileWeb> createState() => _DashboardTileWebState();
}

class _DashboardTileWebState extends State<DashboardTileWeb> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 430,
      height: 325,
      color: Colors.grey,
      child: Column(
        children: [
          SizedBox(
            height: 240,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'lib/images/test_image.jpg',
                fit: BoxFit.fill,
                width: double.infinity,
              ),
            ),
          ),
          Row(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(50),
                    child: Image.asset(
                      'lib/images/pfp.jpg',
                      width: 40,
                      height: 40,
                    ),
                  )
                ],
              ),
              const Column(
                children: [
                  Text(
                    "Qualipaws"
                  )
                ],
              )
            ],
          )
        ],
      ),
    );
  }
}