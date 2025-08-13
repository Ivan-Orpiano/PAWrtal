import 'package:flutter/material.dart';

class VetHoverUnderlineText extends StatefulWidget {
  final String text;
  final VoidCallback? onTap;

  const VetHoverUnderlineText({
    super.key,
    required this.text,
      this.onTap,
  });

  @override
  State<VetHoverUnderlineText> createState() => _VetHoverUnderlineTextState();
}

class _VetHoverUnderlineTextState extends State<VetHoverUnderlineText> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Text(
          widget.text,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            decoration: _isHovered ? TextDecoration.underline : TextDecoration.none,
            decorationThickness: 2,
            decorationColor: Colors.black
          ),
        ),
      ),
    );
  }
}