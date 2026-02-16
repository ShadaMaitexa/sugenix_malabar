import 'package:flutter/material.dart';

class UnsupportedRoleScreen extends StatelessWidget {
  final String role;
  const UnsupportedRoleScreen({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.desktop_windows, size: 64, color: Color(0xFF0C4556)),
              const SizedBox(height: 16),
              Text(
                '$role is available on web',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0C4556),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please use the web portal for the best experience.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

