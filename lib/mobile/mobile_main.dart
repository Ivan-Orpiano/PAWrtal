import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:capstone_app/pages/routes/app_pages.dart';
import 'package:flutter/services.dart';

class MobileMain extends StatefulWidget {
  const MobileMain({super.key});

  @override
  State<MobileMain> createState() => _MobileMainState();
}

class _MobileMainState extends State<MobileMain> {
  
  @override
  Widget build(BuildContext context) {
    //SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: AppPages.initial,
      getPages: AppPages.routes,
    );
  }
}
