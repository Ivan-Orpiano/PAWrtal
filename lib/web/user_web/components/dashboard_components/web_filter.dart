import 'package:flutter/material.dart';

class WebFilter extends StatefulWidget {
  const WebFilter({super.key});

  @override
  State<WebFilter> createState() => _WebFilterState();
}

class _WebFilterState extends State<WebFilter> {

  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: MouseRegion(
        onEnter: (_) {
          if (!_isHovered) {
            setState(() {
              _isHovered = true;
            });
          }
        },
        onExit: (_) {
          if (_isHovered) {
            setState(() {
              _isHovered = false;
            });
          }
        },
        child: AnimatedContainer(
          duration: const Duration(microseconds: 0),
          padding: const EdgeInsets.all(8),
          height: 50,
          width: 100,
          decoration: BoxDecoration(
            color: _isHovered ? Colors.grey.shade200: Colors.transparent,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: _isHovered? Colors.black : const Color.fromARGB(255, 121, 116, 126)
            )
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text(
                "Filters"
              ),
              Icon(
                Icons.filter_list_rounded
              )
            ],
          ),
        ),
      ),
    );
  }
}