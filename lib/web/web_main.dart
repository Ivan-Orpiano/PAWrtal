import 'package:capstone_app/mobile/super_admin/WebVersion/super_ad_main_menu_page.dart';
import 'package:capstone_app/web/web_home.dart';
import 'package:flutter/material.dart';

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(); //
  }
}

class WebMain extends StatelessWidget {
  const WebMain({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      scrollBehavior: MyCustomScrollBehavior(),
      //home: const WebHome(),
      home: const SuperAdMainPage(),
    );
  }
}
