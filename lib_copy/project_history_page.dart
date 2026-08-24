import 'package:flutter/material.dart';
import 'app_core.dart';

/// Shows the activity log for a single project/job — what happened and when.
/// Each entry is a rectangle card with a "Detail" button that opens the
/// full note for that entry.
class ProjectHistoryPage extends StatelessWidget {
  final String projectTitle;
  const ProjectHistoryPage({super.key, required this.projectTitle});

  static final List<_HistoryEntry> _entries = [
    _HistoryEntry(
      "14 May 2026",
      "08:55 AM",
      "Adam K.",
      "Checked in on site",
      "Engineer arrived on site and confirmed job scope with the site contact before starting work.",
    ),
    _HistoryEntry(
      "14 May 2026",
      "09:00 AM",
      "Adam K.",
      "Started service",
      "Began initial inspection of the unit and surrounding area to diagnose the reported issue.",
    ),
    _HistoryEntry(
      "14 May 2026",
      "09:40 AM",
      "Adam K.",
      "Replaced part",
      "Identified a faulty component, replaced it with a new part from the service kit, and re-tested the unit.",
    ),
    _HistoryEntry(
      "14 May 2026",
      "10:15 AM",
      "Adam K.",
      "Completed service",
      "Confirmed the unit was operating normally and cleaned up the work area.",
    ),
    _HistoryEntry(
      "14 May 2026",
      "10:20 AM",
      "Nara P.",
      "Customer signed off",
      "Customer reviewed the completed work and signed the service report.",
    ),
  ];

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
        title: Text("$projectTitle · History", style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: _entries.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final entry = _entries[index];
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
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
                Container(
                  width: 5,
                  height: 54,
                  decoration: BoxDecoration(
                    color: navy,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 11, color: Colors.black38),
                          const SizedBox(width: 4),
                          Text(
                            entry.date,
                            style: const TextStyle(fontSize: 11, color: Colors.black45),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.access_time, size: 11, color: Colors.black38),
                          const SizedBox(width: 4),
                          Text(
                            entry.time,
                            style: const TextStyle(fontSize: 11, color: Colors.black45),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        entry.action,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.person_outline, size: 12, color: Colors.black38),
                          const SizedBox(width: 4),
                          Text(
                            entry.engineerName,
                            style: const TextStyle(fontSize: 12, color: Colors.black54),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => _showDetail(context, entry),
                  child: Text(tr("Detail"), style: const TextStyle(color: navy, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showDetail(BuildContext context, _HistoryEntry entry) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(entry.action),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today, size: 13, color: Colors.black45),
                const SizedBox(width: 6),
                Text(entry.date, style: const TextStyle(color: Colors.black45, fontSize: 12)),
                const SizedBox(width: 12),
                const Icon(Icons.access_time, size: 13, color: Colors.black45),
                const SizedBox(width: 6),
                Text(entry.time, style: const TextStyle(color: Colors.black45, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.person_outline, size: 13, color: Colors.black45),
                const SizedBox(width: 6),
                Text(entry.engineerName, style: const TextStyle(color: Colors.black45, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 10),
            Text(entry.detail),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr("Close"), style: const TextStyle(color: navy)),
          ),
        ],
      ),
    );
  }
}

class _HistoryEntry {
  final String date;
  final String time;
  final String engineerName;
  final String action;
  final String detail;
  _HistoryEntry(this.date, this.time, this.engineerName, this.action, this.detail);
}