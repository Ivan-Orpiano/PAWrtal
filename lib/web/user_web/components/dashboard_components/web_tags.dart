import 'package:flutter/material.dart';

class WebTags extends StatefulWidget {
  const WebTags({super.key});

  @override
  State<WebTags> createState() => _WebTagsState();
}

class _WebTagsState extends State<WebTags> {

  int _selectedindex = 0;

  final List <String> tags = [
    "All",
    "Nearby",
    "Popular",
    "Recommended"
  ];

  double _getTextWidth(String text) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();
  return textPainter.width;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: tags.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedindex = index;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Column(
                    children: [
                      Text(
                        tags[index],
                        style: TextStyle(
                          fontSize: 16,
                          color: _selectedindex == index ? Colors.black : Colors.grey,
                          fontWeight: _selectedindex == index ? FontWeight.bold : FontWeight.normal
                        ),
                      ),
                      if (_selectedindex == index )
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        height: 2,
                        width: _getTextWidth(tags[index]),
                        color: Colors.black,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}