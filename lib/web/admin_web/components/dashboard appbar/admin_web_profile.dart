import 'package:capstone_app/utils/logout_helper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class AdminWebProfile extends StatefulWidget {
  final double? right;
  final double? top;
  final double? width;

  const AdminWebProfile(
      {super.key, this.right = 75, this.top = 70, this.width = 250});

  @override
  State<AdminWebProfile> createState() => _ProfileIconWebState();
}

class _ProfileIconWebState extends State<AdminWebProfile> {
  OverlayEntry? _overlayEntry;
  final GetStorage storage = GetStorage();

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

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                _closePopup();
                await LogoutHelper.logout();
              },
              child: const Text(
                'Logout',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  OverlayEntry _createOverlayEntry(BuildContext context) {
    final userEmail = storage.read("email") ?? "admin@example.com";
    final userName = storage.read("name") ?? "Admin User";
    final userRole = storage.read("role") ?? "admin";

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
                    ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color.fromARGB(255, 81, 115, 153),
                        child: Icon(
                          Icons.person,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(
                        userName,
                        style: const TextStyle(color: Colors.black87),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userEmail,
                            style: const TextStyle(color: Colors.black87),
                          ),
                          Text(
                            userRole.toUpperCase(),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(color: Colors.black87),
                    SizedBox(
                      width: double.infinity,
                      child: _popupItem("Profile", () {
                        Get.snackbar(
                          'Info',
                          'Profile page coming soon',
                          backgroundColor: Colors.blue,
                          colorText: Colors.white,
                        );
                      }),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: _popupItem("Settings", () {
                        Get.snackbar(
                          'Info',
                          'Settings page coming soon',
                          backgroundColor: Colors.blue,
                          colorText: Colors.white,
                        );
                      }),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: _popupItem("Help", () {
                        Get.snackbar(
                          'Info',
                          'Help page coming soon',
                          backgroundColor: Colors.blue,
                          colorText: Colors.white,
                        );
                      }),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: _popupItem("Send feedback", () {
                        Get.snackbar(
                          'Info',
                          'Feedback form coming soon',
                          backgroundColor: Colors.blue,
                          colorText: Colors.white,
                        );
                      }),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: _popupItem("Sign out", () {
                        _showLogoutDialog(context);
                      }),
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
        child: const CircleAvatar(
          backgroundColor: Color.fromARGB(255, 81, 115, 153),
          radius: 17.5,
          child: Icon(
            Icons.person,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }
}

// import 'package:flutter/material.dart';

// class AdminWebProfile extends StatefulWidget {
//   final double? right;
//   final double? top;
//   final double? width;

//   const AdminWebProfile(
//       {super.key, this.right = 75, this.top = 70, this.width = 250});

//   @override
//   State<AdminWebProfile> createState() => _ProfileIconWebState();
// }

// class _ProfileIconWebState extends State<AdminWebProfile> {
//   OverlayEntry? _overlayEntry;

//   void _togglePopup(BuildContext context) {
//     if (_overlayEntry == null) {
//       _overlayEntry = _createOverlayEntry(context);
//       Overlay.of(context).insert(_overlayEntry!);
//     } else {
//       _closePopup();
//     }
//   }

//   void _closePopup() {
//     _overlayEntry?.remove();
//     _overlayEntry = null;
//   }

//   OverlayEntry _createOverlayEntry(BuildContext context) {
//     return OverlayEntry(
//       builder: (context) => Stack(
//         children: [
//           Positioned.fill(
//             child: GestureDetector(
//               behavior: HitTestBehavior.opaque,
//               onTap: _closePopup,
//               child: Container(),
//             ),
//           ),
//           Positioned(
//             right: widget.right,
//             top: widget.top,
//             width: widget.width,
//             child: Material(
//               elevation: 5,
//               borderRadius: BorderRadius.circular(10),
//               color: Colors.white,
//               child: Padding(
//                 padding: const EdgeInsets.only(top: 10, bottom: 10),
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const ListTile(
//                       leading: CircleAvatar(
//                         backgroundImage: AssetImage('lib/images/pfp.jpg'),
//                       ),
//                       title: Text(
//                         "Test",
//                         style: TextStyle(color: Colors.black87),
//                       ),
//                       subtitle: Text(
//                         "test@gmail.com",
//                         style: TextStyle(color: Colors.black87),
//                       ),
//                     ),
//                     const Divider(color: Colors.black87),
//                     SizedBox(
//                       width: double.infinity,
//                       child: _popupItem("Settings", () {}),
//                     ),
//                     SizedBox(
//                       width: double.infinity,
//                       child: _popupItem("Help", () {}),
//                     ),
//                     SizedBox(
//                       width: double.infinity,
//                       child: _popupItem("Send feedback", () {}),
//                     ),
//                     SizedBox(
//                       width: double.infinity,
//                       child: _popupItem("Sign out", () {
//                         _closePopup();
//                         // Navigator.push(
//                         //     context,
//                         //     MaterialPageRoute(
//                         //         builder: (context) => const WebLoginPage()));
//                       }),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _popupItem(String text, VoidCallback onTap) {
//     return InkWell(
//       onTap: () {
//         _closePopup();
//         onTap();
//       },
//       child: Padding(
//         padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8),
//         child: Text(text, style: const TextStyle(color: Colors.black87)),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.only(right: 16),
//       child: InkWell(
//         onTap: () => _togglePopup(context),
//         child: ClipRRect(
//           borderRadius: BorderRadius.circular(50),
//           child: Image.asset(
//             'lib/images/pfp.jpg',
//             width: 35,
//             height: 35,
//           ),
//         ),
//       ),
//     );
//   }
// }


