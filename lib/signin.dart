import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:sugenix/Login.dart';
import 'package:sugenix/main.dart';
import 'package:sugenix/services/auth_service.dart';
import 'package:sugenix/services/language_service.dart';
import 'package:sugenix/utils/responsive_layout.dart';
import 'package:sugenix/widgets/translated_text.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;
  bool _isLoading = false;
  String _selectedDiabetesType = 'Type 1';
  final AuthService _authService = AuthService();

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
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  TranslatedText(
                    'sign_in_title',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: titleSize,
                      fontWeight: FontWeight.bold,
                    ),
                    fallback: 'Sign in',
                  ),
                  const SizedBox(height: 10),
                  TranslatedText(
                    'signup_journey',
                    style: TextStyle(
                        color: Colors.white70, fontSize: subtitleSize),
                    fallback:
                        'Your journey to smarter diabetes care starts here',
                  ),
                  const SizedBox(height: 40),
                  if (kIsWeb)
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0C4556).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF0C4556).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.local_pharmacy,
                            color: Color(0xFF0C4556),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Web registration is exclusive to pharmacies.',
                              style: TextStyle(
                                color: Colors.grey[800],
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isWide ? 560 : double.infinity,
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
                          child: LanguageBuilder(
                            builder: (context, languageCode) {
                              return Column(
                                children: [
                                  TextField(
                                    controller: _nameController,
                                    decoration: InputDecoration(
                                      hintText: LanguageService.translate(
                                          'name', languageCode),
                                      prefixIcon:
                                          const Icon(Icons.person_outlined),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide.none,
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey[100],
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  TextField(
                                    controller: _emailController,
                                    decoration: InputDecoration(
                                      hintText: LanguageService.translate(
                                          'email', languageCode),
                                      prefixIcon:
                                          const Icon(Icons.email_outlined),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
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
                                      hintText: LanguageService.translate(
                                          'password', languageCode),
                                      prefixIcon:
                                          const Icon(Icons.lock_outlined),
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
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide.none,
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey[100],
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  TextField(
                                    controller: _confirmPasswordController,
                                    obscureText: _obscureConfirmPassword,
                                    decoration: InputDecoration(
                                      hintText: LanguageService.translate(
                                          're_enter_password', languageCode),
                                      prefixIcon:
                                          const Icon(Icons.lock_outlined),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscureConfirmPassword
                                              ? Icons.visibility
                                              : Icons.visibility_off,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _obscureConfirmPassword =
                                                !_obscureConfirmPassword;
                                          });
                                        },
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide.none,
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey[100],
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Row(
                                    children: [
                                      Checkbox(
                                        value: _agreeToTerms,
                                        onChanged: (value) {
                                          setState(() {
                                            _agreeToTerms = value ?? false;
                                          });
                                        },
                                        activeColor: const Color(0xFF0C4556),
                                      ),
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () {
                                            Navigator.pushNamed(
                                                context, '/terms');
                                          },
                                          child: Text.rich(
                                            TextSpan(
                                              text: LanguageService.translate(
                                                          'agree_prefix',
                                                          languageCode)
                                                      .contains('agree_prefix')
                                                  ? 'I agree to the '
                                                  : LanguageService.translate(
                                                      'agree_prefix',
                                                      languageCode),
                                              style:
                                                  const TextStyle(fontSize: 14),
                                              children: [
                                                TextSpan(
                                                  text: LanguageService.translate(
                                                              'terms_conditions',
                                                              languageCode)
                                                          .contains(
                                                              'terms_conditions')
                                                      ? 'terms and conditions'
                                                      : LanguageService
                                                          .translate(
                                                              'terms_conditions',
                                                              languageCode),
                                                  style: const TextStyle(
                                                    color: Color(0xFF0C4556),
                                                    fontWeight: FontWeight.bold,
                                                    decoration: TextDecoration
                                                        .underline,
                                                  ),
                                                ),
                                                TextSpan(
                                                  text: LanguageService
                                                              .translate(
                                                                  'agree_suffix',
                                                                  languageCode)
                                                          .contains(
                                                              'agree_suffix')
                                                      ? ''
                                                      : LanguageService
                                                          .translate(
                                                              'agree_suffix',
                                                              languageCode),
                                                  style: const TextStyle(
                                                      fontSize: 14),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: ElevatedButton(
                                      onPressed: _agreeToTerms && !_isLoading
                                          ? _handleSignup
                                          : null,
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
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : TranslatedText(
                                              'signup',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              fallback: 'Sign up',
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      TranslatedText(
                                        'have_account',
                                        style:
                                            const TextStyle(color: Colors.grey),
                                        fallback: 'Have an account? ',
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const Login(),
                                            ),
                                          );
                                        },
                                        child: TranslatedText(
                                          'sign_in',
                                          style: const TextStyle(
                                            color: Color(0xFF0C4556),
                                            fontWeight: FontWeight.w600,
                                          ),
                                          fallback: 'Sign in',
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
        ),
      ),
    );
  }

  Future<void> _handleSignup() async {
    // On web, only allow pharmacy registration
    String? role;
    if (kIsWeb) {
      role = 'pharmacy';
    } else {
      // Ask for role first on mobile
      role = await showModalBottomSheet<String>(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (context) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TranslatedText(
                    'continue_as',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0C4556),
                    ),
                    fallback: 'Continue as',
                  ),
                  const SizedBox(height: 16),
                  LanguageBuilder(
                    builder: (context, languageCode) {
                      return Column(
                        children: [
                          _buildRoleTile(
                              'user',
                              Icons.person,
                              LanguageService.translate(
                                  'patient_user', languageCode)),
                          const SizedBox(height: 8),
                          _buildRoleTile(
                              'doctor',
                              Icons.medical_services,
                              LanguageService.translate(
                                  'doctor_diabetologist', languageCode)),
                          const SizedBox(height: 8),
                          if (!kIsWeb)
                            const SizedBox.shrink()
                          else
                            _buildRoleTile(
                                'pharmacy',
                                Icons.local_pharmacy,
                                LanguageService.translate(
                                    'pharmacy', languageCode)),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    if (role == null) {
      return;
    }

    final languageCode = await LanguageService.getSelectedLanguage();

    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      _showSnackBar(LanguageService.translate('fill_all_fields', languageCode));
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showSnackBar(
          LanguageService.translate('passwords_no_match', languageCode));
      return;
    }

    if (_passwordController.text.length < 6) {
      _showSnackBar(
          LanguageService.translate('password_min_length', languageCode));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.signUpWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        phone: '', // Optional field
        dateOfBirth: null, // User can add from profile later
        gender: null, // User can add from profile later
        diabetesType: _selectedDiabetesType,
      );

      // Set the user role
      await _authService.setUserRole(role);

      if (mounted) {
        // Redirect based on chosen role
        if (role == 'doctor') {
          Navigator.pushReplacementNamed(context, '/register-doctor');
        } else if (role == 'pharmacy') {
          Navigator.pushReplacementNamed(context, '/register-pharmacy');
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => const MainNavigationScreen()),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final languageCode = await LanguageService.getSelectedLanguage();
        final errorMsg =
            LanguageService.translate('signup_failed', languageCode);
        _showSnackBar('$errorMsg: ${e.toString().split(': ').last}');
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

  Widget _buildRoleTile(String value, IconData icon, String label) {
    return InkWell(
      onTap: () => Navigator.pop(context, value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF0C4556)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0C4556),
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
