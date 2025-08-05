import 'package:capstone_app/web/dimensions.dart';
import 'package:flutter/material.dart';

class WebNotificationIcon extends StatefulWidget {
  final double? right;
  final double? top;
  final double? width;

  const WebNotificationIcon({
    super.key,
    this.right = 125,
    this.top= 70,
    this.width = 500
    });

  @override
  State<WebNotificationIcon> createState() => _NotificationIconWebState();
}

class _NotificationIconWebState extends State<WebNotificationIcon> {

  OverlayEntry? _overlayEntry;

  void _togglePopup(BuildContext context) {
    if (_overlayEntry == null) {
      _overlayEntry = _createOverlayEntry();
      Overlay.of(context).insert(_overlayEntry!);
    } else {
      _closePopup();
    }
  }

  void _closePopup() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(left: 8),
                              child: Text(
                                "Notifications",
                                style: TextStyle(
                                  fontSize: 18
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: IconButton(
                                onPressed: () {},
                                icon: const Icon(Icons.settings_rounded),
                              ),
                            )
                          ],
                        ),
                        const Divider(
                          color: Colors.black87
                        ),
                        InkWell(
                          onTap: () {
                            _togglePopup(context);
                          },
                          child: const SizedBox(
                            width: double.infinity,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundImage: AssetImage(
                                  'lib/images/test_image.jpg',
                                ),
                              ),
                              title: Text(
                                'title kunware qualipaws'
                              ),
                              subtitle: Text(
                                'subtitle kunware 10:30 ng umaga'
                              ),
                            )
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
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: IconButton(
        icon: const Icon(Icons.notifications_rounded),
        onPressed: () => _togglePopup(context),
      ),
    );
  }
}