import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Generate consistent chat ID from two UIDs
  String getChatId(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  // Find user by email
  Future<Map<String, dynamic>?> findUserByEmail(String email) async {
    final query = await _firestore
        .collection('users')
        .where('email', isEqualTo: email.trim().toLowerCase())
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;
    final doc = query.docs.first;
    return {'uid': doc.id, ...doc.data()};
  }

  //  Create a new chat or get existing chat
  Future<String> getOrCreateChat({
    required String currentUid,
    required String currentName,
    required String otherUid,
    required String otherName,
  }) async {
    final chatId = getChatId(currentUid, otherUid);
    final chatRef = _firestore.collection('chats').doc(chatId);
    final chatDoc = await chatRef.get();

    if (!chatDoc.exists) {
      await chatRef.set({
        'participants': [currentUid, otherUid],
        'participantNames': {
          currentUid: currentName,
          otherUid: otherName,
        },
        'participantEmails': {
          currentUid: '',
          otherUid:   '',
        },
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'deletedFor': [],
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      await chatRef.update({
        'deletedFor': FieldValue.arrayRemove([currentUid]),
      });
    }

    return chatId;
  }

  // Stream chat list for the current user
  Stream<QuerySnapshot> streamChatList(String uid) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: uid)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }

  // Stream messages for a chat
  Stream<QuerySnapshot> streamMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  // Sending a message
  Future<void> sendMessage({
    required String chatId,
    required String text,
  }) async {
    final uid = _auth.currentUser!.uid;
    final chatRef = _firestore.collection('chats').doc(chatId);
    final msgRef = chatRef.collection('messages').doc();

    final batch = _firestore.batch();

    // Add a message
    batch.set(msgRef, {
      'senderUid':  uid,
      'text': text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
      'deletedFor': [],
    });

    // Update chat metadata & restore for both users
    batch.update(chatRef, {
      'lastMessage': text.trim(),
      'lastMessageTime': FieldValue.serverTimestamp(),
      'deletedFor': [],
    });

    await batch.commit();
  }

// Delete a message for BOTH users
Future<void> deleteMessage({
  required String chatId,
  required String messageId,
}) async {
  final msgRef = _firestore
      .collection('chats')
      .doc(chatId)
      .collection('messages')
      .doc(messageId);

  // Hard delete — removes for both users
  await msgRef.delete();

  // Update lastMessage preview if this was the last message
  final remaining = await _firestore
      .collection('chats')
      .doc(chatId)
      .collection('messages')
      .orderBy('timestamp', descending: true)
      .limit(1)
      .get();

  final chatRef = _firestore.collection('chats').doc(chatId);
  if (remaining.docs.isEmpty) {
    await chatRef.update({
      'lastMessage': '',
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
  } else {
    final lastData = remaining.docs.first.data();
    await chatRef.update({
      'lastMessage': lastData['text'] ?? '',
      'lastMessageTime': lastData['timestamp'],
    });
  }
}

  // Delete the entire chat for current user
  Future<void> deleteChat(String chatId) async {
    final uid = _auth.currentUser!.uid;
    await _firestore.collection('chats').doc(chatId).update({
      'deletedFor': FieldValue.arrayUnion([uid]),
    });
  }
}