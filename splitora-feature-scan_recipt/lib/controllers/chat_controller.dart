import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:splitora_app/services/push_sender_service.dart';

class ChatController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String generateChatId(String uid1, String uid2) {
    List<String> uids = [uid1, uid2];
    uids.sort();
    return "${uids[0]}_${uids[1]}";
  }

  Future<String> createOrGetChat(
    String otherUserId,
    String otherUserName,
  ) async {
    String currentUserId = _auth.currentUser!.uid;
    String chatId = generateChatId(currentUserId, otherUserId);

    DocumentReference chatRef = _firestore.collection('chats').doc(chatId);
    DocumentSnapshot chatDoc = await chatRef.get();

    if (!chatDoc.exists) {
      await chatRef.set({
        'chatId': chatId,
        'isGroup': false,
        'participants': [currentUserId, otherUserId],
        'otherUserName': otherUserName, // optional helper
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
      });
    }

    return chatId;
  }

  Future<void> sendMessage(
    String chatId,
    String text, {
    bool isGroup = false,
    String? imageUrl,
  }) async {
    if (text.trim().isEmpty && imageUrl == null) return;

    String currentUserId = _auth.currentUser!.uid;
    DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(currentUserId).get();

    String senderName = 'Unknown';
    if (userDoc.exists) {
      final data = userDoc.data() as Map<String, dynamic>;
      senderName = data['displayName'] ?? data['firstName'] ?? 'Unknown';
    }

    DocumentReference chatRef = _firestore.collection('chats').doc(chatId);

    // Add the message
    await chatRef.collection('messages').add({
      'text': text.trim(),
      'senderId': currentUserId,
      'senderName': senderName,
      'timestamp': FieldValue.serverTimestamp(),
      if (imageUrl != null) 'imageUrl': imageUrl,
    });

    // Update parent chat document
    await chatRef.set({
      'lastMessage': text.trim().isEmpty ? (imageUrl != null ? '📷 Receipt image' : '') : text.trim(),
      'lastMessageTime': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Push a notification to the other participant(s) so they're alerted even
    // when their app is closed. Fire-and-forget — never blocks/throws.
    final notificationBody = text.trim().isNotEmpty
        ? text.trim()
        : (imageUrl != null ? '🧾 Sent a receipt' : 'New message');
    unawaited(
      PushSenderService.instance.sendChatNotification(
        chatId: chatId,
        senderId: currentUserId,
        senderName: senderName,
        body: notificationBody,
      ),
    );
  }

  Stream<QuerySnapshot> getChatsStream() {
    String currentUserId = _auth.currentUser!.uid;
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getMessagesStream(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// Delete a message. [forEveryone] only allowed for the sender.
  Future<void> deleteMessage({
    required String chatId,
    required String messageId,
    required bool forEveryone,
  }) async {
    final currentUserId = _auth.currentUser!.uid;
    final msgRef = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId);

    if (forEveryone) {
      await msgRef.update({
        'text': 'This message was deleted.',
        'deletedForEveryone': true,
        'imageUrl': FieldValue.delete(),
      });
    } else {
      await msgRef.update({
        'deletedFor': FieldValue.arrayUnion([currentUserId]),
      });
    }
  }
}
