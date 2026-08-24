import 'package:flutter/material.dart';
import 'app_routes.dart';
import 'dashboard_page.dart';
import 'job_history_page.dart';
import 'profile_page.dart';
import 'assign_page.dart';
import 'sales_home_page.dart';
import 'app_core.dart';

/// Which tab is currently active, so the right pill highlights
/// no matter which page the nav bar is shown on.
enum NavTab { home, projects, assign, profile, salesHome }

/// Floating, pill-style bottom navigation bar used on every main page.
/// The active tab expands into a filled navy pill with its label;
/// inactive tabs are just a grey icon. Managers get an extra "Assign" tab.
class AppBottomNav extends StatelessWidget {
  final NavTab current;
  const AppBottomNav({super.key, required this.current});

  void _go(BuildContext context, Widget page) {
    Navigator.pushReplacement(context, AppRoute.replace(page));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([AppSession.roleNotifier, AppLocale.languageNotifier]),
      builder: (context, _) {
        final role = AppSession.currentRole;
        final items = role == UserRole.sales
            ? <_NavItem>[
                _NavItem(NavTab.salesHome, Icons.home_rounded, tr("Home"),
                    () => _go(context, const SalesHomePage())),
                _NavItem(NavTab.profile, Icons.person_rounded, tr("Profile"),
                    () => _go(context, const ProfilePage())),
              ]
            : <_NavItem>[
                _NavItem(NavTab.home, Icons.home_rounded, tr("Home"),
                    () => _go(context, const DashboardPage())),
                _NavItem(NavTab.projects, Icons.list_alt_rounded, tr("Projects"),
                    () => _go(context, const JobHistoryPage())),
                if (role == UserRole.manager)
                  _NavItem(NavTab.assign, Icons.assignment_ind_rounded, tr("Assign"),
                      () => _go(context, const AssignPage())),
                _NavItem(NavTab.profile, Icons.person_rounded, tr("Profile"),
                    () => _go(context, const ProfilePage())),
              ];

        return SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: items.map((item) => _pill(item)).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _pill(_NavItem item) {
    final active = item.tab == current;
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: active ? navy : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(item.icon, size: 26, color: active ? Colors.white : Colors.grey),
            if (active) ...[
              const SizedBox(width: 8),
              Text(
                item.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final NavTab tab;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  _NavItem(this.tab, this.icon, this.label, this.onTap);
}