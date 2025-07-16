import 'package:capstone_app/web/dimensions.dart';
import 'package:capstone_app/web/user_web/desktop_web/login_web/web_login_page.dart';
import 'package:flutter/material.dart';

class WebProfileIcon extends StatefulWidget {
  final double? right;
  final double? top;
  final double? width;
  
  const WebProfileIcon({
    super.key,
    this.right = 75,
    this.top = 70,
    this.width = 250
    });

  @override
  State<WebProfileIcon> createState() => _ProfileIconWebState();
}

class _ProfileIconWebState extends State<WebProfileIcon> {
  OverlayEntry? _overlayEntry;

  void _togglePopup(BuildContext context) {
    if (_overlayEntry == null) {
      _overlayEntry = _createOverlayEntry(context);
      Overlay.of(context).insert(_overlayEntry!);
    } else {
      _closePopup();
    }
  }

  void _closePopup() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry(BuildContext context) {
    return OverlayEntry(
      builder: (context) => LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < mobileWidth) {
            WidgetsBinding.instance.addPostFrameCallback((_){
              _closePopup();
            });
          }
          return Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _closePopup,
                  child: Container(),
                ),
              ),
              Positioned(
                right: widget.right,
                top: widget.top,
                width: widget.width,
                child: Material(
                  elevation: 5,
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const ListTile(
                          leading: CircleAvatar(
                            backgroundImage: AssetImage('lib/images/pfp.jpg'),
                          ),
                          title: Text(
                            "Test",
                          style: TextStyle(color: Colors.black87),
                          ),
                          subtitle: Text(
                            "test@gmail.com",
                            style: TextStyle(color: Colors.black87),
                          ),
                        ),

                        const Divider(color: Colors.black87),

                        SizedBox(
                          width: double.infinity,
                          child: _popupItem(
                            "Settings",
                            () {}
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: _popupItem(
                            "Help", 
                            () {}
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: _popupItem(
                            "Send feedback",
                            () {}
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: _popupItem(
                            "Sign out", () {
                              _closePopup();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const WebLoginPage()
                                )
                              );
                            }
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        }
      )
    );
  }

  Widget _popupItem(String text, VoidCallback onTap) {
    return InkWell(
      onTap: () {
        _closePopup();
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8),
        child: Text(text, style: const TextStyle(color: Colors.black87)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: InkWell(
        onTap: () => _togglePopup(context),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(50),
          child: Image.asset(
            'lib/images/pfp.jpg',
            width: 35,
            height: 35,
          ),
        ),
      ),
    );
  }
}