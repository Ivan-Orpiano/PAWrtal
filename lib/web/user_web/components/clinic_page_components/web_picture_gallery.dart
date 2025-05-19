import 'package:flutter/material.dart';

class WebPictureGallery extends StatelessWidget {
  const WebPictureGallery({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32, top: 16),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Column(
              children: [
                Container(
                  height: 520,
                  width: 565,
                  decoration: const BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(20), bottomLeft: Radius.circular(20))
                  ),
                )
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    width: 280,
                    height: 255,
                    color: Colors.grey,
                  ),
                ),
                Container(
                  width: 280,
                  height: 255,
                  color: Colors.grey,
                )
              ],
            ),
          ),
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  width: 280,
                  height: 255,
                  decoration: const BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.only(topRight: Radius.circular(20))
                  ),
                ),
              ),
              Stack(
                children: [
                  Container(
                    width: 280,
                    height: 255,
                    decoration: const BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.only(bottomRight: Radius.circular(20))
                    ),
                  ),
                  Positioned(
                    left: 95,
                      top: 200,
                        child: Container(
                          padding: const EdgeInsets.only(left: 12, right: 12, top: 4, bottom: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              width: 1
                            )
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.grid_view_rounded
                              ),
                              SizedBox(width: 4),
                              Text(
                            "Show all photos",
                            style: TextStyle(
                              fontWeight: FontWeight.w600
                            ),
                          )
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ],
          )
        ],
      ),
    );
  }
}