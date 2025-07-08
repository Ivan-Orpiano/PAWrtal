import 'package:capstone_app/web/dimensions.dart';
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
      child: GestureDetector(
        onTap: () {
          showDialog(
            context: context,
            barrierDismissible: true,
            builder: (BuildContext context) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < mobileWidth) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
                    });
                  }
                  return Dialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Container(
                      width: 550,
                      height: 1000,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      clipBehavior: Clip.hardEdge,
                      child: const SingleChildScrollView(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Column(
                            children: [
                              SizedBox(height: 16),
                              Text(
                                'Filters',
                                style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
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
                  "Filters",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600
                  ),
                ),
                Icon(
                  Icons.filter_list_rounded
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}