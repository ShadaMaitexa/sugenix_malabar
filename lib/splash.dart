import 'package:flutter/material.dart';
import 'package:sugenix/Login.dart';
import 'package:sugenix/services/auth_service.dart';
import 'package:sugenix/main.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final bool isTablet = width >= 800 && width < 1200;
    final bool isDesktop = width >= 1200;
    final double logoSize = isDesktop ? 250 : (isTablet ? 200 : 160);
    final double titleSize = logoSize * 0.14; // Text is 22% of logo height

    Future.delayed(const Duration(seconds: 3), () async {
      final authService = AuthService();
      final user = authService.currentUser;

      if (user != null) {
        try {
          final profile = await authService.getUserProfile();
          final role = profile?['role'] ?? 'user';

          if (context.mounted) {
            // Only patients and doctors are allowed on the app
            if (role == 'user' || role == 'doctor') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => const MainNavigationScreen()),
              );
            } else {
              // Pharmacy and Admin should go to Login (and eventually see unsupported role or be blocked)
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const Login()),
              );
            }
          }
        } catch (e) {
          if (context.mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const Login()),
            );
          }
        }
      } else {
        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const Login()),
          );
        }
      }
    });

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft, // Start from top-left
            radius: 0.7,
            colors: [Color(0xFF0C4556), Colors.white],
            stops: [0.0, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Add second gradient at bottom-right
            Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.bottomRight,
                  radius: 0.7,
                  colors: [
                    Color(0x800C4556), // 50% opacity
                    Colors.transparent,
                  ],
                  stops: [0.0, 1.0],
                ),
              ),
            ),
            // Center content
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sugenix logo
                  Transform.translate(
                    offset: Offset(0, -15),
                    child: Image.asset(
                      'assets/sugenix_logo.png',
                      height: logoSize,
                      width: logoSize,
                    ),
                  ),
                  Transform.translate(
                    offset: Offset(-65, logoSize * 0.12),
                    child: Text(
                      "SUGENIX",
                      style: TextStyle(
                        color: Color(0xFF0C4556),
                        fontSize: titleSize,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 3.0,
                        fontFamily: 'Zen Antique',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
