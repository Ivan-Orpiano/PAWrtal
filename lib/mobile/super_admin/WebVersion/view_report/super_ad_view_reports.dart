import 'package:capstone_app/mobile/super_admin/WebVersion/view_report/view_reports_container.dart';
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
      backgroundColor: const Color.fromARGB(255, 248, 253, 255),
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

  body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 60),
              child: constraints.maxWidth > 800
                  ? const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(child: ViewReportsContainer()),
                     
                      ],
                    )
                  : const SingleChildScrollView( 
                      scrollDirection: Axis.vertical, 
                      child: Column(
                        children: [
                          ViewReportsContainer(),
                      ],
                    ),
            ),
            ),
          );
        },
      ),






   
    );
  }
}
