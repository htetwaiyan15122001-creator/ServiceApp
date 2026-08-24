import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'app_routes.dart';
import 'survey_page.dart';
import 'project_history_page.dart';
import 'job_history_page.dart';
import 'app_core.dart';

/// Read-only detail view for a single job, opened from the Dashboard,
/// Job History, and Profile "Work History" list.
class JobDetailsPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final String time;
  final String? jobId;
  final String? status;
  final String? heroTag;

  const JobDetailsPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.time,
    this.jobId,
    this.status,
    this.heroTag,
  });

  Color _statusColor(String s) {
    switch (s) {
      case "Completed":
        return Colors.green;
      case "Overdue":
        return Colors.red;
      case "Pending Signature":
        return Colors.orange;
      case "Unassigned":
        return Colors.grey;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final job = jobId != null ? JobHistoryPage.findJob(jobId!) : null;
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: AppLocale.languageNotifier,
      builder: (context, _, __) {
        return Scaffold(
          backgroundColor: bgGray,
          appBar: AppBar(
            backgroundColor: navy,
            elevation: 0,
            title: Text(tr("Job Details"), style: const TextStyle(color: Colors.white)),
            iconTheme: const IconThemeData(color: Colors.white),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _iconBadge(),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _row(Icons.notes_outlined, subtitle),
                      const SizedBox(height: 10),
                      _row(Icons.access_time, time),
                      if (status != null) ...[
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Text(
                              "${tr("Status")}: ",
                              style: const TextStyle(fontSize: 12, color: Colors.black54),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: _statusColor(status!).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                tr(status!),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _statusColor(status!),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (job != null && job.photoBase64.isNotEmpty) ...[
                  _sectionCard(
                    title: tr("Photos"),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: job.photoBase64.length,
                      itemBuilder: (context, index) {
                        final bytes = base64Decode(job.photoBase64[index]);
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: GestureDetector(
                            onTap: () => _showFullImage(context, bytes),
                            child: Image.memory(bytes, fit: BoxFit.cover),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                if (job != null && job.signatureBase64 != null) ...[
                  _sectionCard(
                    title: tr("Customer Signature"),
                    child: GestureDetector(
                      onTap: () => _showFullImage(context, base64Decode(job.signatureBase64!)),
                      child: Container(
                        width: double.infinity,
                        height: 140,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: bgGray,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Image.memory(base64Decode(job.signatureBase64!), fit: BoxFit.contain),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                if (jobId != null) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: navy,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          AppRoute.to(SurveyPage(jobId: jobId)),
                        );
                      },
                      icon: const Icon(Icons.assignment_turned_in_outlined, color: Colors.white, size: 20),
                      label: Text(
                        tr("Start Service"),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: navy, width: 1.4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        AppRoute.to(ProjectHistoryPage(projectTitle: title)),
                      );
                    },
                    icon: const Icon(Icons.history, color: navy, size: 20),
                    label: Text(
                      tr("View Project History"),
                      style: const TextStyle(color: navy, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
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
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  void _showFullImage(BuildContext context, Uint8List bytes) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(backgroundColor: Colors.black, iconTheme: const IconThemeData(color: Colors.white)),
          body: Center(child: InteractiveViewer(child: Image.memory(bytes))),
        ),
      ),
    );
  }

  Widget _row(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.black45),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 13, color: Colors.black87)),
        ),
      ],
    );
  }

  Widget _iconBadge() {
    final badge = Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: navy.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.build, color: navy, size: 22),
    );
    // Only wrap in a Hero when the list tile that pushed this page passed
    // a matching tag — without it, Hero has nothing to animate from.
    return heroTag == null ? badge : Hero(tag: heroTag!, child: badge);
  }
}