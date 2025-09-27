import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'staff_full_details.dart';

class Staff {
  final String name;
  final String email;
  final String? phone;
  final List<String> authorities;
  final Uint8List? imageBytes;

  Staff({
    required this.name,
    required this.email,
    this.phone,
    required this.authorities,
    this.imageBytes,
  });
}

class StaffTile extends StatefulWidget {
  final Staff staff;
  final void Function(List<String>) onUpdate;
  final VoidCallback onRemove;

  const StaffTile({
    super.key,
    required this.staff,
    required this.onUpdate,
    required this.onRemove,
  });

  @override
  State<StaffTile> createState() => _StaffTileState();
}

class _StaffTileState extends State<StaffTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  // Updated color palette to match the interface
  static const Color primaryBlue = Color(0xFF4A6FA5);
  static const Color primaryTeal = Color(0xFF5B9BD5);
  static const Color lightTeal = Color(0xFF9FC5E8);
  static const Color deepBlue = Color(0xFF2F4F7F);
  static const Color softBlue = Color(0xFF6FA8DC);
  static const Color lightGray = Color(0xFFF3F4F6);
  static const Color mediumGray = Color(0xFF9CA3AF);
  static const Color darkText = Color(0xFF374151);
  static const Color vetGreen = Color(0xFF34D399);
  static const Color vetOrange = Color(0xFFF59E0B);
  // FIX: make purple opaque (ARGB -> 0xFF + A855F7)
  static const Color vetPurple50 = Color(0x80A855F7); // 50% opacity
  // Opaque purple (#A855F7)
  static const Color vetPurple = Color(0xFFA855F7);
  static const Color lightVetGreen = Color(0xFFE5F7E5);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showStaffDetails() {
    showDialog(
      context: context,
      builder: (_) => StaffFullDetails(
        staffName: widget.staff.name,
        email: widget.staff.email,
        phone: widget.staff.phone,
        initialAuthorities: widget.staff.authorities,
        onAuthoritiesUpdated: widget.onUpdate,
        onRemove: widget.onRemove,
        imageBytes: widget.staff.imageBytes,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _controller.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTap: _showStaffDetails,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                gradient: _isHovered
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white,
                          lightVetGreen.withOpacity(0.3),
                          primaryTeal.withOpacity(0.1),
                        ],
                      )
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white,
                          lightVetGreen.withOpacity(0.1),
                        ],
                      ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: _isHovered
                        ? primaryTeal.withOpacity(0.2)
                        : primaryTeal.withOpacity(0.1),
                    blurRadius: _isHovered ? 15 : 8,
                    offset: Offset(0, _isHovered ? 6 : 3),
                    spreadRadius: _isHovered ? 2 : 1,
                  ),
                ],
                border: Border.all(
                  color: _isHovered
                      ? primaryTeal.withOpacity(0.4)
                      : primaryTeal.withOpacity(0.2),
                  width: _isHovered ? 2 : 1.5,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: _showStaffDetails,
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Profile Image with Badge
                        Stack(
                          children: [
                            Container(
                              width: 76,
                              height: 76,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                // Avoid single-color gradient when image exists
                                gradient: widget.staff.imageBytes == null
                                    ? LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          primaryTeal.withOpacity(0.15),
                                          primaryBlue.withOpacity(0.1),
                                          lightTeal.withOpacity(0.1),
                                        ],
                                      )
                                    : null,
                                border: Border.all(
                                  color: _isHovered
                                      ? primaryTeal
                                      : primaryTeal.withOpacity(0.4),
                                  width: _isHovered ? 3 : 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryTeal.withOpacity(0.2),
                                    blurRadius: _isHovered ? 12 : 6,
                                    offset: Offset(0, _isHovered ? 4 : 2),
                                  ),
                                ],
                                image: widget.staff.imageBytes != null
                                    ? DecorationImage(
                                        image: MemoryImage(
                                            widget.staff.imageBytes!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: widget.staff.imageBytes == null
                                  ? const Icon(
                                      Icons.person,
                                      size: 36,
                                      color: primaryTeal,
                                    )
                                  : null,
                            ),
                            if (widget.staff.authorities.isNotEmpty)
                              Positioned(
                                bottom: -2,
                                right: -2,
                                child: Container(
                                  width: 26,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [vetGreen, primaryTeal],
                                    ),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 3,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: vetGreen.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${widget.staff.authorities.length}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Name
                        Text(
                          widget.staff.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            foreground: Paint()
                              ..shader = const LinearGradient(
                                colors: [darkText, primaryTeal],
                              ).createShader(const Rect.fromLTWH(0, 0, 200, 50)),
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),

                        // Email
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                mediumGray.withOpacity(0.1),
                                lightVetGreen.withOpacity(0.2),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            widget.staff.email,
                            style: const TextStyle(
                              fontSize: 11,
                              color: mediumGray,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Permissions Preview
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                lightGray,
                                lightVetGreen.withOpacity(0.3),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border:
                                Border.all(color: primaryTeal.withOpacity(0.2)),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          primaryTeal.withOpacity(0.2),
                                          primaryBlue.withOpacity(0.1),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(Icons.security,
                                        size: 12, color: primaryTeal),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'Permissions',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: darkText,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (widget.staff.authorities.isEmpty)
                                Text(
                                  'No permissions assigned',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[500],
                                    fontStyle: FontStyle.italic,
                                  ),
                                )
                              else
                                Wrap(
                                  spacing: 4,
                                  runSpacing: 4,
                                  alignment: WrapAlignment.center,
                                  // FIX: show up to 4 permissions
                                  children: widget.staff.authorities
                                      .take(4)
                                      .map((auth) {
                                    IconData icon;
                                    List<Color> colors;
                                    switch (auth) {
                                      case 'Clinic':
                                        icon = Icons.local_hospital;
                                        colors = [primaryTeal, primaryBlue];
                                        break;
                                      case 'Appointments':
                                        icon = Icons.calendar_month;
                                        colors = [primaryBlue, softBlue];
                                        break;
                                      case 'Staffs': // keep exact label
                                        icon = Icons.group;
                                        colors = [vetPurple, deepBlue];
                                        break;
                                      case 'Messages':
                                        icon = Icons.message;
                                        colors = [vetOrange, primaryTeal];
                                        break;
                                      default:
                                        icon = Icons.check_circle;
                                        colors = [mediumGray, mediumGray];
                                    }

                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            colors.first.withOpacity(0.2),
                                            colors.last.withOpacity(0.1),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color:
                                                colors.first.withOpacity(0.3)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(icon,
                                              size: 10, color: colors.first),
                                          const SizedBox(width: 4),
                                          Text(
                                            auth.length > 8
                                                ? '${auth.substring(0, 6)}...'
                                                : auth,
                                            style: TextStyle(
                                              fontSize: 9,
                                              color: colors.first,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              // FIX: adjust "+N more" threshold/math for 4 visible
                              if (widget.staff.authorities.length > 4)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.grey[200]!,
                                          lightVetGreen.withOpacity(0.3),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '+${widget.staff.authorities.length - 4} more',
                                      style: const TextStyle(
                                        fontSize: 9,
                                        color: mediumGray,
                                        fontStyle: FontStyle.italic,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
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
          ),
        ),
      ),
    );
  }
}
