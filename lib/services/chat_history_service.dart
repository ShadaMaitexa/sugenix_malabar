import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatHistoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Save chat message
  Future<void> saveMessage({
    required String text,
    required bool isUser,
  }) async {
    try {
      if (_auth.currentUser == null) throw Exception('No user logged in');

      await _firestore.collection('chat_history').add({
        'userId': _auth.currentUser!.uid,
        'text': text,
        'isUser': isUser,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to save message: ${e.toString()}');
    }
  }

  // Get chat history
  Stream<List<Map<String, dynamic>>> getChatHistory({int limit = 50}) {
    if (_auth.currentUser == null) return Stream.value([]);

    final userId = _auth.currentUser!.uid;
    return _firestore
        .collection('chat_history')
        .snapshots()
        .map((snapshot) {
      final allMessages = snapshot.docs.map((doc) {
        final data = doc.data();
        final timestamp = data['timestamp'];
        return {
          'id': doc.id,
          ...data,
          'timestamp': timestamp is Timestamp 
              ? timestamp.toDate() 
              : (timestamp is DateTime ? timestamp : DateTime.now()),
        };
      }).toList();
      
      // Filter by userId and sort by timestamp
      final filtered = allMessages.where((m) => m['userId'] == userId).toList();
      filtered.sort((a, b) {
        final aTime = a['timestamp'] as DateTime;
        final bTime = b['timestamp'] as DateTime;
        return aTime.compareTo(bTime); // Ascending (oldest first)
      });
      
      return filtered.take(limit).toList();
    });
  }

  // Clear chat history
  Future<void> clearChatHistory() async {
    try {
      if (_auth.currentUser == null) throw Exception('No user logged in');

      QuerySnapshot snapshot = await _firestore
          .collection('chat_history')
          .get();
      final userId = _auth.currentUser!.uid;

      // Filter by userId
      final filteredDocs = snapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return data['userId'] == userId;
      }).toList();

      WriteBatch batch = _firestore.batch();
      for (var doc in filteredDocs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to clear chat history: ${e.toString()}');
    }
  }
}

