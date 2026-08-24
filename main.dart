import 'package:flutter/material.dart';
import 'login_page.dart';
import 'dashboard_page.dart';
import 'job_history_page.dart';
import 'sales_requests.dart';
import 'sales_home_page.dart';
import 'app_core.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppStorage.init();
  AppLocale.loadSaved();
  AppSession.loadSaved();
  JobHistoryPage.loadSaved();
  SalesRequests.loadSaved();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ServicePro',
      debugShowCheckedModeBanner: false,
      // Without this, Flutter's default Material 3 theme seeds itself with
      // purple and that shows up anywhere we didn't explicitly set a color
      // — like the background behind an open dropdown menu. Seeding from
      // the app's own brand color keeps those default surfaces on-brand
      // instead of an unrelated purple tint.
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: primaryColor),
      ),
      home: !AppSession.isLoggedIn
          ? const LoginPage()
          : (AppSession.isSales ? const SalesHomePage() : const DashboardPage()),
    );
  }
}