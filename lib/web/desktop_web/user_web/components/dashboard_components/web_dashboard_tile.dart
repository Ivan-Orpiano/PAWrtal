import 'package:capstone_app/web/desktop_web/user_web/pages/web_clinic_page.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

class WebDashboardTile extends StatefulWidget {
  final double tileWidth ;
  const WebDashboardTile({super.key, required this.tileWidth});

  @override
  State<WebDashboardTile> createState() => _DashboardTileWebState();
}

class _DashboardTileWebState extends State<WebDashboardTile> {

  bool _isClicked = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 30),
      child: InkWell(
        hoverColor: const Color((0x00000000)),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const WebClinicPage(),
            )
          );
        },
        child: SizedBox(
          width: widget.tileWidth,
          height: widget.tileWidth * 1.4,
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
        ),
      ),
    );
  }
}