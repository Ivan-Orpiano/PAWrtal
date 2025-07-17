import 'package:flutter/material.dart';

class WebTags extends StatefulWidget {
  const WebTags({super.key});

  @override
  State<WebTags> createState() => _WebTagsState();
}

class _WebTagsState extends State<WebTags> {

  final ScrollController _scrollController = ScrollController();
  int _selectedindex = 0;
  bool _showLeft = false;
  bool _showRight = true;
  bool _isHoveredLeft = false;
  bool _isHoveredRight = false;

  final List <String> tags = [
    "All",
    "Favourites",
    "Nearby",
    "Popular",
    "Recommended",
    "Testing",
    "Testing",
    "Testing",
    "Testing",
    "Testing",
    "Testing",
    "Testing",
    "Testing",
    "Testing",
    "Testing",
    "Testing",
    "Testing",
    "Testing",
    "Testing",
    "Testing",
    "Testing",
    "Testing",
    "Testing",
    "Testing",
    "Testing",
    "End"
  ];

  double _getTextWidth(String text) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();
  return textPainter.width;
  }

  void _scrollListener() {
    final max = _scrollController.position.maxScrollExtent;
    final offset = _scrollController.offset;

    setState(() {
      _showLeft = offset > 0;
      _showRight = offset < max;
    });
  }

  @override
  void initState () {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollLeft () {
    _scrollController.animateTo(
      _scrollController.offset - 250,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _scrollRight () {
    _scrollController.animateTo(
      _scrollController.offset + 250,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut
    );
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SizedBox(
        height: 50,
        child: Stack(
          children: [
            Positioned.fill(
              child: ListView.builder(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                itemCount: tags.length,
                //padding: const EdgeInsets.symmetric(horizontal: 40),
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

            //left button
            if (_showLeft)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.white, Colors.white.withOpacity(0)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
                child: MouseRegion(
                  onEnter: (_) {
                    if (!_isHoveredLeft) {
                      setState(() {
                        _isHoveredLeft = true;
                      });
                    }
                  },
                  onExit: (_) {
                    if (_isHoveredLeft) {
                      setState(() {
                        _isHoveredLeft = false;
                      });
                    }
                  },
                  child: AnimatedContainer(
                    height: 35,
                    width: 35,
                    duration: const Duration(milliseconds: 0),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color.fromARGB(255, 121, 116, 126)
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _isHoveredLeft ? Colors.grey.shade300 : Colors.transparent,
                            blurRadius: _isHoveredLeft ? 1 : 0,
                            spreadRadius: _isHoveredLeft ? 1 : 0,
                            offset: _isHoveredLeft ? const Offset(0, 2) : Offset.zero
                          )
                        ]
                      ),
                    child: IconButton(
                      hoverColor: Colors.transparent,
                      onPressed: _scrollLeft,
                      icon: const Icon(
                        Icons.arrow_back_ios_rounded,
                        size: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            //right button
            if (_showRight) 
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                    colors: [
                      Colors.white,
                      Colors.white.withOpacity(0)
                    ],
                  )
                ),
                child: MouseRegion(
                  onEnter: (_) {
                    if (!_isHoveredRight) {
                      setState(() {
                        _isHoveredRight = true;
                      });
                    }
                  },
                  onExit: (_) {
                    if (_isHoveredRight) {
                      setState(() {
                        _isHoveredRight = false;
                      });
                    }
                  },
                  child: AnimatedContainer(
                    height: 35,
                    width: 35,
                    duration: const  Duration(microseconds: 0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color.fromARGB(255, 121, 116, 126)
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _isHoveredRight ? Colors.grey.shade300 : Colors.transparent,
                          blurRadius: _isHoveredRight ? 1 : 0,
                          spreadRadius: _isHoveredRight ? 1 : 0,
                          offset: _isHoveredRight ? const Offset(0, 2) : Offset.zero
                        )
                      ]
                    ),
                    child: IconButton(
                      hoverColor: Colors.transparent,
                      onPressed: _scrollRight,
                      icon: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                      ),
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}