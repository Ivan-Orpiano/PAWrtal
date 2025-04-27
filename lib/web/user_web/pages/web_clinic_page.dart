import 'package:capstone_app/web/user_web/components/appbar_components/web_notification_icon.dart';
import 'package:capstone_app/web/user_web/components/appbar_components/web_profile_icon.dart';
import 'package:capstone_app/web/user_web/components/clinic_page_components/web_clinic_description.dart';
import 'package:capstone_app/web/user_web/components/clinic_page_components/web_clinic_services.dart';
import 'package:capstone_app/web/user_web/components/clinic_page_components/web_like.dart';
import 'package:capstone_app/web/user_web/components/clinic_page_components/web_picture_gallery.dart';
import 'package:capstone_app/web/user_web/components/clinic_page_components/web_share_button.dart';
import 'package:capstone_app/web/user_web/components/dashboard_components/web_search_bar.dart';
import 'package:capstone_app/web/user_web/pages/web_user_home_page.dart';
import 'package:flutter/material.dart';

class WebClinicPage extends StatefulWidget {
  const WebClinicPage({super.key});

  @override
  State<WebClinicPage> createState() => _WebClinicPageState();
}

class _WebClinicPageState extends State<WebClinicPage> {
  final ScrollController _scrollController = ScrollController();
  bool _showWidget = false;

  @override
  void initState() {
    _scrollController.addListener((){
      if (_scrollController.offset > 5 && !_showWidget) {
        setState(() {
          _showWidget = true;
        });
      } else if (_scrollController.offset <= 5 && _showWidget) {
        setState(() {
          _showWidget = false;
        });
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          ListView(
            controller: _scrollController,
            children: [
              Container(
                height: 81,
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.black26,
                      width: 1
                    )
                  )
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

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Container(
                  padding: const EdgeInsets.only(left: 380, right: 380),
                  child: Column(
                    children: [
                      const Row(
                        children: [
                          Text(
                            "Qualipaws Animal Health Clinic",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold
                            ),
                          ),
                          Spacer(),
                          WebShareButton(),
                          SizedBox(width: 12),
                          WebLike(),
                        ],
                      ),
                      const WebPictureGallery(),
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.asset(
                              'lib/images/pfp.jpg',
                              height: 40,
                              width: 40,
                            ),
                          ),
          
                          const SizedBox(width: 18),
          
                          const Text(
                            "Qualipaws Veterinary Clinic",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16
                            ),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.only(top: 32, bottom: 32),
                        child: Divider(
                          endIndent: 500,
                          height: 1,
                          thickness: 0.5,
                          color: Colors.grey,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Text(
                              'About this veterinary clinic',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 22
                              ),
                            ),
                          ],
                        ),
                      ),
                      const WebClinicDescription(),
                      const Padding(
                        padding: EdgeInsets.only(top: 32, bottom: 32),
                        child: Divider(
                          endIndent: 500,
                          height: 1,
                          thickness: 0.5,
                          color: Colors.grey,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Text(
                              'Services offered',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 22
                              ),
                            ),
                          ],
                        ),
                      ),
                      const WebClinicServices(),
                      const Padding(
                        padding: EdgeInsets.only(top: 32, bottom: 32),
                        child: Divider(
                          endIndent: 500,
                          height: 1,
                          thickness: 0.5,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_showWidget)
          Positioned(
            child: Container(
              color: Colors.white,
              height: 80,
            )
          ),
        ],
      ),
    );
  }
}