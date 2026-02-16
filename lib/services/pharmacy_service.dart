import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sugenix/services/emailjs_service.dart';

class PharmacyService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get pending pharmacies for admin approval
  Stream<List<Map<String, dynamic>>> getPendingPharmacies() {
    return _db.collection('pharmacies').snapshots().map((snapshot) {
      final allPharmacies = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();

      // Filter by approvalStatus or verified field
      return allPharmacies.where((p) {
        final approvalStatus = p['approvalStatus'] as String?;
        final verified = p['verified'] as bool?;
        // If approvalStatus exists, use it; otherwise check verified field
        if (approvalStatus != null) {
          return approvalStatus == 'pending';
        }
        // If using old verified field, treat false as pending
        return verified == false;
      }).toList();
    });
  }

  // Approve or reject a pharmacy
  Future<void> updatePharmacyApprovalStatus(
      String pharmacyId, String status) async {
    // Get pharmacy data before updating
    final pharmacyDoc = await _db.collection('pharmacies').doc(pharmacyId).get();
    final pharmacyData = pharmacyDoc.data();
    final pharmacyName = pharmacyData?['name'] as String? ?? 'Pharmacy';

    // Get user email from Firestore users collection
    final userDoc = await _db.collection('users').doc(pharmacyId).get();
    final userData = userDoc.data();
    String? userEmail = userData?['email'] as String?;
    
    // If email not in users collection, try to get from current user if it matches
    if ((userEmail == null || userEmail.isEmpty) && _auth.currentUser?.uid == pharmacyId) {
      userEmail = _auth.currentUser?.email;
    }

    // Update pharmacy status
    await _db.collection('pharmacies').doc(pharmacyId).update({
      'approvalStatus': status,
      'verified': status == 'approved',
      'approvedAt': status == 'approved' ? FieldValue.serverTimestamp() : null,
    });

    // Also update in users collection
    await _db.collection('users').doc(pharmacyId).update({
      'approvalStatus': status,
    });

    // Send email notification
    if (userEmail != null && userEmail.isNotEmpty) {
      try {
        if (status == 'approved') {
          await EmailJSService.sendApprovalEmail(
            recipientEmail: userEmail,
            recipientName: pharmacyName,
            role: 'pharmacy',
          );
        } else if (status == 'rejected') {
          await EmailJSService.sendRejectionEmail(
            recipientEmail: userEmail,
            recipientName: pharmacyName,
            role: 'pharmacy',
          );
        }
      } catch (e) {
        print('Failed to send email notification: $e');
        // Don't throw error - email is optional
      }
    }
  }

  // Get all approved pharmacies
  Stream<List<Map<String, dynamic>>> getApprovedPharmacies() {
    return _db.collection('pharmacies').snapshots().map((snapshot) {
      return snapshot.docs
          .where((doc) {
            final data = doc.data();
            final approvalStatus = data['approvalStatus'] as String?;
            final verified = data['verified'] as bool?;
            if (approvalStatus != null) {
              return approvalStatus == 'approved';
            }
            return verified == true;
          })
          .map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              ...data,
            };
          })
          .toList();
    });
  }
}

