import 'package:capstone_app/user/components/general_components/notif_button.dart';
import 'package:flutter/material.dart';

class MyAppBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  final Size preferredSize;

  const MyAppBar({super.key})
  
  // to adjust appbar height  
  : preferredSize = const Size.fromHeight(50.0);

  @override

  Widget build(BuildContext context) {
    return AppBar(
      centerTitle: true,
      primary: true,
      title: Image.asset(
        'lib/images/PAWrtal_logo.png',
        width: 180, 
        fit: BoxFit.contain,
        
      ),
      leading: Builder(
        builder: (context) {
          return IconButton(
            icon: const Icon(Icons.menu_outlined),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          );
        }
      ),
      actions: const [
        MyNotifButton()
      ],
    );
  }
}