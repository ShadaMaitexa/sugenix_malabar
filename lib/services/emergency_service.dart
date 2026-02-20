import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sugenix/services/platform_location_service.dart';
import 'package:sugenix/services/emailjs_service.dart';

class EmergencyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Send emergency alert
  Future<void> sendEmergencyAlert({String? customMessage}) async {
    try {
      if (_auth.currentUser == null) throw Exception('No user logged in');

      // Get user data for name
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .get();
      String userName =
          (userDoc.data() as Map<String, dynamic>?)?['name'] ?? 'User';

      // Get user's current location
      Position? position = await PlatformLocationService.getCurrentLocation();

      // Get user's recent glucose readings
      List<Map<String, dynamic>> recentReadings =
          await _getRecentGlucoseReadings();

      // Get emergency contacts
      List<Map<String, dynamic>> emergencyContacts =
          await _getEmergencyContacts();

      // Create emergency alert
      await _firestore.collection('emergency_alerts').add({
        'userId': _auth.currentUser!.uid,
        'timestamp': FieldValue.serverTimestamp(),
        'location': position != null
            ? {
                'latitude': position.latitude,
                'longitude': position.longitude,
                'address':
                    await PlatformLocationService.getAddressFromCoordinates(
                  position.latitude,
                  position.longitude,
                ),
              }
            : null,
        'recentGlucoseReadings': recentReadings,
        'customMessage': customMessage,
        'status': 'active',
        'contactsNotified': [],
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Notify emergency contacts
      await _notifyEmergencyContacts(
        emergencyContacts,
        position,
        recentReadings,
        customMessage,
        userName,
      );
    } catch (e) {
      throw Exception('Failed to send emergency alert: ${e.toString()}');
    }
  }

  // Get recent glucose readings
  Future<List<Map<String, dynamic>>> _getRecentGlucoseReadings() async {
    try {
      if (_auth.currentUser == null) return [];

      QuerySnapshot snapshot =
          await _firestore.collection('glucose_readings').limit(5).get();

      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return {
          'value': data['value'],
          'type': data['type'],
          'timestamp': data['timestamp'],
          'notes': data['notes'],
        };
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // Get emergency contacts
  Future<List<Map<String, dynamic>>> _getEmergencyContacts() async {
    try {
      if (_auth.currentUser == null) return [];

      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        return List<Map<String, dynamic>>.from(
          userData['emergencyContacts'] ?? [],
        );
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  // Notify emergency contacts
  Future<void> _notifyEmergencyContacts(
    List<Map<String, dynamic>> contacts,
    Position? position,
    List<Map<String, dynamic>> glucoseReadings,
    String? customMessage,
    String userName,
  ) async {
    try {
      String locationText = position != null
          ? 'Location: ${position.latitude}, ${position.longitude}'
          : 'Location: Unable to determine';

      String message = '''
🚨 EMERGENCY ALERT from Sugenix App 🚨

${customMessage ?? 'User has activated emergency SOS'}

$locationText

Please check on the user immediately!
''';

      for (Map<String, dynamic> contact in contacts) {
        String? phone = contact['phone'] as String?;
        String? email = contact['email'] as String?;
        String contactName = contact['name'] as String? ?? 'Emergency Contact';

        if (phone != null && phone.isNotEmpty) {
          await _sendSMS(phone, message);
        }

        if (email != null && email.isNotEmpty) {
          await EmailJSService.sendSOSEmail(
            recipientEmail: email,
            recipientName: contactName,
            userName: userName,
            message: message,
          );
        }
      }
    } catch (e) {
      // Continue even if SMS fails
    }
  }

  // Send SMS
  Future<void> _sendSMS(String phoneNumber, String message) async {
    try {
      String cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      if (!cleanPhone.startsWith('+')) {
        cleanPhone = '+$cleanPhone';
      }

      final Uri smsUri = Uri(
        scheme: 'sms',
        path: cleanPhone,
        query: 'body=${Uri.encodeComponent(message)}',
      );

      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
      }
    } catch (e) {
      // SMS sending failed, continue
    }
  }

  // Cancel emergency alert
  Future<void> cancelEmergencyAlert() async {
    try {
      if (_auth.currentUser == null) throw Exception('No user logged in');

      QuerySnapshot activeAlerts =
          await _firestore.collection('emergency_alerts').get();
      final userId = _auth.currentUser!.uid;

      // Filter by userId and status
      final filteredDocs = activeAlerts.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return data['userId'] == userId && data['status'] == 'active';
      }).toList();

      for (var doc in filteredDocs) {
        await doc.reference.update({
          'status': 'cancelled',
          'cancelledAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      throw Exception('Failed to cancel emergency alert: ${e.toString()}');
    }
  }

  // Get emergency history
  Stream<List<Map<String, dynamic>>> getEmergencyHistory() {
    if (_auth.currentUser == null) return Stream.value([]);

    final userId = _auth.currentUser!.uid;
    return _firestore.collection('emergency_alerts').snapshots().map(
      (snapshot) {
        final allAlerts = snapshot.docs.map((doc) {
          Map<String, dynamic> data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();

        // Filter by userId and sort by timestamp
        final filtered = allAlerts.where((a) => a['userId'] == userId).toList();
        filtered.sort((a, b) {
          final aTime = a['timestamp'];
          final bTime = b['timestamp'];
          if (aTime == null || bTime == null) return 0;
          final aDate = aTime is Timestamp
              ? aTime.toDate()
              : (aTime is DateTime ? aTime : DateTime.now());
          final bDate = bTime is Timestamp
              ? bTime.toDate()
              : (bTime is DateTime ? bTime : DateTime.now());
          return bDate.compareTo(aDate); // Descending
        });
        return filtered;
      },
    );
  }

  // Check if emergency is active
  Future<bool> isEmergencyActive() async {
    try {
      if (_auth.currentUser == null) return false;

      QuerySnapshot activeAlerts =
          await _firestore.collection('emergency_alerts').get();

      return activeAlerts.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Request location permission
  Future<bool> requestLocationPermission() async {
    return await PlatformLocationService.requestLocationPermission();
  }

  // Check location permission
  Future<bool> hasLocationPermission() async {
    return await PlatformLocationService.hasLocationPermission();
  }

  // Get emergency contacts for current user
  Stream<List<Map<String, dynamic>>> getEmergencyContacts() {
    if (_auth.currentUser == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        return List<Map<String, dynamic>>.from(
          data['emergencyContacts'] ?? [],
        );
      }
      return <Map<String, dynamic>>[];
    });
  }

  // Add emergency contact
  Future<void> addEmergencyContact({
    required String name,
    required String phone,
    String? email,
    required String relationship,
  }) async {
    try {
      if (_auth.currentUser == null) throw Exception('No user logged in');

      // Firestore does not allow sentinel values like FieldValue.serverTimestamp()
      // inside arrayUnion elements. Use a client timestamp instead or perform a
      // separate update. Here we use the local timestamp to avoid the invalid-data error.
      await _firestore.collection('users').doc(_auth.currentUser!.uid).update({
        'emergencyContacts': FieldValue.arrayUnion([
          {
            'name': name,
            'phone': phone,
            'email': email ?? '',
            'relationship': relationship,
            'addedAt': DateTime.now().toUtc(),
          },
        ]),
      });
    } catch (e) {
      throw Exception('Failed to add emergency contact: ${e.toString()}');
    }
  }

  // Remove emergency contact
  Future<void> removeEmergencyContact(int index) async {
    try {
      if (_auth.currentUser == null) throw Exception('No user logged in');

      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .get();
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      List<dynamic> contacts = data['emergencyContacts'] ?? [];

      if (index >= 0 && index < contacts.length) {
        contacts.removeAt(index);
        await _firestore.collection('users').doc(_auth.currentUser!.uid).update(
          {'emergencyContacts': contacts},
        );
      }
    } catch (e) {
      throw Exception('Failed to remove emergency contact: ${e.toString()}');
    }
  }
}
