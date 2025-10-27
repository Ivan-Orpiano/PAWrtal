import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:capstone_app/data/models/clinic_settings_model.dart';
import 'package:capstone_app/utils/image_helper.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;

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
  late Animation<double> _pulseAnimation;
  late Animation<double> _shimmerAnimation;

  bool _imageLoaded = false;
  bool _imageError = false;
  String? _cachedImageUrl;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _shimmerAnimation = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    _updateImageUrl();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(SuperAdminVetClinicTile oldWidget) {
    super.didUpdateWidget(oldWidget);

    // ✅ CRITICAL: Check for dashboard image changes
    if (oldWidget.clinic.image != widget.clinic.image ||
        oldWidget.clinic.dashboardPic != widget.clinic.dashboardPic ||
        oldWidget.clinic.clinicName != widget.clinic.clinicName ||
        oldWidget.clinic.services != widget.clinic.services ||
        oldWidget.settings?.gallery != widget.settings?.gallery) {
      print('📄 Real-time update detected for: ${widget.clinic.clinicName}');

      setState(() {
        _imageLoaded = false;
        _imageError = false;
      });

      _updateImageUrl();
    }
  }

  void _updateImageUrl() {
    // ✅ PRIORITY 1: Use dashboard image if available
    if (widget.clinic.dashboardPic != null &&
        widget.clinic.dashboardPic!.isNotEmpty) {
      final newUrl = getPetImageUrl(widget.clinic.dashboardPic!);
      if (newUrl != _cachedImageUrl) {
        setState(() {
          _cachedImageUrl = newUrl;
        });
      }
      return;
    }

    // ✅ PRIORITY 2: Use main clinic image
    if (widget.clinic.image.isNotEmpty) {
      final newUrl = getPetImageUrl(widget.clinic.image);
      if (newUrl != _cachedImageUrl) {
        setState(() {
          _cachedImageUrl = newUrl;
        });
      }
      return;
    }

    // ✅ PRIORITY 3: No image
    setState(() {
      _cachedImageUrl = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isOpen = widget.settings?.isOpenNow() ?? false;
    final detailedStatus = widget.settings?.getDetailedStatus() ?? 'Unknown';

    final clinicServices = widget.clinic.services
        .split(',')
        .where((s) => s.trim().isNotEmpty)
        .toList();
    final settingsServices = widget.settings?.services ?? [];
    final allServices =
        <String>{...clinicServices, ...settingsServices}.toList();
    final servicesCount = allServices.length;

    final galleryCount = widget.settings?.gallery.length ?? 0;

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 400),
      tween: Tween(begin: 0.95, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.isTablet ? 24 : 28),
              boxShadow: [
                BoxShadow(
                  color: const Color.fromRGBO(81, 115, 153, 0.08),
                  blurRadius: widget.isTablet ? 10 : 12,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: const Color.fromRGBO(81, 115, 153, 0.15),
                  blurRadius: widget.isTablet ? 20 : 24,
                  offset: const Offset(0, 8),
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(widget.isTablet ? 24 : 28),
                side: BorderSide(
                  color: const Color.fromRGBO(81, 115, 153, 0.15),
                  width: 2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Section
                  Expanded(
                    flex: widget.isTablet ? 6 : 5,
                    child: _buildImageSection(
                        isOpen, detailedStatus, galleryCount),
                  ),

                  // Info Section
                  Expanded(
                    flex: widget.isTablet ? 5 : 4,
                    child: _buildInfoSection(servicesCount),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageSection(
      bool isOpen, String detailedStatus, int galleryCount) {
    final borderRadius = widget.isTablet ? 22.0 : 26.0;

    return Stack(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 600),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.95, end: 1.0).animate(animation),
                child: child,
              ),
            );
          },
          child: Container(
            key: ValueKey(_cachedImageUrl ?? 'placeholder'),
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(borderRadius),
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFF8FAFC),
                  const Color.fromRGBO(81, 115, 153, 0.05),
                ],
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(borderRadius),
              ),
              child: _cachedImageUrl != null
                  ? _buildNetworkImage()
                  : _buildPlaceholder(),
            ),
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(borderRadius),
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.4),
                  Colors.black.withOpacity(0.7),
                ],
                stops: const [0.5, 0.8, 1.0],
              ),
            ),
          ),
        ),
        Positioned(
          top: widget.isTablet ? 14 : 20,
          right: widget.isTablet ? 14 : 20,
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: isOpen ? _pulseAnimation.value : 1.0,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: widget.isMobile
                        ? 18
                        : widget.isTablet
                            ? 14
                            : 16,
                    vertical: widget.isMobile
                        ? 11
                        : widget.isTablet
                            ? 8
                            : 10,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isOpen
                          ? [const Color(0xFF10B981), const Color(0xFF059669)]
                          : [const Color(0xFFEF4444), const Color(0xFFDC2626)],
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: (isOpen
                                ? const Color(0xFF10B981)
                                : const Color(0xFFEF4444))
                            .withOpacity(0.4),
                        blurRadius: widget.isTablet ? 10 : 14,
                        spreadRadius: widget.isTablet ? 1 : 2,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: widget.isTablet ? 8 : 10,
                        height: widget.isTablet ? 8 : 10,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.8),
                              blurRadius: widget.isTablet ? 6 : 8,
                              spreadRadius: widget.isTablet ? 1 : 2,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                          width: widget.isMobile
                              ? 8
                              : widget.isTablet
                                  ? 6
                                  : 7),
                      Text(
                        isOpen ? 'OPEN NOW' : 'CLOSED',
                        style: TextStyle(
                          fontSize: widget.isMobile
                              ? 12.5
                              : widget.isTablet
                                  ? 10.5
                                  : 11.5,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: widget.isTablet ? 1.0 : 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        if (_imageLoaded)
          Positioned(
            top: widget.isTablet ? 14 : 20,
            left: widget.isTablet ? 14 : 20,
            child: TweenAnimationBuilder<double>(
              duration: const Duration(seconds: 3),
              tween: Tween(begin: 1.0, end: 0.0),
              curve: Curves.easeOut,
              builder: (context, opacity, child) {
                if (opacity < 0.05) return const SizedBox.shrink();
                return Opacity(
                  opacity: opacity,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: widget.isTablet ? 10 : 12,
                      vertical: widget.isTablet ? 6 : 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color.fromRGBO(81, 115, 153, 0.95),
                          Color.fromRGBO(81, 115, 153, 0.85),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color.fromRGBO(81, 115, 153, 0.4),
                          blurRadius: widget.isTablet ? 6 : 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 800),
                          tween: Tween(begin: 0.0, end: 1.0),
                          builder: (context, value, child) {
                            return Transform.rotate(
                              angle: value * 2 * 3.14159,
                              child: Icon(
                                Icons.sync,
                                color: Colors.white,
                                size: widget.isTablet ? 12 : 14,
                              ),
                            );
                          },
                        ),
                        SizedBox(width: widget.isTablet ? 5 : 6),
                        Text(
                          'Updated',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: widget.isTablet ? 10 : 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        if (galleryCount > 0)
          Positioned(
            bottom: widget.isTablet ? 14 : 20,
            left: widget.isTablet ? 14 : 20,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: widget.isTablet ? 10 : 14,
                vertical: widget.isTablet ? 7 : 10,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.75),
                    Colors.black.withOpacity(0.65),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: widget.isTablet ? 10 : 12,
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
                    size: widget.isTablet ? 15 : 18,
                  ),
                  SizedBox(width: widget.isTablet ? 6 : 8),
                  Text(
                    '$galleryCount',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: widget.isTablet ? 12 : 14,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'photos',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: widget.isTablet ? 10 : 12,
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
                  padding: EdgeInsets.all(widget.isTablet ? 16 : 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color.fromRGBO(81, 115, 153, 0.2),
                        blurRadius: widget.isTablet ? 16 : 20,
                        spreadRadius: widget.isTablet ? 4 : 5,
                      ),
                    ],
                  ),
                  child: CircularProgressIndicator(
                    strokeWidth: widget.isTablet ? 2.5 : 3,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color.fromRGBO(81, 115, 153, 1),
                    ),
                  ),
                ),
                SizedBox(height: widget.isTablet ? 12 : 16),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: widget.isTablet ? 12 : 16,
                    vertical: widget.isTablet ? 6 : 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color.fromRGBO(81, 115, 153, 0.15),
                        blurRadius: widget.isTablet ? 8 : 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    'Loading image...',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: widget.isTablet ? 11 : 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
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
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFF8FAFC),
            const Color.fromRGBO(81, 115, 153, 0.08),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(widget.isTablet ? 20 : 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color.fromRGBO(81, 115, 153, 0.15),
                    const Color.fromRGBO(81, 115, 153, 0.08),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromRGBO(81, 115, 153, 0.2),
                    blurRadius: widget.isTablet ? 16 : 20,
                    spreadRadius: widget.isTablet ? 4 : 5,
                  ),
                ],
              ),
              child: Icon(
                isError ? Icons.broken_image_rounded : Icons.pets_rounded,
                size: widget.isMobile
                    ? 72
                    : widget.isTablet
                        ? 56
                        : 64,
                color: const Color.fromRGBO(81, 115, 153, 0.6),
              ),
            ),
            SizedBox(
                height: widget.isMobile
                    ? 16
                    : widget.isTablet
                        ? 12
                        : 14),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: widget.isTablet ? 16 : 20,
                vertical: widget.isTablet ? 8 : 10,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromRGBO(81, 115, 153, 0.15),
                    blurRadius: widget.isTablet ? 10 : 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                isError ? 'Image failed to load' : 'No Image Available',
                style: TextStyle(
                  color: const Color.fromRGBO(81, 115, 153, 1),
                  fontSize: widget.isMobile
                      ? 15
                      : widget.isTablet
                          ? 12
                          : 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(int servicesCount) {
    return Container(
      padding: EdgeInsets.all(
        widget.isMobile
            ? 20.0
            : widget.isTablet
                ? 12.0
                : 18.0,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white,
            Color(0xFFF8FAFC),
          ],
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(widget.isTablet ? 22.0 : 26.0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AnimatedSwitcher(
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
                fontSize: widget.isMobile
                    ? 20
                    : widget.isTablet
                        ? 14
                        : 16,
                fontWeight: FontWeight.w900,
                color: const Color.fromRGBO(81, 115, 153, 1),
                height: 1.2,
                letterSpacing: 0.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
              height: widget.isMobile
                  ? 12
                  : widget.isTablet
                      ? 6
                      : 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(widget.isTablet ? 5 : 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color.fromRGBO(81, 115, 153, 0.15),
                      Color.fromRGBO(81, 115, 153, 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.location_on_rounded,
                  size: widget.isTablet ? 14 : 18,
                  color: const Color.fromRGBO(81, 115, 153, 1),
                ),
              ),
              SizedBox(width: widget.isTablet ? 7 : 10),
              Expanded(
                child: Text(
                  widget.clinic.address,
                  style: TextStyle(
                    fontSize: widget.isMobile
                        ? 13.5
                        : widget.isTablet
                            ? 8.5
                            : 10.5,
                    color: Colors.grey[700],
                    height: 1.3,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(
              height: widget.isMobile
                  ? 12
                  : widget.isTablet
                      ? 6
                      : 10),
          Row(
            children: [
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(
                      scale: animation,
                      child: FadeTransition(
                        opacity: animation,
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    key: ValueKey('services_$servicesCount'),
                    padding: EdgeInsets.symmetric(
                      horizontal: widget.isTablet ? 7 : 12,
                      vertical: widget.isTablet ? 6 : 10,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color.fromRGBO(81, 115, 153, 0.18),
                          Color.fromRGBO(81, 115, 153, 0.10),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color.fromRGBO(81, 115, 153, 0.35),
                        width: widget.isTablet ? 1.5 : 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color.fromRGBO(81, 115, 153, 0.1),
                          blurRadius: widget.isTablet ? 6 : 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.medical_services_rounded,
                          size: widget.isTablet ? 14 : 18,
                          color: const Color.fromRGBO(81, 115, 153, 1),
                        ),
                        SizedBox(width: widget.isTablet ? 4 : 7),
                        Text(
                          '$servicesCount',
                          style: TextStyle(
                            fontSize: widget.isTablet ? 12 : 15,
                            fontWeight: FontWeight.w900,
                            color: const Color.fromRGBO(81, 115, 153, 1),
                          ),
                        ),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            'services',
                            style: TextStyle(
                              fontSize: widget.isTablet ? 8.5 : 10.5,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: widget.isTablet ? 7 : 10),
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: widget.isTablet ? 7 : 12,
                    vertical: widget.isTablet ? 6 : 10,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.green[100]!,
                        Colors.green[50]!,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.green[400]!,
                      width: widget.isTablet ? 1.5 : 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.15),
                        blurRadius: widget.isTablet ? 6 : 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.phone_rounded,
                        size: widget.isTablet ? 14 : 18,
                        color: Colors.green[700],
                      ),
                      SizedBox(width: widget.isTablet ? 4 : 7),
                      Flexible(
                        child: Text(
                          widget.clinic.contact,
                          style: TextStyle(
                            fontSize: widget.isTablet ? 8.5 : 12,
                            fontWeight: FontWeight.w800,
                            color: Colors.green[800],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}