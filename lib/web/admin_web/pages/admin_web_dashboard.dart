import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:capstone_app/web/admin_web/pages/admin_web_appointments.dart';

class AdminWebDashboard extends StatefulWidget {
  final int acceptedCount;
  final int pendingCount;
  final int declinedCount;
  final int completedCount;
  final List<FeedbackItem> feedbacks;
  final List<AppointmentBrief> todaysAppointments;
  final List<UpcomingAppt> upcomingAppointments;
  final List<VaccineDue> vaccinesDue;
  final int noShowToday;
  final String? lastNoShowAt;
  final int totalPatientsThisMonth;
  final double revenueThisMonth;

  const AdminWebDashboard({
    super.key,
    this.acceptedCount = 0,
    this.pendingCount = 0,
    this.declinedCount = 0,
    this.completedCount = 0,
    this.feedbacks = const [],
    this.todaysAppointments = const [],
    this.upcomingAppointments = const [],
    this.vaccinesDue = const [],
    this.noShowToday = 0,
    this.lastNoShowAt,
    this.totalPatientsThisMonth = 0,
    this.revenueThisMonth = 0.0,
  });

  @override
  State<AdminWebDashboard> createState() => _AdminWebDashboardState();
}

class _Palette {
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

  static const Color white = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF8FAFC);
  static const Color cardBorder = Color(0xFFE2E8F0);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color success = Color(0xFF059669);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFD97706);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color danger = Color(0xFFDC2626);
  static const Color dangerLight = Color(0xFFFEE2E2);
  static const Color purple = Color(0xFF7C3AED);
  static const Color purpleLight = Color(0xFFEDE9FE);
}

/// Breakpoints
class _Bp {
  static const double xl = 1280;
  static const double lg = 1024;
  static const double md = 768;
  static const double sm = 560;
}

class _AdminWebDashboardState extends State<AdminWebDashboard> {
  late DateTime today;

  @override
  void initState() {
    super.initState();
    today = DateTime.now();
  }

  void openAppointments([String? category]) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AdminWebAppointments(),
        settings: RouteSettings(
          arguments: category == null ? null : {"category": category},
        ),
      ),
    );
  }

  double get _avgRating {
    if (widget.feedbacks.isEmpty) return 0;
    final sum = widget.feedbacks.fold<double>(0, (a, b) => a + b.rating);
    return sum / widget.feedbacks.length;
  }

  int get _totalAppointments =>
      widget.acceptedCount +
      widget.pendingCount +
      widget.declinedCount +
      widget.completedCount;

  double get _completionRate => _totalAppointments > 0
      ? (widget.completedCount / _totalAppointments) * 100
      : 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Palette.lightGray,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildKPICardsGrid(constraints.maxWidth),
                      const SizedBox(height: 32),
                      _buildMainContentResponsive(constraints.maxWidth),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ===== Header =====
  Widget _buildHeader() {
    final isWide = MediaQuery.of(context).size.width > _Bp.md;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            _Palette.lightVetGreen.withOpacity(0.3),
            Colors.white,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: _Palette.primaryTeal.withOpacity(0.15),
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
              _Palette.primaryBlue.withOpacity(0.08),
              _Palette.primaryTeal.withOpacity(0.12),
              _Palette.softBlue.withOpacity(0.06),
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
        // Left Side: Icon + Title
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _Palette.primaryTeal.withOpacity(0.2),
                _Palette.primaryBlue.withOpacity(0.15),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _Palette.primaryTeal.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Icon(
            Icons.dashboard_rounded,
            color: _Palette.primaryTeal,
            size: 26,
          ),
        ),
        const SizedBox(width: 18),

        // Title & Subtitle
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [
                    _Palette.darkText,
                    _Palette.deepBlue,
                    _Palette.primaryTeal
                  ],
                ).createShader(bounds),
                child: const Text(
                  'Veterinary Dashboard',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Welcome back! Here\'s what\'s happening today.',
                style: TextStyle(
                  fontSize: 15,
                  color: _Palette.mediumGray,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        // Right Side: KPI Cards aligned right
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatCard(
              'Today\'s Appointments',
              '${widget.todaysAppointments.length}',
              Icons.event_available_rounded,
              [_Palette.primaryBlue, _Palette.softBlue],
            ),
            const SizedBox(width: 12),
            _buildStatCard(
              'Completion Rate',
              '${_completionRate.toInt()}%',
              Icons.trending_up_rounded,
              [_Palette.vetGreen, _Palette.primaryTeal],
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
                    _Palette.primaryTeal.withOpacity(0.2),
                    _Palette.primaryBlue.withOpacity(0.15),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _Palette.primaryTeal.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Icon(
                Icons.dashboard_rounded,
                color: _Palette.primaryTeal,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [
                    _Palette.darkText,
                    _Palette.deepBlue,
                    _Palette.primaryTeal
                  ],
                ).createShader(bounds),
                child: const Text(
                  'Veterinary Dashboard',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Welcome back! Here\'s what\'s happening today.',
          style: TextStyle(
            fontSize: 14,
            color: _Palette.mediumGray,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _Palette.primaryTeal.withOpacity(0.1),
                _Palette.primaryBlue.withOpacity(0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _Palette.primaryTeal.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Column(
            children: [
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [
                    _Palette.darkText,
                    _Palette.deepBlue,
                    _Palette.primaryTeal
                  ],
                ).createShader(bounds),
                child: Text(
                  DateFormat('EEEE').format(today),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [
                    _Palette.darkText,
                    _Palette.deepBlue,
                    _Palette.primaryTeal
                  ],
                ).createShader(bounds),
                child: Text(
                  DateFormat('MMMM d, yyyy').format(today),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===== KPI as Responsive Grid (no overflow) =====
  Widget _buildKPICardsGrid(double maxWidth) {
    // columns: xl=4, lg=3, md=2, else 1
    int cols = 4;
    if (maxWidth < _Bp.xl) cols = 3;
    if (maxWidth < _Bp.lg) cols = 2;
    if (maxWidth < _Bp.md) cols = 1;

    // IMPORTANT: make cells taller as cols increase / width shrinks
    // childAspectRatio = width / height; smaller number => taller cell
    double ratio;
    if (cols == 4) {
      ratio = 1.45; // very tall to avoid overflow on tighter widths
    } else if (cols == 3) {
      ratio = 1.55;
    } else if (cols == 2) {
      ratio = 1.75;
    } else {
      // single column doesn't need a grid; just stack
      final items = _kpiItems();
      return Column(
        children: [
          for (final w in items) ...[w, const SizedBox(height: 16)],
        ],
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 4,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: ratio,
      ),
      itemBuilder: (_, i) => _kpiItems()[i],
    );
  }

// Build the KPI cards list (was inline before)
  List<Widget> _kpiItems() => [
        _KPICard(
          title: 'Today\'s Appointments',
          value: '${widget.todaysAppointments.length}',
          subtitle: 'Scheduled for today',
          icon: Icons.event_available,
          color: _Palette.primaryBlue,
          backgroundColor: _Palette.lightTeal,
          trend: widget.todaysAppointments.length > 10 ? 'Busy Day' : 'Normal',
          trendUp: widget.todaysAppointments.length > 10,
          onTap: () => openAppointments('today'),
        ),
        _KPICard(
          title: 'Pending Reviews',
          value: '${widget.pendingCount}',
          subtitle: 'Awaiting approval',
          icon: Icons.pending_actions,
          color: _Palette.vetOrange,
          backgroundColor: _Palette.warningLight,
          trend: widget.pendingCount > 5 ? 'High Priority' : 'Under Control',
          trendUp: widget.pendingCount > 5,
          onTap: () => openAppointments('pending'),
        ),
        _KPICard(
          title: 'Completion Rate',
          value: '${_completionRate.toInt()}%',
          subtitle: 'This month',
          icon: Icons.trending_up,
          color: _Palette.vetGreen,
          backgroundColor: _Palette.lightVetGreen,
          trend: _completionRate >= 80 ? 'Excellent' : 'Needs Improvement',
          trendUp: _completionRate >= 80,
        ),
        _KPICard(
          title: 'Patient Satisfaction',
          value: _avgRating > 0 ? _avgRating.toStringAsFixed(1) : '0.0',
          subtitle: '${widget.feedbacks.length} reviews',
          icon: Icons.star,
          color: _Palette.vetOrange,
          backgroundColor: _Palette.warningLight,
          trend: _avgRating >= 4.0 ? 'Great' : 'Good',
          trendUp: _avgRating >= 4.0,
        ),
      ];

  // ===== Main content responsive (two columns -> stacked) =====
  Widget _buildMainContentResponsive(double maxWidth) {
    if (maxWidth >= _Bp.lg) {
      // Two columns
      final sidebarWidth = maxWidth >= _Bp.xl
          ? 360.0
          : maxWidth >= _Bp.lg
              ? 320.0
              : 300.0;

      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: pipeline + overview
          Expanded(
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: _buildAppointmentPipeline()),
                    const SizedBox(width: 20),
                    Expanded(flex: 2, child: _buildTodayOverview()),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          // Right: sidebar with max width (prevents overflow)
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: sidebarWidth,
              minWidth: 260,
            ),
            child: Column(
              children: [
                _buildVaccineTracker(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      );
    } else {
      // Stacked for narrow screens
      return Column(
        children: [
          _buildAppointmentPipeline(),
          const SizedBox(height: 20),
          _buildTodayOverview(),
          const SizedBox(height: 20),
          _buildVaccineTracker(),
        ],
      );
    }
  }

  // ====== Reused pieces from your code (minor safety tweaks) ======
  Widget _buildStatCard(
      String label, String value, IconData icon, List<Color> colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.first.withOpacity(0.15),
            colors.last.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.first.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.first.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: colors),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
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
                      color: Colors.white,
                    ),
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.first.withOpacity(0.9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentPipeline() {
    return _DashboardCard(
      title: 'Appointment Pipeline',
      subtitle: 'Overview of all appointments',
      icon: Icons.analytics,
      child: Column(
        children: [
          _PipelineItem(
            label: 'Pending Review',
            count: widget.pendingCount,
            total: _totalAppointments,
            color: _Palette.vetOrange,
            icon: Icons.schedule,
            onTap: () => openAppointments('pending'),
          ),
          const SizedBox(height: 12),
          _PipelineItem(
            label: 'Accepted',
            count: widget.acceptedCount,
            total: _totalAppointments,
            color: _Palette.primaryBlue,
            icon: Icons.event_available,
            onTap: () => openAppointments('accepted'),
          ),
          const SizedBox(height: 12),
          _PipelineItem(
            label: 'Completed',
            count: widget.completedCount,
            total: _totalAppointments,
            color: _Palette.vetGreen,
            icon: Icons.check_circle,
            onTap: () => openAppointments('completed'),
          ),
          const SizedBox(height: 12),
          _PipelineItem(
            label: 'Declined',
            count: widget.declinedCount,
            total: _totalAppointments,
            color: _Palette.danger,
            icon: Icons.cancel,
            onTap: () => openAppointments('declined'),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayOverview() {
    final sampleAppointments = widget.todaysAppointments.isEmpty
        ? [
            AppointmentBrief(
              petName: 'Buddy',
              ownerName: 'Sarah Johnson',
              timeLabel: '2:30 PM',
              service: 'Vaccination',
            ),
            AppointmentBrief(
              petName: 'Luna',
              ownerName: 'Mike Chen',
              timeLabel: '3:15 PM',
              service: 'Check-up',
            ),
          ]
        : widget.todaysAppointments;

    final nextAppointment =
        sampleAppointments.isNotEmpty ? sampleAppointments.first : null;

    return _DashboardCard(
      title: 'Today\'s Overview',
      subtitle: DateFormat('MMM d, yyyy').format(today),
      icon: Icons.today,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _Palette.primaryBlue.withOpacity(0.1),
                  _Palette.lightTeal
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _Palette.primaryBlue.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.access_time, color: _Palette.primaryBlue, size: 24),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Time',
                      style: TextStyle(
                        fontSize: 12,
                        color: _Palette.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      DateFormat('h:mm a').format(DateTime.now()),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _Palette.primaryBlue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (nextAppointment != null)
            _buildNextAppointment(nextAppointment)
          else
            _buildEmptyAppointments(),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _TodaysStat(
                label: 'Scheduled',
                value: '${sampleAppointments.length}',
                icon: Icons.event,
                color: _Palette.primaryBlue,
              ),
              _TodaysStat(
                label: 'No-shows',
                value: '${widget.noShowToday}',
                icon: Icons.person_off,
                color: _Palette.danger,
              ),
              _TodaysStat(
                label: 'Completed',
                value: '${widget.completedCount}',
                icon: Icons.check_circle,
                color: _Palette.vetGreen,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNextAppointment(AppointmentBrief appointment) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _Palette.lightVetGreen,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _Palette.vetGreen.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.schedule, color: _Palette.vetGreen, size: 16),
              const SizedBox(width: 6),
              Text(
                'Next Appointment',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _Palette.vetGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            appointment.timeLabel,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _Palette.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${appointment.petName} (${appointment.ownerName})',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _Palette.textPrimary,
            ),
          ),
          Text(
            appointment.service,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: _Palette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyAppointments() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.free_breakfast,
            size: 48,
            color: _Palette.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          Text(
            'No appointments today',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: _Palette.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Enjoy your day off!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: _Palette.textSecondary.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVaccineTracker() {
    final sampleVaccines = widget.vaccinesDue.isEmpty
        ? [
            VaccineDue(
              petName: 'Max',
              vaccine: 'Rabies Vaccine',
              dueDate: DateTime.now().add(const Duration(days: 3)),
            ),
            VaccineDue(
              petName: 'Bella',
              vaccine: 'DHPP Booster',
              dueDate: DateTime.now().subtract(const Duration(days: 2)),
            ),
            VaccineDue(
              petName: 'Charlie',
              vaccine: 'Flea Prevention',
              dueDate: DateTime.now().add(const Duration(days: 14)),
            ),
            VaccineDue(
              petName: 'Milo',
              vaccine: 'Annual Check-up',
              dueDate: DateTime.now(),
            ),
          ]
        : widget.vaccinesDue;

    final now = DateTime.now();
    final urgentVaccines = sampleVaccines
        .where((v) => v.dueDate.difference(now).inDays <= 7)
        .length;
    final overdueVaccines = sampleVaccines
        .where(
            (v) => v.dueDate.isBefore(DateTime(now.year, now.month, now.day)))
        .length;

    return _DashboardCard(
      title: 'Vaccine Tracker',
      subtitle: 'Pet vaccination schedule',
      icon: Icons.vaccines,
      headerColor: _Palette.vetOrange,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _VaccineStatItem(
                label: 'Total Due',
                count: sampleVaccines.length,
                color: _Palette.vetOrange,
              ),
              _VaccineStatItem(
                label: 'Urgent',
                count: urgentVaccines,
                color: _Palette.danger,
              ),
              _VaccineStatItem(
                label: 'Overdue',
                count: overdueVaccines,
                color: _Palette.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (sampleVaccines.isEmpty)
            _buildEmptyState('All vaccines up to date', Icons.check_circle)
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sampleVaccines.length.clamp(0, 4),
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final vaccine = sampleVaccines[index];
                final daysUntil = vaccine.dueDate.difference(now).inDays;
                return _VaccineItem(vaccine: vaccine, daysUntil: daysUntil);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            icon,
            size: 40,
            color: _Palette.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: _Palette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _KPICard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color backgroundColor;
  final String trend;
  final bool trendUp;
  final VoidCallback? onTap;

  const _KPICard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.backgroundColor,
    required this.trend,
    required this.trendUp,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16), // tighter
        decoration: BoxDecoration(
          color: _Palette.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _Palette.cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              offset: const Offset(0, 2),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // header row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 22), // slightly smaller
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color:
                        trendUp ? _Palette.lightVetGreen : _Palette.dangerLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(trendUp ? Icons.trending_up : Icons.trending_down,
                          size: 12,
                          color: trendUp ? _Palette.vetGreen : _Palette.danger),
                      const SizedBox(width: 4),
                      Text(
                        trend,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: trendUp ? _Palette.vetGreen : _Palette.danger,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12), // smaller gap
            // value
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 28, // down from 32
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            // title + subtitle
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15, // down from 16
                fontWeight: FontWeight.w600,
                color: _Palette.textPrimary,
              ),
            ),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13, // down from 14
                color: _Palette.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color? headerColor;
  final Widget child;

  const _DashboardCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
    this.headerColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = headerColor ?? _Palette.primaryBlue;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _Palette.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _Palette.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _Palette.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        color: _Palette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class _PipelineItem extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _PipelineItem({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = total > 0 ? (count / total) : 0.0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _Palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: percentage,
                    backgroundColor: _Palette.cardBorder,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodaysStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _TodaysStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            color: _Palette.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _VaccineStatItem extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _VaccineStatItem({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$count',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            color: _Palette.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _VaccineItem extends StatelessWidget {
  final VaccineDue vaccine;
  final int daysUntil;

  const _VaccineItem({
    required this.vaccine,
    required this.daysUntil,
  });

  @override
  Widget build(BuildContext context) {
    final isOverdue = daysUntil < 0;
    final isUrgent = daysUntil <= 7;
    final color = isOverdue
        ? _Palette.danger
        : (isUrgent ? _Palette.danger : _Palette.vetOrange);
    final backgroundColor = isOverdue
        ? _Palette.dangerLight
        : (isUrgent ? _Palette.dangerLight : _Palette.warningLight);

    String badgeText;
    if (isOverdue) {
      badgeText = '${daysUntil.abs()}d overdue';
    } else if (daysUntil == 0) {
      badgeText = 'Due today';
    } else {
      badgeText = 'in ${daysUntil}d';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.pets, size: 16, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vaccine.petName,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _Palette.textPrimary,
                  ),
                ),
                Text(
                  vaccine.vaccine,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: _Palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              badgeText,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===== Data classes =====
class FeedbackItem {
  final String customerName;
  final String comment;
  final double rating;
  final DateTime date;

  const FeedbackItem({
    required this.customerName,
    required this.comment,
    required this.rating,
    required this.date,
  });

  String get initials {
    final parts = customerName.trim().split(RegExp(r"\s+"));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}

class AppointmentBrief {
  final String petName;
  final String ownerName;
  final String timeLabel;
  final String service;

  const AppointmentBrief({
    required this.petName,
    required this.ownerName,
    required this.timeLabel,
    required this.service,
  });
}

class UpcomingAppt {
  final String petName;
  final String ownerName;
  final DateTime date;
  final String timeLabel;
  final String service;

  const UpcomingAppt({
    required this.petName,
    required this.ownerName,
    required this.date,
    required this.timeLabel,
    required this.service,
  });
}

class VaccineDue {
  final String petName;
  final String vaccine;
  final DateTime dueDate;

  const VaccineDue({
    required this.petName,
    required this.vaccine,
    required this.dueDate,
  });
}
