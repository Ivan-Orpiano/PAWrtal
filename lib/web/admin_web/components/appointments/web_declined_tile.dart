import 'package:flutter/material.dart';
import 'package:capstone_app/web/admin_web/pages/admin_web_appointments.dart';
import 'web_appointment_details.dart';
import 'package:intl/intl.dart';

class WebDeclinedTile extends StatefulWidget {
  final Appointment appointment;
  final bool showDate;

  const WebDeclinedTile({
    super.key,
    required this.appointment,
    required this.showDate,
  });

  @override
  State<WebDeclinedTile> createState() => _WebDeclinedTileState();
}

class _WebDeclinedTileState extends State<WebDeclinedTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  ImageProvider _imageFor(String src) {
    // Auto-detect asset vs network image
    if (src.startsWith('http://') || src.startsWith('https://')) {
      return NetworkImage(src);
    }
    return AssetImage(src);
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _showPopup(BuildContext context) {
    final a = widget.appointment;
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.85,
          width: 700,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: WebAppointmentDetails(
            appointmentData: {
              'owner': a.owner,
              'petName': a.petName,
              'breed': a.breed,
              'service': a.service,
              'time': a.time,
              'date': a.date.toIso8601String(),
              'status': 'declined',
              'imageUrl': a.imageUrl,
              'declineReason': a.declineReason ?? 'No reason provided',
            },
            // If WebAppointmentDetails requires this (as in your Accepted tile),
            // this no-op keeps compile happy for Declined flow:
            onComplete: () {},
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.appointment;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: MouseRegion(
              onEnter: (_) {
                setState(() => _isHovered = true);
                _animationController.forward();
              },
              onExit: (_) {
                setState(() => _isHovered = false);
                _animationController.reverse();
              },
              child: InkWell(
                onTap: () => _showPopup(context),
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFFEE2E2),
                        Color(0xFFFECACB),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _isHovered
                          ? const Color(0xFFEF4444)
                          : const Color(0xFFEF4444).withOpacity(0.3),
                      width: _isHovered ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFEF4444)
                            .withOpacity(_isHovered ? 0.15 : 0.08),
                        blurRadius: _isHovered ? 12 : 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Image with Status Indicator
                      Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFEF4444),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xFFEF4444).withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 28,
                              backgroundImage: _imageFor(a.imageUrl),
                              backgroundColor: Colors.white,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444),
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 14),

                      // Appointment Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Owner Name
                            Text(
                              a.owner,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            const SizedBox(height: 6),

                            // Pet Info
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "${a.petName} • ${a.breed}",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFFEF4444),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Service
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Icon(
                                  Icons.medical_services_rounded,
                                  size: 16,
                                  color: Color(0xFF6B7280),
                                ),
                                SizedBox(width: 4),
                                // Wrap in Expanded to avoid horizontal overflow
                              ],
                            ),
                            Row(
                              children: [
                                const SizedBox(width: 20), // indent under icon
                                Expanded(
                                  child: Text(
                                    a.service,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF6B7280),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),

                            // Time
                            Row(
                              children: const [
                                Icon(
                                  Icons.access_time_rounded,
                                  size: 16,
                                  color: Color(0xFF6B7280),
                                ),
                                SizedBox(width: 4),
                              ],
                            ),
                            Row(
                              children: [
                                const SizedBox(width: 20),
                                Text(
                                  a.time,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF6B7280),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),

                            // Date (if showing)
                            if (widget.showDate) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: const [
                                  Icon(
                                    Icons.calendar_today_rounded,
                                    size: 16,
                                    color: Color(0xFF6B7280),
                                  ),
                                  SizedBox(width: 4),
                                ],
                              ),
                              Row(
                                children: [
                                  const SizedBox(width: 20),
                                  Text(
                                    DateFormat('MMM d, y').format(a.date),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF6B7280),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],

                            // Decline reason (visible inline)
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Icon(
                                  Icons.report_gmailerrorred_rounded,
                                  size: 16,
                                  color: Color(0xFFEF4444),
                                ),
                                SizedBox(width: 4),
                              ],
                            ),
                            Row(
                              children: [
                                const SizedBox(width: 20),
                                Expanded(
                                  child: Text(
                                    a.declineReason ?? 'No reason provided',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF991B1B),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
