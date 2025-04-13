import 'package:flutter/material.dart';

class WebNotificationIcon extends StatefulWidget {
  const WebNotificationIcon({super.key});

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
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _closePopup,
              child: Container(),
            ),
          ),
          Positioned(
            right: 80,
            top: 70,
            width: 500,
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
                              'lib/images/pfp.jpg',
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
      ),
    );
  }

  // Widget _popupItem(String text) {
  //   return InkWell(
  //     onTap: () { 
  //       _togglePopup(context);
  //     },
  //     child: Padding(
  //       padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8),
  //       child: Text(
  //         text, style: const TextStyle(
  //           color: Colors.black87
  //         )
  //       ),
  //     ),
  //   );
  // }

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