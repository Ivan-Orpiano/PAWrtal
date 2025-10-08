import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:capstone_app/data/models/clinic_settings_model.dart';
import 'package:capstone_app/utils/image_helper.dart';
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
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

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
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOpen = widget.settings?.isOpenNow() ?? false;
    final detailedStatus = widget.settings?.getDetailedStatus() ?? 'Unknown';
    final services = widget.clinic.services
        .split(',')
        .where((s) => s.trim().isNotEmpty)
        .length;
    final galleryCount = widget.settings?.gallery.length ?? 0;

    // Responsive sizing
    final cardHeight = widget.isMobile
        ? 400.0
        : widget.isTablet
            ? 360.0
            : 340.0;

    return Container(
      height: cardHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(81, 115, 153, 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: const Color.fromRGBO(81, 115, 153, 0.2),
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Enhanced Image Section with Real-time Status
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  // Main Image
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(22),
                      ),
                      color: Colors.grey[100],
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(22),
                      ),
                      child: widget.clinic.image.isNotEmpty
                          ? Image.network(
                              getPetImageUrl(widget.clinic.image),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildPlaceholder();
                              },
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    color:
                                        const Color.fromRGBO(81, 115, 153, 1),
                                    value: loadingProgress.expectedTotalBytes !=
                                            null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                );
                              },
                            )
                          : _buildPlaceholder(),
                    ),
                  ),

                  // Gradient Overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(22),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.6),
                          ],
                          stops: const [0.6, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // Real-time Status Badge with Pulse Animation
                  Positioned(
                    top: 16,
                    right: 16,
                    child: AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: isOpen ? _pulseAnimation.value : 1.0,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: widget.isMobile ? 16 : 14,
                              vertical: widget.isMobile ? 10 : 8,
                            ),
                            decoration: BoxDecoration(
                              color: isOpen
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFEF4444),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: (isOpen ? Colors.green : Colors.red)
                                      .withOpacity(0.5),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 9,
                                  height: 9,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.white.withOpacity(0.6),
                                        blurRadius: 6,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: widget.isMobile ? 7 : 6),
                                Text(
                                  isOpen ? 'OPEN NOW' : 'CLOSED',
                                  style: TextStyle(
                                    fontSize: widget.isMobile ? 12 : 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 1,
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
                      bottom: 16,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.photo_library,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '$galleryCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Enhanced Info Section
            Expanded(
              flex: 4,
              child: Container(
                padding: EdgeInsets.all(widget.isMobile ? 18.0 : 16.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white,
                      const Color(0xFFF8FAFC),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Clinic Name
                    Text(
                      widget.clinic.clinicName,
                      style: TextStyle(
                        fontSize: widget.isMobile ? 19 : 17,
                        fontWeight: FontWeight.bold,
                        color: const Color.fromRGBO(81, 115, 153, 1),
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: widget.isMobile ? 10 : 8),

                    // Address with Icon
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color.fromRGBO(81, 115, 153, 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.location_on,
                            size: 16,
                            color: Color.fromRGBO(81, 115, 153, 1),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.clinic.address,
                            style: TextStyle(
                              fontSize: widget.isMobile ? 13 : 12,
                              color: Colors.grey[700],
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: widget.isMobile ? 10 : 8),

                    // Info Pills Row
                    Row(
                      children: [
                        // Services Badge
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color.fromRGBO(81, 115, 153, 0.15),
                                  Color.fromRGBO(79, 115, 153, 0.08),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color.fromRGBO(81, 115, 153, 0.3),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.medical_services,
                                  size: 16,
                                  color: Color.fromRGBO(81, 115, 153, 1),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '$services',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromRGBO(81, 115, 153, 1),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'services',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Contact Badge
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.green[300]!,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.phone,
                                  size: 16,
                                  color: Colors.green[700],
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    widget.clinic.contact,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green[700],
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
                    SizedBox(height: widget.isMobile ? 10 : 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: const Color(0xFFF8FAFC),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pets_rounded,
            size: widget.isMobile ? 64 : 56,
            color: const Color.fromRGBO(81, 115, 153, 0.3),
          ),
          SizedBox(height: widget.isMobile ? 12 : 10),
          Text(
            'No Image',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: widget.isMobile ? 15 : 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
