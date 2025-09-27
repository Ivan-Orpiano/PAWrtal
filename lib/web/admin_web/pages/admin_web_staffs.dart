import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:capstone_app/web/admin_web/components/staffs/staff_tile.dart';
import 'package:capstone_app/web/admin_web/components/staffs/new_staff_tile.dart';

class AdminWebStaffs extends StatefulWidget {
  const AdminWebStaffs({super.key});

  @override
  State<AdminWebStaffs> createState() => _AdminWebStaffsState();
}

class _AdminWebStaffsState extends State<AdminWebStaffs>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String? selectedTag;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Palette
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
  static const Color vetPurple = Color(0xFF6A1B9A); // opaque purple
  static const Color lightVetGreen = Color(0xFFE5F7E5);

  final List<String> tags = const [
    'Clinic',
    'Appointments',
    'Staffs',
    'Messages'
  ];

  // Sample data
  List<Staff> staffList = [
    Staff(
      name: 'Dr. Sarah Johnson',
      email: 'sarah.johnson@vetclinic.com',
      phone: '+1 555-0101',
      authorities: ['Clinic', 'Appointments'],
      imageBytes: null,
    ),
    Staff(
      name: 'Dr. Michael Chen',
      email: 'michael.chen@vetclinic.com',
      phone: '+1 555-0102',
      authorities: ['Appointments'],
      imageBytes: null,
    ),
    Staff(
      name: 'Emily Rodriguez',
      email: 'emily.rodriguez@vetclinic.com',
      phone: '+1 555-0103',
      authorities: ['Appointments', 'Messages'],
      imageBytes: null,
    ),
    Staff(
      name: 'James Wilson',
      email: 'james.wilson@vetclinic.com',
      phone: '+1 555-0104',
      authorities: ['Staffs', 'Clinic'],
      imageBytes: null,
    ),
    Staff(
      name: 'Dr. Lisa Anderson',
      email: 'lisa.anderson@vetclinic.com',
      phone: '+1 555-0105',
      authorities: ['Clinic'],
      imageBytes: null,
    ),
    Staff(
      name: 'Robert Taylor',
      email: 'robert.taylor@vetclinic.com',
      phone: '+1 555-0106',
      authorities: ['Staffs', 'Messages'],
      imageBytes: null,
    ),
    Staff(
      name: 'Dr. Amanda White',
      email: 'amanda.white@vetclinic.com',
      phone: '+1 555-0107',
      authorities: ['Clinic', 'Appointments', 'Staffs', 'Messages'],
      imageBytes: null,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation =
        CurvedAnimation(parent: _animationController, curve: Curves.easeIn);
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _addNewStaff(String name, String email, List<String> authorities,
      Uint8List? imageBytes) {
    setState(() {
      staffList.add(Staff(
        name: name,
        email: email,
        phone: null,
        authorities: authorities,
        imageBytes: imageBytes,
      ));
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text('New staff has been added successfully')),
          ],
        ),
        backgroundColor: vetGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _updateStaffAuthorities(Staff staff, List<String> newAuthorities) {
    setState(() {
      final index = staffList.indexOf(staff);
      if (index != -1) {
        staffList[index] = Staff(
          name: staff.name,
          email: staff.email,
          phone: staff.phone,
          authorities: newAuthorities,
          imageBytes: staff.imageBytes,
        );
      }
    });
  }

  void _removeStaff(Staff staff) {
    setState(() => staffList.remove(staff));
  }

  List<Staff> get filteredStaffs {
    final query = _searchController.text.trim().toLowerCase();
    return staffList.where((staff) {
      final matchesSearch = query.isEmpty ||
          staff.name.toLowerCase().contains(query) ||
          staff.email.toLowerCase().contains(query);
      final matchesTag =
          selectedTag == null || staff.authorities.contains(selectedTag);
      return matchesSearch && matchesTag;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLarge = screenWidth > 1200;
    final isMedium = screenWidth > 768;
    final isSmall = screenWidth <= 768;

    return Scaffold(
      backgroundColor: lightGray,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // Header + filters
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    lightVetGreen.withOpacity(0.3),
                    Colors.white
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryTeal.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Title bar
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMedium ? 24 : 16,
                      vertical: isSmall ? 16 : 20,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          primaryBlue.withOpacity(0.08),
                          primaryTeal.withOpacity(0.12),
                          softBlue.withOpacity(0.06),
                        ],
                      ),
                    ),
                    child: _buildTitleSection(isLarge, isMedium, isSmall),
                  ),

                  // Filters/search — responsive, never overlaps
                  LayoutBuilder(
                    builder: (context, cons) {
                      final w = cons.maxWidth;
                      final wideHeader =
                          w >= 1100; // side-by-side on wide, stacked on smaller
                      return Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isMedium ? 24 : 16,
                          vertical: 18,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withOpacity(0.8),
                              lightGray.withOpacity(0.5)
                            ],
                          ),
                        ),
                        child: wideHeader
                            ? Row(
                                children: [
                                  Expanded(child: _buildFilterTags()),
                                  const SizedBox(width: 20),
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(
                                        maxWidth: 420, minWidth: 280),
                                    child: _buildSearchBar(),
                                  ),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildFilterTags(),
                                  const SizedBox(height: 12),
                                  _buildSearchBar(fullWidth: true),
                                ],
                              ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Grid
            Expanded(
              child: Container(
                color: lightGray,
                child: Padding(
                  padding: EdgeInsets.all(isMedium ? 24 : 16),
                  child: filteredStaffs.isEmpty &&
                          _searchController.text.isNotEmpty
                      ? _buildEmptyState()
                      : _buildStaffGrid(), // <— updated grid below
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleSection(bool isLarge, bool isMedium, bool isSmall) {
    if (!isMedium) {
      // Mobile
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      primaryTeal.withOpacity(0.2),
                      primaryBlue.withOpacity(0.15)
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: primaryTeal.withOpacity(0.3), width: 1.5),
                ),
                child: const Icon(Icons.group_rounded,
                    color: primaryTeal, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ShaderMask(
                  shaderCallback: (bounds) =>
                      const LinearGradient(colors: [darkText, deepBlue, primaryTeal])
                          .createShader(bounds),
                  blendMode: BlendMode.srcIn,
                  child: Text(
                    'Staff Management',
                    style: TextStyle(
                      fontSize: isSmall ? 18 : 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Manage your veterinary clinic staff and permissions',
            style: TextStyle(
                fontSize: 14, color: mediumGray, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),
          // Mobile stats
          Row(
            children: [
              Expanded(
                child: _buildMobileStatCard(
                  'Total Staff',
                  staffList.length.toString(),
                  Icons.people_rounded,
                  const [primaryBlue, softBlue],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMobileStatCard(
                  'Active',
                  staffList.length.toString(),
                  Icons.check_circle_rounded,
                  const [vetGreen, primaryTeal],
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      // Desktop / tablet
      return Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primaryTeal.withOpacity(0.2),
                  primaryBlue.withOpacity(0.15)
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: primaryTeal.withOpacity(0.3), width: 1.5),
            ),
            child:
                const Icon(Icons.group_rounded, color: primaryTeal, size: 26),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) =>
                      const LinearGradient(colors: [darkText, deepBlue, primaryTeal])
                          .createShader(bounds),
                  blendMode: BlendMode.srcIn,
                  child: const Text(
                    'Staff Management',
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Manage your veterinary clinic staff and permissions',
                  style: TextStyle(
                      fontSize: 15,
                      color: mediumGray,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          if (isLarge) ...[
            _buildStatCard('Total Staff', staffList.length.toString(),
                Icons.people_rounded, const [primaryBlue, softBlue]),
            const SizedBox(width: 18),
            _buildStatCard('Active', staffList.length.toString(),
                Icons.check_circle_rounded, const [vetGreen, primaryTeal]),
          ],
        ],
      );
    }
  }

  // ---------- Filters & Search ----------

  Widget _buildFilterTags() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primaryTeal.withOpacity(0.1),
                  primaryBlue.withOpacity(0.08)
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: primaryTeal.withOpacity(0.2)),
            ),
            child: const Text(
              'Filter by permission',
              style: TextStyle(
                  fontSize: 14, color: darkText, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 16),
          ...tags.map((tag) {
            final bool isSelected = tag == selectedTag;

            IconData icon;
            List<Color> colors;
            switch (tag) {
              case 'Clinic':
                icon = Icons.local_hospital_rounded;
                colors = const [primaryTeal, primaryBlue];
                break;
              case 'Appointments':
                icon = Icons.calendar_month_rounded;
                colors = const [primaryBlue, softBlue];
                break;
              case 'Staffs':
                icon = Icons.group_rounded;
                colors = const [vetPurple, deepBlue];
                break;
              case 'Messages':
                icon = Icons.message_rounded;
                colors = const [vetOrange, primaryTeal];
                break;
              default:
                icon = Icons.check_circle;
                colors = const [mediumGray, mediumGray];
            }

            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: GestureDetector(
                onTap: () =>
                    setState(() => selectedTag = isSelected ? null : tag),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(colors: colors)
                        : LinearGradient(
                            colors: [
                              colors.first.withOpacity(0.1),
                              colors.last.withOpacity(0.05)
                            ],
                          ),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: isSelected
                          ? colors.first
                          : colors.first.withOpacity(0.3),
                      width: 2,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: colors.first.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon,
                          size: 18,
                          color: isSelected ? Colors.white : colors.first),
                      const SizedBox(width: 8),
                      Text(
                        tag,
                        style: TextStyle(
                          color: isSelected ? Colors.white : colors.first,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          if (selectedTag != null)
            IconButton(
              onPressed: () => setState(() => selectedTag = null),
              tooltip: 'Clear filter',
              icon: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(Icons.clear, size: 16, color: Colors.red[600]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar({bool fullWidth = false}) {
    final isMedium = MediaQuery.of(context).size.width > 768;

    return SizedBox(
      width: fullWidth ? double.infinity : (isMedium ? 320 : double.infinity),
      height: 48,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, lightVetGreen.withOpacity(0.3)],
          ),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: primaryTeal.withOpacity(0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: primaryTeal.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Search staff by name or email...',
            hintStyle:
                TextStyle(fontSize: 15, color: mediumGray.withOpacity(0.8)),
            prefixIcon: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryTeal.withOpacity(0.2),
                    primaryBlue.withOpacity(0.1)
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.search_rounded,
                  size: 20, color: primaryTeal),
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          shape: BoxShape.circle),
                      child: const Icon(Icons.clear, size: 16, color: mediumGray),
                    ),
                  )
                : null,
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
        ),
      ),
    );
  }

  // ---------- KPI cards (header) ----------

  Widget _buildStatCard(
      String label, String value, IconData icon, List<Color> colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.first.withOpacity(0.15),
            colors.last.withOpacity(0.08)
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.first.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
              color: colors.first.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                gradient: LinearGradient(colors: colors),
                shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ShaderMask(
                shaderCallback: (bounds) =>
                    LinearGradient(colors: colors).createShader(bounds),
                blendMode: BlendMode.srcIn,
                child: Text(
                  value,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
              Text(
                label,
                style: TextStyle(
                    fontSize: 13,
                    color: colors.first.withOpacity(0.9),
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileStatCard(
      String label, String value, IconData icon, List<Color> colors) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.first.withOpacity(0.15),
            colors.last.withOpacity(0.08)
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.first.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
              color: colors.first.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
                gradient: LinearGradient(colors: colors),
                shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          const SizedBox(height: 8),
          Text(value,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(
            label,
            style: TextStyle(
                fontSize: 11,
                color: colors.first.withOpacity(0.9),
                fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: primaryTeal.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8)),
              ],
            ),
            child: const Icon(Icons.search_off_rounded, size: 72, color: mediumGray),
          ),
          const SizedBox(height: 20),
          const Text('No staff found',
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w700, color: darkText)),
          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'No staff members match your search criteria.\nTry adjusting your search or filters.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: mediumGray, height: 1.5),
            ),
          ),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: () {
              _searchController.clear();
              setState(() => selectedTag = null);
            },
            icon: const Icon(Icons.clear_all_rounded, color: Colors.white),
            label: const Text('Clear Filters',
                style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  // ================== RESPONSIVE GRID (no overflows, up to 8 cols) ==================
  Widget _buildStaffGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double w = constraints.maxWidth;
        final double spacing = w > 768 ? 20.0 : 12.0;

        // Columns by width (8 on wide web)
        int cols;
        if (w >= 1600) {
          cols = 8;
        } else if (w >= 1400) {
          cols = 7;
        } else if (w >= 1200) {
          cols = 6;
        } else if (w >= 1000) {
          cols = 5;
        } else if (w >= 820) {
          cols = 4;
        } else if (w >= 620) {
          cols = 3;
        } else if (w >= 460) {
          cols = 2;
        } else {
          cols = 1;
        }

        // Compute tile width
        final double tileWidth = (w - (cols - 1) * spacing) / cols;

        // Base aspect ratio for the usual height feel
        final double baseRatio = (cols <= 2) ? 0.66 : 0.62;

        // Minimum heights so small widths never overflow
        final double minH = (cols <= 1)
            ? 340
            : (cols == 2)
                ? 300
                : (cols == 3)
                    ? 260
                    : (cols == 4)
                        ? 250
                        : (cols == 5)
                            ? 240
                            : (cols == 6)
                                ? 230
                                : (cols == 7)
                                    ? 220
                                    : 210;

        // --- EXTRA HEIGHT when permission chips wrap -------------------------
        // Estimate max number of chips across all visible tiles.
        int maxChips = 0;
        for (final s in filteredStaffs) {
          if (s.authorities.length > maxChips) maxChips = s.authorities.length;
        }
        // If there is no staff, still include "Add New Staff" tile (no chips).
        if (maxChips < 0) maxChips = 0;

        // Very safe average width for a permission chip (icon + text + padding).
        // "Appointments" is the longest; 96 keeps us safe across fonts/scales.
        const double chipW = 96.0;
        const double chipGap = 8.0;

        // Inner content width inside the card (subtract typical horizontal padding).
        final double innerW = tileWidth - 48.0;

        // How many lines will the chips need at this width?
        // (At least one line; add gaps between chips.)
        final double chipsTotalW =
            maxChips > 0 ? (maxChips * chipW + (maxChips - 1) * chipGap) : 0.0;
        final int chipLines =
            (chipsTotalW > 0 && innerW > 0) ? (chipsTotalW / innerW).ceil() : 1;

        // Add extra height for each additional line of chips (beyond the first).
        // 28–30px per wrapped line is usually enough; add a small cushion.
        final double extraForWrap =
            (chipLines > 1) ? (chipLines - 1) * 30.0 : 0.0;

        // Base height from aspect ratio
        final double heightFromBase = tileWidth / baseRatio;

        // Final height respects min height and any extra needed for wrapping
        double finalHeight = heightFromBase;
        if (finalHeight < minH) finalHeight = minH;
        finalHeight += extraForWrap + 6; // tiny cushion to kill 1–3px warnings

        final double finalRatio = tileWidth / finalHeight;

        return GridView.builder(
          itemCount: filteredStaffs.length + 1,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            childAspectRatio: finalRatio,
          ),
          itemBuilder: (context, index) {
            if (index == filteredStaffs.length) {
              return NewStaffTile(onStaffCreated: _addNewStaff);
            }
            final staff = filteredStaffs[index];
            return StaffTile(
              staff: staff,
              onUpdate: (authorities) =>
                  _updateStaffAuthorities(staff, authorities),
              onRemove: () => _removeStaff(staff),
            );
          },
        );
      },
    );
  }
}
