import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sugenix/services/platform_location_service.dart';
import 'package:sugenix/services/emailjs_service.dart';
import 'package:geolocator/geolocator.dart';

class SOSAlertService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Request necessary permissions proactively

  // Generate SOS message with location
  static String _generateSOSMessage({
    required String userName,
    required String userEmail,
    required String? address,
    required double? latitude,
    required double? longitude,
    required List<Map<String, dynamic>> recentReadings,
  }) {
    String message = '''🚨 SOS EMERGENCY ALERT 🚨
    
User: $userName
Alert Type: Medical Emergency

Location Details:
${address != null && !address.startsWith('Lat:') ? 'Address: $address' : ''}
GPS Coordinates: ${latitude ?? 'N/A'}, ${longitude ?? 'N/A'}
View Live Location: https://maps.google.com/?q=${latitude ?? 0},${longitude ?? 0}

The user $userName is in distress and has activated an SOS alert from the Sugenix App. 
Please respond immediately! This is a critical health emergency.

Sent from: Sugenix - Diabetes Management App
''';

    return message;
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
              (contact['phone'] != null &&
                  contact['phone'].toString().isNotEmpty) ||
              (contact['email'] != null &&
                  contact['email'].toString().isNotEmpty))
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
      final userEmail =
          userData?['email'] ?? _auth.currentUser?.email ?? 'No email';

      // Get current location with proper permission handling
      Position? position;
      String? address;
      String? locationError;

      try {
        print('📍 Requesting location permission...');
        // Request location permission first
        final hasPermission =
            await PlatformLocationService.hasLocationPermission();
        if (!hasPermission) {
          print('📍 Permission not granted, requesting...');
          final granted = await PlatformLocationService.requestLocationPermission();
          if (!granted) {
            locationError = 'Location permission denied';
            print('⚠️ Location permission denied');
          }
        }

        if (locationError == null) {
          print('📍 Fetching current location...');
          // Get current location with timeout
          position = await PlatformLocationService.getCurrentLocation()
              .timeout(const Duration(seconds: 8), onTimeout: () {
            print('⏱️ Location fetch timeout');
            locationError = 'Location fetch timeout';
            return null;
          });

          if (position != null) {
            print('✅ Location obtained: ${position.latitude}, ${position.longitude}');
            final pos = position;
            try {
              // Very short timeout for reverse geocoding to avoid blocking SOS
              address = await PlatformLocationService.getAddressFromCoordinates(
                pos.latitude,
                pos.longitude,
              ).timeout(const Duration(seconds: 3), onTimeout: () {
                return 'Lat: ${pos.latitude.toStringAsFixed(4)}, Lng: ${pos.longitude.toStringAsFixed(4)}';
              });
            } catch (e) {
              address =
                  'Lat: ${pos.latitude.toStringAsFixed(4)}, Lng: ${pos.longitude.toStringAsFixed(4)}';
            }
          } else {
            locationError = locationError ?? 'Failed to get location';
            print('❌ Location is null: $locationError');
          }
        }
      } catch (e) {
        locationError = e.toString();
        print('❌ Location error (non-fatal for SOS): $e');
      }

      // Get recent glucose readings
      final glucoseReadings = await _getRecentGlucoseReadings();

      // Get emergency contacts
      final emergencyContacts = await _getEmergencyContacts();

      if (emergencyContacts.isEmpty) {
        return {
          'success': false,
          'error':
              'No emergency contacts found. Please add contacts in settings first.',
          'type': 'no_contacts',
        };
      }

      // Require at least one contact with email (SOS sends via EmailJS)
      final contactsWithEmail = emergencyContacts
          .where((c) =>
              (c['email'] != null && c['email'].toString().trim().isNotEmpty))
          .toList();
      if (contactsWithEmail.isEmpty) {
        return {
          'success': false,
          'error':
              'No emergency contact has an email address. Please add email to at least one contact in Emergency Contacts.',
          'type': 'no_email',
        };
      }

      // Generate SOS message
      final sosMessage = _generateSOSMessage(
        userName: userName,
        userEmail: userEmail,
        address: address,
        latitude: position?.latitude,
        longitude: position?.longitude,
        recentReadings: glucoseReadings,
      );

      // Store SOS alert in Firestore (even if location failed, we still create the alert)
      final alertDoc = await _firestore.collection('sos_alerts').add({
        'userId': userId,
        'userName': userName,
        'timestamp': FieldValue.serverTimestamp(),
        'location': position != null
            ? {
                'latitude': position.latitude,
                'longitude': position.longitude,
                'address': address ?? 'Location obtained but address unavailable',
              }
            : null,
        'locationError': locationError,
        'glucoseReadings': glucoseReadings,
        'customMessage': customMessage,
        'status': 'active',
        'emergencyContactsCount': emergencyContacts.length,
        'notificationStatus': {},
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Send Email messages to all emergency contacts with email addresses
      List<Map<String, dynamic>> notificationResults = [];
      Map<String, dynamic> notificationStatus = {};

      print('📧 Attempting to send SOS emails to ${contactsWithEmail.length} contact(s) with email');

      for (final contact in contactsWithEmail) {
        final contactName = contact['name']?.toString() ?? 'Emergency Contact';
        final email = contact['email']?.toString().trim();

        if (email == null || email.isEmpty) {
          print('⚠️ Skipping contact $contactName - email is empty');
          continue;
        }

        print('📧 Sending SOS email to $contactName ($email)...');
        
        String? emailError;
        bool emailSuccess = false;
        
        try {
          final emailResult = await EmailJSService.sendSOSEmailWithError(
            recipientEmail: email,
            recipientName: contactName,
            userName: userName,
            message: sosMessage,
            latitude: position?.latitude,
            longitude: position?.longitude,
          ).timeout(const Duration(seconds: 15), onTimeout: () {
            emailError = 'EmailJS request timeout (15s)';
            print('⏱️ EmailJS timeout for $email');
            return {'success': false, 'error': emailError!};
          });

          emailSuccess = emailResult['success'] == true;
          emailError = emailResult['error'] as String?;

          if (emailSuccess) {
            print('✅ SOS email sent successfully to $email');
          } else {
            print('❌ Failed to send SOS email to $email: ${emailError ?? "Unknown error"}');
          }
        } catch (e, stackTrace) {
          emailError = e.toString();
          print('❌ Exception sending SOS email to $email: $e');
          print('Stack trace: $stackTrace');
        }

        notificationResults.add({
          'contact': contactName,
          'email': email,
          'status': emailSuccess ? 'sent' : 'failed',
          'error': emailError,
          'timestamp': DateTime.now().toIso8601String(),
        });

        notificationStatus[email.replaceAll('.', '_')] = {
          'name': contactName,
          'status': emailSuccess ? 'sent' : 'failed',
          'error': emailError,
          'timestamp': FieldValue.serverTimestamp(),
        };
      }

      // Update alert with final status
      await alertDoc.update({
        'notificationStatus': notificationStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final successCount =
          notificationResults.where((r) => r['status'] == 'sent').length;
      final failedCount = notificationResults.where((r) => r['status'] == 'failed').length;

      print('📊 SOS Email Summary: $successCount sent, $failedCount failed out of ${contactsWithEmail.length} contacts');

      if (successCount == 0 && failedCount > 0) {
        // Get first error for more details
        final firstError = notificationResults.firstWhere(
          (r) => r['status'] == 'failed',
          orElse: () => {},
        );
        final errorMsg = firstError['error']?.toString() ?? 'Unknown error';
        print('❌ All emails failed. First error: $errorMsg');
      }

      return {
        'success': successCount > 0,
        'contactsNotified': successCount,
        'totalContacts': contactsWithEmail.length,
        'failedCount': failedCount,
        'notificationDetails': notificationResults,
        'error': successCount == 0
            ? 'Failed to notify any contacts via email. Please check your internet connection, EmailJS settings, or contact settings.'
            : null,
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
      final userId = _auth.currentUser!.uid;
      QuerySnapshot snapshot = await _firestore
          .collection('sos_alerts')
          .where('userId', isEqualTo: userId)
          .limit(limit * 2) // Get more to sort
          .get();

      final alerts = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>?;
        return {
          'id': doc.id,
          'timestamp': data?['timestamp'],
          'status': data?['status'],
          'location': data?['location'],
          'contactsNotified': data?['emergencyContactsCount'],
          'glucoseReadings': data?['glucoseReadings'],
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
