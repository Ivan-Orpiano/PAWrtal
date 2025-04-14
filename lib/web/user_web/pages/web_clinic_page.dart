import 'package:capstone_app/web/user_web/components/appbar_components/web_notification_icon.dart';
import 'package:capstone_app/web/user_web/components/appbar_components/web_profile_icon.dart';
import 'package:capstone_app/web/user_web/components/dashboard_components/web_search_bar.dart';
import 'package:capstone_app/web/user_web/pages/web_user_home_page.dart';
import 'package:flutter/material.dart';

class WebClinicPage extends StatefulWidget {
  const WebClinicPage({super.key});

  @override
  State<WebClinicPage> createState() => _WebClinicPageState();
}

class _WebClinicPageState extends State<WebClinicPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Container(
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 246, 238, 250),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 0,
                    spreadRadius: 0.75,
                    offset: Offset.zero,
                    color: Colors.grey.shade400
                  )
                ]
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.only(left: 380, right: 380),
                    child: SizedBox(
                      height: 80,
                      child: Row(
                        children: [
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const WebUserHomePage(),
                                )
                              );
                            },
                            child: Image.asset(
                              'lib/images/PAWrtal_logo.png',
                              width: 150,
                              height: 100,
                            ),
                          ),
                          const Spacer(),
                          
                          const WebSearchBar(
                            width: 350,
                          ),
                          const Spacer(),
            
                          const WebNotificationIcon(
                            right: 445,
                            top: 70,
                            width: 500,
                          ),
                          const WebProfileIcon(
                            right: 395,
                            top: 70,
                            width: 250,
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.only(left: 380, right: 380),
            child: const Column(
              children: [
                Row(
                  children: [
                    Text(
                      "Qualipaws Animal Health Clinic",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}