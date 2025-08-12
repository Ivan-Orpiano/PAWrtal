import 'package:flutter/material.dart';

class VetProfileAlbum extends StatefulWidget {
  const VetProfileAlbum({super.key});

  @override
  State<VetProfileAlbum> createState() => _VetProfileAlbumState();
}

class _VetProfileAlbumState extends State<VetProfileAlbum> {
  @override
  Widget build(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 16),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
      /// Large left box
        Flexible(
          flex: 3,
          child: Container(
            height: 520,
            decoration: const BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                bottomLeft: Radius.circular(20),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        /// Middle column (2 stacked boxes)
        Flexible(
          flex: 2,
          child: Column(
            children: [
              Container(
                height: 255,
                margin: const EdgeInsets.only(bottom: 10),
                decoration: const BoxDecoration(
                  color: Colors.grey,
                ),
              ),
              Container(
                height: 255,
                decoration: const BoxDecoration(
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),

        /// Right column (2 stacked boxes with button)
        Flexible(
          flex: 2,
          child: Column(
            children: [
              Container(
                height: 255,
                margin: const EdgeInsets.only(bottom: 10),
                decoration: const BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(20),
                  ),
                ),
              ),
              Stack(
                children: [
                  Container(
                    height: 255,
                    decoration: const BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.only(
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: Padding(
                      padding: const EdgeInsets.only(top:200),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(width: 1),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.grid_view_rounded),
                            SizedBox(width: 4),
                            Text(
                              "Show all photos",
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
  }
}