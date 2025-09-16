import 'package:flutter/material.dart';

class WebSearchBar extends StatefulWidget {
  final double? width;
  final Function(String)? onSearchChanged;
  
  const WebSearchBar({
    super.key, 
    this.width, 
    this.onSearchChanged,
  });

  @override
  State<WebSearchBar> createState() => _WebSearchBarState();
}

class _WebSearchBarState extends State<WebSearchBar> {
  final TextEditingController _controller = TextEditingController();
  bool _showClear = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {
        _showClear = _controller.text.isNotEmpty;
      });
      // Notify parent about search changes
      if (widget.onSearchChanged != null) {
        widget.onSearchChanged!(_controller.text);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width ?? 380,
      height: 50,
      child: TextField(
        controller: _controller,
        decoration: InputDecoration(
          hintText: 'Search for clinics, services, locations...',
          hintStyle: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Colors.black54),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(
              color: Colors.black,
              width: 1.5,
            ),
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Colors.grey,
          ),
          suffixIcon: _showClear 
            ? IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  color: Colors.grey,
                ),
                onPressed: () {
                  _controller.clear();
                  setState(() {
                    _showClear = false;
                  });
                  // Notify parent about cleared search
                  if (widget.onSearchChanged != null) {
                    widget.onSearchChanged!('');
                  }
                },
              )
            : null,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }
}