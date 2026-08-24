import 'package:flutter/material.dart';
import 'app_routes.dart';
import 'job_history_page.dart';
import 'assign_job_detail_page.dart';
import 'app_core.dart';


class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late DateTime _visibleMonth; // first day of the month being shown
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDay = DateTime(now.year, now.month, now.day);
    _visibleMonth = DateTime(now.year, now.month, 1);
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<HistoryJob> _jobsOn(DateTime day) {
    return JobHistoryPage.allJobs.where((j) => jobActiveOn(j, day)).toList();
  }

  void _changeMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta, 1);
    });
  }

  void _createForSelectedDay() {
    Navigator.push(
      context,
      AppRoute.to(
        AssignJobDetailPage(
          engineers: engineerNames,
          initialDate: _selectedDay,
        ),
      ),
    );
  }

  void _editJob(HistoryJob job) {
    Navigator.push(
      context,
      AppRoute.to(AssignJobDetailPage(existing: job, engineers: engineerNames)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: AppLocale.languageNotifier,
      builder: (context, _, __) => ValueListenableBuilder<List<HistoryJob>>(
        valueListenable: JobHistoryPage.createdJobsNotifier,
        builder: (context, _, __) => _buildScaffold(context),
      ),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    const monthNames = [
      "January", "February", "March", "April", "May", "June",
      "July", "August", "September", "October", "November", "December",
    ];

    return Scaffold(
      backgroundColor: bgGray,
      appBar: AppBar(
        backgroundColor: navy,
        elevation: 0,
        title: Text(tr("Calendar"), style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: navy,
        onPressed: _createForSelectedDay,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(tr("New task"), style: const TextStyle(color: Colors.white)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => _changeMonth(-1),
                    icon: const Icon(Icons.chevron_left, color: navy),
                  ),
                  Text(
                    "${tr(monthNames[_visibleMonth.month - 1])} ${_visibleMonth.year}",
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  IconButton(
                    onPressed: () => _changeMonth(1),
                    icon: const Icon(Icons.chevron_right, color: navy),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: _monthGrid(),
            ),
            Expanded(child: _selectedDayPanel()),
          ],
        ),
      ),
    );
  }

  Widget _monthGrid() {
    const weekdayLabels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    final firstOfMonth = _visibleMonth;
    final daysInMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;
    // DateTime.weekday: Mon=1 ... Sun=7. Leading blanks before day 1.
    final leadingBlanks = firstOfMonth.weekday - 1;
    final today = DateTime.now();
    final todayNorm = DateTime(today.year, today.month, today.day);

    final cells = <Widget>[];
    for (final label in weekdayLabels) {
      cells.add(Center(
        child: Text(
          tr(label),
          style: const TextStyle(fontSize: 11, color: Colors.black45, fontWeight: FontWeight.w600),
        ),
      ));
    }
    for (int i = 0; i < leadingBlanks; i++) {
      cells.add(const SizedBox.shrink());
    }
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_visibleMonth.year, _visibleMonth.month, day);
      final isToday = _sameDay(date, todayNorm);
      final isSelected = _sameDay(date, _selectedDay);
      final hasJobs = _jobsOn(date).isNotEmpty;

      cells.add(
        InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => setState(() => _selectedDay = date),
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isSelected ? navy : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: isToday && !isSelected ? Border.all(color: navy, width: 1.4) : null,
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
                    color: !hasJobs
                        ? Colors.transparent
                        : (isSelected ? Colors.white : navy),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.15,
      children: cells,
    );
  }

  Widget _selectedDayPanel() {
    final jobs = _jobsOn(_selectedDay);
    final today = DateTime.now();
    final todayNorm = DateTime(today.year, today.month, today.day);
    final dayDiff = _selectedDay.difference(todayNorm).inDays;

    String subtitle;
    if (dayDiff == 0) {
      subtitle = tr("Today");
    } else if (dayDiff == 1) {
      subtitle = tr("Tomorrow");
    } else if (dayDiff > 1) {
      subtitle = "${tr("In")} $dayDiff ${tr("days")}";
    } else {
      subtitle = formatJobDate(_selectedDay);
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 90),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                formatJobDate(_selectedDay),
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: navy.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: navy, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: jobs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.event_available_outlined, size: 32, color: Colors.black26),
                        const SizedBox(height: 8),
                        Text(tr("Nothing scheduled"), style: const TextStyle(color: Colors.black45, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(tr("Tap New task to schedule one"), style: const TextStyle(color: Colors.black38, fontSize: 12)),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: jobs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) => _jobRow(jobs[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _jobRow(HistoryJob job) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _editJob(job),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: bgGray,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(jobTypeIcon(job.jobType), size: 18, color: navy),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(job.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(
                    job.assignedTo ?? tr("Unassigned"),
                    style: TextStyle(
                      fontSize: 12,
                      color: job.assignedTo == null ? Colors.black38 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.black26, size: 18),
          ],
        ),
      ),
    );
  }
}
