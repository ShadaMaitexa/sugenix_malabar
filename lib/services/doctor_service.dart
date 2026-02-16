import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sugenix/models/doctor.dart';
import 'package:sugenix/services/emailjs_service.dart';

class DoctorService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<List<Doctor>> streamDoctors() {
    return _db.collection('doctors').snapshots().map((snapshot) {
      // Filter by approvalStatus before converting to Doctor objects
      final approvedDocs = snapshot.docs.where((doc) {
        final data = doc.data();
        return (data['approvalStatus'] as String?) == 'approved';
      }).toList();

      return approvedDocs.map((doc) {
        final data = doc.data();
        // Ensure id field presence
        return Doctor.fromJson({
          'id': data['id'] ?? doc.id,
          ...data,
        });
      }).toList();
    });
  }

  Future<List<Doctor>> getDoctors() async {
    final snapshot = await _db.collection('doctors').get();
    // Filter by approvalStatus before converting to Doctor objects
    final approvedDocs = snapshot.docs.where((doc) {
      final data = doc.data();
      return (data['approvalStatus'] as String?) == 'approved';
    }).toList();

    return approvedDocs.map((doc) {
      final data = doc.data();
      return Doctor.fromJson({
        'id': data['id'] ?? doc.id,
        ...data,
      });
    }).toList();
  }

  // Get pending doctors for admin approval
  Stream<List<Map<String, dynamic>>> getPendingDoctors() {
    return _db.collection('doctors').snapshots().map((snapshot) {
      final allDoctors = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();

      // Filter by approvalStatus
      return allDoctors
          .where((d) => (d['approvalStatus'] as String?) == 'pending')
          .toList();
    });
  }

  // Approve or reject a doctor
  Future<void> updateDoctorApprovalStatus(
      String doctorId, String status) async {
    // Get doctor data before updating
    final doctorDoc = await _db.collection('doctors').doc(doctorId).get();
    final doctorData = doctorDoc.data();
    final doctorName = doctorData?['name'] as String? ?? 'Doctor';

    // Get user email from Firestore users collection
    final userDoc = await _db.collection('users').doc(doctorId).get();
    final userData = userDoc.data();
    String? userEmail = userData?['email'] as String?;
    
    // If email not in users collection, try to get from current user if it matches
    if ((userEmail == null || userEmail.isEmpty) && _auth.currentUser?.uid == doctorId) {
      userEmail = _auth.currentUser?.email;
    }

    // Update doctor status
    await _db.collection('doctors').doc(doctorId).update({
      'approvalStatus': status,
      'approvedAt': status == 'approved' ? FieldValue.serverTimestamp() : null,
    });

    // Also update in users collection
    await _db.collection('users').doc(doctorId).update({
      'approvalStatus': status,
    });

    // Send email notification
    if (userEmail != null && userEmail.isNotEmpty) {
      try {
        if (status == 'approved') {
          await EmailJSService.sendApprovalEmail(
            recipientEmail: userEmail,
            recipientName: doctorName,
            role: 'doctor',
          );
        } else if (status == 'rejected') {
          await EmailJSService.sendRejectionEmail(
            recipientEmail: userEmail,
            recipientName: doctorName,
            role: 'doctor',
          );
        }
      } catch (e) {
        print('Failed to send email notification: $e');
        // Don't throw error - email is optional
      }
    }
  }
}
