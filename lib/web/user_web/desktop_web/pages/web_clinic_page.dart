import 'package:capstone_app/web/user_web/desktop_web/components/appbar_components/user_web_notification_icon.dart';
import 'package:capstone_app/web/user_web/desktop_web/components/appbar_components/user_web_profile_icon.dart';
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
import 'package:capstone_app/web/user_web/controllers/user_web_appointment_controller.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/utils/user_session_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WebClinicPageUpdated extends StatefulWidget {
  final Clinic clinic;

  const WebClinicPageUpdated({super.key, required this.clinic});

  @override
  State<WebClinicPageUpdated> createState() => _WebClinicPageUpdatedState();
}

enum PanelState { scrollable, fixed, staticBottom }

class _WebClinicPageUpdatedState extends State<WebClinicPageUpdated> {
  final ScrollController _scrollController = ScrollController();
  bool _showWidget = false;
  PanelState _panelState = PanelState.scrollable;

  final galleryKey = GlobalKey();
  final servicesKey = GlobalKey();
  final locationKey = GlobalKey();
  final reviewsKey = GlobalKey();
  final leftContentKey = GlobalKey();
  final reviewsEndKey = GlobalKey();

  double _appointmentPanelHeight = 0;
  double _leftContentBottom = 0;
  double _contentStartY = 0;

  late WebAppointmentController _appointmentController;

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
    if (_contentStartY == 0 || _leftContentBottom == 0) return;

    final offset = _scrollController.offset;
    final screenHeight = MediaQuery.of(context).size.height;

    // First breakpoint: when panel starts to stick (content starts going off screen)
    final firstBreakpoint =
        _contentStartY - 120; // 120 = header height + padding

    // Second breakpoint: when left content bottom would be above panel bottom if panel stayed fixed
    final secondBreakpoint = _leftContentBottom - screenHeight + 120;

    PanelState newState;

    if (offset < firstBreakpoint) {
      newState = PanelState.scrollable;
    } else if (offset < secondBreakpoint) {
      newState = PanelState.fixed;
    } else {
      newState = PanelState.staticBottom;
    }

    if (newState != _panelState) {
      setState(() => _panelState = newState);
    }
  }

  void _calculateDimensions() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final RenderBox? contentBox =
          leftContentKey.currentContext?.findRenderObject() as RenderBox?;
      final RenderBox? reviewsEndBox =
          reviewsEndKey.currentContext?.findRenderObject() as RenderBox?;

      if (contentBox != null && reviewsEndBox != null) {
        final contentPosition = contentBox.localToGlobal(Offset.zero);
        final reviewsEndPosition = reviewsEndBox.localToGlobal(Offset.zero);

        setState(() {
          _contentStartY = contentPosition.dy + _scrollController.offset;
          _leftContentBottom = reviewsEndPosition.dy +
              reviewsEndBox.size.height +
              _scrollController.offset;
        });

        // Recalculate after getting panel height
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _updatePanelState();
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();

    _appointmentController = Get.put(
      WebAppointmentController(
        authRepository: Get.find<AuthRepository>(),
        session: Get.find<UserSessionService>(),
        clinic: widget.clinic,
      ),
      tag: widget.clinic.documentId,
    );

    _scrollController.addListener(() {
      final offset = _scrollController.offset;

      if (offset > 550 && !_showWidget) {
        setState(() => _showWidget = true);
      } else if (offset <= 550 && _showWidget) {
        setState(() => _showWidget = false);
      }

      _updatePanelState();
    });

    _calculateDimensions();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    Get.delete<WebAppointmentController>(tag: widget.clinic.documentId);
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

  double responsiveRight(
      {required double screenWidth,
      required double desiredMaxRight,
      required double desiredMinRight}) {
    const double minScreen = 1100;
    const double maxScreen = 1920;

    if (screenWidth <= minScreen) return desiredMinRight;
    if (screenWidth >= maxScreen) return desiredMaxRight;

    double t = (screenWidth - minScreen) / (maxScreen - minScreen);
    return desiredMinRight + t * (desiredMaxRight - desiredMinRight);
  }

  double getLeftSideWidth(double screenWidth) {
    final horizontalPadding = getResponsivePadding(screenWidth) * 2;
    const spacingBetween = 125;
    final appointmentPanelWidth = getAppointmentPanelWidth(screenWidth);

    final availableWidth = screenWidth -
        horizontalPadding -
        spacingBetween -
        appointmentPanelWidth;

    return availableWidth.clamp(400.0, double.infinity);
  }

  double getAppointmentPanelWidth(double screenWidth) {
    const double minScreen = 800;
    const double midScreen = 1200;
    const double maxScreen = 1920;
    const double minWidth = 300;
    const double midWidth = 360;
    const double maxWidth = 420;

    if (screenWidth <= minScreen) {
      return minWidth;
    } else if (screenWidth <= midScreen) {
      double t = (screenWidth - minScreen) / (midScreen - minScreen);
      return minWidth + t * (midWidth - minWidth);
    } else if (screenWidth <= maxScreen) {
      double t = (screenWidth - midScreen) / (maxScreen - midScreen);
      return midWidth + t * (maxWidth - midWidth);
    } else {
      return maxWidth;
    }
  }

  double getAppointmentPanelMaxHeight(double screenHeight) {
    if (screenHeight <= 768) {
      return screenHeight * 0.75;
    } else if (screenHeight <= 1080) {
      return screenHeight * 0.7;
    } else {
      return 800;
    }
  }

  bool shouldUseCompactMode(double screenHeight) {
    return screenHeight <= 900;
  }

  Widget _buildLeftContent() {
    return Column(
        key: leftContentKey,
        crossAxisAlignment: CrossAxisAlignment.start,
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
                      fontWeight: FontWeight.w600, fontSize: 16),
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
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 22),
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
          WebRatingsAndReviews(
            key: reviewsKey,
            reviewsEndKey: reviewsEndKey,
            clinicId: widget.clinic.documentId!,
          ),
        ]);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final appointmentWidth = getAppointmentPanelWidth(screenWidth);
    final maxHeight = getAppointmentPanelMaxHeight(screenHeight);
    final isCompact = shouldUseCompactMode(screenHeight);
    final horizontalPadding = getResponsivePadding(screenWidth);

    double iconRight = responsiveRight(
        screenWidth: screenWidth, desiredMaxRight: 395, desiredMinRight: 30);

    double notifRight = responsiveRight(
        screenWidth: screenWidth, desiredMaxRight: 445, desiredMinRight: 80);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Container(
                  height: 81,
                  decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(
                          bottom: BorderSide(color: Colors.black26, width: 1))),
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: horizontalPadding),
                    child: SizedBox(
                      height: 80,
                      child: Row(
                        children: [
                          InkWell(
                            onTap: () => Navigator.pop(context),
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
                ),
              ),

              // Clinic name and gallery
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: horizontalPadding),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.clinic.clinicName,
                                style: const TextStyle(
                                    fontSize: 24, fontWeight: FontWeight.bold),
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
              ),

              // Main content - two column layout
              SliverToBoxAdapter(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Stack(
                    children: [
                      // Two column layout
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left content
                          SizedBox(
                            width: getLeftSideWidth(screenWidth),
                            child: _buildLeftContent(),
                          ),

                          const SizedBox(width: 125),

                          // Right side - placeholder space for panel
                          SizedBox(
                            width: appointmentWidth,
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                // Measure the panel height on first build
                                WidgetsBinding.instance
                                    .addPostFrameCallback((_) {
                                  if (_appointmentPanelHeight == 0) {
                                    setState(() {
                                      _appointmentPanelHeight =
                                          maxHeight.clamp(400.0, 800.0);
                                    });
                                    _calculateDimensions();
                                  }
                                });

                                // Show panel only in scrollable state, otherwise show empty space
                                return _panelState == PanelState.scrollable
                                    ? EnhancedWebAppointmentPanel(
                                        clinic: widget.clinic,
                                        maxHeight: maxHeight,
                                        compact: isCompact,
                                      )
                                    : SizedBox(height: _appointmentPanelHeight);
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Location section
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: horizontalPadding),
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
                    const SizedBox(height: 64),
                  ],
                ),
              ),
            ],
          ),

          // Fixed/Sticky appointment panel
          if (_panelState == PanelState.fixed)
            Positioned(
              top: 120,
              right: horizontalPadding,
              child: SizedBox(
                width: appointmentWidth,
                child: EnhancedWebAppointmentPanel(
                  clinic: widget.clinic,
                  maxHeight: maxHeight,
                  compact: isCompact,
                ),
              ),
            ),

          // Static Bottom appointment panel
          if (_panelState == PanelState.staticBottom && _leftContentBottom > 0)
            Positioned(
              top: _leftContentBottom -
                  _appointmentPanelHeight -
                  _scrollController.offset,
              right: horizontalPadding,
              child: SizedBox(
                width: appointmentWidth,
                child: EnhancedWebAppointmentPanel(
                  clinic: widget.clinic,
                  maxHeight: maxHeight,
                  compact: isCompact,
                ),
              ),
            ),

          // Navigation bar overlay
          if (_showWidget)
            Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  height: 80,
                  decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(
                          bottom: BorderSide(color: Colors.black26, width: 1))),
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
                )),
        ],
      ),
    );
  }
}
