import 'package:flutter/material.dart';
import 'package:capstone_app/web/admin_web/components/appointments/web_accepted_tile.dart';
import 'package:capstone_app/web/admin_web/components/appointments/web_pending_tile.dart';
import 'package:capstone_app/web/admin_web/components/appointments/web_declined_tile.dart';

class Appointment {
  final String owner;
  final String petName;
  final String breed;
  final String service;
  final String time;
  final String imageUrl;
  final DateTime date;
  final bool isCompleted;
  final String? declineReason;

  Appointment({
    required this.owner,
    required this.petName,
    required this.breed,
    required this.service,
    required this.time,
    required this.imageUrl,
    required this.date,
    this.isCompleted = false,
    this.declineReason,
  });
}

List<Appointment> appointments = [];

class AdminWebAppointments extends StatefulWidget {
  const AdminWebAppointments({super.key});

  @override
  State<AdminWebAppointments> createState() => _AdminWebAppointmentsState();
}

class _AdminWebAppointmentsState extends State<AdminWebAppointments> {
  String selectedTag = 'Today';

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
  static const Color lightVetGreen = Color(0xFFE5F7E5);

  // Breakpoints
  static const double bpLg = 1280;
  static const double bpMd = 900;
  static const double bpSm = 768;

  final List<String> tags = ['Today', 'All', 'Completed'];

  /// Completed tiles data source (simple map list for now)
  final List<Map<String, String>> completedAppointments = [
    {
      'owner': 'Pet Owner A',
      'petName': 'Kobe',
      'breed': 'Shih Tzu',
      'service': 'Nail Trimming',
      'time': '3:00 PM - 3:30 PM',
      'imageUrl': 'assets/profile.png',
    },
    {
      'owner': 'Pet Owner B',
      'petName': 'Bella',
      'breed': 'Pug',
      'service': 'Vaccination',
      'time': '2:00 PM - 2:30 PM',
      'imageUrl': 'assets/profile.png',
    },
    {
      'owner': 'Pet Owner C',
      'petName': 'Charlie',
      'breed': 'Labrador',
      'service': 'Deworming',
      'time': '1:00 PM - 1:30 PM',
      'imageUrl': 'assets/profile.png',
    },
    {
      'owner': 'Pet Owner D',
      'petName': 'Max',
      'breed': 'Husky',
      'service': 'Check-up',
      'time': '11:00 AM - 11:30 AM',
      'imageUrl': 'assets/profile.png',
    },
  ];

  List<Appointment> accepted = [
    Appointment(
      owner: 'Pet Owner A',
      date: DateTime.now(),
      petName: 'Kobe',
      breed: 'Shih Tzu',
      service: 'Nail Trimming',
      time: '3:00 PM - 3:30 PM',
      imageUrl: 'assets/profile.png',
    ),
  ];

  List<Appointment> pending = [
    Appointment(
      owner: 'Pet Owner 1',
      date: DateTime.now(),
      petName: 'Cerberus',
      breed: 'Chihuahua',
      service: 'Grooming',
      time: '10:00 AM - 10:30 AM',
      imageUrl: 'assets/profile.png',
    ),
    Appointment(
      owner: 'Pet Owner 2',
      date: DateTime.now().add(const Duration(days: 1)),
      petName: 'Rex',
      breed: 'Bulldog',
      service: 'Vaccination',
      time: '11:00 AM - 11:30 AM',
      imageUrl: 'assets/profile.png',
    ),
    Appointment(
      owner: 'Pet Owner 3',
      date: DateTime.now().add(const Duration(days: 2)),
      petName: 'Milo',
      breed: 'Poodle',
      service: 'Check-up',
      time: '12:00 PM - 12:30 PM',
      imageUrl: 'assets/profile.png',
    ),
    Appointment(
      owner: 'Pet Owner 4',
      date: DateTime.now().add(const Duration(days: 3)),
      petName: 'Luna',
      breed: 'Beagle',
      service: 'Surgery',
      time: '1:00 PM - 1:30 PM',
      imageUrl: 'assets/profile.png',
    ),
    Appointment(
      owner: 'Pet Owner 5',
      date: DateTime.now().add(const Duration(days: 4)),
      petName: 'Simba',
      breed: 'Golden Retriever',
      service: 'Dental Cleaning',
      time: '2:00 PM - 2:30 PM',
      imageUrl: 'assets/profile.png',
    ),
  ];

  List<Appointment> declined = [
    Appointment(
      owner: 'Pet Owner X',
      date: DateTime.now(),
      petName: 'Nala',
      breed: 'Persian Cat',
      service: 'Deworming',
      time: '4:00 PM - 4:30 PM',
      imageUrl: 'assets/profile.png',
      declineReason: 'Scheduling conflict with another appointment',
    ),
  ];

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  List<Appointment> _filterByTag(List<Appointment> list) {
    if (selectedTag == 'Today') {
      return list.where((a) => _isToday(a.date)).toList();
    }
    return list;
  }

  void acceptAppointment(Appointment appointment) {
    setState(() {
      pending.remove(appointment);
      accepted.add(appointment);
    });
  }

  void declineAppointment(Appointment appointment, String reason) {
    setState(() {
      pending.remove(appointment);
      declined.add(
        Appointment(
          owner: appointment.owner,
          petName: appointment.petName,
          breed: appointment.breed,
          service: appointment.service,
          time: appointment.time,
          imageUrl: appointment.imageUrl,
          date: appointment.date,
          declineReason: reason,
        ),
      );
    });
  }

  int get _totalAppointments =>
      accepted.length +
      pending.length +
      declined.length +
      completedAppointments.length;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final width = constraints.maxWidth;
        final isWide = width >= bpSm;

        final acceptedFiltered = _filterByTag(accepted);
        final pendingFiltered = _filterByTag(pending);
        final declinedFiltered = _filterByTag(declined);

        return Scaffold(
          backgroundColor: lightGray,
          body: Column(
            children: [
              _buildHeader(width),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        lightGray,
                        lightVetGreen.withOpacity(0.1),
                        lightGray
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(isWide ? 24 : 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFilterTags(),
                        const SizedBox(height: 20),
                        Expanded(
                          child: selectedTag == 'Completed'
                              ? _buildCompletedGrid(width)
                              : _buildColumnsResponsive(
                                  width: width,
                                  pendingFiltered: pendingFiltered,
                                  acceptedFiltered: acceptedFiltered,
                                  declinedFiltered: declinedFiltered,
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ================= HEADER =================

  Widget _buildHeader(double width) {
    final isWide = width > bpSm;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, lightVetGreen.withOpacity(0.3), Colors.white],
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
      child: Container(
        padding:
            EdgeInsets.symmetric(horizontal: isWide ? 24 : 16, vertical: 20),
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
        child: isWide ? _headerWide() : _headerNarrow(),
      ),
    );
  }

  Widget _headerWide() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
            border: Border.all(color: primaryTeal.withOpacity(0.3), width: 1.5),
          ),
          child: const Icon(Icons.calendar_month_rounded,
              color: primaryTeal, size: 26),
        ),
        const SizedBox(width: 18),

        // Title + subtitle
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              _HeaderTitle(text: 'Appointment Management'),
              SizedBox(height: 6),
              Text(
                'Manage your veterinary clinic appointments and schedules',
                style: TextStyle(
                    fontSize: 15,
                    color: mediumGray,
                    fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),

        // KPI on the RIGHT
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatCard(
              'Total Appointments',
              '$_totalAppointments',
              Icons.event_rounded,
              const [primaryBlue, softBlue],
            ),
            const SizedBox(width: 12),
            _buildStatCard(
              'Completed Appointments',
              '${completedAppointments.length}',
              Icons.check_circle_rounded,
              const [vetGreen, primaryTeal],
            ),
          ],
        ),
      ],
    );
  }

  Widget _headerNarrow() {
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
                border:
                    Border.all(color: primaryTeal.withOpacity(0.3), width: 1.5),
              ),
              child: const Icon(Icons.calendar_month_rounded,
                  color: primaryTeal, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(child: _HeaderTitle(text: 'Appointment Management')),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'Manage your veterinary clinic appointments and schedules',
          style: TextStyle(
              fontSize: 14, color: mediumGray, fontWeight: FontWeight.w500),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMobileStatCard(
                'Total Appointments',
                '$_totalAppointments',
                Icons.event_rounded,
                const [primaryBlue, softBlue],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMobileStatCard(
                'Completed Appointments',
                '${completedAppointments.length}',
                Icons.check_circle_rounded,
                const [vetGreen, primaryTeal],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ================= BODY =================

  /// Responsive columns:
  /// - ≥ 1280: 3 columns in a Row
  /// - 900–1279: 2 columns grid (Pending + Accepted) and Declined below
  /// - < 900: stacked sections (mobile)
  Widget _buildColumnsResponsive({
    required double width,
    required List<Appointment> pendingFiltered,
    required List<Appointment> acceptedFiltered,
    required List<Appointment> declinedFiltered,
  }) {
    if (width >= bpLg) {
      // 3 columns
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
              child: _columnCard(
                  'Accepted', vetGreen, Icons.check_circle_rounded,
                  count: acceptedFiltered.length,
                  child: _tileListAccepted(acceptedFiltered))),
          const SizedBox(width: 16),
          Expanded(
              child: _columnCard('Pending', vetOrange, Icons.schedule_rounded,
                  textColor: Colors.white,
                  count: pendingFiltered.length,
                  child: _tileListPending(pendingFiltered))),
          const SizedBox(width: 16),
          Expanded(
              child: _columnCard('Declined', Colors.red, Icons.cancel_rounded,
                  count: declinedFiltered.length,
                  child: _tileListDeclined(declinedFiltered))),
        ],
      );
    } else if (width >= bpMd) {
      // 2 columns (grid-ish): Pending + Accepted side-by-side; Declined below full width
      return Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                  child: _columnCard(
                      'Pending', vetOrange, Icons.schedule_rounded,
                      textColor: Colors.white,
                      count: pendingFiltered.length,
                      child: _tileListPending(pendingFiltered))),
              const SizedBox(width: 16),
              Expanded(
                  child: _columnCard(
                      'Accepted', vetGreen, Icons.check_circle_rounded,
                      count: acceptedFiltered.length,
                      child: _tileListAccepted(acceptedFiltered))),
            ],
          ),
          const SizedBox(height: 16),
          _columnCard('Declined', Colors.red, Icons.cancel_rounded,
              count: declinedFiltered.length,
              child: _tileListDeclined(declinedFiltered)),
        ],
      );
    } else {
      // Mobile stacked with capped internal heights to prevent overflow
      return SingleChildScrollView(
        child: Column(
          children: [
            _columnCard('Pending', vetOrange, Icons.schedule_rounded,
                textColor: Colors.white,
                count: pendingFiltered.length,
                child: _tileListPending(pendingFiltered, capHeight: 220)),
            const SizedBox(height: 16),
            _columnCard('Accepted', vetGreen, Icons.check_circle_rounded,
                count: acceptedFiltered.length,
                child: _tileListAccepted(acceptedFiltered, capHeight: 220)),
            const SizedBox(height: 16),
            _columnCard('Declined', Colors.red, Icons.cancel_rounded,
                count: declinedFiltered.length,
                child: _tileListDeclined(declinedFiltered, capHeight: 220)),
          ],
        ),
      );
    }
  }

  Widget _buildCompletedGrid(double width) {
    int cross = 3;
    if (width < bpLg) cross = 2;
    if (width < bpMd) cross = 1;

    return Container(
      padding: EdgeInsets.all(width >= bpSm ? 20 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: primaryTeal.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 4))
        ],
      ),
      child: GridView.builder(
        itemCount: completedAppointments.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cross,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: width >= bpMd ? 2.6 : 3.0,
        ),
        itemBuilder: (context, index) {
          final a = completedAppointments[index];
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [lightGray, lightVetGreen.withOpacity(0.3)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: vetGreen.withOpacity(0.3), width: 2),
            ),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: vetGreen.withOpacity(0.3), width: 2),
                  ),
                  child: CircleAvatar(
                    backgroundImage:
                        AssetImage(a['imageUrl'] ?? 'lib/images/pfp.jpg'),
                    radius: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(a['owner'] ?? '',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text('${a['petName'] ?? ''} • ${a['breed'] ?? ''}',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: mediumGray)),
                      Text(a['service'] ?? '',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12,
                              color: primaryTeal,
                              fontWeight: FontWeight.w600)),
                      Text(a['time'] ?? '',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11, color: mediumGray)),
                    ],
                  ),
                ),
                const Icon(Icons.check_circle, color: vetGreen, size: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  // ---------- Reusable column card ----------
  Widget _columnCard(
    String title,
    Color backgroundColor,
    IconData icon, {
    Color? textColor,
    int? count,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: primaryTeal.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          TabHeader(
            title: title,
            backgroundColor: backgroundColor,
            textColor: textColor,
            icon: icon,
            count: count,
          ),
          child,
        ],
      ),
    );
  }

  // ---------- Lists (with optional height cap for mobile) ----------
  Widget _tileListPending(List<Appointment> items, {double? capHeight}) {
    final list = ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return WebPendingTile(
          showDate: selectedTag != 'Today',
          appointment: item,
          onAccept: () => acceptAppointment(item),
          onDecline: (reason) => declineAppointment(item, reason),
        );
      },
    );
    if (capHeight != null) return SizedBox(height: capHeight, child: list);
    return Expanded(child: list);
  }

  Widget _tileListAccepted(List<Appointment> items, {double? capHeight}) {
    final list = ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return WebAcceptedTile(
          showDate: selectedTag != 'Today',
          appointment: item,
          onComplete: () => setState(() {
            accepted.remove(item);
            completedAppointments.add({
              'owner': item.owner,
              'petName': item.petName,
              'breed': item.breed,
              'service': item.service,
              'time': item.time,
              'imageUrl': item.imageUrl,
            });
          }),
        );
      },
    );
    if (capHeight != null) return SizedBox(height: capHeight, child: list);
    return Expanded(child: list);
  }

  Widget _tileListDeclined(List<Appointment> items, {double? capHeight}) {
    final list = ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return WebDeclinedTile(
          showDate: selectedTag != 'Today',
          appointment: item,
        );
      },
    );
    if (capHeight != null) return SizedBox(height: capHeight, child: list);
    return Expanded(child: list);
  }

  // ================= SMALL WIDGETS =================

  Widget _buildFilterTags() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          const SizedBox(width: 10),
          ...tags.map((tag) {
            final bool isSelected = tag == selectedTag;
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: () => setState(() => selectedTag = tag),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? const LinearGradient(
                            colors: [primaryBlue, primaryTeal])
                        : const LinearGradient(
                            colors: [Colors.white, Colors.white]),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: isSelected
                          ? primaryTeal
                          : primaryBlue.withOpacity(0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: primaryTeal.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                    ],
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isSelected ? Colors.white : primaryBlue,
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  static Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    List<Color> colors,
  ) {
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
            children: [
              ShaderMask(
                shaderCallback: (bounds) =>
                    LinearGradient(colors: colors).createShader(bounds),
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
    String label,
    String value,
    IconData icon,
    List<Color> colors,
  ) {
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
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
                gradient: LinearGradient(colors: colors),
                shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          const SizedBox(height: 8),
          ShaderMask(
            shaderCallback: (bounds) =>
                LinearGradient(colors: colors).createShader(bounds),
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
}

/// Tab Header with optional count badge
class TabHeader extends StatelessWidget {
  final String title;
  final Color backgroundColor;
  final Color? textColor;
  final IconData icon;
  final int? count;

  const TabHeader({
    super.key,
    required this.title,
    required this.backgroundColor,
    required this.icon,
    this.textColor,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    final Color effectiveText = textColor ?? Colors.white;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Icon(icon, color: effectiveText, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                  color: effectiveText,
                  fontWeight: FontWeight.w700,
                  fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (count != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white24),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                    color: effectiveText,
                    fontWeight: FontWeight.w700,
                    fontSize: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HeaderTitle extends StatelessWidget {
  final String text;
  const _HeaderTitle({required this.text});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(colors: [
        _AdminWebAppointmentsState.darkText,
        _AdminWebAppointmentsState.deepBlue,
        _AdminWebAppointmentsState.primaryTeal
      ]).createShader(bounds),
      child: Text(
        text,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        style: const TextStyle(
            fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }
}
