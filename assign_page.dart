import 'package:flutter/material.dart';
import 'app_routes.dart';
import 'bottom_nav.dart';
import 'job_history_page.dart';
import 'assign_job_detail_page.dart';
import 'calendar_page.dart';
import 'app_core.dart';

class AssignPage extends StatefulWidget {
  const AssignPage({super.key});

  @override
  State<AssignPage> createState() => _AssignPageState();
}

class _AssignPageState extends State<AssignPage> {
  final List<String> engineers = engineerNames;

  void _createJob() {
    Navigator.push(
      context,
      AppRoute.to(AssignJobDetailPage(engineers: engineers)),
    );
  }

  void _editJob(HistoryJob job) {
    Navigator.push(
      context,
      AppRoute.to(AssignJobDetailPage(existing: job, engineers: engineers)),
    );
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
        title: Text(tr("Assign Jobs"), style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined),
            tooltip: tr("Calendar"),
            onPressed: () {
              Navigator.push(context, AppRoute.to(const CalendarPage()));
            },
          ),
        ],
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: navy,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                onPressed: _createJob,
                icon: const Icon(Icons.add, color: Colors.white),
                label: Text(
                  tr("Create"),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ValueListenableBuilder<List<HistoryJob>>(
                valueListenable: JobHistoryPage.createdJobsNotifier,
                builder: (context, jobs, _) {
                  if (jobs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.assignment_outlined, size: 40, color: Colors.black26),
                          const SizedBox(height: 10),
                          Text(
                            tr("No jobs yet"),
                            style: const TextStyle(color: Colors.black45, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tr("Tap Create to assign a new job"),
                            style: const TextStyle(color: Colors.black38, fontSize: 12),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    itemCount: jobs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) => _jobTile(jobs[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(current: NavTab.assign),
    );
  }

  Widget _jobTile(HistoryJob job) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _editJob(job),
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
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: navy.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.engineering_outlined, color: navy),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job.title,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    job.subtitle,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 13,
                        color: job.assignedTo == null ? Colors.black38 : navy,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        job.assignedTo ?? tr("Unassigned"),
                        style: TextStyle(
                          fontSize: 12,
                          color: job.assignedTo == null ? Colors.black38 : Colors.black87,
                          fontWeight: job.assignedTo == null ? FontWeight.normal : FontWeight.w600,
                        ),
                      ),
                      if (job.action != null) ...[
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: navy.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            job.action!,
                            style: const TextStyle(fontSize: 10, color: navy, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.black26),
          ],
        ),
      ),
    );
  }
}