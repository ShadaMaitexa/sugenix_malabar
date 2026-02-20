import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sugenix/services/chat_service.dart';
import 'package:sugenix/screens/chat_screen.dart';
import 'package:intl/intl.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatService _chatService = ChatService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Messages',
          style: TextStyle(
            color: Color(0xFF0C4556),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _chatService.getRecentChats(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final chats = snapshot.data ?? [];

          if (chats.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_outlined, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text(
                    'No conversations yet',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: chats.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final chat = chats[index];
              final currentUserId = _auth.currentUser?.uid;

              // Identify the other participant
              final participants =
                  List<String>.from(chat['participants'] ?? []);
              final otherParticipantId = participants.firstWhere(
                (id) => id != currentUserId,
                orElse: () => '',
              );

              return FutureBuilder<DocumentSnapshot>(
                future: _firestore
                    .collection('users')
                    .doc(otherParticipantId)
                    .get(),
                builder: (context, userSnapshot) {
                  final userData =
                      userSnapshot.data?.data() as Map<String, dynamic>?;
                  final otherName = userData?['name'] ?? 'User';
                  final lastMessage = chat['lastMessage'] ?? '';
                  final timestamp = chat['updatedAt'] as Timestamp?;

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF0C4556).withOpacity(0.1),
                      child: const Icon(Icons.person, color: Color(0xFF0C4556)),
                    ),
                    title: Text(
                      otherName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0C4556),
                      ),
                    ),
                    subtitle: Text(
                      lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    trailing: timestamp != null
                        ? Text(
                            DateFormat('hh:mm a').format(timestamp.toDate()),
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12),
                          )
                        : null,
                    onTap: () {
                      final isDoctor = userData?['role'] == 'doctor';
                      final doctorId =
                          isDoctor ? otherParticipantId : currentUserId!;
                      final patientId =
                          isDoctor ? currentUserId! : otherParticipantId;

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            doctorId: doctorId,
                            doctorName: isDoctor
                                ? otherName
                                : (userData?['name'] ?? 'Doctor'),
                            patientId: patientId,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
