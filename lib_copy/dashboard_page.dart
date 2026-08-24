import 'dart:math';
import 'package:flutter/material.dart';
import 'job_details_page.dart';
import 'job_history_page.dart';
import 'profile_page.dart';
import 'app_routes.dart';
import 'bottom_nav.dart';
import 'date_range_picker.dart';
import 'sales_requests.dart';
import 'notifications_page.dart';
import 'app_core.dart';

enum _TaskFilter { today, month, range }

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late DateTime _selectedDay;
  late DateTime _visibleMonth; // first day of the month currently shown
  _TaskFilter _taskFilter = _TaskFilter.today;
  DateTimeRange? _customRange;
  String? _statusFilter; // null = All

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDay = DateTime(now.year, now.month, now.day);
    _visibleMonth = DateTime(now.year, now.month, 1);
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // "Overdue" is no longer shown on the dashboard at all — those projects
  // are excluded here so every Tasks view (today/month/range) and the
  // status chart all agree on the same, smaller set of jobs.
  List<HistoryJob> get _visibleJobs =>
      JobHistoryPage.allJobs.where((j) => j.status != "Overdue").toList();

  List<HistoryJob> _jobsOn(DateTime day) {
    return _visibleJobs.where((j) => jobActiveOn(j, day)).toList();
  }

  List<HistoryJob> _jobsInMonth(DateTime month) {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    final jobs = _visibleJobs
        .where((j) => j.expectedDate != null && _rangeOverlaps(j, firstDay, lastDay))
        .toList();
    jobs.sort((a, b) => a.expectedDate!.compareTo(b.expectedDate!));
    return jobs;
  }

  List<HistoryJob> _jobsInRange(DateTimeRange range) {
    final jobs = _visibleJobs
        .where((j) => j.expectedDate != null && _rangeOverlaps(j, range.start, range.end))
        .toList();
    jobs.sort((a, b) => a.expectedDate!.compareTo(b.expectedDate!));
    return jobs;
  }

  bool _rangeOverlaps(HistoryJob job, DateTime rangeStart, DateTime rangeEnd) {
    final jobStart = DateTime(job.expectedDate!.year, job.expectedDate!.month, job.expectedDate!.day);
    final jobEnd = job.endDate != null
        ? DateTime(job.endDate!.year, job.endDate!.month, job.endDate!.day)
        : jobStart;
    final rStart = DateTime(rangeStart.year, rangeStart.month, rangeStart.day);
    final rEnd = DateTime(rangeEnd.year, rangeEnd.month, rangeEnd.day);
    return !jobEnd.isBefore(rStart) && !jobStart.isAfter(rEnd);
  }

  Future<void> _pickCustomRange() async {
    final picked = await pickDateRange(context, initialRange: _customRange);
    if (picked != null) {
      setState(() {
        _customRange = picked;
        _taskFilter = _TaskFilter.range;
      });
    }
  }

  void _setMonth(int month) {
    setState(() => _visibleMonth = DateTime(_visibleMonth.year, month, 1));
  }

  void _setYear(int year) {
    setState(() => _visibleMonth = DateTime(year, _visibleMonth.month, 1));
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: AppLocale.languageNotifier,
      builder: (context, _, __) => _buildScaffold(context),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGray,
      body: SafeArea(
        child: RefreshIndicator(
          color: navy,
          onRefresh: () async {
            // No live backend to re-fetch from yet — this simply gives the
            // page a moment to visually refresh so the gesture always
            // feels responsive.
            await Future.delayed(const Duration(milliseconds: 600));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                child: ValueListenableBuilder<List<HistoryJob>>(
                  valueListenable: JobHistoryPage.createdJobsNotifier,
                  builder: (context, _, __) {
                    final jobs = _visibleJobs;
                    // Counts every real status value (service-job statuses
                    // plus the project stages imported from the Project
                    // List spreadsheet) so the dashboard reflects whatever
                    // statuses actually show up in the data, not just a
                    // fixed Assigned/In Progress/Completed set.
                    final statusCounts = <String, int>{
                      for (final s in jobStatuses) s: jobs.where((j) => j.status == s).length,
                    };
                    final now = DateTime.now();
                    final todayNorm = DateTime(now.year, now.month, now.day);
                    final isToday = _sameDay(_selectedDay, todayNorm);
                    // Demo rows don't carry an expectedDate, so "today" keeps
                    // showing the original mixed feed when today is selected;
                    // any other selected day, the whole-month filter, or a
                    // custom range shows only jobs actually scheduled with a date.
                    final todaysJobsRaw = _taskFilter == _TaskFilter.month
                        ? _jobsInMonth(_visibleMonth)
                        : _taskFilter == _TaskFilter.range
                            ? (_customRange != null ? _jobsInRange(_customRange!) : <HistoryJob>[])
                            : (isToday
                                // With a status filter active, search every job so
                                // the selected status's projects always show up —
                                // not just whichever happen to be in the first 5
                                // demo rows shown for the unfiltered "today" view.
                                ? (_statusFilter != null ? jobs : jobs.take(5).toList())
                                : _jobsOn(_selectedDay));

                    // Apply the status filter, if one is selected.
                    final statusFiltered = _statusFilter == null
                        ? todaysJobsRaw
                        : todaysJobsRaw.where((j) => jobMatchesStatusFilter(j, _statusFilter)).toList();

                    // Default view (no status filter): keep everything, but
                    // sink Completed jobs to the bottom so active work stays
                    // front and center. Order is preserved within each group.
                    final todaysJobs = _statusFilter != null
                        ? statusFiltered
                        : [
                            ...statusFiltered.where((j) => j.status != "Completed"),
                            ...statusFiltered.where((j) => j.status == "Completed"),
                          ];

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr("Dashboard"),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _DashboardStatusChart(
                          bars: [
                            for (final s in jobStatuses)
                              if (statusCounts[s]! > 0)
                                _BarData(tr(s), statusCounts[s]!, statusChartColors[s] ?? Colors.blueGrey, s),
                          ],
                          selectedFilterKey: _statusFilter,
                          onBarTap: (filterKey) => setState(() {
                            // Tapping the same bar again clears the filter.
                            _statusFilter = _statusFilter == filterKey ? null : filterKey;
                          }),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              tr("Tasks"),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  AppRoute.to(const JobHistoryPage()),
                                );
                              },
                              child: Text(
                                tr("See All"),
                                style: const TextStyle(color: navy, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _taskFilterToggle(),
                        const SizedBox(height: 10),
                        _statusFilterDropdown(),
                        const SizedBox(height: 14),
                        if (todaysJobs.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.event_available, size: 36, color: Colors.black26),
                                  const SizedBox(height: 8),
                                  Text(
                                    tr("No jobs yet"),
                                    style: const TextStyle(color: Colors.black45, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          ...todaysJobs.map(
                            (job) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _jobCard(
                                context,
                                icon: jobTypeIcon(job.jobType),
                                title: job.title,
                                subtitle: job.subtitle.isNotEmpty
                                    ? job.subtitle
                                    : (job.location ?? ""),
                                time: (_taskFilter == _TaskFilter.month ||
                                            _taskFilter == _TaskFilter.range) &&
                                        job.expectedDate != null
                                    ? "${formatJobDate(job.expectedDate!)} · ${job.time}"
                                    : job.time,
                                jobId: job.id,
                                status: job.status,
                              ),
                            ),
                          ),
                        const SizedBox(height: 24),
                        _monthCalendar(),
                        const SizedBox(height: 78),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(current: NavTab.home),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
      decoration: const BoxDecoration(
        color: navy,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Builder(
            builder: (context) => InkWell(
              customBorder: const CircleBorder(),
              onTap: () {
                Navigator.push(
                  context,
                  AppRoute.to(const ProfilePage()),
                );
              },
              child: const CircleAvatar(
                radius: 26,
                backgroundColor: Colors.white24,
                child: Icon(Icons.person, color: Colors.white, size: 28),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: AnimatedBuilder(
              animation: AppSession.listenable,
              builder: (context, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppSession.currentName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    AppSession.roleLabel,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          ValueListenableBuilder<List<ManagerNotification>>(
            valueListenable: SalesRequests.notificationsNotifier,
            builder: (context, _, __) {
              final unread = SalesRequests.unreadCount;
              return Builder(
                builder: (context) => InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => Navigator.push(context, AppRoute.to(const NotificationsPage())),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.notifications_none, color: Colors.white, size: 28),
                      ),
                      if (unread > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                            decoration: const BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              "$unread",
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  static const List<String> _monthNames = [
    "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December",
  ];

  Widget _monthCalendar() {
    final now = DateTime.now();
    final todayNorm = DateTime(now.year, now.month, now.day);
    final weekdayLabels = [
      tr("Mon"), tr("Tue"), tr("Wed"), tr("Thu"), tr("Fri"), tr("Sat"), tr("Sun"),
    ];

    final daysInMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;
    final leadingBlanks = _visibleMonth.weekday - 1; // Mon=1 ... Sun=7
    final years = List.generate(7, (i) => now.year - 3 + i);

    final dayCells = <Widget>[];
    for (int i = 0; i < leadingBlanks; i++) {
      dayCells.add(const SizedBox.shrink());
    }
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_visibleMonth.year, _visibleMonth.month, day);
      final isToday = _sameDay(date, todayNorm);
      final isSelected = _sameDay(date, _selectedDay);
      final hasJobs = _jobsOn(date).isNotEmpty;

      dayCells.add(
        InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => setState(() => _selectedDay = date),
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isSelected ? navy : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: isToday && !isSelected ? Border.all(color: navy, width: 1.2) : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "$day",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: !hasJobs ? Colors.transparent : (isSelected ? Colors.white : navy),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DropdownButton<int>(
                value: _visibleMonth.month,
                underline: const SizedBox.shrink(),
                itemHeight: 56,
                icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: navy),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black87),
                items: List.generate(
                  12,
                  (i) => DropdownMenuItem(
                    value: i + 1,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(tr(_monthNames[i])),
                    ),
                  ),
                ),
                onChanged: (m) {
                  if (m != null) _setMonth(m);
                },
              ),
              const SizedBox(width: 12),
              DropdownButton<int>(
                value: _visibleMonth.year,
                underline: const SizedBox.shrink(),
                itemHeight: 56,
                icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: navy),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black87),
                items: years
                    .map((y) => DropdownMenuItem(
                          value: y,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text("$y"),
                          ),
                        ))
                    .toList(),
                onChanged: (y) {
                  if (y != null) _setYear(y);
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: weekdayLabels
                .map((label) => Expanded(
                      child: Center(
                        child: Text(
                          label,
                          style: const TextStyle(fontSize: 11, color: Colors.black45, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 4),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.3,
            children: dayCells,
          ),
        ],
      ),
    );
  }

  Widget _taskFilterToggle() {
    Widget pill(String label, _TaskFilter value, {VoidCallback? onTap, IconData? icon}) {
      final selected = _taskFilter == value;
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap ?? () => setState(() => _taskFilter = value),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: BoxDecoration(
              color: selected ? navy : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 13, color: selected ? Colors.white : Colors.black54),
                  const SizedBox(width: 4),
                ],
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final rangeLabel = _customRange != null
        ? "${formatShortDate(_customRange!.start)} \u2013 ${formatShortDate(_customRange!.end)}"
        : tr("Date range");

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          pill(tr("Today"), _TaskFilter.today),
          pill(tr("Whole month"), _TaskFilter.month),
          pill(
            rangeLabel,
            _TaskFilter.range,
            onTap: _pickCustomRange,
            icon: _customRange == null ? Icons.date_range : Icons.edit_calendar,
          ),
        ],
      ),
    );
  }

  Widget _statusFilterDropdown() {
    return Align(
      alignment: Alignment.centerRight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            tr("Project Status"),
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black45),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.filter_list, size: 16, color: navy),
                const SizedBox(width: 4),
                DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: _statusFilter,
                    dropdownColor: Colors.white,
                    itemHeight: 56,
                    icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: navy),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                    borderRadius: BorderRadius.circular(12),
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(tr("All")),
                        ),
                      ),
                      // Assigned and Overdue aren't shown on the dashboard
                      // anymore, so they're left out of this dropdown too —
                      // quickStatusFilters itself stays untouched since
                      // other pages (like Job History) still use it as-is.
                      for (final s in quickStatusFilters)
                        if (s != "Assigned" && s != "Overdue")
                          DropdownMenuItem<String?>(
                            value: s,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text(tr(s)),
                            ),
                          ),
                    ],
                    onChanged: (value) => setState(() => _statusFilter = value),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _jobCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    String? jobId,
    String? status,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.push(
          context,
          AppRoute.to(
            JobDetailsPage(
              title: title,
              subtitle: subtitle,
              time: time,
              jobId: jobId,
              status: status,
              heroTag: jobId != null ? 'job-icon-$jobId' : null,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildCardIcon(icon, jobId),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (status != null) ...[
                        _statusChip(status),
                        const SizedBox(width: 6),
                      ],
                      const Icon(Icons.access_time, size: 12, color: Colors.black38),
                      const SizedBox(width: 4),
                      Text(
                        time,
                        style: const TextStyle(fontSize: 11, color: Colors.black45),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardIcon(IconData icon, String? jobId) {
    final badge = Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: navy.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: navy),
    );
    return jobId == null ? badge : Hero(tag: 'job-icon-$jobId', child: badge);
  }

  Widget _statusChip(String status) {
    final color = statusChartColors[status] ?? Colors.blueGrey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        tr(status),
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _BarData {
  final String label;
  final int value;
  final Color color;
  final String filterKey; // canonical, language-independent status key
  _BarData(this.label, this.value, this.color, this.filterKey);
}

/// The dashboard's job-status visual: a big, dependency-free 3D (extruded)
/// pie chart up top, with the full status list (dot + label + count)
/// underneath it — matching the reference list layout. Tapping a pie slice
/// (or a list row) filters the Tasks list below by that status; tapping
/// the already-selected one again clears the filter.
class _DashboardStatusChart extends StatelessWidget {
  final List<_BarData> bars;
  final String? selectedFilterKey;
  final ValueChanged<String> onBarTap;

  const _DashboardStatusChart({required this.bars, required this.onBarTap, this.selectedFilterKey});

  @override
  Widget build(BuildContext context) {
    final total = bars.fold<int>(0, (a, b) => a + b.value);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Chart header + big 3D pie chart ---
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr("Jobs"),
                  style: const TextStyle(fontSize: 12, color: Colors.black45, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  "$total",
                  style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: navy),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 220,
                  child: total == 0
                      ? Center(
                          child: Text(tr("No data yet"), style: const TextStyle(color: Colors.black38, fontSize: 12)),
                        )
                      : Center(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final size = Size(
                                constraints.maxWidth,
                                constraints.maxHeight,
                              );
                              return TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0, end: 1),
                                duration: const Duration(milliseconds: 650),
                                curve: Curves.easeOutCubic,
                                builder: (context, progress, _) => GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTapUp: (details) {
                                    final key = _Pie3DGeometry.hitTest(
                                      size: size,
                                      bars: bars,
                                      localPosition: details.localPosition,
                                    );
                                    if (key != null) onBarTap(key);
                                  },
                                  child: CustomPaint(
                                    size: size,
                                    painter: _Pie3DPainter(
                                      bars: bars,
                                      selectedFilterKey: selectedFilterKey,
                                      progress: progress,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(height: 1, color: Colors.black.withValues(alpha: 0.06)),
          ),
          // --- Status list, full width, below the chart ---
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: bars.map((bar) {
                final selected = selectedFilterKey == bar.filterKey;
                return InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => onBarTap(bar.filterKey),
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected ? bar.color.withValues(alpha: 0.10) : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(color: bar.color, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            bar.label,
                            style: TextStyle(
                              fontSize: 13,
                              color: selected ? bar.color : Colors.black54,
                              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          "${bar.value}",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: selected ? bar.color : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shared slice geometry for the 3D pie: given a box [size], works out the
/// ellipse center/radii/extrusion depth, and each bar's start/end angle
/// around it. Both the painter and the tap handler use this so drawing and
/// hit-testing always agree on where each slice actually is.
class _Pie3DGeometry {
  final Offset center;
  final double radiusX;
  final double radiusY;
  final double depth;

  _Pie3DGeometry(this.center, this.radiusX, this.radiusY, this.depth);

  factory _Pie3DGeometry.of(Size size) {
    final radiusX = min(size.width / 2 - 4, 108.0);
    final radiusY = radiusX * 0.58;
    final depth = radiusY * 0.85;
    final cx = size.width / 2;
    // Center the ellipse+extrusion block vertically within the box.
    final cy = (size.height - depth) / 2;
    return _Pie3DGeometry(Offset(cx, cy), radiusX, radiusY, depth);
  }

  /// Cumulative slice boundaries in "raw" angle space, starting at -pi/2
  /// (12 o'clock) and sweeping clockwise. Skips zero-value bars.
  static List<MapEntry<_BarData, List<double>>> slices(List<_BarData> bars) {
    final total = bars.fold<int>(0, (a, b) => a + b.value);
    final result = <MapEntry<_BarData, List<double>>>[];
    if (total == 0) return result;
    double angle = -pi / 2;
    for (final bar in bars) {
      if (bar.value <= 0) continue;
      final sweep = (bar.value / total) * 2 * pi;
      result.add(MapEntry(bar, [angle, angle + sweep]));
      angle += sweep;
    }
    return result;
  }

  /// Returns the filterKey of the slice under [localPosition], or null if
  /// the tap missed the pie entirely.
  static String? hitTest({
    required Size size,
    required List<_BarData> bars,
    required Offset localPosition,
  }) {
    final geo = _Pie3DGeometry.of(size);
    final dx = localPosition.dx - geo.center.dx;
    final dy = localPosition.dy - geo.center.dy;
    // Roughly bound the tap to the pie's overall silhouette (top ellipse
    // plus the extruded band beneath it) before worrying about angle.
    final withinX = dx.abs() <= geo.radiusX + 4;
    final withinY = dy >= -(geo.radiusY + 4) && dy <= geo.radiusY + geo.depth + 4;
    if (!withinX || !withinY) return null;

    var a = atan2(dy / geo.radiusY, dx / geo.radiusX);
    if (a < -pi / 2) a += 2 * pi; // fold into the same angle domain used when drawing
    for (final entry in slices(bars)) {
      final range = entry.value;
      if (a >= range[0] && a < range[1]) return entry.key.filterKey;
    }
    return null;
  }
}

/// Paints an extruded ("3D") pie: an elliptical top sliced into wedges,
/// sitting on a cylinder-like wall so the front-facing half reads as
/// having depth. [progress] (0..1) animates the whole pie sweeping in on
/// first build.
class _Pie3DPainter extends CustomPainter {
  final List<_BarData> bars;
  final String? selectedFilterKey;
  final double progress;

  _Pie3DPainter({required this.bars, required this.selectedFilterKey, required this.progress});

  Offset _pointOn(Offset center, double radiusX, double radiusY, double angle, double dy) {
    return Offset(center.dx + radiusX * cos(angle), center.dy + dy + radiusY * sin(angle));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final geo = _Pie3DGeometry.of(size);
    final slices = _Pie3DGeometry.slices(bars);
    if (slices.isEmpty) return;

    final hasSelection = selectedFilterKey != null;
    // Only the raw-angle range between 0 and pi faces the viewer, the
    // bottom half of the ellipse — that's the only part that needs an
    // extruded wall, since the back half is hidden behind the top face.
    const frontStart = 0.0;
    const frontEnd = pi;

    // --- Pass 1: extruded side walls for the visible front half ---
    for (final entry in slices) {
      final bar = entry.key;
      final range = entry.value;
      final a0 = -pi / 2 + (range[0] - (-pi / 2)) * progress;
      final a1 = -pi / 2 + (range[1] - (-pi / 2)) * progress;
      final ov0 = max(a0, frontStart);
      final ov1 = min(a1, frontEnd);
      if (ov1 <= ov0) continue;

      final selected = selectedFilterKey == bar.filterKey;
      final opacity = !hasSelection || selected ? 1.0 : 0.30;
      final wallColor = Color.lerp(bar.color, Colors.black, 0.28)!.withValues(alpha: opacity);

      final segments = max(2, ((ov1 - ov0) / (pi / 24)).ceil());
      final wallPath = Path();
      for (int i = 0; i <= segments; i++) {
        final a = ov0 + (ov1 - ov0) * i / segments;
        final p = _pointOn(geo.center, geo.radiusX, geo.radiusY, a, 0);
        if (i == 0) {
          wallPath.moveTo(p.dx, p.dy);
        } else {
          wallPath.lineTo(p.dx, p.dy);
        }
      }
      for (int i = segments; i >= 0; i--) {
        final a = ov0 + (ov1 - ov0) * i / segments;
        final p = _pointOn(geo.center, geo.radiusX, geo.radiusY, a, geo.depth);
        wallPath.lineTo(p.dx, p.dy);
      }
      wallPath.close();
      canvas.drawPath(wallPath, Paint()..color = wallColor);
    }

    // --- Pass 2: the flat top ellipse, sliced into wedges ---
    for (final entry in slices) {
      final bar = entry.key;
      final range = entry.value;
      final a0 = -pi / 2 + (range[0] - (-pi / 2)) * progress;
      final a1 = -pi / 2 + (range[1] - (-pi / 2)) * progress;
      if (a1 <= a0) continue;

      final selected = selectedFilterKey == bar.filterKey;
      final opacity = !hasSelection || selected ? 1.0 : 0.30;
      final topColor = Color.lerp(bar.color, Colors.white, 0.12)!.withValues(alpha: opacity);

      // Lift a selected slice slightly for a subtle "pop out" cue.
      final lift = selected ? 6.0 : 0.0;
      final center = Offset(geo.center.dx, geo.center.dy - lift);

      final segments = max(2, ((a1 - a0) / (pi / 24)).ceil());
      final wedge = Path()..moveTo(center.dx, center.dy);
      for (int i = 0; i <= segments; i++) {
        final a = a0 + (a1 - a0) * i / segments;
        final p = _pointOn(center, geo.radiusX, geo.radiusY, a, 0);
        wedge.lineTo(p.dx, p.dy);
      }
      wedge.close();
      canvas.drawPath(wedge, Paint()..color = topColor);
      canvas.drawPath(
        wedge,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _Pie3DPainter oldDelegate) =>
      oldDelegate.bars != bars ||
      oldDelegate.selectedFilterKey != selectedFilterKey ||
      oldDelegate.progress != progress;
}