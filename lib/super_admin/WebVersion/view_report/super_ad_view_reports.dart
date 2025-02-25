import 'package:flutter/material.dart';

class SuperAdViewReports extends StatefulWidget {
  const SuperAdViewReports({super.key});

  @override
  State<SuperAdViewReports> createState() => _SuperAdViewReportsState();
}

class _SuperAdViewReportsState extends State<SuperAdViewReports> {
  late final double screenHeight;
  late final double screenWidth;
  

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: const Color.fromARGB(255, 248, 253, 255),
        centerTitle: true,
        toolbarHeight: screenHeight * 0.1,
        flexibleSpace: Container(
          margin: const EdgeInsets.only(top: 15.0),
          child: Center(
            child: Image.asset(
              "lib/images/PAWrtal_logo.png",
              height: screenHeight * 0.08,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
   
    );
  }
}
