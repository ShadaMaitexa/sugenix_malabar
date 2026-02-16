import 'package:flutter/material.dart';
import 'package:sugenix/services/auth_service.dart';
import 'package:sugenix/services/language_service.dart';
import 'package:sugenix/services/glucose_service.dart';
import 'package:sugenix/services/app_localization_service.dart';
import 'package:sugenix/services/locale_notifier.dart';
import 'package:sugenix/utils/responsive_layout.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _notificationsEnabled = true;
  bool _biometricEnabled = false;
  String _selectedLanguage = 'en';
  bool _loadingSettings = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      // Load language
      final language = await LanguageService.getSelectedLanguage();

      // Load preferences from Firestore
      final userProfile = await _authService.getUserProfile();
      final preferences = userProfile?['preferences'] as Map<String, dynamic>?;

      // Load from SharedPreferences as fallback
      final prefs = await SharedPreferences.getInstance();

      setState(() {
        _selectedLanguage = language;
        _notificationsEnabled = preferences?['notifications'] as bool? ??
            prefs.getBool('notifications_enabled') ??
            true;
        _biometricEnabled = preferences?['biometric'] as bool? ??
            prefs.getBool('biometric_enabled') ??
            false;
        _loadingSettings = false;
      });
    } catch (e) {
      // Fallback to SharedPreferences only
      final prefs = await SharedPreferences.getInstance();
      final language = await LanguageService.getSelectedLanguage();
      setState(() {
        _selectedLanguage = language;
        _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
        _biometricEnabled = prefs.getBool('biometric_enabled') ?? false;
        _loadingSettings = false;
      });
    }
  }

  Future<void> _saveNotificationPreference(bool value) async {
    setState(() {
      _notificationsEnabled = value;
    });

    try {
      // Save to Firestore
      final user = _authService.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'preferences.notifications': value,
        });
      }

      // Also save to SharedPreferences as backup
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notifications_enabled', value);
    } catch (e) {
      // If Firestore fails, at least save locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notifications_enabled', value);
    }
  }

  Future<void> _saveBiometricPreference(bool value) async {
    setState(() {
      _biometricEnabled = value;
    });

    try {
      // Save to Firestore
      final user = _authService.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'preferences.biometric': value,
        });
      }

      // Also save to SharedPreferences as backup
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('biometric_enabled', value);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                value ? 'Biometric login enabled' : 'Biometric login disabled'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // If Firestore fails, at least save locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('biometric_enabled', value);
    }
  }

  Future<void> _showLanguagePicker(BuildContext context) async {
    final languages = LanguageService.getSupportedLanguages();
    String tempSelected = _selectedLanguage;
    final localeNotifier = Provider.of<LocaleNotifier>(context, listen: false);
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Text(
                'Select Language',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Color(0xFF0C4556),
                ),
              ),
              const Divider(),
              ...languages.map((lang) {
                final code = lang['code'] ?? 'en';
                final name = lang['name'] ?? code.toUpperCase();
                final flag = lang['flag'] ?? '';
                return RadioListTile<String>(
                  value: code,
                  groupValue: tempSelected,
                  onChanged: (val) {
                    if (val == null) return;
                    tempSelected = val;
                    setState(() => _selectedLanguage = val);
                    LanguageService.setSelectedLanguage(val);
                    // Also update the app locale
                    localeNotifier.setLocale(Locale(val));
                    AppLocalizationService.saveLocale(Locale(val));
                    Navigator.pop(ctx);
                  },
                  title: Text(
                    name,
                    style: const TextStyle(
                      color: Color(0xFF0C4556),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  secondary: Text(flag, style: const TextStyle(fontSize: 18)),
                );
              }).toList(),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Color(0xFF0C4556),
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0C4556)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        top: false,
        bottom: true,
        child: _loadingSettings
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: ResponsiveHelper.getResponsivePadding(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('General'),
                    _buildSettingsCard(
                      children: [
                        _buildSettingsTile(
                          icon: Icons.language,
                          title: 'Language',
                          subtitle: LanguageService.getLanguageName(
                              _selectedLanguage),
                          onTap: () => _showLanguagePicker(context),
                        ),
                        const Divider(),
                        _buildSwitchTile(
                          icon: Icons.notifications,
                          title: 'Notifications',
                          subtitle: 'Enable push notifications',
                          value: _notificationsEnabled,
                          onChanged: _saveNotificationPreference,
                        ),
                        const Divider(),
                        _buildSwitchTile(
                          icon: Icons.fingerprint,
                          title: 'Biometric Login',
                          subtitle: 'Use fingerprint or face ID',
                          value: _biometricEnabled,
                          onChanged: _saveBiometricPreference,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Privacy & Security'),
                    _buildSettingsCard(
                      children: [
                        _buildSettingsTile(
                          icon: Icons.lock,
                          title: 'Change Password',
                          subtitle: 'Update your account password',
                          onTap: () => _showChangePasswordDialog(context),
                        ),
                        const Divider(),
                        _buildSettingsTile(
                          icon: Icons.privacy_tip,
                          title: 'Privacy Policy',
                          subtitle: 'View our privacy policy',
                          onTap: () => _showPrivacyPolicy(context),
                        ),
                        const Divider(),
                        _buildSettingsTile(
                          icon: Icons.security,
                          title: 'Terms & Conditions',
                          subtitle: 'Read terms and conditions',
                          onTap: () => _showTermsAndConditions(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Data & Storage'),
                    _buildSettingsCard(
                      children: [
                        _buildSettingsTile(
                          icon: Icons.cloud_download,
                          title: 'Backup Data',
                          subtitle: 'Backup your data to cloud',
                          onTap: () => _backupData(context),
                        ),
                        const Divider(),
                        _buildSettingsTile(
                          icon: Icons.delete_outline,
                          title: 'Clear Cache',
                          subtitle: 'Clear app cache and temporary files',
                          onTap: () => _clearCache(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Account'),
                    _buildSettingsCard(
                      children: [
                        _buildSettingsTile(
                          icon: Icons.logout,
                          title: 'Logout',
                          subtitle: 'Sign out from your account',
                          onTap: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Logout'),
                                content: const Text(
                                    'Are you sure you want to logout?'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('Logout',
                                        style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await _authService.signOut();
                              if (context.mounted) {
                                Navigator.of(context).pushNamedAndRemoveUntil(
                                    '/login', (route) => false);
                              }
                            }
                          },
                          isDestructive: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    // Add bottom padding for Android navigation buttons
                    SizedBox(height: MediaQuery.of(context).padding.bottom),
                  ],
                ),
              ),
      ),
      backgroundColor: const Color(0xFFF5F6F8),
    );
  }

  Future<void> _clearCache(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text(
            'Are you sure you want to clear all cached data? This will not delete your account data.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // Clear SharedPreferences cache (except important settings)
        final prefs = await SharedPreferences.getInstance();
        final keys = prefs.getKeys();

        // Keep important settings
        final keepKeys = [
          'selected_language',
          'notifications_enabled',
          'biometric_enabled',
          'guest_cart_items',
        ];

        for (final key in keys) {
          if (!keepKeys.contains(key)) {
            await prefs.remove(key);
          }
        }

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cache cleared successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to clear cache: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: ResponsiveHelper.getResponsiveFontSize(
            context,
            mobile: 16,
            tablet: 18,
            desktop: 20,
          ),
          fontWeight: FontWeight.bold,
          color: const Color(0xFF0C4556),
        ),
      ),
    );
  }

  Widget _buildSettingsCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : const Color(0xFF0C4556),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : const Color(0xFF0C4556),
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      trailing:
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF0C4556)),
      title: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF0C4556),
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF0C4556),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        bool obscureCurrent = true;
        bool obscureNew = true;
        bool obscureConfirm = true;
        bool isProcessing = false;

        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Change Password'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: currentPasswordController,
                    obscureText: obscureCurrent,
                    decoration: InputDecoration(
                      labelText: 'Current Password',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(obscureCurrent
                            ? Icons.visibility
                            : Icons.visibility_off),
                        onPressed: () => setDialogState(
                            () => obscureCurrent = !obscureCurrent),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: newPasswordController,
                    obscureText: obscureNew,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(obscureNew
                            ? Icons.visibility
                            : Icons.visibility_off),
                        onPressed: () =>
                            setDialogState(() => obscureNew = !obscureNew),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: confirmPasswordController,
                    obscureText: obscureConfirm,
                    decoration: InputDecoration(
                      labelText: 'Confirm New Password',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(obscureConfirm
                            ? Icons.visibility
                            : Icons.visibility_off),
                        onPressed: () => setDialogState(
                            () => obscureConfirm = !obscureConfirm),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isProcessing
                    ? null
                    : () async {
                        // Validate inputs
                        if (currentPasswordController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Please enter current password')),
                          );
                          return;
                        }

                        if (newPasswordController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Please enter new password')),
                          );
                          return;
                        }

                        if (newPasswordController.text !=
                            confirmPasswordController.text) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('New passwords do not match')),
                          );
                          return;
                        }

                        if (newPasswordController.text.length < 6) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Password must be at least 6 characters')),
                          );
                          return;
                        }

                        if (currentPasswordController.text ==
                            newPasswordController.text) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'New password must be different from current password')),
                          );
                          return;
                        }

                        // Show loading
                        setDialogState(() {
                          isProcessing = true;
                        });

                        try {
                          await _authService.changePassword(
                            currentPassword: currentPasswordController.text,
                            newPassword: newPasswordController.text,
                          );

                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Password changed successfully'),
                                backgroundColor: Colors.green,
                                duration: Duration(seconds: 3),
                              ),
                            );
                          }
                        } catch (e) {
                          setDialogState(() {
                            isProcessing = false;
                          });
                          if (context.mounted) {
                            String errorMessage = 'Failed to change password';
                            final errorStr = e.toString();
                            if (errorStr.contains('wrong-password') ||
                                errorStr.contains('invalid-credential')) {
                              errorMessage = 'Current password is incorrect';
                            } else if (errorStr.contains('weak-password')) {
                              errorMessage =
                                  'New password is too weak. Please use a stronger password';
                            } else if (errorStr
                                .contains('requires-recent-login')) {
                              errorMessage =
                                  'Please login again to change password';
                            } else {
                              errorMessage = errorStr.split(': ').last;
                            }

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(errorMessage),
                                backgroundColor: Colors.red,
                                duration: const Duration(seconds: 4),
                              ),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0C4556),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[300],
                ),
                child: isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Change Password'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: SingleChildScrollView(
          child: const Text(
            'Sugenix Privacy Policy\n\n'
            'Last Updated: 2024\n\n'
            '1. Information We Collect\n'
            'We collect information you provide directly to us, including:\n'
            '- Personal information (name, email, phone number)\n'
            '- Health information (glucose readings, medical records)\n'
            '- Device information and usage data\n\n'
            '2. How We Use Your Information\n'
            'We use your information to:\n'
            '- Provide and improve our services\n'
            '- Monitor your health data\n'
            '- Send you important updates\n'
            '- Ensure app security\n\n'
            '3. Data Security\n'
            'We implement industry-standard security measures to protect your data.\n\n'
            '4. Your Rights\n'
            'You have the right to access, update, or delete your personal information at any time.\n\n'
            '5. Contact Us\n'
            'For questions about this policy, contact us at privacy@sugenix.com',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showTermsAndConditions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms & Conditions'),
        content: SingleChildScrollView(
          child: const Text(
            'Sugenix Terms & Conditions\n\n'
            'Last Updated: 2024\n\n'
            '1. Acceptance of Terms\n'
            'By using Sugenix, you agree to these terms and conditions.\n\n'
            '2. Medical Disclaimer\n'
            'Sugenix is not a substitute for professional medical advice. Always consult with healthcare professionals.\n\n'
            '3. User Responsibilities\n'
            '- Provide accurate information\n'
            '- Keep your account secure\n'
            '- Use the app responsibly\n\n'
            '4. Prohibited Activities\n'
            'You may not:\n'
            '- Misuse the app or its services\n'
            '- Share false medical information\n'
            '- Violate any laws or regulations\n\n'
            '5. Limitation of Liability\n'
            'Sugenix is not liable for any damages arising from the use of this app.\n\n'
            '6. Changes to Terms\n'
            'We reserve the right to modify these terms at any time.\n\n'
            '7. Contact\n'
            'For questions, contact us at support@sugenix.com',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _backupData(BuildContext context) async {
    try {
      final user = _authService.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login to backup data'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Backup user data to Firestore backup collection
      final userProfile = await _authService.getUserProfile();
      final glucoseService = GlucoseService();
      final recentReadings = await glucoseService.getGlucoseReadingsByDateRange(
        startDate: DateTime.now().subtract(const Duration(days: 365)),
        endDate: DateTime.now(),
      );

      // Create backup document
      await _firestore.collection('backups').doc(user.uid).set({
        'userId': user.uid,
        'userProfile': userProfile,
        'glucoseReadings': recentReadings,
        'backupDate': FieldValue.serverTimestamp(),
        'backupType': 'manual',
      }, SetOptions(merge: true));

      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data backed up successfully to cloud'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog if still open
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
