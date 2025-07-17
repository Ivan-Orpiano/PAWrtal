import 'package:flutter/material.dart';

class WebShareButton extends StatefulWidget {
  const WebShareButton({super.key});

  @override
  State<WebShareButton> createState() => _WebShareButtonState();
}

class _WebShareButtonState extends State<WebShareButton> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      customBorder: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10)
      ),
      onTap: () {
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (BuildContext context) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)
              ),
              insetPadding: const EdgeInsets.symmetric(horizontal: 100, vertical: 60),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.3,
                height: 400,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20)
                ),
                clipBehavior: Clip.hardEdge,
                child: Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16),
                  child: Column(
                    children: [
                      
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          InkWell(
                            onTap: () {
                              Navigator.pop(context);
                            },
                            child: const Icon(
                              Icons.close_rounded
                            )
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            );
          }
        );
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        child: const Row(
          children: [
            Icon(
              Icons.share_rounded,
              size: 20,
            ),
        
            SizedBox(width: 8),
        
            Text(
              "Share",
              style: TextStyle(
                decoration: TextDecoration.underline,
                fontWeight: FontWeight.w600,
                fontSize: 14
              ),
            ),
          ],
        ),
      ),
    );
  }
}