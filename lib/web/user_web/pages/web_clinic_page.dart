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
      appBar: AppBar(
        centerTitle: true,
        leadingWidth: 530,
        toolbarHeight: 80,
        shadowColor: Colors.grey.shade400,
        elevation: 1,
        leading: Padding(
          padding: const EdgeInsets.only(left: 380),
          child: InkWell(
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
            )
          ),
        ),
        title: WebSearchBar(
          width: 350,
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 380),
            child: Row(
              children: [
                  WebNotificationIcon(
                    right: 445,
                    top: 70,
                    width: 500,
                  ),
                  WebProfileIcon(
                    right: 395,
                    top: 70,
                    width: 250,
                  ),
              ],
            ),
          )
        ],
      ),
    );
  }
}