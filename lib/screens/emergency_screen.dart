import 'package:flutter/material.dart';
import 'package:sugenix/services/sos_alert_service.dart';
import 'package:sugenix/utils/responsive_layout.dart';
import 'package:sugenix/services/language_service.dart';
import 'package:sugenix/services/platform_location_service.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  final SOSAlertService _sosAlertService = SOSAlertService();

  bool _isEmergencyActive = false;
  bool _isSending = false;
  int _countdown = 5;



  @override
  void initState() {
    super.initState();
    // Request permissions immediately when screen loads
    // so the user isn't interrupted during an emergency
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestPermissions();
    });
  }

  Future<void> _requestPermissions() async {
    await _sosAlertService.requestSMSPermissions();
    await PlatformLocationService.requestLocationPermission();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: StreamBuilder<String>(
          stream: LanguageService.currentLanguageStream,
          builder: (context, snapshot) {
            final lang = snapshot.data ?? 'en';
            final title = LanguageService.translate('home', lang);
            return Text(
              title == 'home' ? 'Emergency' : title,
              style: const TextStyle(color: Colors.white),
            );
          },
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1,
            colors: _isEmergencyActive
                ? [Colors.red, Colors.red.shade900]
                : [const Color(0xFF0C4556), Colors.white],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!_isEmergencyActive) ...[
                  _buildEmergencyIcon(),
                  const SizedBox(height: 30),
                  _buildEmergencyTitle(),
                  const SizedBox(height: 20),
                  _buildEmergencyDescription(),
                  const SizedBox(height: 40),
                  _buildSOSButton(),
                ] else ...[
                  _buildCountdownDisplay(),
                  const SizedBox(height: 30),
                  _buildEmergencyActiveContent(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================= UI (UNCHANGED) =================

  Widget _buildEmergencyIcon() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.emergency, size: 60, color: Colors.white),
    );
  }

  Widget _buildEmergencyTitle() {
    return Text(
      "Emergency SOS",
      style: TextStyle(
        fontSize: ResponsiveHelper.getResponsiveFontSize(
          context,
          mobile: 24,
          tablet: 26,
          desktop: 28,
        ),
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildEmergencyDescription() {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveHelper.isMobile(context) ? 30 : 40,
      ),
      child: Text(
        "Press and hold the button below to activate emergency mode. Your location will be shared with emergency contacts.",
        style: TextStyle(
          fontSize: ResponsiveHelper.getResponsiveFontSize(
            context,
            mobile: 14,
            tablet: 15,
            desktop: 16,
          ),
          color: Colors.white70,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildSOSButton() {
    final size = ResponsiveHelper.isMobile(context) ? 180.0 : 200.0;

    return GestureDetector(
      onLongPress: () {
        if (!_isEmergencyActive && !_isSending) {
          _startEmergency();
        }
      },
      onTap: () {
        if (!_isEmergencyActive && !_isSending) {
          // Show a helpful tooltip or just start it if they click
          // Given the user's request "when click sos", we'll start it
          _startEmergency();
        }
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: _isSending ? Colors.grey : Colors.red,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: (_isSending ? Colors.grey : Colors.red).withOpacity(0.5),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _isSending ? "SENDING" : "SOS",
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (!_isSending) 
                const Text(
                  "Tap or Hold",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCountdownDisplay() {
    final size = ResponsiveHelper.isMobile(context) ? 130.0 : 150.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          _countdown.toString(),
          style: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildEmergencyActiveContent() {
    return Column(
      children: [
        const Text(
          "Emergency Activated!",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 15),
        const Text(
          "Emergency contacts have been notified.\nHelp is on the way!",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 40),
        ElevatedButton(
          onPressed: _cancelEmergency,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.red,
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
          ),
          child: const Text(
            "Cancel Emergency",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  // ================= LOGIC (FIXED) =================

  void _startEmergency() {
    setState(() {
      _isEmergencyActive = true;
      _isSending = false;
      _countdown = 5;
    });
    _startCountdown();
  }

  void _startCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted || !_isEmergencyActive || _isSending) return;

      if (_countdown > 1) {
        setState(() => _countdown--);
        _startCountdown();
      } else {
        setState(() => _countdown = 0);
        _sendSOS();
      }
    });
  }

  Future<void> _sendSOS() async {
    if (_isSending) return;

    setState(() => _isSending = true);

    try {
      final result = await _sosAlertService.triggerSOSAlert();

      if (!mounted) return;

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "🚨 SOS sent to ${result['contactsNotified']} contacts",
            ),
            backgroundColor: Colors.red,
          ),
        );

        _showStatus(result['notificationDetails']);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? "SOS failed"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _cancelEmergency() {
    setState(() {
      _isEmergencyActive = false;
      _countdown = 5;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("🛑 SOS Cancelled"),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _showStatus(List<Map<String, dynamic>> details) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("SOS Status"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: details.map((d) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                "${d['status'] == 'sent' ? '✅' : '❌'} "
                "${d['contact']} - ${d['phone']}",
                style: const TextStyle(fontSize: 12),
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
}
