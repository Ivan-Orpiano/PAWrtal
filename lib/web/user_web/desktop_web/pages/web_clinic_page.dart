import 'package:capstone_app/web/user_web/desktop_web/components/appbar_components/web_notification_icon.dart';
import 'package:capstone_app/web/user_web/desktop_web/components/appbar_components/web_profile_icon.dart';
import 'package:capstone_app/web/user_web/desktop_web/components/clinic_page_components/web_appointment_panel.dart';
import 'package:capstone_app/web/user_web/desktop_web/components/clinic_page_components/web_clinic_description.dart';
import 'package:capstone_app/web/user_web/desktop_web/components/clinic_page_components/web_clinic_location.dart';
import 'package:capstone_app/web/user_web/desktop_web/components/clinic_page_components/web_clinic_services.dart';
import 'package:capstone_app/web/user_web/desktop_web/components/clinic_page_components/web_like.dart';
import 'package:capstone_app/web/user_web/desktop_web/components/clinic_page_components/web_picture_gallery.dart';
import 'package:capstone_app/web/user_web/desktop_web/components/clinic_page_components/web_share_button.dart';
import 'package:capstone_app/web/user_web/desktop_web/components/clinic_page_components/web_hover_underline_text.dart';
import 'package:capstone_app/web/user_web/desktop_web/components/clinic_page_components/web_ratings_and_reviews.dart';
import 'package:capstone_app/web/user_web/desktop_web/components/dashboard_components/web_search_bar.dart';
import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:flutter/material.dart';

class WebClinicPageUpdated extends StatefulWidget {
  final Clinic clinic;
  
  const WebClinicPageUpdated({super.key, required this.clinic});

  @override
  State<WebClinicPageUpdated> createState() => _WebClinicPageUpdatedState();
}

enum PanelState { scrollable, positioned, static }
PanelState _panelState = PanelState.scrollable;

class _WebClinicPageUpdatedState extends State<WebClinicPageUpdated> {
  final ScrollController _scrollController = ScrollController();
  bool _showWidget = false;
  final galleryKey = GlobalKey();
  final servicesKey = GlobalKey();
  final locationKey = GlobalKey();
  final reviewsKey = GlobalKey();

  void _scrollToSection(GlobalKey key) {
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: 0.6, 
      );
    }
  }

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(() {
      final offset = _scrollController.offset;

      if (offset > 500 && !_showWidget) {
        setState(() {
          _showWidget = true;
        });
      } else if (offset <= 500 && _showWidget) {
        setState(() {
          _showWidget = false;
        });
      }

      if (offset <= 550 && _panelState != PanelState.scrollable) {
        setState(() => _panelState = PanelState.scrollable);
      } else if (offset > 550 && offset <= 1550 && _panelState != PanelState.positioned) {
        setState(() => _panelState = PanelState.positioned);
      } else if (offset > 1550 && _panelState != PanelState.static) {
        setState(() => _panelState = PanelState.static);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  double getResponsivePadding(double screenWidth) {
    const double minScreen = 1100;
    const double maxScreen = 1920;
    const double minPadding = 16;
    const double maxPadding = 380;

    if (screenWidth <= minScreen) return minPadding;
    if (screenWidth >= maxScreen) return maxPadding;

    double t = (screenWidth - minScreen) / (maxScreen - minScreen);
    return minPadding + t * (maxPadding - minPadding);
  }

  double responsiveRight({
    required double screenWidth,
    required double desiredMaxRight,
    required double desiredMinRight
  }) {
    const double minScreen = 1100;
    const double maxScreen = 1920;

    if (screenWidth <= minScreen) return desiredMinRight;
    if (screenWidth >= maxScreen) return desiredMaxRight;

    double t = (screenWidth - minScreen) / (maxScreen - minScreen);
    return desiredMinRight + t * (desiredMaxRight - desiredMinRight);
  }

  double getLeftSideWidth(double screenWidth) {
    if (screenWidth >= 1550) {
      return 700;
    } else if (screenWidth >= 1100) {
      double factor = (screenWidth - 1100) / (1550 - 1100);
      return 600 + (100 * factor);
    } else {
      return 600;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    double iconRight = responsiveRight(
      screenWidth: screenWidth,
      desiredMaxRight: 395,
      desiredMinRight: 30
    );

    double notifRight = responsiveRight(
      screenWidth: screenWidth,
      desiredMaxRight: 445,
      desiredMinRight: 80
    );

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
                      padding: EdgeInsets.symmetric(horizontal: getResponsivePadding(screenWidth)),
                      child: SizedBox(
                        height: 80,
                        child: Row(
                          children: [
                            InkWell(
                              onTap: () {
                                Navigator.pop(context);
                              },
                              child: Image.asset(
                                'lib/images/PAWrtal_logo.png',
                                width: 150,
                                height: 100,
                              ),
                            ),
                            const Spacer(flex: 1),
                            const Expanded(
                              flex: 2,
                              child: WebSearchBar(width: 380),
                            ),
                            const Spacer(flex: 1),
                            WebNotificationIcon(
                              right: notifRight,
                              top: 70,
                              width: 500,
                            ),
                            WebProfileIcon(
                              right: iconRight,
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
                  padding: EdgeInsets.symmetric(horizontal: getResponsivePadding(screenWidth)),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.clinic.clinicName,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold
                              ),
                            ),
                          ),
                          const WebShareButton(),
                          const SizedBox(width: 12),
                          const WebLike(),
                        ],
                      ),
                      WebPictureGalleryUpdated(
                        key: galleryKey,
                        clinic: widget.clinic,
                      ),
                    ],
                  ),
                ),
              ),
              
              Container(
                padding: EdgeInsets.symmetric(horizontal: getResponsivePadding(screenWidth)),
                child: Row(
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: getLeftSideWidth(screenWidth)
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: widget.clinic.image.isNotEmpty
                                  ? Image.network(
                                      widget.clinic.image,
                                      height: 40,
                                      width: 40,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Image.asset(
                                          'lib/images/test_image.jpg',
                                          height: 40,
                                          width: 40,
                                          fit: BoxFit.cover,
                                        );
                                      },
                                    )
                                  : Image.asset(
                                      'lib/images/test_image.jpg',
                                      height: 40,
                                      width: 40,
                                      fit: BoxFit.cover,
                                    ),
                              ),
                              const SizedBox(width: 18),
                              Expanded(
                                child: Text(
                                  widget.clinic.clinicName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16
                                  ),
                                ),
                              )
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 32),
                            child: SizedBox(
                              width: double.infinity,
                              child: Divider(
                                height: 1,
                                thickness: 0.5,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          WebClinicDescriptionUpdated(clinic: widget.clinic),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 32),
                            child: SizedBox(
                              width: double.infinity,
                              child: Divider(
                                height: 1,
                                thickness: 0.5,
                                color: Colors.grey,
                              ),
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
                                )
                              ],
                            ),
                          ),
                          WebClinicServicesUpdated(
                            key: servicesKey,
                            clinic: widget.clinic,
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 32),
                            child: SizedBox(
                              width: double.infinity,
                              child: Divider(
                                height: 1,
                                thickness: 0.5,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          WebRatingsAndReviews(key: reviewsKey),
                        ]
                      ),
                    ),
                    const Flexible(
                      flex: 2,
                      child: SizedBox(width: 125),
                    ),
              
                    Stack(
                      children: [
                        Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 925),
                              child: Visibility(
                                visible: _panelState == PanelState.scrollable,
                                child: EnhancedWebAppointmentPanel(clinic: widget.clinic),
                              ),
                            ),
                            Visibility(
                              visible: _panelState == PanelState.static,
                              child: EnhancedWebAppointmentPanel(clinic: widget.clinic),
                            )
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: getResponsivePadding(screenWidth)),
                child: const Padding(
                  padding: EdgeInsets.only(top: 64, bottom: 64),
                  child: Divider(
                    height: 1,
                    thickness: 0.5,
                  ),
                ),
              ),
              WebClinicLocationUpdated(
                key: locationKey,
                clinic: widget.clinic,
              ),
              const SizedBox(height: 64)
            ],
          ),
          if (_panelState == PanelState.positioned)
          Positioned(
            top: 120,
            right: getResponsivePadding(screenWidth),
            child: EnhancedWebAppointmentPanel(clinic: widget.clinic)
          ),
          if (_showWidget)
          Positioned(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: getResponsivePadding(screenWidth)),
              height: 80,
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: Colors.black26,
                    width: 1
                  )
                )
              ),
              child: Row(
                spacing: 18,
                children: [
                  WebHoverUnderlineText(
                    text: "Gallery",
                    onTap: () => _scrollToSection(galleryKey),
                  ),
                  WebHoverUnderlineText(
                    text: "Services",
                    onTap: () => _scrollToSection(servicesKey),
                  ),
                  WebHoverUnderlineText(
                    text: "Reviews & Ratings",
                    onTap: () => _scrollToSection(reviewsKey),
                  ),
                  WebHoverUnderlineText(
                    text: "Location",
                    onTap: () => _scrollToSection(locationKey),
                  )
                ],
              ),
            )
          ),
        ],
      ),
    );
  }
}