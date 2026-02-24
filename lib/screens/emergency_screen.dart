import 'package:flutter/material.dart';
import 'package:sugenix/services/sos_alert_service.dart';
import 'package:sugenix/utils/responsive_layout.dart';
import 'package:sugenix/services/language_service.dart';
import 'package:sugenix/services/platform_location_service.dart';
import 'package:url_launcher/url_launcher.dart';

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
            final title = LanguageService.translate('emergency', lang);
            return Text(
              title,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
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

    setState(() {
      _isSending = true;
      _sosStatus = "Getting Location...";
    });

    try {
      final result = await _sosAlertService.triggerSOSAlert();

      if (!mounted) return;

      if (result['success'] == true) {
        setState(() => _sosStatus = "SOS Sent Successfully!");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "🚨 SOS sent to ${result['contactsNotified']} contacts",
            ),
            backgroundColor: Colors.green,
          ),
        );

        _showStatus(result['notificationDetails']);
      } else {
        setState(() => _sosStatus = "SOS Failed");

        if (result['type'] == 'no_contacts') {
          _showNoContactsDialog();
        } else if (result['type'] == 'no_email') {
          _showNoEmailDialog();
        } else {
          final errorMsg = result['error']?.toString() ?? "SOS failed";
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMsg),
              backgroundColor: Colors.red,
              duration:
                  const Duration(seconds: 10), // Show longer for debugging
              action: SnackBarAction(
                label: "OK",
                textColor: Colors.white,
                onPressed: () {},
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) setState(() => _sosStatus = "Error: ${e.toString()}");
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

  void _sendManualSMS(String phone, String name) async {
    final String message = "🚨 SOS EMERGENCY ALERT! 🚨\n\n"
        "This is an emergency alert from Sugenix App. The user is in distress and needs immediate help.\n\n"
        "Please check on them! System triggered this because email alert to you failed.";

    final Uri smsUri = Uri(
      scheme: 'sms',
      path: phone,
      queryParameters: {'body': message},
    );

    try {
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Could not open SMS app")));
      }
    } catch (e) {
      print("SMS launch error: $e");
    }
  }

  void _showStatus(List<Map<String, dynamic>> details) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("SOS Status"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: details.map((d) {
              final bool isFailed = d['status'] == 'failed';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(d['status'] == 'sent' ? '✅' : '❌'),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "${d['contact']} (${d['email'] ?? d['phone'] ?? ''})",
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    if (isFailed) ...[
                      Text(
                        "Error: ${d['error'] ?? 'Unknown'}",
                        style: const TextStyle(fontSize: 11, color: Colors.red),
                      ),
                      const SizedBox(height: 4),
                      TextButton.icon(
                        onPressed: () {
                          final phone = d['phone'] ?? '';
                          if (phone.isNotEmpty) {
                            _sendManualSMS(phone, d['contact'] ?? '');
                          }
                        },
                        icon: const Icon(Icons.sms, size: 16),
                        label: const Text("Send Manual SMS Fallback",
                            style: TextStyle(fontSize: 12)),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),
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

  void _showNoContactsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("No Emergency Contacts"),
        content: const Text(
            "You haven't added any emergency contacts yet. Please add at least one contact with an email address to use the SOS feature."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Later"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/emergency_contacts');
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0C4556)),
            child: const Text("Add Contacts",
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showNoEmailDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("No Email on Contacts"),
        content: const Text(
            "SOS sends alerts by email. None of your emergency contacts have an email address. Please open Emergency Contacts and add an email to at least one contact."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Later"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/emergency_contacts');
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0C4556)),
            child: const Text("Edit Contacts",
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _sosStatus = "";

  Widget _buildEmergencyActiveContent() {
    final bool isFailed =
        _sosStatus == "SOS Failed" || _sosStatus.startsWith("Error:");
    final bool isSent = _sosStatus == "SOS Sent Successfully!";

    return Column(
      children: [
        Text(
          _sosStatus.isEmpty ? "Emergency Activated!" : _sosStatus,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 15),
        Text(
          isFailed
              ? "We couldn't reach your contacts yet.\nPlease check your internet and setup."
              : (isSent
                  ? "Your contacts have been alerted.\nHelp is on the way!"
                  : "Emergency contacts are being notified.\nHelp is on the way!"),
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70),
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
}
