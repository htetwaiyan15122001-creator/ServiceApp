import 'package:flutter/material.dart';
import 'dashboard_page.dart';
import 'sales_home_page.dart';
import 'app_routes.dart';
import 'app_core.dart';
import 'sharepoint_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool obscure = true;
  bool _loading = false;
  String? _errorText;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGray,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: navy.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Image.asset(
                    'assets/images/JUNG_LOGO_Black.png',
                    width: 48,
                    height: 48,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                tr("Welcome Back"),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: navy,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                tr("Please sign in to continue"),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 36),
              _buildField(
                controller: emailController,
                label: tr("Email address"),
                icon: Icons.email_outlined,
              ),
              const SizedBox(height: 16),
              Container(
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
                child: TextField(
                  controller: passwordController,
                  obscureText: obscure,
                  decoration: InputDecoration(
                    labelText: tr("Password"),
                    prefixIcon: const Icon(Icons.lock_outline, color: navy, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: Colors.black38,
                        size: 20,
                      ),
                      onPressed: () => setState(() => obscure = !obscure),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: Text(tr("Forgot Password?"), style: const TextStyle(color: navy)),
                ),
              ),
              const SizedBox(height: 16),
              if (_errorText != null) ...[
                Text(
                  _errorText!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
                const SizedBox(height: 12),
              ],
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: navy,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _loading ? null : _handleSignIn,
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                        )
                      : Text(
                          tr("Sign In"),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSignIn() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _errorText = tr("Enter your work email"));
      return;
    }

    setState(() {
      _loading = true;
      _errorText = null;
    });

    // Role is no longer picked in the app — it's whatever an admin has set
    // for this email address in the backend's UserRoles list. This also
    // doubles as the account gate: an email that isn't in that list can't
    // sign in at all.
    final result = await SharePointService.fetchUserRole(email);

    if (!mounted) return;

    if (!result.success) {
      setState(() {
        _loading = false;
        _errorText = result.error;
      });
      return;
    }

    final role = UserRole.values.firstWhere(
      (r) => r.name == result.role,
      orElse: () => UserRole.engineer,
    );

    AppSession.currentRole = role;
    AppSession.currentEmail = email;
    AppSession.currentName = result.name ?? AppSession.deriveNameFromEmail(email);
    AppSession.markLoggedIn();

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      AppRoute.replace(
        role == UserRole.sales ? const SalesHomePage() : const DashboardPage(),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return Container(
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
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: navy, size: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        ),
      ),
    );
  }
}