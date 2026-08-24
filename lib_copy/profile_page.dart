import 'package:flutter/material.dart';
import 'login_page.dart';
import 'app_routes.dart';
import 'bottom_nav.dart';
import 'job_history_page.dart';
import 'job_details_page.dart';
import 'app_core.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static final List<_WorkItem> _workHistory = [
    _WorkItem("Kansi", "Room 501 · AC Service", "14 May 2026", "Completed"),
    _WorkItem("Adam", "Room 320 · Lighting Maintenance", "13 May 2026", "Completed"),
    _WorkItem("Buugan", "Room 1208 · Switch Socket Issue", "12 May 2026", "In Progress"),
  ];

  @override
  void initState() {
    super.initState();
    AppLocale.languageNotifier.addListener(_onLanguageChanged);
  }

  @override
  void dispose() {
    AppLocale.languageNotifier.removeListener(_onLanguageChanged);
    super.dispose();
  }

  void _onLanguageChanged() => setState(() {});

  void _editName(BuildContext context) {
    final controller = TextEditingController(text: AppSession.currentName);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(tr("Edit Name")),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: tr("Your name")),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr("Cancel")),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                AppSession.currentName = controller.text.trim();
              }
              Navigator.pop(context);
            },
            child: Text(tr("Save"), style: const TextStyle(color: navy, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGray,
      appBar: AppBar(
        backgroundColor: navy,
        elevation: 0,
        title: Text(tr("Profile & Settings"), style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
      ),
      body: SingleChildScrollView(
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
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 32,
                    backgroundColor: navy,
                    child: Icon(Icons.person, color: Colors.white, size: 34),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ValueListenableBuilder<String>(
                      valueListenable: AppSession.nameNotifier,
                      builder: (context, name, _) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tr(AppSession.roleLabel),
                            style: const TextStyle(color: Colors.black54, fontSize: 13),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            AppSession.currentEmail.isEmpty
                                ? tr("No email on file")
                                : AppSession.currentEmail,
                            style: const TextStyle(color: Colors.black38, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _editName(context),
                    icon: const Icon(Icons.edit_outlined, color: navy),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  const Icon(Icons.language, color: navy),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      tr("Language"),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                  _LanguageToggle(),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  tr("Work History"),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      AppRoute.to(const JobHistoryPage()),
                    );
                  },
                  child: Text(tr("View All"), style: const TextStyle(color: navy)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              "${tr("Projects")} ${AppSession.currentName} ${tr("has worked on")}",
              style: const TextStyle(fontSize: 11, color: Colors.black38),
            ),
            const SizedBox(height: 12),
            ..._workHistory.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => Navigator.push(
                      context,
                      AppRoute.to(
                        JobDetailsPage(
                          title: item.title,
                          subtitle: item.subtitle,
                          time: item.date,
                        ),
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: navy.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.build, color: navy, size: 18),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.subtitle,
                                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(item.date, style: const TextStyle(fontSize: 10, color: Colors.black45)),
                              const SizedBox(height: 4),
                              Text(
                                tr(item.status),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: item.status == "Completed" ? Colors.green : Colors.blueGrey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                )),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  AppSession.logOut();
                  Navigator.pushAndRemoveUntil(
                    context,
                    AppRoute.replace(const LoginPage()),
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.logout, color: Colors.red),
                label: Text(tr("Log Out"), style: const TextStyle(color: Colors.red)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(current: NavTab.profile),
    );
  }

}

class _WorkItem {
  final String title;
  final String subtitle;
  final String date;
  final String status;

  _WorkItem(this.title, this.subtitle, this.date, this.status);
}

/// Pill-style EN / TH switch. Tapping a side updates
/// [AppLocale.languageNotifier], which every screen that listens for it
/// rebuilds against immediately.
class _LanguageToggle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: AppLocale.languageNotifier,
      builder: (context, lang, _) {
        return Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: bgGray,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _segment(context, "EN", AppLanguage.en, lang),
              _segment(context, "TH", AppLanguage.th, lang),
            ],
          ),
        );
      },
    );
  }

  Widget _segment(BuildContext context, String label, AppLanguage value, AppLanguage current) {
    final selected = value == current;
    return GestureDetector(
      onTap: () => AppLocale.current = value,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? navy : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black54,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}