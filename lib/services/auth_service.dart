import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email and password
  Future<UserCredential?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required String phone,
    DateTime? dateOfBirth,
    String? gender,
    required String diabetesType,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user profile in Firestore
      await _firestore.collection('users').doc(result.user!.uid).set({
        'name': name,
        'email': email,
        'phone': phone,
        'dateOfBirth': dateOfBirth,
        'gender': gender,
        'diabetesType': diabetesType,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
        'isActive': true,
        'emergencyContacts': [],
        'medicalHistory': [],
        'preferences': {
          'notifications': true,
          'reminders': true,
          'language': 'en',
        },
      });

      return result;
    } catch (e) {
      throw Exception('Sign up failed: ${e.toString()}');
    }
  }

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update last login
      await _firestore.collection('users').doc(result.user!.uid).update({
        'lastLogin': FieldValue.serverTimestamp(),
      });

      return result;
    } catch (e) {
      throw Exception('Sign in failed: ${e.toString()}');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Sign out failed: ${e.toString()}');
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception('Password reset failed: ${e.toString()}');
    }
  }

  // Change password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      if (currentUser == null) throw Exception('No user logged in');

      // Re-authenticate user
      final credential = EmailAuthProvider.credential(
        email: currentUser!.email!,
        password: currentPassword,
      );
      await currentUser!.reauthenticateWithCredential(credential);

      // Update password
      await currentUser!.updatePassword(newPassword);
    } catch (e) {
      throw Exception('Password change failed: ${e.toString()}');
    }
  }

  // Update user profile (handles role-specific fields)
  Future<void> updateUserProfile({
    String? name,
    String? phone,
    DateTime? dateOfBirth,
    String? gender,
    String? diabetesType,
    double? height,
    double? weight,
    // Doctor-specific fields
    String? specialization,
    String? hospital,
    String? bio,
    String? experience,
    String? education,
    double? consultationFee,
    List<String>? languages,
    // Pharmacy-specific fields
    String? address,
    String? licenseNumber,
  }) async {
    try {
      if (currentUser == null) throw Exception('No user logged in');

      // Get user role
      final userDoc =
          await _firestore.collection('users').doc(currentUser!.uid).get();
      final role = userDoc.data()?['role'] as String?;

      // Update users collection (common fields)
      Map<String, dynamic> userUpdateData = {};
      if (name != null) userUpdateData['name'] = name;
      if (phone != null) userUpdateData['phone'] = phone;

      // Patient-specific fields
      if (role == 'user' || role == null) {
        if (dateOfBirth != null) userUpdateData['dateOfBirth'] = dateOfBirth;
        if (gender != null) userUpdateData['gender'] = gender;
        if (diabetesType != null) userUpdateData['diabetesType'] = diabetesType;
        if (height != null) userUpdateData['height'] = height;
        if (weight != null) userUpdateData['weight'] = weight;
      }

      if (userUpdateData.isNotEmpty) {
        await _firestore
            .collection('users')
            .doc(currentUser!.uid)
            .update(userUpdateData);
      }

      // Update role-specific collections
      if (role == 'doctor') {
        Map<String, dynamic> doctorUpdateData = {};
        if (name != null) doctorUpdateData['name'] = name;
        if (phone != null) doctorUpdateData['phone'] = phone;
        if (specialization != null)
          doctorUpdateData['specialization'] = specialization;
        if (hospital != null) doctorUpdateData['hospital'] = hospital;
        if (bio != null) doctorUpdateData['bio'] = bio;
        if (experience != null) doctorUpdateData['experience'] = experience;
        if (education != null) doctorUpdateData['education'] = education;
        if (consultationFee != null)
          doctorUpdateData['consultationFee'] = consultationFee;
        if (languages != null) doctorUpdateData['languages'] = languages;

        if (doctorUpdateData.isNotEmpty) {
          await _firestore
              .collection('doctors')
              .doc(currentUser!.uid)
              .update(doctorUpdateData);
        }
      } else if (role == 'pharmacy') {
        Map<String, dynamic> pharmacyUpdateData = {};
        if (name != null) pharmacyUpdateData['name'] = name;
        if (phone != null) pharmacyUpdateData['phone'] = phone;
        if (address != null) pharmacyUpdateData['address'] = address;
        if (licenseNumber != null)
          pharmacyUpdateData['licenseNumber'] = licenseNumber;

        if (pharmacyUpdateData.isNotEmpty) {
          await _firestore
              .collection('pharmacies')
              .doc(currentUser!.uid)
              .update(pharmacyUpdateData);
        }
      }
    } catch (e) {
      throw Exception('Profile update failed: ${e.toString()}');
    }
  }

  // Get user profile (merges data from users and role-specific collections)
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      if (currentUser == null) return null;

      // Get user data
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(currentUser!.uid).get();

      if (!userDoc.exists) return null;

      Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;
      if (userData == null) return null;

      // Get role-specific data
      final role = userData['role'] as String?;
      if (role == 'doctor') {
        DocumentSnapshot doctorDoc =
            await _firestore.collection('doctors').doc(currentUser!.uid).get();
        if (doctorDoc.exists) {
          final doctorData = doctorDoc.data() as Map<String, dynamic>?;
          if (doctorData != null) {
            userData = {...userData, ...doctorData};
          }
        }
      } else if (role == 'pharmacy') {
        DocumentSnapshot pharmacyDoc = await _firestore
            .collection('pharmacies')
            .doc(currentUser!.uid)
            .get();
        if (pharmacyDoc.exists) {
          final pharmacyData = pharmacyDoc.data() as Map<String, dynamic>?;
          if (pharmacyData != null) {
            userData = {...userData, ...pharmacyData};
          }
        }
      }

      return userData;
    } catch (e) {
      throw Exception('Failed to get user profile: ${e.toString()}');
    }
  }

  // Add emergency contact
  Future<void> addEmergencyContact({
    required String name,
    required String phone,
    String? email,
    required String relationship,
  }) async {
    try {
      if (currentUser == null) throw Exception('No user logged in');

      await _firestore.collection('users').doc(currentUser!.uid).update({
        'emergencyContacts': FieldValue.arrayUnion([
          {
            'name': name,
            'phone': phone,
            'email': email ?? '',
            'relationship': relationship,
            'addedAt': FieldValue.serverTimestamp(),
          },
        ]),
      });
    } catch (e) {
      throw Exception('Failed to add emergency contact: ${e.toString()}');
    }
  }

  // Delete emergency contact
  Future<void> deleteEmergencyContact(int index) async {
    try {
      if (currentUser == null) throw Exception('No user logged in');

      DocumentSnapshot doc =
          await _firestore.collection('users').doc(currentUser!.uid).get();
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      List<dynamic> contacts = data['emergencyContacts'] ?? [];

      if (index >= 0 && index < contacts.length) {
        contacts.removeAt(index);
        await _firestore.collection('users').doc(currentUser!.uid).update({
          'emergencyContacts': contacts,
        });
      }
    } catch (e) {
      throw Exception('Failed to delete emergency contact: ${e.toString()}');
    }
  }

  // Set user role
  Future<void> setUserRole(String role) async {
    try {
      if (currentUser == null) throw Exception('No user logged in');

      await _firestore.collection('users').doc(currentUser!.uid).update({
        'role': role,
      });
    } catch (e) {
      throw Exception('Failed to set user role: ${e.toString()}');
    }
  }
}
