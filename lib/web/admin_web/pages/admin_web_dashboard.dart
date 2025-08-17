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
  });

  @override
  State<AdminWebDashboard> createState() => _AdminWebDashboardState();
}

class _Palette {
  static const Color primary = Color(0xFF628BBE);
  static const Color primaryDark = Color(0xFF3E6A9E);
  static const Color primaryLight = Color(0xFFEAF2FB);
  static const Color cardBorder = Color(0x33628BBE);
}

class _AdminWebDashboardState extends State<AdminWebDashboard> {
  late DateTime today;
  late DateTime firstDayOfMonth;
  late int daysInMonth;
  late int startWeekday;
  final ScrollController _feedbackCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    today = DateTime.now();
    firstDayOfMonth = DateTime(today.year, today.month, 1);
    daysInMonth = DateTime(today.year, today.month + 1, 0).day;
    startWeekday = firstDayOfMonth.weekday % 7;
  }

  @override
  void dispose() {
    _feedbackCtrl.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Palette.primaryLight,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    elevation: 1.5,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: _Palette.cardBorder),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Overview',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: _Palette.primaryDark,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _MiniStat(
                                  label: 'Total Appointments',
                                  value: (widget.acceptedCount +
                                          widget.pendingCount +
                                          widget.declinedCount +
                                          widget.completedCount)
                                      .toString(),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _MiniNoShows(
                                  label: 'No-shows Today',
                                  count: widget.noShowToday,
                                  lastAt: widget.lastNoShowAt,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _MiniRating(
                                  label: 'Avg Rating',
                                  rating: _avgRating,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _StatTile(
                          icon: Icons.check_circle,
                          value: widget.acceptedCount,
                          color: const Color(0xFF2E7D32),
                          label: 'Accepted',
                          onTap: () => openAppointments('accepted'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatTile(
                          icon: Icons.hourglass_top,
                          value: widget.pendingCount,
                          color: const Color(0xFFF6C044),
                          label: 'Pending',
                          onTap: () => openAppointments('pending'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatTile(
                          icon: Icons.cancel,
                          value: widget.declinedCount,
                          color: const Color(0xFFD32F2F),
                          label: 'Declined',
                          onTap: () => openAppointments('declined'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatTile(
                          icon: Icons.done_all,
                          value: widget.completedCount,
                          color: _Palette.primaryDark,
                          label: 'Completed',
                          onTap: () => openAppointments('completed'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child:
                            _AppointmentsCard(items: widget.todaysAppointments),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child:
                            _UpcomingCard(items: widget.upcomingAppointments),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _VaccinesCard(items: widget.vaccinesDue),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 420,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final calHeight = constraints.maxHeight * 2 / 3;
                  return Column(
                    children: [
                      SizedBox(
                        height: calHeight,
                        child: Card(
                          elevation: 1.5,
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: _Palette.cardBorder),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          DateFormat('MMMM yyyy').format(today),
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w700,
                                            color: _Palette.primaryDark,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          DateFormat('EEEE, MMM d')
                                              .format(today),
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: _Palette.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: _Palette.primaryLight,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color: _Palette.cardBorder),
                                      ),
                                      child: Text(
                                        DateFormat('MMM d, yyyy').format(today),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: _Palette.primaryDark,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Expanded(
                                  child: _CalendarGrid(
                                    today: today,
                                    daysInMonth: daysInMonth,
                                    startWeekday: startWeekday,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: Card(
                          elevation: 1.5,
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: _Palette.cardBorder),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  'Recent Feedback',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: _Palette.primaryDark,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Expanded(
                                  child: Scrollbar(
                                    controller: _feedbackCtrl,
                                    thumbVisibility: true,
                                    child: widget.feedbacks.isEmpty
                                        ? const Center(
                                            child: Text(
                                              'No feedback yet',
                                              style: TextStyle(
                                                  color: _Palette.primaryDark),
                                            ),
                                          )
                                        : ListView.separated(
                                            controller: _feedbackCtrl,
                                            itemCount: widget.feedbacks.length,
                                            separatorBuilder: (_, __) =>
                                                const Divider(
                                              height: 24,
                                              color: _Palette.cardBorder,
                                            ),
                                            itemBuilder: (context, index) {
                                              final f = widget.feedbacks[index];
                                              return Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  CircleAvatar(
                                                    radius: 20,
                                                    backgroundColor:
                                                        _Palette.primaryLight,
                                                    child: Text(
                                                      f.initials,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color: _Palette
                                                            .primaryDark,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceBetween,
                                                          children: [
                                                            Text(
                                                              f.customerName,
                                                              style:
                                                                  const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                                color: _Palette
                                                                    .primaryDark,
                                                              ),
                                                            ),
                                                            _Stars(
                                                                rating:
                                                                    f.rating),
                                                          ],
                                                        ),
                                                        const SizedBox(
                                                            height: 6),
                                                        Text(
                                                          f.comment,
                                                          maxLines: 3,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                        const SizedBox(
                                                            height: 6),
                                                        Text(
                                                          DateFormat(
                                                                  'MMM d, yyyy • h:mm a')
                                                              .format(f.date),
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 12,
                                                            color: _Palette
                                                                .primary,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  final DateTime today;
  final int daysInMonth;
  final int startWeekday;
  const _CalendarGrid(
      {required this.today,
      required this.daysInMonth,
      required this.startWeekday});

  @override
  Widget build(BuildContext context) {
    final days = <Widget>[];
    const labels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    days.add(Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: labels
          .map(
            (e) => Expanded(
              child: Center(
                child: Text(
                  e,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: _Palette.primaryDark,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    ));
    days.add(const SizedBox(height: 8));

    final totalCells = startWeekday + daysInMonth;
    final rows = (totalCells / 7).ceil();
    int day = 1;

    for (int r = 0; r < rows; r++) {
      final cells = <Widget>[];
      for (int c = 0; c < 7; c++) {
        final idx = r * 7 + c;
        if (idx < startWeekday || day > daysInMonth) {
          cells.add(const Expanded(child: SizedBox(height: 40)));
        } else {
          final isToday = day == today.day;
          cells.add(
            Expanded(
              child: Container(
                height: 40,
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isToday ? _Palette.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _Palette.cardBorder),
                ),
                child: Center(
                  child: Text(
                    '$day',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isToday ? Colors.white : _Palette.primaryDark,
                    ),
                  ),
                ),
              ),
            ),
          );
          day++;
        }
      }
      days.add(Row(children: cells));
    }

    return Column(children: days);
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final int value;
  final Color color;
  final String label;
  final VoidCallback onTap;
  const _StatTile(
      {required this.icon,
      required this.value,
      required this.color,
      required this.label,
      required this.onTap});

  Color _onColor(Color c) =>
      c.computeLuminance() > 0.5 ? Colors.black : Colors.white;

  @override
  Widget build(BuildContext context) {
    final fg = _onColor(color);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _Palette.cardBorder),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 20, color: fg),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: fg,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '$value',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppointmentsCard extends StatelessWidget {
  final List<AppointmentBrief> items;
  const _AppointmentsCard({required this.items});
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1.5,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: _Palette.cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Today',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _Palette.primaryDark,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 240,
              child: items.isEmpty
                  ? const Center(
                      child: Text(
                        'No appointments today',
                        style: TextStyle(color: _Palette.primaryDark),
                      ),
                    )
                  : ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final a = items[i];
                        return Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: _Palette.primaryLight,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: _Palette.cardBorder),
                              ),
                              child: Text(
                                a.timeLabel,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: _Palette.primaryDark),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${a.petName} • ${a.ownerName}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _Palette.primary,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(a.service,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UpcomingCard extends StatelessWidget {
  final List<UpcomingAppt> items;
  const _UpcomingCard({required this.items});
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1.5,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: _Palette.cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Upcoming (7 days)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _Palette.primaryDark,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 240,
              child: items.isEmpty
                  ? const Center(
                      child: Text('No upcoming appointments',
                          style: TextStyle(color: _Palette.primaryDark)),
                    )
                  : ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final a = items[i];
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: _Palette.primaryLight,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: _Palette.cardBorder),
                              ),
                              child: Text(
                                DateFormat('EEE, MMM d').format(a.date),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: _Palette.primaryDark),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${a.petName} • ${a.ownerName}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _Palette.primary,
                                          borderRadius:
                                              BorderRadius.circular(999),
                                        ),
                                        child: Text(a.service,
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700)),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _Palette.primaryLight,
                                          borderRadius:
                                              BorderRadius.circular(999),
                                          border: Border.all(
                                              color: _Palette.cardBorder),
                                        ),
                                        child: Text(a.timeLabel,
                                            style: const TextStyle(
                                                color: _Palette.primaryDark,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VaccinesCard extends StatelessWidget {
  final List<VaccineDue> items;
  const _VaccinesCard({required this.items});
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1.5,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: _Palette.cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Vaccinations Due',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _Palette.primaryDark,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 240,
              child: items.isEmpty
                  ? const Center(
                      child: Text('No upcoming due vaccines',
                          style: TextStyle(color: _Palette.primaryDark)),
                    )
                  : ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final v = items[i];
                        return Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(v.petName,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 4),
                                  Text(v.vaccine,
                                      style: const TextStyle(
                                          color: _Palette.primaryDark,
                                          fontSize: 12)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: _Palette.primaryLight,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: _Palette.cardBorder),
                              ),
                              child: Text(DateFormat('MMM d').format(v.dueDate),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: _Palette.primaryDark)),
                            ),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStat({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _Palette.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  color: _Palette.primaryDark,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: _Palette.primaryDark)),
        ],
      ),
    );
  }
}

class _MiniNoShows extends StatelessWidget {
  final String label;
  final int count;
  final String? lastAt;
  const _MiniNoShows({required this.label, required this.count, this.lastAt});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _Palette.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  color: _Palette.primaryDark,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('$count',
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: _Palette.primaryDark)),
          if (lastAt != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _Palette.primaryLight,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: _Palette.cardBorder),
              ),
              child: Text('Last: $lastAt',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _Palette.primaryDark)),
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniRating extends StatelessWidget {
  final String label;
  final double rating;
  const _MiniRating({required this.label, required this.rating});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _Palette.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  color: _Palette.primaryDark,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.star, size: 18, color: _Palette.primaryDark),
              const SizedBox(width: 6),
              Text(rating.toStringAsFixed(1),
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: _Palette.primaryDark)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stars extends StatelessWidget {
  final double rating;
  const _Stars({required this.rating});
  @override
  Widget build(BuildContext context) {
    final full = rating.floor();
    final half = (rating - full) >= 0.5 ? 1 : 0;
    final empty = 5 - full - half;
    final icons = <Widget>[];
    for (int i = 0; i < full; i++) {
      icons.add(const Icon(Icons.star, size: 16, color: _Palette.primary));
    }
    if (half == 1) {
      icons.add(const Icon(Icons.star_half, size: 16, color: _Palette.primary));
    }
    for (int i = 0; i < empty; i++) {
      icons.add(
          const Icon(Icons.star_border, size: 16, color: _Palette.primary));
    }
    return Row(children: icons);
  }
}

class FeedbackItem {
  final String customerName;
  final String comment;
  final double rating;
  final DateTime date;
  const FeedbackItem(
      {required this.customerName,
      required this.comment,
      required this.rating,
      required this.date});
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
  const AppointmentBrief(
      {required this.petName,
      required this.ownerName,
      required this.timeLabel,
      required this.service});
}

class UpcomingAppt {
  final String petName;
  final String ownerName;
  final DateTime date;
  final String timeLabel;
  final String service;
  const UpcomingAppt(
      {required this.petName,
      required this.ownerName,
      required this.date,
      required this.timeLabel,
      required this.service});
}

class VaccineDue {
  final String petName;
  final String vaccine;
  final DateTime dueDate;
  const VaccineDue(
      {required this.petName, required this.vaccine, required this.dueDate});
}
