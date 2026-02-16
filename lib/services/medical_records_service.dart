import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sugenix/services/cloudinary_service.dart';

class MedicalRecordsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Add medical record
  Future<void> addMedicalRecord({
    required String title,
    required String description,
    required String recordType,
    required String recordDate,
    required String addedBy,
    required List<XFile> images,
  }) async {
    try {
      if (_auth.currentUser == null) throw Exception('No user logged in');
      final userId = _auth.currentUser!.uid;

      // Upload images to Cloudinary
      List<String> imageUrls = await CloudinaryService.uploadImages(images);

      // Add record to Firestore
      await _firestore.collection('medical_records').add({
        'title': title,
        'description': description,
        'recordType': recordType,
        'recordDate': recordDate,
        'addedBy': userId,
        'addedByName': addedBy,
        'imageUrls': imageUrls,
        'userId': userId,
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
      });
    } catch (e) {
      throw Exception('Failed to add medical record: $e');
    }
  }

  // Get medical records for current user
  Stream<List<Map<String, dynamic>>> getMedicalRecords() {
    if (_auth.currentUser == null) return Stream.value([]);

    final userId = _auth.currentUser!.uid;
    // Optimized: Filter by userId and isActive
    return _firestore
        .collection('medical_records')
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true) // Filter out deleted records
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
      (snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            ...data,
          };
        }).toList();
      },
    );
  }

  // Get medical record by ID
  Future<Map<String, dynamic>?> getMedicalRecordById(String recordId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('medical_records').doc(recordId).get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      } else {
        return null;
      }
    } catch (e) {
      throw Exception('Failed to get medical record: $e');
    }
  }

  // Update medical record
  Future<void> updateMedicalRecord({
    required String recordId,
    String? title,
    String? description,
    String? recordType,
    String? recordDate,
    List<XFile>? newImages,
  }) async {
    try {
      Map<String, dynamic> updateData = {};

      if (title != null) updateData['title'] = title;
      if (description != null) updateData['description'] = description;
      if (recordType != null) updateData['recordType'] = recordType;
      if (recordDate != null) updateData['recordDate'] = recordDate;

      // Handle new images if provided
      if (newImages != null && newImages.isNotEmpty) {
        List<String> newImageUrls = await CloudinaryService.uploadImages(
          newImages,
        );

        // Get existing images and add new ones
        DocumentSnapshot doc =
            await _firestore.collection('medical_records').doc(recordId).get();
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        List<String> existingImages = List<String>.from(
          data['imageUrls'] ?? [],
        );
        existingImages.addAll(newImageUrls);

        updateData['imageUrls'] = existingImages;
      }

      await _firestore
          .collection('medical_records')
          .doc(recordId)
          .update(updateData);
    } catch (e) {
      throw Exception('Failed to update medical record: ${e.toString()}');
    }
  }

  // Delete medical record (soft delete)
  Future<void> deleteMedicalRecord(String recordId) async {
    try {
      await _firestore.collection('medical_records').doc(recordId).update({
        'isActive': false,
        'deletedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to delete medical record: ${e.toString()}');
    }
  }

  // Get medical record statistics
  Future<Map<String, dynamic>> getMedicalRecordsStatistics() async {
    try {
      if (_auth.currentUser == null) throw Exception('No user logged in');
      final userId = _auth.currentUser!.uid;

      // Optimized: Filter by userId and isActive
      QuerySnapshot snapshot = await _firestore
          .collection('medical_records')
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .get();

      int totalRecords = snapshot.docs.length;
      int reports = 0;
      int prescriptions = 0;
      int invoices = 0;

      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String type =
            (data['recordType'] as String? ?? data['type'] as String? ?? '')
                .toLowerCase();

        switch (type) {
          case 'report':
          case 'lab_report':
            reports++;
            break;
          case 'prescription':
            prescriptions++;
            break;
          case 'invoice':
          case 'bill':
            invoices++;
            break;
        }
      }

      return {
        'totalRecords': totalRecords,
        'reports': reports,
        'prescriptions': prescriptions,
        'invoices': invoices,
      };
    } catch (e) {
      throw Exception(
        'Failed to get medical records statistics: ${e.toString()}',
      );
    }
  }

  // Search medical records
  Future<List<Map<String, dynamic>>> searchMedicalRecords(String query) async {
    try {
      if (_auth.currentUser == null) throw Exception('No user logged in');
      final userId = _auth.currentUser!.uid;

      // Optimized: Filter by userId and isActive
      QuerySnapshot snapshot = await _firestore
          .collection('medical_records')
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .get();

      List<Map<String, dynamic>> results = [];
      String lowerQuery = query.toLowerCase();

      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String title = (data['title'] as String? ?? '').toLowerCase();
        String description =
            (data['description'] as String? ?? '').toLowerCase();
        String type =
            (data['recordType'] as String? ?? data['type'] as String? ?? '')
                .toLowerCase();

        if (title.contains(lowerQuery) ||
            description.contains(lowerQuery) ||
            type.contains(lowerQuery)) {
          results.add({
            'id': doc.id,
            ...data,
          });
        }
      }

      return results;
    } catch (e) {
      throw Exception('Failed to search medical records: ${e.toString()}');
    }
  }

  // Share medical record (generate shareable link)
  Future<String> generateShareableLink(String recordId) async {
    try {
      // In a real implementation, you would create a secure shareable link
      // e.g. using Firebase Dynamic Links or a dedicated collection for shared links
      return 'https://sugenix.app/medical-record/$recordId';
    } catch (e) {
      throw Exception('Failed to generate shareable link: ${e.toString()}');
    }
  }

  // Export medical records (generate PDF or other format)
  Future<List<Map<String, dynamic>>> exportMedicalRecords({
    DateTime? startDate,
    DateTime? endDate,
    String? type,
  }) async {
    try {
      if (_auth.currentUser == null) throw Exception('No user logged in');
      final userId = _auth.currentUser!.uid;

      // Optimized: Filter by userId and isActive
      QuerySnapshot snapshot = await _firestore
          .collection('medical_records')
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .get();

      // Filter by date range and type client-side
      final filteredDocs = snapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;

        if (startDate != null) {
          final createdAt = data['createdAt'];
          if (createdAt != null) {
            final date = createdAt is Timestamp
                ? createdAt.toDate()
                : (createdAt is DateTime ? createdAt : null);
            if (date != null &&
                date.isBefore(startDate.subtract(const Duration(seconds: 1))))
              return false;
          }
        }
        if (endDate != null) {
          final createdAt = data['createdAt'];
          if (createdAt != null) {
            final date = createdAt is Timestamp
                ? createdAt.toDate()
                : (createdAt is DateTime ? createdAt : null);
            if (date != null &&
                date.isAfter(endDate.add(const Duration(days: 1))))
              return false;
          }
        }
        if (type != null && data['recordType'] != type && data['type'] != type)
          return false;
        return true;
      }).toList();

      final results = filteredDocs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();

      // Sort by createdAt descending
      results.sort((a, b) {
        final aTime = a['createdAt'];
        final bTime = b['createdAt'];
        if (aTime == null || bTime == null) return 0;
        final aDate = aTime is Timestamp
            ? aTime.toDate()
            : (aTime is DateTime ? aTime : DateTime.now());
        final bDate = bTime is Timestamp
            ? bTime.toDate()
            : (bTime is DateTime ? bTime : DateTime.now());
        return bDate.compareTo(aDate);
      });

      return results;
    } catch (e) {
      throw Exception('Failed to export medical records: ${e.toString()}');
    }
  }
}
