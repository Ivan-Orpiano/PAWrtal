import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:capstone_app/data/models/clinic_settings_model.dart';
import 'package:capstone_app/utils/image_helper.dart';
import 'package:capstone_app/web/dimensions.dart';
import 'package:flutter/material.dart';

class SuperAdminVetClinicTile extends StatefulWidget {
  final Clinic clinic;
  final ClinicSettings? settings;
  final bool isMobile;
  final bool isTablet;

  const SuperAdminVetClinicTile({
    super.key,
    required this.clinic,
    this.settings,
    this.isMobile = false,
    this.isTablet = false,
  });

  @override
  State<SuperAdminVetClinicTile> createState() =>
      _SuperAdminVetClinicTileState();
}

class _SuperAdminVetClinicTileState extends State<SuperAdminVetClinicTile>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _shimmerController;
  late AnimationController _addressPulseController;
  late AnimationController _hoverController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _addressPulseAnimation;
  late Animation<double> _hoverAnimation;

  bool _imageLoaded = false;
  bool _imageError = false;
  String? _cachedImageUrl;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat();

    _shimmerAnimation = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    _addressPulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _addressPulseAnimation = Tween<double>(begin: 0.96, end: 1.0).animate(
      CurvedAnimation(parent: _addressPulseController, curve: Curves.easeInOut),
    );

    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _hoverAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOut),
    );

    _updateImageUrl();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _shimmerController.dispose();
    _addressPulseController.dispose();
    _hoverController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(SuperAdminVetClinicTile oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.clinic.image != widget.clinic.image ||
        oldWidget.clinic.dashboardPic != widget.clinic.dashboardPic ||
        oldWidget.clinic.clinicName != widget.clinic.clinicName ||
        oldWidget.clinic.services != widget.clinic.services ||
        oldWidget.settings?.gallery != widget.settings?.gallery) {
      print('🔄 Real-time update detected for: ${widget.clinic.clinicName}');

      setState(() {
        _imageLoaded = false;
        _imageError = false;
      });

      _updateImageUrl();
    }
  }

  void _updateImageUrl() {
    // PRIORITY 1: Check for dashboardPic
    if (widget.clinic.dashboardPic != null &&
        widget.clinic.dashboardPic!.isNotEmpty) {
      final newUrl = getDashImageUrl(widget.clinic.dashboardPic!);
      if (newUrl != _cachedImageUrl) {
        setState(() {
          _cachedImageUrl = newUrl;
        });
      }
      return;
    }

    // PRIORITY 2: Fallback to regular clinic image
    if (widget.clinic.image.isNotEmpty) {
      final newUrl = getDashImageUrl(widget.clinic.image);
      if (newUrl != _cachedImageUrl) {
        setState(() {
          _cachedImageUrl = newUrl;
        });
      }
      return;
    }

    setState(() {
      _cachedImageUrl = null;
    });
  }

  // Responsive sizing helper
  double _getResponsiveSize({
    required double mobile,
    required double tablet,
    required double desktop,
  }) {
    if (widget.isMobile) return mobile;
    if (widget.isTablet) return tablet;
    return desktop;
  }

  @override
  Widget build(BuildContext context) {
    final isOpen = widget.settings?.isOpenNow() ?? false;
    final detailedStatus = widget.settings?.getDetailedStatus() ?? 'Unknown';
    final galleryCount = widget.settings?.gallery.length ?? 0;

    final borderRadius = _getResponsiveSize(
      mobile: 20.0,
      tablet: 22.0,
      desktop: 26.0,
    );

    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _hoverController.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _hoverController.reverse();
      },
      child: AnimatedBuilder(
        animation: _hoverAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _hoverAnimation.value,
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 400),
              tween: Tween(begin: 0.92, end: 1.0),
              curve: Curves.easeOutCubic,
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(borderRadius),
                      boxShadow: [
                        BoxShadow(
                          color: _isHovered
                              ? const Color.fromRGBO(81, 115, 153, 0.15)
                              : const Color.fromRGBO(81, 115, 153, 0.08),
                          blurRadius: _isHovered ? 16 : 10,
                          offset: Offset(0, _isHovered ? 6 : 4),
                        ),
                        BoxShadow(
                          color: _isHovered
                              ? const Color.fromRGBO(81, 115, 153, 0.25)
                              : const Color.fromRGBO(81, 115, 153, 0.15),
                          blurRadius: _isHovered ? 28 : 20,
                          offset: Offset(0, _isHovered ? 12 : 8),
                          spreadRadius: _isHovered ? 3 : 2,
                        ),
                      ],
                    ),
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(borderRadius),
                        side: BorderSide(
                          color: _isHovered
                              ? const Color.fromRGBO(81, 115, 153, 0.25)
                              : const Color.fromRGBO(81, 115, 153, 0.15),
                          width: _isHovered ? 2.5 : 2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Image Section
                          Expanded(
                            flex: widget.isMobile ? 5 : widget.isTablet ? 6 : 5,
                            child: _buildImageSection(
                                isOpen, detailedStatus, galleryCount, borderRadius),
                          ),

                          // Info Section
                          Expanded(
                            flex: widget.isMobile ? 4 : widget.isTablet ? 5 : 4,
                            child: _buildInfoSection(),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildImageSection(
      bool isOpen, String detailedStatus, int galleryCount, double borderRadius) {
    return Stack(
      children: [
        // Main Image with Smooth Transitions
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 600),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.92, end: 1.0).animate(animation),
                child: child,
              ),
            );
          },
          child: Container(
            key: ValueKey(_cachedImageUrl ?? 'placeholder'),
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(borderRadius - 2),
              ),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF8FAFC),
                  Color.fromRGBO(81, 115, 153, 0.05),
                ],
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(borderRadius - 2),
              ),
              child: _cachedImageUrl != null
                  ? _buildNetworkImage()
                  : _buildPlaceholder(),
            ),
          ),
        ),

        // Gradient Overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(borderRadius - 2),
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.35),
                  Colors.black.withOpacity(0.65),
                ],
                stops: const [0.5, 0.8, 1.0],
              ),
            ),
          ),
        ),

        // Open/Closed Status Badge
        Positioned(
          top: _getResponsiveSize(mobile: 12, tablet: 14, desktop: 18),
          right: _getResponsiveSize(mobile: 12, tablet: 14, desktop: 18),
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: isOpen ? _pulseAnimation.value : 1.0,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: _getResponsiveSize(
                      mobile: 14,
                      tablet: 15,
                      desktop: 16,
                    ),
                    vertical: _getResponsiveSize(
                      mobile: 9,
                      tablet: 9.5,
                      desktop: 10,
                    ),
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isOpen
                          ? [const Color(0xFF10B981), const Color(0xFF059669)]
                          : [const Color(0xFFEF4444), const Color(0xFFDC2626)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: (isOpen
                                ? const Color(0xFF10B981)
                                : const Color(0xFFEF4444))
                            .withOpacity(0.4),
                        blurRadius: _getResponsiveSize(
                          mobile: 10,
                          tablet: 11,
                          desktop: 14,
                        ),
                        spreadRadius: _getResponsiveSize(
                          mobile: 1,
                          tablet: 1.5,
                          desktop: 2,
                        ),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: _getResponsiveSize(
                          mobile: 8,
                          tablet: 9,
                          desktop: 10,
                        ),
                        height: _getResponsiveSize(
                          mobile: 8,
                          tablet: 9,
                          desktop: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.8),
                              blurRadius: _getResponsiveSize(
                                mobile: 6,
                                tablet: 7,
                                desktop: 8,
                              ),
                              spreadRadius: _getResponsiveSize(
                                mobile: 1,
                                tablet: 1.5,
                                desktop: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: _getResponsiveSize(
                          mobile: 7,
                          tablet: 7.5,
                          desktop: 8,
                        ),
                      ),
                      Text(
                        isOpen ? 'OPEN' : 'CLOSED',
                        style: TextStyle(
                          fontSize: _getResponsiveSize(
                            mobile: 11,
                            tablet: 11.5,
                            desktop: 12,
                          ),
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Gallery Count Badge
        if (galleryCount > 0)
          Positioned(
            bottom: _getResponsiveSize(mobile: 12, tablet: 14, desktop: 18),
            left: _getResponsiveSize(mobile: 12, tablet: 14, desktop: 18),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: _getResponsiveSize(
                  mobile: 12,
                  tablet: 13,
                  desktop: 14,
                ),
                vertical: _getResponsiveSize(
                  mobile: 8,
                  tablet: 9,
                  desktop: 10,
                ),
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.75),
                    Colors.black.withOpacity(0.65),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: _getResponsiveSize(
                      mobile: 8,
                      tablet: 10,
                      desktop: 12,
                    ),
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.photo_library_rounded,
                    color: Colors.white,
                    size: _getResponsiveSize(
                      mobile: 16,
                      tablet: 17,
                      desktop: 18,
                    ),
                  ),
                  SizedBox(
                    width: _getResponsiveSize(
                      mobile: 6,
                      tablet: 7,
                      desktop: 8,
                    ),
                  ),
                  Text(
                    '$galleryCount',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: _getResponsiveSize(
                        mobile: 13,
                        tablet: 13.5,
                        desktop: 14,
                      ),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    galleryCount == 1 ? 'photo' : 'photos',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: _getResponsiveSize(
                        mobile: 11,
                        tablet: 11.5,
                        desktop: 12,
                      ),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildNetworkImage() {
    return Image.network(
      _cachedImageUrl!,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        print('❌ Image loading error: $error');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _imageError = true;
              _imageLoaded = false;
            });
          }
        });
        return _buildPlaceholder(isError: true);
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_imageLoaded) {
              setState(() {
                _imageLoaded = true;
                _imageError = false;
              });
              print('✅ Image loaded successfully: ${widget.clinic.clinicName}');
            }
          });
          return child;
        }
        return _buildShimmerLoading();
      },
    );
  }

  Widget _buildShimmerLoading() {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFF8FAFC),
                const Color.fromRGBO(81, 115, 153, 0.08),
                const Color(0xFFF8FAFC),
              ],
              stops: [
                (_shimmerAnimation.value - 1).clamp(0.0, 1.0),
                _shimmerAnimation.value.clamp(0.0, 1.0),
                (_shimmerAnimation.value + 1).clamp(0.0, 1.0),
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(_getResponsiveSize(
                    mobile: 16,
                    tablet: 18,
                    desktop: 20,
                  )),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color.fromRGBO(81, 115, 153, 0.2),
                        blurRadius: _getResponsiveSize(
                          mobile: 14,
                          tablet: 16,
                          desktop: 20,
                        ),
                        spreadRadius: _getResponsiveSize(
                          mobile: 3,
                          tablet: 4,
                          desktop: 5,
                        ),
                      ),
                    ],
                  ),
                  child: CircularProgressIndicator(
                    strokeWidth: _getResponsiveSize(
                      mobile: 2.5,
                      tablet: 2.75,
                      desktop: 3,
                    ),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color.fromRGBO(81, 115, 153, 1),
                    ),
                  ),
                ),
                SizedBox(
                  height: _getResponsiveSize(
                    mobile: 12,
                    tablet: 14,
                    desktop: 16,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: _getResponsiveSize(
                      mobile: 14,
                      tablet: 15,
                      desktop: 16,
                    ),
                    vertical: _getResponsiveSize(
                      mobile: 7,
                      tablet: 7.5,
                      desktop: 8,
                    ),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: const Color.fromRGBO(81, 115, 153, 0.15),
                        blurRadius: _getResponsiveSize(
                          mobile: 8,
                          tablet: 9,
                          desktop: 10,
                        ),
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    'Loading image...',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: _getResponsiveSize(
                        mobile: 12,
                        tablet: 12.5,
                        desktop: 13,
                      ),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlaceholder({bool isError = false}) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF8FAFC),
            Color.fromRGBO(81, 115, 153, 0.08),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(_getResponsiveSize(
                mobile: 20,
                tablet: 22,
                desktop: 24,
              )),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color.fromRGBO(81, 115, 153, 0.15),
                    Color.fromRGBO(81, 115, 153, 0.08),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromRGBO(81, 115, 153, 0.2),
                    blurRadius: _getResponsiveSize(
                      mobile: 16,
                      tablet: 18,
                      desktop: 20,
                    ),
                    spreadRadius: _getResponsiveSize(
                      mobile: 4,
                      tablet: 4.5,
                      desktop: 5,
                    ),
                  ),
                ],
              ),
              child: Icon(
                isError ? Icons.broken_image_rounded : Icons.pets_rounded,
                size: _getResponsiveSize(
                  mobile: 60,
                  tablet: 64,
                  desktop: 68,
                ),
                color: const Color.fromRGBO(81, 115, 153, 0.6),
              ),
            ),
            SizedBox(
              height: _getResponsiveSize(
                mobile: 14,
                tablet: 15,
                desktop: 16,
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: _getResponsiveSize(
                  mobile: 18,
                  tablet: 19,
                  desktop: 20,
                ),
                vertical: _getResponsiveSize(
                  mobile: 9,
                  tablet: 9.5,
                  desktop: 10,
                ),
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromRGBO(81, 115, 153, 0.15),
                    blurRadius: _getResponsiveSize(
                      mobile: 10,
                      tablet: 11,
                      desktop: 12,
                    ),
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                isError ? 'Image failed to load' : 'No Image Available',
                style: TextStyle(
                  color: const Color.fromRGBO(81, 115, 153, 1),
                  fontSize: _getResponsiveSize(
                    mobile: 13,
                    tablet: 13.5,
                    desktop: 14,
                  ),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: EdgeInsets.all(_getResponsiveSize(
        mobile: 16.0,
        tablet: 17.0,
        desktop: 18.0,
      )),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(_getResponsiveSize(
            mobile: 18.0,
            tablet: 20.0,
            desktop: 24.0,
          )),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableHeight = constraints.maxHeight;

          // Dynamic font sizes based on available space
          final clinicNameFontSize = _getResponsiveSize(
            mobile: availableHeight > 110 ? 18.0 : 16.0,
            tablet: availableHeight > 100 ? 15.0 : 13.0,
            desktop: availableHeight > 110 ? 17.0 : 15.0,
          );

          final locationLabelFontSize = _getResponsiveSize(
            mobile: availableHeight > 110 ? 9.5 : 8.5,
            tablet: availableHeight > 100 ? 8.0 : 7.0,
            desktop: availableHeight > 110 ? 9.0 : 8.0,
          );

          final addressFontSize = _getResponsiveSize(
            mobile: availableHeight > 110 ? 13.0 : 11.5,
            tablet: availableHeight > 100 ? 10.5 : 9.5,
            desktop: availableHeight > 110 ? 12.0 : 10.5,
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Clinic Name with Animation
              Flexible(
                flex: 2,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.1),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: Text(
                    widget.clinic.clinicName,
                    key: ValueKey(widget.clinic.clinicName),
                    style: TextStyle(
                      fontSize: clinicNameFontSize,
                      fontWeight: FontWeight.w900,
                      color: const Color.fromRGBO(81, 115, 153, 1),
                      height: 1.2,
                      letterSpacing: 0.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),

              SizedBox(
                height: availableHeight > 110
                    ? _getResponsiveSize(
                        mobile: 14,
                        tablet: 11,
                        desktop: 13,
                      )
                    : _getResponsiveSize(
                        mobile: 8,
                        tablet: 7,
                        desktop: 8,
                      ),
              ),

              // Creative Address Section with Animated Pin
              Flexible(
                flex: 3,
                child: AnimatedBuilder(
                  animation: _addressPulseAnimation,
                  builder: (context, child) {
                    return Container(
                      padding: EdgeInsets.all(
                        availableHeight > 110
                            ? _getResponsiveSize(
                                mobile: 14.0,
                                tablet: 11.0,
                                desktop: 13.0,
                              )
                            : _getResponsiveSize(
                                mobile: 11.0,
                                tablet: 9.0,
                                desktop: 10.0,
                              ),
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color.fromRGBO(81, 115, 153, 0.12),
                            Color.fromRGBO(81, 115, 153, 0.06),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(
                          _getResponsiveSize(
                            mobile: 16,
                            tablet: 17,
                            desktop: 18,
                          ),
                        ),
                        border: Border.all(
                          color: const Color.fromRGBO(81, 115, 153, 0.25),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color.fromRGBO(81, 115, 153, 0.15),
                            blurRadius: _getResponsiveSize(
                              mobile: 8,
                              tablet: 10,
                              desktop: 12,
                            ),
                            offset: const Offset(0, 3),
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Animated Location Pin
                          Transform.scale(
                            scale: _addressPulseAnimation.value,
                            child: Container(
                              padding: EdgeInsets.all(
                                availableHeight > 110
                                    ? _getResponsiveSize(
                                        mobile: 9.0,
                                        tablet: 8.0,
                                        desktop: 9.0,
                                      )
                                    : _getResponsiveSize(
                                        mobile: 7.0,
                                        tablet: 6.0,
                                        desktop: 7.0,
                                      ),
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color.fromRGBO(81, 115, 153, 1),
                                    Color.fromRGBO(81, 115, 153, 0.8),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(
                                  _getResponsiveSize(
                                    mobile: 11,
                                    tablet: 12,
                                    desktop: 13,
                                  ),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color.fromRGBO(81, 115, 153, 0.3),
                                    blurRadius: _getResponsiveSize(
                                      mobile: 6,
                                      tablet: 7,
                                      desktop: 8,
                                    ),
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.location_on_rounded,
                                size: availableHeight > 110
                                    ? _getResponsiveSize(
                                        mobile: 20,
                                        tablet: 18,
                                        desktop: 19,
                                      )
                                    : _getResponsiveSize(
                                        mobile: 17,
                                        tablet: 16,
                                        desktop: 17,
                                      ),
                                color: Colors.white,
                              ),
                            ),
                          ),

                          SizedBox(
                            width: availableHeight > 110
                                ? _getResponsiveSize(
                                    mobile: 12,
                                    tablet: 10,
                                    desktop: 12,
                                  )
                                : _getResponsiveSize(
                                    mobile: 9,
                                    tablet: 8,
                                    desktop: 9,
                                  ),
                          ),

                          // Address Text
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'LOCATION',
                                  style: TextStyle(
                                    fontSize: locationLabelFontSize,
                                    fontWeight: FontWeight.w900,
                                    color: const Color.fromRGBO(81, 115, 153, 0.6),
                                    letterSpacing: 1.3,
                                  ),
                                ),
                                SizedBox(
                                  height: availableHeight > 110
                                      ? _getResponsiveSize(
                                          mobile: 5,
                                          tablet: 4,
                                          desktop: 5,
                                        )
                                      : _getResponsiveSize(
                                          mobile: 3,
                                          tablet: 3,
                                          desktop: 3,
                                        ),
                                ),
                                Flexible(
                                  child: Text(
                                    widget.clinic.address,
                                    style: TextStyle(
                                      fontSize: addressFontSize,
                                      color: const Color.fromRGBO(81, 115, 153, 1),
                                      height: 1.3,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.2,
                                    ),
                                    maxLines: availableHeight > 110 ? 3 : 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}