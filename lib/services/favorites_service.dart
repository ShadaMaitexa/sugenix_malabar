import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sugenix/models/doctor.dart';

class FavoritesService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> _collection() {
    return _db.collection('users').doc(_uid).collection('favorites');
  }

  Future<void> addFavorite(String doctorId) async {
    await _collection().doc(doctorId).set({
      'doctorId': doctorId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeFavorite(String doctorId) async {
    await _collection().doc(doctorId).delete();
  }

  Stream<bool> isFavoriteStream(String doctorId) {
    return _collection().doc(doctorId).snapshots().map((doc) => doc.exists);
  }

  Future<bool> isFavorite(String doctorId) async {
    final doc = await _collection().doc(doctorId).get();
    return doc.exists;
  }

  Future<void> toggleFavorite(String doctorId) async {
    final exists = await isFavorite(doctorId);
    if (exists) {
      await removeFavorite(doctorId);
    } else {
      await addFavorite(doctorId);
    }
  }

  Stream<List<Doctor>> streamFavoriteDoctors() {
    // Listen to favorites list, then map to doctors from main doctors collection
    return _collection().snapshots().asyncMap((favSnap) async {
      if (favSnap.docs.isEmpty) return <Doctor>[];
      final ids = favSnap.docs.map((d) => d.id).toList();
      if (ids.isEmpty) return <Doctor>[];

      final List<Doctor> doctors = [];
      final snap = await _db.collection('doctors').get();
      doctors.addAll(snap.docs.map((doc) {
        final data = doc.data();
        return Doctor.fromJson({'id': doc.id, ...data});
      }));

      return doctors;
    });
  }
}
