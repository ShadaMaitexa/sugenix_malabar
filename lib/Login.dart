import 'package:flutter/material.dart';
import 'package:sugenix/signin.dart';
import 'package:sugenix/forgetpass.dart';
import 'package:sugenix/main.dart';
import 'package:sugenix/services/auth_service.dart';
import 'package:sugenix/services/admin_service.dart';
import 'package:sugenix/utils/responsive_layout.dart';
import 'package:sugenix/l10n/app_localizations.dart';
import 'package:sugenix/services/language_service.dart';
import 'package:provider/provider.dart';
import 'package:sugenix/services/locale_notifier.dart';
import 'package:sugenix/screens/admin_panel_screen.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  final AuthService _authService = AuthService();
  final AdminService _adminService = AdminService();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isWide = screenWidth >= 800;
    final double titleSize = ResponsiveHelper.getResponsiveFontSize(
      context,
      mobile: 28,
      tablet: 32,
      desktop: 36,
    );
    final double subtitleSize = ResponsiveHelper.getResponsiveFontSize(
      context,
      mobile: 16,
      tablet: 18,
      desktop: 20,
    );

    return Scaffold(
        body: Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topLeft,
                radius: 0.7,
                colors: [Color(0xFF0C4556), Colors.white],
                stops: [0.0, 1.0],
              ),
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 40),
                          Builder(
                            builder: (context) {
                              final l10n = AppLocalizations.of(context)!;
                              return Text(
                                l10n.welcomeBack,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: titleSize,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                          Builder(
                            builder: (context) {
                              final l10n = AppLocalizations.of(context)!;
                              return Text(
                                l10n.signInToContinue,
                                style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: subtitleSize),
                              );
                            },
                          ),
                          const SizedBox(height: 40),
                          Center(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: isWide ? 520 : double.infinity,
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Builder(
                                    builder: (context) {
                                      final l10n =
                                          AppLocalizations.of(context)!;
                                      return Column(
                                        children: [
                                          TextField(
                                            controller: _emailController,
                                            decoration: InputDecoration(
                                              hintText: l10n.email,
                                              prefixIcon: const Icon(
                                                  Icons.email_outlined),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                borderSide: BorderSide.none,
                                              ),
                                              filled: true,
                                              fillColor: Colors.grey[100],
                                            ),
                                          ),
                                          const SizedBox(height: 20),
                                          TextField(
                                            controller: _passwordController,
                                            obscureText: _obscurePassword,
                                            decoration: InputDecoration(
                                              hintText: l10n.password,
                                              prefixIcon: const Icon(
                                                  Icons.lock_outlined),
                                              suffixIcon: IconButton(
                                                icon: Icon(
                                                  _obscurePassword
                                                      ? Icons.visibility
                                                      : Icons.visibility_off,
                                                ),
                                                onPressed: () {
                                                  setState(() {
                                                    _obscurePassword =
                                                        !_obscurePassword;
                                                  });
                                                },
                                              ),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                borderSide: BorderSide.none,
                                              ),
                                              filled: true,
                                              fillColor: Colors.grey[100],
                                            ),
                                          ),
                                          const SizedBox(height: 20),
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: TextButton(
                                              onPressed: () {
                                                _showForgotPasswordModal(
                                                    context);
                                              },
                                              child: Text(
                                                l10n.forgotPassword,
                                                style: const TextStyle(
                                                  color: Color(0xFF0C4556),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 20),
                                          SizedBox(
                                            width: double.infinity,
                                            height: 50,
                                            child: ElevatedButton(
                                              onPressed: _isLoading
                                                  ? null
                                                  : _handleLogin,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    const Color(0xFF0C4556),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                              ),
                                              child: _isLoading
                                                  ? const SizedBox(
                                                      width: 20,
                                                      height: 20,
                                                      child:
                                                          CircularProgressIndicator(
                                                        color: Colors.white,
                                                        strokeWidth: 2,
                                                      ),
                                                    )
                                                  : Text(
                                                      l10n.login,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                            ),
                                          ),
                                          const SizedBox(height: 20),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                l10n.dontHaveAccount,
                                                style: const TextStyle(
                                                    color: Colors.grey),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          const Signup(),
                                                    ),
                                                  );
                                                },
                                                child: Text(
                                                  l10n.signup,
                                                  style: const TextStyle(
                                                    color: Color(0xFF0C4556),
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Language selector in top-right corner
                  Positioned(
                    top: 10,
                    right: 10,
                    child: _buildLanguageSelector(),
                  ),
                ],
              ),
            )));
  }

  Widget _buildLanguageSelector() {
    return Consumer<LocaleNotifier>(
      builder: (context, localeNotifier, child) {
        final currentLocale = localeNotifier.locale;
        return PopupMenuButton<Locale>(
          onSelected: (Locale locale) {
            localeNotifier.setLocale(locale);
          },
          itemBuilder: (BuildContext context) => [
            const PopupMenuItem<Locale>(
              value: Locale('en'),
              child: Text('English'),
            ),
            const PopupMenuItem<Locale>(
              value: Locale('hi'),
              child: Text('हिंदी'),
            ),
            const PopupMenuItem<Locale>(
              value: Locale('ml'),
              child: Text('മലയാളം'),
            ),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  currentLocale.languageCode == 'en'
                      ? 'EN'
                      : currentLocale.languageCode == 'hi'
                          ? 'HI'
                          : 'ML',
                  style: const TextStyle(
                    color: Color(0xFF0C4556),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.language,
                  color: Color(0xFF0C4556),
                  size: 16,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleLogin() async {
    final l10n = AppLocalizations.of(context)!;

    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnackBar(l10n.fillAllFields);
      return;
    }

    // Hardcoded Admin Login
    if (_emailController.text == 'admin@sugenix.com' &&
        _passwordController.text == 'admin123') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AdminPanelScreen()),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      // Check if credentials match an admin account in Firestore
      final isAdmin =
          await _adminService.verifyAdminCredentials(email, password);

      if (isAdmin) {
        // Admin login - sign in admin user
        await _authService.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => const MainNavigationScreen()),
          );
        }
        return;
      }

      // Regular user login
      await _authService.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Check if user is a doctor or pharmacy and verify approval status
      final userProfile = await _authService.getUserProfile();
      final userRole = userProfile?['role'];

      if (userRole == 'doctor' || userRole == 'pharmacy') {
        final approvalStatus = userProfile?['approvalStatus'] ?? 'pending';

        if (approvalStatus != 'approved') {
          // Sign out if not approved
          await _authService.signOut();

          if (mounted) {
            _showSnackBar(l10n.accountPending);
          }
          return;
        }
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        _showSnackBar('${l10n.loginFailed}: ${e.toString().split(': ').last}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showForgotPasswordModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ForgotPasswordModal(),
    );
  }
}
