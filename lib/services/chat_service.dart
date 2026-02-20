import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Check if a valid appointment exists between patient and doctor
  Future<bool> canStartChat(String doctorId, String patientId) async {
    try {
      // Check for 'scheduled', 'confirmed' or 'completed' appointments
      // We might want to restrict 'completed' to a certain timeframe, but for now simple check
      final snapshot = await _firestore
          .collection('appointments')
          .where('doctorId', isEqualTo: doctorId)
          .where('patientId', isEqualTo: patientId)
          .where('status', whereIn: ['scheduled', 'confirmed', 'completed'])
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking appointment status: $e');
      return false;
    }
  }

  // Get or Create a Chat ID based on participants
  String getChatId(String userId1, String userId2) {
    List<String> ids = [userId1, userId2];
    ids.sort(); // Sort to ensure consistency
    return ids.join('_');
  }

  // Send a message
  Future<void> sendMessage({
    required String doctorId,
    required String patientId,
    required String text,
    required String senderName,
  }) async {
    if (_auth.currentUser == null) return;

    final currentUserId = _auth.currentUser!.uid;
    final chatId = getChatId(patientId, doctorId);

    // 1. Create/Update Chat Room Metadata
    final chatDocRef = _firestore.collection('chats').doc(chatId);

    await chatDocRef.set({
      'doctorId': doctorId,
      'patientId': patientId,
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastSenderId': currentUserId,
      'participants': [doctorId, patientId],
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // 2. Add Message to Subcollection
    await chatDocRef.collection('messages').add({
      'senderId': currentUserId,
      'senderName': senderName,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
      'type': 'text',
    });
  }

  // Get Messages Stream
  Stream<QuerySnapshot> getMessages(String doctorId, String patientId) {
    final chatId = getChatId(patientId, doctorId);
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')

        .snapshots();
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String doctorId, String patientId) async {
    if (_auth.currentUser == null) return;

    final chatId = getChatId(patientId, doctorId);
    final currentUserId = _auth.currentUser!.uid;

    final unreadMessages = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('read', isEqualTo: false)
        .where('senderId', isNotEqualTo: currentUserId)
        .get();

    for (var doc in unreadMessages.docs) {
      await doc.reference.update({'read': true});
    }
  }

  // Get list of active chats for a user
  Stream<List<Map<String, dynamic>>> getRecentChats() {
    if (_auth.currentUser == null) return Stream.value([]);

    final userId = _auth.currentUser!.uid;

    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }
}
