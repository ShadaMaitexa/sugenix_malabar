import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sugenix/services/revenue_service.dart';

class AppointmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final RevenueService _revenueService = RevenueService();

  // Book an appointment
  Future<String> bookAppointment({
    required String doctorId,
    required String doctorName,
    required DateTime dateTime,
    required String patientName,
    required String patientMobile,
    required String patientType,
    String? notes,
    double? fee,
  }) async {
    try {
      if (_auth.currentUser == null) throw Exception('No user logged in');

      // Check if slot is available for this specific doctor and dateTime
      // Get all active appointments for this doctor (client-side filter for now to avoid Index issues)
      final allAppointments = await _firestore
          .collection('appointments')
          .where('doctorId', isEqualTo: doctorId)
          .get();

      // Check for conflicts
      for (var doc in allAppointments.docs) {
        final existingData = doc.data();
        final existingStatus = existingData['status'] as String?;

        // Skip cancelled or rejected appointments
        if (existingStatus == 'cancelled' ||
            existingStatus == 'rejected' ||
            existingStatus == 'completed') {
          continue;
        }

        final existingDateTime =
            (existingData['dateTime'] as Timestamp?)?.toDate();
        if (existingDateTime == null) continue;

        // precise check: same year, month, day
        if (existingDateTime.year == dateTime.year &&
            existingDateTime.month == dateTime.month &&
            existingDateTime.day == dateTime.day) {
          // Check if time slot conflicts (within 30 minutes)
          final timeDifference =
              (existingDateTime.difference(dateTime).inMinutes).abs();
          if (timeDifference < 30) {
            throw Exception('This time slot is already booked');
          }
        }
      }

      // Calculate fees
      double consultationFee = fee ?? 0.0;
      final fees = RevenueService.calculateFees(consultationFee);
      final totalFee = fees['totalFee']!;
      final platformFee = fees['platformFee']!;
      final doctorFee = fees['doctorFee']!;

      // Create appointment
      final appointmentRef = await _firestore.collection('appointments').add({
        'doctorId': doctorId,
        'doctorName': doctorName,
        'patientId': _auth.currentUser!.uid,
        'dateTime': Timestamp.fromDate(dateTime),
        'status': 'scheduled',
        'patientName': patientName,
        'patientMobile': patientMobile,
        'patientType': patientType,
        'notes': notes,
        'fee': consultationFee,
        'totalFee': totalFee,
        'platformFee': platformFee,
        'doctorFee': doctorFee,
        'paymentStatus': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update doctor's booking count
      await _firestore.collection('doctors').doc(doctorId).update({
        'totalBookings': FieldValue.increment(1),
      });

      return appointmentRef.id;
    } catch (e) {
      throw Exception('Failed to book appointment: ${e.toString()}');
    }
  }

  // Process payment for appointment
  Future<void> processPayment({
    required String appointmentId,
    required String paymentMethod,
  }) async {
    try {
      final appointmentDoc =
          await _firestore.collection('appointments').doc(appointmentId).get();

      if (!appointmentDoc.exists) {
        throw Exception('Appointment not found');
      }

      final data = appointmentDoc.data()!;
      final consultationFee = (data['fee'] as num?)?.toDouble() ?? 0.0;
      final doctorId = data['doctorId'] as String;
      final patientId = data['patientId'] as String;

      // Record revenue
      await _revenueService.recordRevenue(
        appointmentId: appointmentId,
        doctorId: doctorId,
        patientId: patientId,
        consultationFee: consultationFee,
        platformFee: (data['platformFee'] as num?)?.toDouble() ?? 0.0,
        doctorFee: (data['doctorFee'] as num?)?.toDouble() ?? 0.0,
        paymentMethod: paymentMethod,
      );

      // Update appointment payment status
      await _firestore.collection('appointments').doc(appointmentId).update({
        'paymentStatus': 'paid',
        'paymentMethod': paymentMethod,
        'paidAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to process payment: ${e.toString()}');
    }
  }

  // Get user's appointments
  Stream<List<Map<String, dynamic>>> getUserAppointments() {
    if (_auth.currentUser == null) return Stream.value([]);

    final userId = _auth.currentUser!.uid;
    // Optimized: Filter by patientId in query
    return _firestore
        .collection('appointments')
        .where('patientId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final allAppointments = snapshot.docs.map((doc) {
        final data = doc.data();
        final timestamp = data['dateTime'] as Timestamp?;
        return {
          'id': doc.id,
          ...data,
          'dateTime': timestamp?.toDate() ?? DateTime.now(),
        };
      }).toList();

      // Sort by dateTime descending (client-side)
      allAppointments.sort((a, b) {
        final aDate = a['dateTime'] as DateTime;
        final bDate = b['dateTime'] as DateTime;
        return bDate.compareTo(aDate); // Descending
      });
      return allAppointments;
    });
  }

  // Get doctor's appointments
  Stream<List<Map<String, dynamic>>> getDoctorAppointments() {
    if (_auth.currentUser == null) return Stream.value([]);

    final doctorId = _auth.currentUser!.uid;
    // Optimized: Filter by doctorId in query
    return _firestore
        .collection('appointments')
        .where('doctorId', isEqualTo: doctorId)
        .snapshots()
        .map((snapshot) {
      final allAppointments = snapshot.docs.map((doc) {
        final data = doc.data();
        final timestamp = data['dateTime'] as Timestamp?;
        return {
          'id': doc.id,
          ...data,
          'dateTime': timestamp?.toDate() ?? DateTime.now(),
        };
      }).toList();

      // Sort by dateTime ascending (client-side)
      allAppointments.sort((a, b) {
        final aDate = a['dateTime'] as DateTime;
        final bDate = b['dateTime'] as DateTime;
        return aDate.compareTo(bDate);
      });
      return allAppointments;
    });
  }

  // Get appointment by ID
  Future<Map<String, dynamic>?> getAppointmentById(String appointmentId) async {
    try {
      final doc =
          await _firestore.collection('appointments').doc(appointmentId).get();
      if (doc.exists) {
        final data = doc.data()!;
        final timestamp = data['dateTime'] as Timestamp?;
        return {
          'id': doc.id,
          ...data,
          'dateTime': timestamp?.toDate() ?? DateTime.now(),
        };
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get appointment: ${e.toString()}');
    }
  }

  // Cancel appointment
  Future<void> cancelAppointment(String appointmentId) async {
    try {
      await _firestore.collection('appointments').doc(appointmentId).update({
        'status': 'cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to cancel appointment: ${e.toString()}');
    }
  }

  Future<void> updateAppointmentStatus(
      String appointmentId, String status) async {
    try {
      await _firestore.collection('appointments').doc(appointmentId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update appointment: ${e.toString()}');
    }
  }

  // Share medical records with doctor
  Future<void> shareMedicalRecordsWithDoctor({
    required String doctorId,
    required String appointmentId,
    required List<String> recordIds,
  }) async {
    try {
      if (_auth.currentUser == null) throw Exception('No user logged in');

      await _firestore.collection('shared_records').add({
        'patientId': _auth.currentUser!.uid,
        'doctorId': doctorId,
        'appointmentId': appointmentId,
        'recordIds': recordIds,
        'sharedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to share records: ${e.toString()}');
    }
  }

  // Get shared records for an appointment
  Future<List<String>> getSharedRecordsForAppointment(
      String appointmentId) async {
    try {
      final snapshot =
          await _firestore.collection('shared_records').limit(1).get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        return List<String>.from(data['recordIds'] ?? []);
      }
      return [];
    } catch (e) {
      throw Exception('Failed to get shared records: ${e.toString()}');
    }
  }

  // Get doctor's available time slots for a date
  Future<List<String>> getAvailableTimeSlots(
      String doctorId, DateTime date) async {
    try {
      // Get all appointments for this doctor (filtered by doctorId)
      final appointments = await _firestore
          .collection('appointments')
          .where('doctorId', isEqualTo: doctorId)
          .get();

      final bookedSlots = appointments.docs
          .map((doc) {
            final data = doc.data();

            // Check status - dont count cancelled as booked
            final status = data['status'] as String?;
            if (status == 'cancelled' ||
                status == 'rejected' ||
                status == 'completed') return null;

            final timestamp = data['dateTime'] as Timestamp?;
            if (timestamp != null) {
              final dt = timestamp.toDate();

              // Only consider appointments on the SAME DAY
              if (dt.year == date.year &&
                  dt.month == date.month &&
                  dt.day == date.day) {
                return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
              }
            }
            return null;
          })
          .where((slot) => slot != null)
          .toSet();

      // Generate all possible slots (9 AM to 9 PM, 30-minute intervals)
      final allSlots = <String>[];
      for (int hour = 9; hour < 21; hour++) {
        for (int minute = 0; minute < 60; minute += 30) {
          final slot =
              '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

          // Check if slot is in the past (if date is today)
          if (date.year == DateTime.now().year &&
              date.month == DateTime.now().month &&
              date.day == DateTime.now().day) {
            final now = DateTime.now();
            final slotTime =
                DateTime(date.year, date.month, date.day, hour, minute);

            if (slotTime.isBefore(now)) {
              continue; // Skip past slots
            }
          }

          if (!bookedSlots.contains(slot)) {
            allSlots.add(slot);
          }
        }
      }

      return allSlots;
    } catch (e) {
      print('Error getting available slots: $e');
      // Return empty list on error
      return [
        '09:00',
        '09:30',
        '10:00',
        '10:30',
        '11:00',
        '11:30',
        '12:00',
        '12:30',
        '13:00',
        '13:30',
        '14:00',
        '14:30',
        '15:00',
        '15:30',
        '16:00',
        '16:30',
        '17:00',
        '17:30',
        '18:00',
        '18:30',
        '19:00',
        '19:30',
        '20:00',
        '20:30'
      ];
    }
  }
}
