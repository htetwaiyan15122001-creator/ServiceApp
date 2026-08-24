import 'package:flutter/material.dart';
import 'app_routes.dart';
import 'app_core.dart';

const List<String> _monthNamesFull = [
  "January", "February", "March", "April", "May", "June",
  "July", "August", "September", "October", "November", "December",
];

const List<String> _monthAbbr = [
  "Jan", "Feb", "Mar", "Apr", "May", "Jun",
  "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
];

const List<String> _weekdayAbbr = [
  "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun",
];

/// "Mon, Jul 27" style short label used in the summary bar.
String formatShortDate(DateTime d) {
  final weekday = _weekdayAbbr[d.weekday - 1];
  return "$weekday, ${_monthAbbr[d.month - 1]} ${d.day}";
}

/// Opens the start/end date range picker as a full page and returns the
/// chosen [DateTimeRange], or null if the user backed out without picking.
Future<DateTimeRange?> pickDateRange(
  BuildContext context, {
  DateTimeRange? initialRange,
}) {
  return Navigator.push<DateTimeRange>(
    context,
    AppRoute.to(_DateRangePickerPage(initialRange: initialRange)),
  );
}

class _DateRangePickerPage extends StatefulWidget {
  final DateTimeRange? initialRange;
  const _DateRangePickerPage({this.initialRange});

  @override
  State<_DateRangePickerPage> createState() => _DateRangePickerPageState();
}

class _DateRangePickerPageState extends State<_DateRangePickerPage> {
  DateTime? _start;
  DateTime? _end;
  late final List<DateTime> _months;

  @override
  void initState() {
    super.initState();
    _start = widget.initialRange?.start;
    _end = widget.initialRange?.end;

    final now = DateTime.now();
    final firstMonth = DateTime(now.year, now.month, 1);
    // Show a year and a half ahead — plenty of runway for scheduling.
    _months = List.generate(18, (i) => DateTime(firstMonth.year, firstMonth.month + i, 1));
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _onTapDay(DateTime day) {
    setState(() {
      if (_start == null || (_start != null && _end != null)) {
        _start = day;
        _end = null;
      } else if (day.isBefore(_start!)) {
        _start = day;
        _end = null;
      } else {
        _end = day;
      }
    });
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
      appBar: AppBar(
        backgroundColor: navy,
        elevation: 0,
        title: Text(tr("Select dates"), style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              itemCount: _months.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: _monthBlock(_months[index]),
              ),
            ),
          ),
          _summaryBar(),
        ],
      ),
    );
  }

  Widget _monthBlock(DateTime month) {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leadingBlanks = month.weekday - 1; // Mon=1 ... Sun=7
    final now = DateTime.now();
    final todayNorm = DateTime(now.year, now.month, now.day);

    final cells = <Widget>[];
    for (final label in _weekdayAbbr) {
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
      final date = DateTime(month.year, month.month, day);
      final isPast = date.isBefore(todayNorm);
      final isToday = _sameDay(date, todayNorm);
      final isStart = _start != null && _sameDay(date, _start!);
      final isEnd = _end != null && _sameDay(date, _end!);
      final inRange = _start != null &&
          _end != null &&
          date.isAfter(_start!) &&
          date.isBefore(_end!);

      cells.add(_dayCell(
        date: date,
        day: day,
        isPast: isPast,
        isToday: isToday,
        isStart: isStart,
        isEnd: isEnd,
        inRange: inRange,
      ));
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          Text(
            "${tr(_monthNamesFull[month.month - 1])} ${month.year}",
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.15,
            children: cells,
          ),
        ],
      ),
    );
  }

  Widget _dayCell({
    required DateTime date,
    required int day,
    required bool isPast,
    required bool isToday,
    required bool isStart,
    required bool isEnd,
    required bool inRange,
  }) {
    final isEndpoint = isStart || isEnd;

    Widget content = Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isEndpoint
            ? navy
            : (inRange ? navy.withValues(alpha: 0.12) : Colors.transparent),
        borderRadius: BorderRadius.circular(10),
        border: isToday && !isEndpoint ? Border.all(color: navy, width: 1.2) : null,
      ),
      child: Center(
        child: Text(
          "$day",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isPast
                ? Colors.black26
                : (isEndpoint ? Colors.white : Colors.black87),
          ),
        ),
      ),
    );

    if (isPast) return content;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => _onTapDay(date),
      child: content,
    );
  }

  Widget _summaryBar() {
    String label;
    if (_start != null && _end != null) {
      label = "${formatShortDate(_start!)}  \u2013  ${formatShortDate(_end!)}";
    } else if (_start != null) {
      label = "${formatShortDate(_start!)}  \u2013  ${tr("Select end date")}";
    } else {
      label = tr("Select start date");
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
            TextButton(
              onPressed: (_start == null && _end == null)
                  ? null
                  : () => setState(() {
                        _start = null;
                        _end = null;
                      }),
              child: Text(tr("Clear")),
            ),
            const SizedBox(width: 4),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: navy,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: _start == null
                  ? null
                  : () => Navigator.pop(
                        context,
                        DateTimeRange(start: _start!, end: _end ?? _start!),
                      ),
              child: Text(tr("Done"), style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}