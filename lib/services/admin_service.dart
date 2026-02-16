import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Check if email and password match an admin account in Firestore
  Future<bool> verifyAdminCredentials(String email, String password) async {
    try {
      // Check if user exists in Firestore with admin role
      final usersSnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .where('role', isEqualTo: 'admin')
          .limit(1)
          .get();

      if (usersSnapshot.docs.isEmpty) {
        return false;
      }

      // Try to sign in with Firebase Auth to verify password
      try {
        await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        return true;
      } catch (e) {
        // Password doesn't match or other auth error
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// Get admin configuration from Firestore
  Future<Map<String, dynamic>?> getAdminConfig() async {
    try {
      final doc = await _firestore.collection('admin_config').doc('settings').get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Check if a user is an admin
  Future<bool> isAdmin(String? userId) async {
    if (userId == null) return false;
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data();
        return (data?['role'] as String?) == 'admin';
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}

