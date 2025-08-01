import 'package:capstone_app/web/user_web/desktop_web/pages/web_clinic_page.dart';
import 'package:capstone_app/web/user_web/responsive_page_handlers/web_clinic_page_handler.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

class WebDashboardTile extends StatefulWidget {
  final double tileWidth;
  final double tileHeight;

  const WebDashboardTile({
    super.key, 
    required this.tileWidth, 
    double ? tileHeight,
    }) : tileHeight = tileHeight ?? tileWidth * 1.4;

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
        borderRadius: BorderRadius.circular(20),
        hoverColor: const Color((0x00000000)),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const WebClinicPageHandler(),
            )
          );
        },
        child: SizedBox(
          width: widget.tileWidth,
          height: widget.tileHeight,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Stack(
                children: [
                  SizedBox(
                    height: widget.tileHeight * 0.7,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.asset(
                        fit: BoxFit.fitHeight,
                        'lib/images/test_image.jpg',
                      ),
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}