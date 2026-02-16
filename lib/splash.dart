import 'package:flutter/material.dart';
import 'package:sugenix/Login.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final bool isTablet = width >= 800 && width < 1200;
    final bool isDesktop = width >= 1200;
    final double logoSize = isDesktop ? 250 : (isTablet ? 200 : 160);
    final double titleSize = logoSize * 0.14; // Text is 22% of logo height
    Future.delayed(Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Login()),
      );
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
