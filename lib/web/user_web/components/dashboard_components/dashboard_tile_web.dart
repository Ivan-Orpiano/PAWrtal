import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

class DashboardTileWeb extends StatefulWidget {
  const DashboardTileWeb({super.key});

  @override
  State<DashboardTileWeb> createState() => _DashboardTileWebState();
}

class _DashboardTileWebState extends State<DashboardTileWeb> {

  final List <String> images = [
    'lib/images/pfp.jpg',
    'lib/images/pfp.jpg'
  ];

  bool _isClicked = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      height: 355,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.asset(
                  'lib/images/pfp.jpg',
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: IconButton(
                  icon: _isClicked ? 
                  const Icon(
                    Icons.favorite_rounded,
                    color: Colors.red,
                    ) : 
                    const Icon(
                      Icons.favorite_border_rounded,
                      color: Colors.white,                   
                  ),
                  onPressed: () {
                    setState(() {
                      _isClicked = !_isClicked;
                    });
                  },
                ),
              )
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children:[
                Text(
                  "Qualipaws",
                  style: TextStyle(
                    fontWeight: FontWeight.bold
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      Icons.star_rounded,
                    ),
                    Text(
                      "4.95",
                      style: TextStyle(
                        fontWeight: FontWeight.bold
                      ),
                    )
                  ],
                )
              ]
            ),
          ),
          const Row(
            children: [
              Text(
                "3 kilometers away",
                style: TextStyle(
                  color: Colors.grey
                ),
              )
            ],
          ),
          const Row(
            children: [
              Padding(
                padding: EdgeInsets.only(right: 8),
                child: Text(
                  "Services",
                  style: TextStyle(
                    fontWeight: FontWeight.w600
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Icon(
                    Icons.health_and_safety_rounded,
                  ),
                  Icon(
                    Icons.pets_rounded
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