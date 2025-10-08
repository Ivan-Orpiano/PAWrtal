import 'package:capstone_app/web/user_web/desktop_web/pages/web_pets_page.dart';
import 'package:flutter/material.dart';

class WebTabletPetsPage extends StatefulWidget {
  const WebTabletPetsPage({super.key});

  @override
  State<WebTabletPetsPage> createState() => _WebTabletPetsPageState();
}

class _WebTabletPetsPageState extends State<WebTabletPetsPage> {
  @override
  Widget build(BuildContext context) {
    return const WebPetsPage();
  }
}