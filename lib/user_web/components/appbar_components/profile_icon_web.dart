import 'package:flutter/material.dart';

class ProfileIconWeb extends StatefulWidget {
  const ProfileIconWeb({super.key});

  @override
  State<ProfileIconWeb> createState() => _ProfileIconWebState();
}

class _ProfileIconWebState extends State<ProfileIconWeb> {
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
            right: 20,
            top: 70,
            width: 250,
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
                        backgroundImage: AssetImage(
                          'lib/images/pfp.jpg'
                        ),
                      ),
                      title: Text(
                        "Test",
                        style: TextStyle(
                          color: Colors.black87
                        ),
                      ),
                      subtitle: Text(
                        "test@gmail.com",
                        style: TextStyle(
                          color: Colors.black87
                        ),
                      ),
                    ),
                    const Divider(
                      color: Colors.black87
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: _popupItem(
                        "Settings"
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: _popupItem(
                        "Help"
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: _popupItem(
                        "Send feedback"
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: _popupItem(
                        "Sign out"
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

  Widget _popupItem(String text) {
    return InkWell(
      onTap: () {
        _closePopup();
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
            width: 40,
            height: 40,
          ),
        ),
      ),
    );
  }
}