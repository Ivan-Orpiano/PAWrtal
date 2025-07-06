import 'package:capstone_app/web/user_web/desktop_web/user_web/components/clinic_page_components/web_services.dart';
import 'package:flutter/material.dart';

class WebClinicServices extends StatefulWidget {
  const WebClinicServices({super.key});

  @override
  State<WebClinicServices> createState() => _WebClinicServicesState();
}

class _WebClinicServicesState extends State<WebClinicServices> {
  @override
  Widget build(BuildContext context) {
    return  GridView.count(
      crossAxisCount: 2, 
      mainAxisSpacing: 12, 
      crossAxisSpacing: 12, 
      shrinkWrap: true, 
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 10,
      children: const [
        WebServices(),
        WebServices(),
        WebServices(),
        WebServices(),
        WebServices(),
        WebServices(),
        WebServices(),
        WebServices(),
      ],
    );
  }
}