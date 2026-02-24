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
  static const String _serviceId = 'service_f6ka8jm';
  static const String _approvalTemplateId = 'template_xygncaq';
  static const String _sosTemplateId = 'template_u50mo7i';
  static const String _publicKey = 'CHxG3ZYeXEUuvz1MA';
  // 🔑 Private Key - Required for strict mode.
  // Get this from: https://dashboard.emailjs.com/ → Account → API Keys
  static const String _privateKey = '5eNG3DW6xv0PbE5rSZjcm';
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
          'template_id': _approvalTemplateId,
          'user_id': _publicKey,
          'accessToken': _privateKey,
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
          'template_id': _approvalTemplateId,
          'user_id': _publicKey,
          'accessToken': _privateKey,
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

  /// Send Emergency SOS email to emergency contacts (uses same template as approval emails).
  /// Message includes current location; lat/long and map_url are also sent for template use.
  /// Returns a Map with 'success' bool and optional 'error' string for detailed error info.
  static Future<Map<String, dynamic>> sendSOSEmailWithError({
    required String recipientEmail,
    required String recipientName,
    required String userName,
    required String userEmail,
    required String message,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final subject = 'SOS Emergency Alert from $userName';

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'service_id': _serviceId,
          'template_id': _sosTemplateId,
          'user_id': _publicKey,
          'accessToken': _privateKey,
          'template_params': {
            'to_email': recipientEmail,
            'name':
                userName, // Changed to patient's name to match {{name}} in your template
            'to_name': recipientName, // Original contact name
            'email':
                userEmail, // Changed to patient's actual email for Reply-To
            'subject': subject,
            'message': message,
            'time': DateTime.now()
                .toString()
                .split('.')
                .first, // Added {{time}} for your template
            'map_url': latitude != null && longitude != null
                ? 'https://maps.google.com/?q=$latitude,$longitude'
                : 'No location available',
            'app_name': 'Sugenix',
          },
        }),
      );

      print(
          'DEBUG: SOS EmailJS Attempt - Service: $_serviceId, Template: $_sosTemplateId');

      if (response.statusCode == 200) {
        print('✅ SOS email sent successfully to $recipientEmail');
        return {'success': true};
      } else {
        final errorBody = response.body;
        print('❌ EmailJS SOS Error: ${response.statusCode}');
        print('DEBUG: SOS Template Used: $_sosTemplateId');
        print('DEBUG: Error Body: $errorBody');
        print('ServiceID: $_serviceId, TemplateID: $_sosTemplateId');
        print('Recipient: $recipientEmail');

        // Try to parse error message from response
        String errorMessage = 'HTTP ${response.statusCode}';
        try {
          final errorJson = jsonDecode(errorBody);
          if (errorJson is Map && errorJson.containsKey('text')) {
            errorMessage = errorJson['text'].toString();
          } else if (errorJson is Map && errorJson.containsKey('message')) {
            errorMessage = errorJson['message'].toString();
          } else {
            errorMessage = errorBody.isNotEmpty ? errorBody : 'Unknown error';
          }
        } catch (_) {
          errorMessage = errorBody.isNotEmpty ? errorBody : 'Unknown error';
        }

        print('Parsed error: $errorMessage');

        // Check if it's a configuration error
        if (response.statusCode == 400) {
          errorMessage =
              'Bad Request (400): Check template parameters and template_id. $errorMessage';
          print(
              '⚠️ EmailJS Bad Request (400) - Check template parameters and template_id');
        } else if (response.statusCode == 401) {
          errorMessage =
              'Unauthorized (401): Check public_key (user_id). $errorMessage';
          print('⚠️ EmailJS Unauthorized (401) - Check public_key (user_id)');
        } else if (response.statusCode == 404) {
          errorMessage =
              'Not Found (404): Check service_id and template_id. $errorMessage';
          print(
              '⚠️ EmailJS Not Found (404) - Check service_id and template_id');
        }

        return {'success': false, 'error': errorMessage};
      }
    } catch (e, stackTrace) {
      print('❌ EmailJS SOS Exception: $e');
      print('Stack trace: $stackTrace');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Send Emergency SOS email to emergency contacts (uses same template as approval emails).
  /// Message includes current location; lat/long and map_url are also sent for template use.
  /// This is a convenience method that returns bool for backward compatibility.
  static Future<bool> sendSOSEmail({
    required String recipientEmail,
    required String recipientName,
    required String userName,
    String? userEmail,
    required String message,
    double? latitude,
    double? longitude,
  }) async {
    final result = await sendSOSEmailWithError(
      recipientEmail: recipientEmail,
      recipientName: recipientName,
      userName: userName,
      userEmail: userEmail ?? '',
      message: message,
      latitude: latitude,
      longitude: longitude,
    );
    return result['success'] == true;
  }
}
