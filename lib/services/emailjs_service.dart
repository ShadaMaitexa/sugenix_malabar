import 'dart:convert';
import 'package:http/http.dart' as http;

/// EmailJS Service for sending emails (Admin approvals, notifications)
///
/// Setup Instructions:
/// 1. Sign up at https://www.emailjs.com/
/// 2. Create an Email Service (Gmail, Outlook, etc.)
/// 3. Create an email template with these variables:
///    - {{to_email}} - Recipient email
///    - {{to_name}} - Recipient name
///    - {{subject}} - Email subject
///    - {{title}} - Email title
///    - {{message}} - Email message body
///    - {{app_name}} - App name (Sugenix)
/// 4. Get credentials from EmailJS dashboard
/// 5. Replace the values below with your actual credentials
class EmailJSService {
  // EmailJS Configuration
  // ⚠️ IMPORTANT: Replace these with your actual EmailJS credentials
  // Get these from https://www.emailjs.com/
  // Current values are placeholders - emails won't work until replaced
  static const String _serviceId =
      'service_f6ka8jm'; // TODO: Replace with your EmailJS Service ID
  static const String _templateId =
      'template_u50mo7i'; // TODO: Replace with your EmailJS Template ID
  static const String _publicKey =
      'CHxG3ZYeXEUuvz1MA'; // TODO: Replace with your EmailJS Public Key (User ID)
  static const String _baseUrl = 'https://api.emailjs.com/api/v1.0/email/send';

  /// Send approval email to pharmacy or doctor
  static Future<bool> sendApprovalEmail({
    required String recipientEmail,
    required String recipientName,
    required String role, // 'pharmacy' or 'doctor'
  }) async {
    try {
      // Draft email content from code
      final subject = 'Account Approved - Sugenix';
      final title = 'Congratulations! Your Account Has Been Approved';

      final message = role == 'pharmacy'
          ? '''Dear ${recipientName},

We are pleased to inform you that your pharmacy account has been successfully approved by our admin team.

You can now log in to Sugenix and start:
• Managing your medicine inventory
• Adding new medicines to your catalog
• Processing orders from patients
• Tracking your sales and revenue

Welcome to the Sugenix platform! We look forward to working with you.

Best regards,
Sugenix Team'''
          : '''Dear ${recipientName},

We are pleased to inform you that your doctor account has been successfully approved by our admin team.

You can now log in to Sugenix and start:
• Accepting appointments from patients
• Managing your schedule
• Viewing patient medical records
• Providing consultations

Welcome to the Sugenix platform! We look forward to working with you.

Best regards,
Sugenix Team''';

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'service_id': _serviceId,
          'template_id': _templateId,
          'user_id': _publicKey,
          'template_params': {
            'to_email': recipientEmail,
            'name': recipientName, // Matches {{name}} in your screenshot
            'email': 'support@sugenix.app', // Matches {{email}} in Reply-To
            'to_name': recipientName,
            'subject': subject, // Matches {{subject}} in your screenshot
            'message': message, // Matches {{message}} in your screenshot
            'title': title,
            'app_name': 'Sugenix',
            'login_url': 'https://sugenix.app/login',
          },
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Approval email sent successfully to $recipientEmail');
        return true;
      } else {
        final errorBody = response.body;
        print('❌ EmailJS Error: ${response.statusCode} - $errorBody');
        // Check if it's a configuration error
        if (response.statusCode == 400 || response.statusCode == 401) {
          print(
              '⚠️ EmailJS credentials may be incorrect. Please check service_id, template_id, and public_key.');
        }
        return false;
      }
    } catch (e) {
      print('❌ EmailJS Exception: $e');
      // Check if credentials are placeholders
      if (_serviceId.contains('service_') && _serviceId.length < 20) {
        print(
            '⚠️ EmailJS credentials appear to be placeholders. Please configure with your actual EmailJS credentials.');
      }
      return false;
    }
  }

  /// Send rejection email to pharmacy or doctor
  static Future<bool> sendRejectionEmail({
    required String recipientEmail,
    required String recipientName,
    required String role, // 'pharmacy' or 'doctor'
    String? reason,
  }) async {
    try {
      // Draft email content from code
      final subject = 'Account Application Status - Sugenix';
      final title = 'Account Application Update';

      final defaultMessage = '''Dear ${recipientName},

We regret to inform you that your ${role == 'pharmacy' ? 'pharmacy' : 'doctor'} account application has been reviewed and unfortunately, we are unable to approve it at this time.

Please review your application details and ensure all required information and documents are provided correctly. If you believe this is an error or have any questions, please contact our support team.

We appreciate your interest in joining the Sugenix platform.''';

      final message = reason != null && reason.isNotEmpty
          ? '''Dear ${recipientName},

We regret to inform you that your ${role == 'pharmacy' ? 'pharmacy' : 'doctor'} account application has been reviewed and unfortunately, we are unable to approve it at this time.

Reason: $reason

Please review your application details and ensure all required information and documents are provided correctly. If you have any questions, please contact our support team.

We appreciate your interest in joining the Sugenix platform.'''
          : defaultMessage;

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'service_id': _serviceId,
          'template_id': _templateId,
          'user_id': _publicKey,
          'template_params': {
            'to_email': recipientEmail,
            'name': recipientName, // Matches {{name}} in your screenshot
            'email': 'support@sugenix.app', // Matches {{email}} in Reply-To
            'to_name': recipientName,
            'subject': subject, // Matches {{subject}} in your screenshot
            'message': message, // Matches {{message}} in your screenshot
            'title': title,
            'app_name': 'Sugenix',
          },
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Rejection email sent successfully to $recipientEmail');
        return true;
      } else {
        final errorBody = response.body;
        print('❌ EmailJS Error: ${response.statusCode} - $errorBody');
        // Check if it's a configuration error
        if (response.statusCode == 400 || response.statusCode == 401) {
          print(
              '⚠️ EmailJS credentials may be incorrect. Please check service_id, template_id, and public_key.');
        }
        return false;
      }
    } catch (e) {
      print('❌ EmailJS Exception: $e');
      // Check if credentials are placeholders
      if (_serviceId.contains('service_') && _serviceId.length < 20) {
        print(
            '⚠️ EmailJS credentials appear to be placeholders. Please configure with your actual EmailJS credentials.');
      }
      return false;
    }
  }

  /// Send Emergency SOS email to emergency contacts
  static Future<bool> sendSOSEmail({
    required String recipientEmail,
    required String recipientName,
    required String userName,
    required String message,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final subject = '🚨 CRITICAL: SOS Emergency Alert from $userName';
      final title = '🚨 MEDICAL EMERGENCY ALERT';

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'service_id': _serviceId,
          'template_id': _templateId,
          'user_id': _publicKey,
          'template_params': {
            'to_email': recipientEmail,
            'name': recipientName, // Matches {{name}} in your screenshot
            'email': 'support@sugenix.app', // Matches {{email}} in Reply-To
            'to_name': recipientName,
            'user_name': userName,
            'from_name': userName,
            'subject': subject, // Matches {{subject}} in your screenshot
            'title': title,
            'message': message, // Matches {{message}} in your screenshot
            'latitude': latitude ?? 0.0,
            'longitude': longitude ?? 0.0,
            'map_url': latitude != null && longitude != null
                ? 'https://maps.google.com/?q=$latitude,$longitude'
                : '',
            'app_name': 'Sugenix',
          },
        }),
      );

      if (response.statusCode == 200) {
        print('✅ SOS email sent successfully to $recipientEmail');
        return true;
      } else {
        final errorBody = response.body;
        print('❌ EmailJS SOS Error: ${response.statusCode} - $errorBody');
        // Additional logging for debugging
        print(
            'Payload was sent to EmailJS with ServiceID: $_serviceId, TemplateID: $_templateId');
        return false;
      }
    } catch (e) {
      print('❌ EmailJS SOS Exception: $e');
      return false;
    }
  }
}
