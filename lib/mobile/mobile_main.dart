import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:capstone_app/pages/routes/app_pages.dart';

class MobileMain extends StatefulWidget {
  const MobileMain({super.key});

  @override
  State<MobileMain> createState() => _MobileMainState();
}

class _MobileMainState extends State<MobileMain> {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      //home: UserHomePage(),
      initialRoute: AppPages.initial,
      getPages: AppPages.routes,
    );
  }
}
