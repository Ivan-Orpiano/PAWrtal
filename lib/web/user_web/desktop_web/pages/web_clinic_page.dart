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

class _WebClinicPageUpdatedState extends State<WebClinicPageUpdated> {
  final ScrollController _scrollController = ScrollController();
  bool _showWidget = false;
  PanelState _panelState = PanelState.scrollable;
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

  void _updatePanelState() {
    final offset = _scrollController.offset;

    if (offset <= 550 && _panelState != PanelState.scrollable) {
      setState(() => _panelState = PanelState.scrollable);
    } else if (offset > 550 && offset <= 1800 && _panelState != PanelState.positioned) {
      setState(() => _panelState = PanelState.positioned);
    } else if (offset > 1800 && _panelState != PanelState.static) {
      setState(() => _panelState = PanelState.static);
    }
  }

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(() {
      final offset = _scrollController.offset;

      if (offset > 550 && !_showWidget) {
        setState(() {
          _showWidget = true;
        });
      } else if (offset <= 550 && _showWidget) {
        setState(() {
          _showWidget = false;
        });
      }

      _updatePanelState();
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
    // Calculate available width after padding and spacing
    final horizontalPadding = getResponsivePadding(screenWidth) * 2; // Both sides
    final spacingBetween = 125; // The flexible spacing
    final appointmentPanelWidth = getAppointmentPanelWidth(screenWidth);
    
    // Total available width minus reserved space
    final availableWidth = screenWidth - horizontalPadding - spacingBetween - appointmentPanelWidth;
    
    // Ensure minimum width for left content
    return availableWidth.clamp(400.0, double.infinity);
  }

  double getAppointmentPanelWidth(double screenWidth) {
    // Smooth responsive scaling for appointment panel
    const double minScreen = 800;
    const double midScreen = 1200;
    const double maxScreen = 1920;
    const double minWidth = 300;
    const double midWidth = 360;
    const double maxWidth = 420;

    if (screenWidth <= minScreen) {
      return minWidth;
    } else if (screenWidth <= midScreen) {
      // Smooth interpolation between min and mid
      double t = (screenWidth - minScreen) / (midScreen - minScreen);
      return minWidth + t * (midWidth - minWidth);
    } else if (screenWidth <= maxScreen) {
      // Smooth interpolation between mid and max
      double t = (screenWidth - midScreen) / (maxScreen - midScreen);
      return midWidth + t * (maxWidth - midWidth);
    } else {
      return maxWidth;
    }
  }

  // Alternative method if you want even more control over the layout
  Map<String, double> getResponsiveWidths(double screenWidth) {
    final horizontalPadding = getResponsivePadding(screenWidth) * 2;
    final spacingBetween = 125;
    final totalReservedSpace = horizontalPadding + spacingBetween;
    
    // Define appointment panel width with smooth scaling
    late double appointmentWidth;
    if (screenWidth >= 1400) {
      appointmentWidth = 420;
    } else if (screenWidth >= 1100) {
      // Smooth interpolation
      double t = (screenWidth - 1100) / (1400 - 1100);
      appointmentWidth = 320 + t * 100; // 320 to 420
    } else if (screenWidth >= 800) {
      double t = (screenWidth - 800) / (1100 - 800);
      appointmentWidth = 280 + t * 40; // 280 to 320
    } else {
      appointmentWidth = 280; // Minimum width
    }
    
    // Calculate left side width
    final leftSideWidth = (screenWidth - totalReservedSpace - appointmentWidth).clamp(300.0, 800.0);
    
    return {
      'leftSide': leftSideWidth,
      'appointmentPanel': appointmentWidth,
    };
  }

  Widget _buildMainContent(double screenWidth) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: getResponsivePadding(screenWidth)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: getLeftSideWidth(screenWidth)
            ),
            child: _buildLeftContent(),
          ),
          const Flexible(
            flex: 2,
            child: SizedBox(width: 125),
          ),
          
          // Appointment panel stack - always on the right
          SizedBox(
            width: getAppointmentPanelWidth(screenWidth),
            child: Stack(
              children: [
                Column(
                  children: [
                    // Scrollable state panel
                    if (_panelState == PanelState.scrollable)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 40),
                        child: EnhancedWebAppointmentPanel(clinic: widget.clinic),
                      ),
                    
                    // Static state panel
                    if (_panelState == PanelState.static)
                      Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: EnhancedWebAppointmentPanel(clinic: widget.clinic),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftContent() {
    return Column(
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
    );
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
      backgroundColor: Colors.grey.shade50,
      body: Stack(
        children: [
          ListView(
            controller: _scrollController,
            children: [
              // Header
              Container(
                height: 81,
                decoration: const BoxDecoration(
                  color: Colors.white,
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

              // Clinic name and gallery section
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
              
              // Main content area
              _buildMainContent(screenWidth),

              // Location section
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

          // Positioned appointment panel
          if (_panelState == PanelState.positioned)
          Positioned(
            top: 120,
            right: getResponsivePadding(screenWidth),
            child: SizedBox(
              width: getAppointmentPanelWidth(screenWidth),
              child: EnhancedWebAppointmentPanel(clinic: widget.clinic),
            ),
          ),

          // Navigation bar overlay
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