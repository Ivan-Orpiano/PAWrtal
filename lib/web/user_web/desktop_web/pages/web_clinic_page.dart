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

class _WebClinicPageUpdatedState extends State<WebClinicPageUpdated> {
  final ScrollController _scrollController = ScrollController();
  bool _showWidget = false;

  final galleryKey = GlobalKey();
  final servicesKey = GlobalKey();
  final locationKey = GlobalKey();
  final reviewsKey = GlobalKey();

  bool _showNavbarOverlay = false;
  bool _isPanelSticky = false;
  double _stickyPanelTop = 0;
  double _panelOriginalOffset = 0;
  double _stickyStartOffset = 0;
  double _stickyEndOffset = 0;
  
  final GlobalKey _appointmentPanelKey = GlobalKey();

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

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateOffsets();
    });
    _appointmentController = Get.put(
      WebAppointmentController(
        authRepository: Get.find<AuthRepository>(),
        session: Get.find<UserSessionService>(),
        clinic: widget.clinic,
      ),
      tag: widget.clinic.documentId,
      
    );
  }

    void _calculateOffsets() {
    // Get the initial position of the appointment panel
    final RenderBox? panelBox = _appointmentPanelKey.currentContext
        ?.findRenderObject() as RenderBox?;
    
    if (panelBox != null) {
      final position = panelBox.localToGlobal(Offset.zero);
      _panelOriginalOffset = position.dy + _scrollController.offset;
      
      // Define when sticky behavior starts (when navbar appears)
      _stickyStartOffset = 600; // Adjust based on your navbar trigger point
      
      // Define when sticky behavior ends (height of left content)
      final leftContentHeight = _getLeftContentHeight();
      _stickyEndOffset = _panelOriginalOffset + leftContentHeight - 
          MediaQuery.of(context).size.height + 200; // Buffer
      
      setState(() {});
    }
  }

  double _getLeftContentHeight() {
    // Calculate or estimate the height of your left content
    // This should be the total height of all sections in _buildLeftContent
    return 2000; // Adjust based on actual content
  }

    double _calculateStickyTop() {
    final offset = _scrollController.offset;
    
    if (offset <= _stickyStartOffset) {
      // Before sticky zone
      return 100;
    } else if (offset > _stickyStartOffset && offset <= _stickyEndOffset) {
      // In sticky zone - fixed to top
      return 100;
    } else {
      // After sticky zone - calculate position to "stick" with left content end
      // As user scrolls past _stickyEndOffset, panel moves up with the content
      final beyondEnd = offset - _stickyEndOffset;
      return 100 - beyondEnd;
    }
  }

  void _onScroll() {
    final offset = _scrollController.offset;
    
    // Update navbar overlay visibility
    final shouldShowNavbar = offset > _stickyStartOffset;
    if (shouldShowNavbar != _showNavbarOverlay) {
      setState(() {
        _showNavbarOverlay = shouldShowNavbar;
      });
    }
    
    // Update panel sticky state
    if (offset < _stickyStartOffset) {
      // Before sticky zone - panel scrolls normally with content
      if (_isPanelSticky) {
        setState(() {
          _isPanelSticky = false;
        });
      }
    } else if (offset >= _stickyStartOffset && offset <= _stickyEndOffset) {
      // In sticky zone - panel is fixed to viewport
      if (!_isPanelSticky) {
        setState(() {
          _isPanelSticky = true;
          _stickyPanelTop = 100; // Distance from top when sticky (after navbar)
        });
      }
    }
    // After sticky zone (offset > _stickyEndOffset) - panel remains sticky
    // but positioned at the end, effectively "sticking" with the left content
  }

  @override
  void dispose() {
    _scrollController.dispose();
    Get.delete<WebAppointmentController>(tag: widget.clinic.documentId);
    super.dispose();
  }

    Widget _buildAppointmentPanel() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final panelWidth = getAppointmentPanelWidth(screenWidth);
    final maxHeight = getAppointmentPanelMaxHeight(screenHeight);
    final compactMode = shouldUseCompactMode(screenHeight);
    
    return EnhancedWebAppointmentPanel(
      key: _appointmentPanelKey,
      clinic: widget.clinic,
      maxHeight: maxHeight,
      compact: compactMode,
    );
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
            clinicId: widget.clinic.documentId!,
          ),
        ]);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = getResponsivePadding(screenWidth);
    final panelWidth = getAppointmentPanelWidth(screenWidth);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Header
              _buildHeader(horizontalPadding),

              // Clinic name and gallery
              _buildClinicHeader(horizontalPadding),

              // Main content - two column layout
              SliverToBoxAdapter(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left content
                      SizedBox(
                        width: getLeftSideWidth(screenWidth),
                        child: _buildLeftContent(),
                      ),
                      
                      const SizedBox(width: 125),
                      
                      // Right side - Appointment panel (only when not sticky)
                      if (!_isPanelSticky)
                        SizedBox(
                          width: panelWidth,
                          child: _buildAppointmentPanel(),
                        ),
                      
                      // Placeholder when sticky to maintain layout
                      if (_isPanelSticky)
                        SizedBox(width: panelWidth),
                    ],
                  ),
                ),
              ),

              // Location section
              _buildLocationSection(horizontalPadding),
            ],
          ),
          
          // Sticky appointment panel
          if (_isPanelSticky)
            Positioned(
              top: _calculateStickyTop(),
              right: getResponsivePadding(screenWidth),
              child: SizedBox(
                width: getAppointmentPanelWidth(screenWidth),
                child: _buildAppointmentPanel(),
              ),
            ),
          
          // Navigation bar overlay
          if (_showNavbarOverlay)
            _buildNavbarOverlay(horizontalPadding),
        ],
      ),
    );
  }

  Widget _buildHeader(double horizontalPadding) {
    return SliverToBoxAdapter(
      child: Container(
        height: 81,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(color: Colors.black26, width: 1),
          ),
        ),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
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
                  right: responsiveRight(
                    screenWidth: MediaQuery.of(context).size.width,
                    desiredMaxRight: 445,
                    desiredMinRight: 80,
                  ),
                  top: 70,
                  width: 500,
                ),
                WebProfileIcon(
                  right: responsiveRight(
                    screenWidth: MediaQuery.of(context).size.width,
                    desiredMaxRight: 395,
                    desiredMinRight: 30,
                  ),
                  top: 70,
                  width: 250,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

    Widget _buildClinicHeader(double horizontalPadding) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.clinic.clinicName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
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
    );
  }
  Widget _buildNavbarOverlay(double horizontalPadding) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        height: 80,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(color: Colors.black26, width: 1),
          ),
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSection(double horizontalPadding) {
    return SliverToBoxAdapter(
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
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
    );
  }
}