import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RoleService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get uid => _auth.currentUser?.uid;

  Stream<String> roleStream() {
    final id = uid;
    if (id == null) return const Stream.empty();
    return _db.collection('users').doc(id).snapshots().map((doc) {
      final data = doc.data();
      return (data?['role'] as String?) ?? 'user';
    });
  }

  Future<String> getRole() async {
    final id = uid;
    if (id == null) return 'user';
    final doc = await _db.collection('users').doc(id).get();
    return (doc.data()?['role'] as String?) ?? 'user';
  }

  Future<bool> isAdmin() async => (await getRole()) == 'admin';
  Future<bool> isDoctor() async => (await getRole()) == 'doctor';
}


