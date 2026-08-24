import 'package:flutter/material.dart';
import 'app_routes.dart';
import 'bottom_nav.dart';
import 'new_project_form_page.dart';
import 'engineer_action_request_page.dart';
import 'after_sale_service_request_page.dart';
import 'app_core.dart';

/// Home screen for the Sales role — three actions, matching the reference
/// design: New Project Information, Engineer Action Request, After Sale
/// Service Request.
class SalesHomePage extends StatelessWidget {
  const SalesHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: AppLocale.languageNotifier,
      builder: (context, _, __) {
        return Scaffold(
          backgroundColor: bgGray,
          appBar: AppBar(
            backgroundColor: navy,
            elevation: 0,
            title: Text(tr("Sales"), style: const TextStyle(color: Colors.white)),
            iconTheme: const IconThemeData(color: Colors.white),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${tr("Welcome")}, ${AppSession.currentName}",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tr("What would you like to do?"),
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [navy.withValues(alpha: 0.06), navy.withValues(alpha: 0.14)],
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _actionTile(
                            context,
                            icon: Icons.playlist_add_check_circle_outlined,
                            label: tr("New Project Information"),
                            onTap: () => Navigator.push(context, AppRoute.to(const NewProjectFormPage())),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _actionTile(
                            context,
                            icon: Icons.engineering_outlined,
                            label: tr("Engineer Action Request"),
                            onTap: () => Navigator.push(context, AppRoute.to(const EngineerActionRequestPage())),
                          ),
                        ),
                        const SizedBox(width: 12),                 
                        Expanded(
                          child: _actionTile(
                            context,
                            icon: Icons.support_agent_outlined,
                            label: tr("After Sale Service Request"),
                            onTap: () => Navigator.push(context, AppRoute.to(const AfterSaleServiceRequestPage())),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: const AppBottomNav(current: NavTab.salesHome),
        );
      },
    );
  }

  Widget _actionTile(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          decoration: BoxDecoration(
            color: navy,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: navy.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 5)),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 32),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 3,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12, height: 1.25),
              ),
            ],
          ),
        ),
      ),
    );
  }
}