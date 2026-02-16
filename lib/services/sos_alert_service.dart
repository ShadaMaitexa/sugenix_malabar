import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sugenix/services/platform_location_service.dart';
import 'package:sugenix/services/emailjs_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:telephony/telephony.dart';

class SOSAlertService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Telephony _telephony = Telephony.instance;

  // Request necessary permissions proactively
  Future<bool> requestSMSPermissions() async {
    final bool? granted = await _telephony.requestPhoneAndSmsPermissions;
    return granted ?? false;
  }

  // Generate SOS message with location
  static String _generateSOSMessage({
    required String userName,
    required String? address,
    required double? latitude,
    required double? longitude,
    required List<Map<String, dynamic>> recentReadings,
  }) {
    String message = '''🚨 SOS EMERGENCY ALERT 🚨

User: $userName
Alert Type: Medical Emergency - Diabetic Crisis

Location Details:
${address != null ? 'Address: $address' : ''}
${latitude != null && longitude != null ? 'GPS Coordinates: $latitude, $longitude\nView Location: https://maps.google.com/?q=$latitude,$longitude' : 'Location: Not available'}

Recent Glucose Readings:
''';

    if (recentReadings.isNotEmpty) {
      for (int i = 0; i < recentReadings.length && i < 3; i++) {
        final reading = recentReadings[i];
        final value = reading['value'] ?? 'N/A';
        final type = reading['type'] ?? 'Unknown';
        final timestamp = reading['timestamp'] ?? 'Unknown time';
        message += '\n• $value mg/dL ($type) - $timestamp';
      }
    } else {
      message += '\nNo recent readings available';
    }

    message += '''

Emergency Contact Information:
Please respond immediately! This is a critical health emergency.

Sent from: Sugenix - Diabetes Management App
''';

    return message;
  }

  // Send SOS alert via SMS
  Future<bool> _sendSOSViaSMS({
    required String phoneNumber,
    required String message,
  }) async {
    try {
      print('Attempting to send SOS SMS to $phoneNumber');

      // Check/Request SMS permission
      final bool? permissionsGranted =
          await _telephony.requestPhoneAndSmsPermissions;

      if (permissionsGranted != true) {
        print('SMS permissions denied');
        return false;
      }

      // Format phone number
      // 1. Remove all non-digit characters except +
      String cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

      // 2. If it doesn't start with +, and is 10 digits, assume India (+91)
      // This is a common requirement for many Indian carriers to send SMS
      if (!cleanPhone.startsWith('+')) {
        if (cleanPhone.length == 10) {
          cleanPhone = '+91$cleanPhone';
        } else if (cleanPhone.length > 10) {
          // If it's already more than 10 digits but no +, add one if it doesn't have it
          cleanPhone = '+$cleanPhone';
        }
      }

      print('Sending SMS to $cleanPhone...');

      await _telephony.sendSms(
        to: cleanPhone,
        message: message,
        isMultipart: true, // Handle long messages
      );

      print('SMS sent successfully to $cleanPhone');
      return true;
    } catch (e) {
      print('Error sending SOS SMS: $e');
      return false;
    }
  }

  // Get recent glucose readings for the current user
  Future<List<Map<String, dynamic>>> _getRecentGlucoseReadings() async {
    try {
      if (_auth.currentUser == null) return [];

      final userId = _auth.currentUser!.uid;

      // Fetch without ordering to avoid index requirements for urgent SOS
      final snapshot = await _firestore
          .collection('glucose_readings')
          .where('userId', isEqualTo: userId)
          .limit(10) // Get more to sort in memory
          .get();

      final readings = snapshot.docs.map((doc) {
        final data = doc.data();
        final timestamp = data['timestamp'] as Timestamp?;
        return {
          'value': data['value'] ?? 0,
          'type': data['type'] ?? 'Unknown',
          'timestamp': timestamp != null ? timestamp.toDate() : DateTime.now(),
        };
      }).toList();

      // Sort in memory (descending)
      readings.sort((a, b) =>
          (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime));

      // Return top 3 formatted
      return readings
          .take(3)
          .map((r) => {
                'value': r['value'],
                'type': r['type'],
                'timestamp':
                    (r['timestamp'] as DateTime).toString().split('.').first,
              })
          .toList();
    } catch (e) {
      print('Error fetching glucose readings: $e');
      return [];
    }
  }

  // Get emergency contacts for the current user
  Future<List<Map<String, dynamic>>> _getEmergencyContacts() async {
    try {
      if (_auth.currentUser == null) return [];

      final userId = _auth.currentUser!.uid;

      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();

      final contacts = userData?['emergencyContacts'] as List? ?? [];

      return contacts
          .map((contact) {
            if (contact is Map) {
              return Map<String, dynamic>.from(contact);
            }
            return <String, dynamic>{};
          })
          .where((contact) =>
              contact['phone'] != null &&
              contact['phone'].toString().isNotEmpty)
          .toList();
    } catch (e) {
      print('Error fetching emergency contacts: $e');
      return [];
    }
  }

  // Send SOS alert to all emergency contacts
  Future<Map<String, dynamic>> triggerSOSAlert({
    String? customMessage,
  }) async {
    try {
      if (_auth.currentUser == null) {
        throw Exception('No user logged in');
      }

      final userId = _auth.currentUser!.uid;

      // Get user information
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();
      final userName = userData?['name'] ?? 'User';

      // Get current location with proper permission handling
      Position? position;
      String? address;

      try {
        // Request location permission first
        final hasPermission =
            await PlatformLocationService.hasLocationPermission();
        if (!hasPermission) {
          final granted =
              await PlatformLocationService.requestLocationPermission();
          if (!granted) {
            // Permission denied, continue without location
            print(
                'Location permission denied - SOS will continue without location');
          }
        }

        // Get current location (works with GPS even without SIM card)
        try {
          position = await PlatformLocationService.getCurrentLocation();
        } catch (e) {
          print(
              'Location request failed: $e - SOS will continue without location');
          position = null;
        }

        if (position != null) {
          final pos = position; // Local variable
          try {
            address = await PlatformLocationService.getAddressFromCoordinates(
              pos.latitude,
              pos.longitude,
            ).timeout(const Duration(seconds: 3), onTimeout: () {
              return 'Latitude: ${pos.latitude.toStringAsFixed(6)}, Longitude: ${pos.longitude.toStringAsFixed(6)}';
            });
          } catch (e) {
            print('Error getting address: $e');
            // Continue with coordinates only
            address =
                'Latitude: ${pos.latitude.toStringAsFixed(6)}, Longitude: ${pos.longitude.toStringAsFixed(6)}';
          }
        } else {
          print(
              'Location not available - SOS will continue without location (this is OK, may be due to no SIM/WiFi)');
        }
      } catch (e) {
        print(
            'Error getting location: $e - SOS will continue without location');
        // Continue without location - SOS should still work
      }

      // Get recent glucose readings
      final glucoseReadings = await _getRecentGlucoseReadings();

      // Get emergency contacts
      final emergencyContacts = await _getEmergencyContacts();

      if (emergencyContacts.isEmpty) {
        throw Exception('No emergency contacts saved');
      }

      // Generate SOS message
      final sosMessage = _generateSOSMessage(
        userName: userName,
        address: address,
        latitude: position?.latitude,
        longitude: position?.longitude,
        recentReadings: glucoseReadings,
      );

      // Store SOS alert in Firestore
      final alertDoc = await _firestore.collection('sos_alerts').add({
        'userId': userId,
        'userName': userName,
        'timestamp': FieldValue.serverTimestamp(),
        'location': position != null
            ? {
                'latitude': position.latitude,
                'longitude': position.longitude,
                'address': address,
              }
            : null,
        'glucoseReadings': glucoseReadings,
        'customMessage': customMessage,
        'sosMessage': sosMessage,
        'status': 'active',
        'emergencyContactsCount': emergencyContacts.length,
        'notificationStatus': {},
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Send SMS messages to all emergency contacts
      List<Map<String, dynamic>> notificationResults = [];
      Map<String, dynamic> notificationStatus = {};

      for (final contact in emergencyContacts) {
        final phoneNumber = contact['phone']?.toString() ?? '';
        final contactName = contact['name']?.toString() ?? 'Emergency Contact';

        if (phoneNumber.isNotEmpty) {
          final success = await _sendSOSViaSMS(
            phoneNumber: phoneNumber,
            message: sosMessage,
          );

          // Also send via EmailJS if email is available
          final email = contact['email']?.toString() ?? '';
          bool emailSuccess = false;
          if (email.isNotEmpty) {
            emailSuccess = await EmailJSService.sendSOSEmail(
              recipientEmail: email,
              recipientName: contactName,
              userName: userName,
              message: sosMessage,
            );
          }

          notificationResults.add({
            'contact': contactName,
            'phone': phoneNumber,
            'email': email,
            'status': (success || emailSuccess) ? 'sent' : 'failed',
            'sms_status': success ? 'sent' : 'failed',
            'email_status': email.isNotEmpty
                ? (emailSuccess ? 'sent' : 'failed')
                : 'not_available',
            'timestamp': DateTime.now().toIso8601String(),
          });

          notificationStatus[phoneNumber] = {
            'name': contactName,
            'status': (success || emailSuccess) ? 'sent' : 'failed',
            'sms_status': success ? 'sent' : 'failed',
            'email_status': email.isNotEmpty
                ? (emailSuccess ? 'sent' : 'failed')
                : 'not_available',
            'timestamp': FieldValue.serverTimestamp(),
          };
        }
      }

      // Update alert with notification status
      await alertDoc.update({
        'notificationStatus': notificationStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final successCount =
          notificationResults.where((r) => r['status'] == 'sent').length;

      return {
        'success': true,
        'contactsNotified': successCount,
        'notificationDetails': notificationResults,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Get SOS alert history for the current user
  Future<List<Map<String, dynamic>>> getSOSAlertHistory({
    int limit = 10,
  }) async {
    try {
      if (_auth.currentUser == null) return [];

      final snapshot = await _firestore
          .collection('sos_alerts')
          .where('userId', isEqualTo: _auth.currentUser!.uid)
          .limit(limit * 2) // Get more to sort
          .get();

      final alerts = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'timestamp': data['timestamp'],
          'status': data['status'],
          'location': data['location'],
          'contactsNotified': data['emergencyContactsCount'],
          'glucoseReadings': data['glucoseReadings'],
        };
      }).toList();

      // Sort in memory
      alerts.sort((a, b) {
        final aTime = a['timestamp'] as Timestamp?;
        final bTime = b['timestamp'] as Timestamp?;
        if (aTime == null || bTime == null) return 0;
        return bTime.compareTo(aTime);
      });

      return alerts.take(limit).toList();
    } catch (e) {
      print('Error fetching SOS history: $e');
      return [];
    }
  }

  // Cancel active SOS alert
  Future<void> cancelSOSAlert({required String alertId}) async {
    try {
      await _firestore.collection('sos_alerts').doc(alertId).update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to cancel SOS alert: ${e.toString()}');
    }
  }
}
