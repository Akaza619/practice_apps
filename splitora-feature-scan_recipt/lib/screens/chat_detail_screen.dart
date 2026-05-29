import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:splitora_app/controllers/chat_controller.dart';
import 'package:splitora_app/theme/app_theme.dart';

class ChatDetailScreen extends StatefulWidget {
  final String chatId;
  final bool isGroup;
  final String chatName;

  const ChatDetailScreen({
    super.key,
    required this.chatId,
    required this.isGroup,
    required this.chatName,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final ChatController chatController = Get.put(ChatController());
  final TextEditingController msgController = TextEditingController();
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  void sendMessage() {
    String text = msgController.text.trim();
    if (text.isNotEmpty) {
      chatController.sendMessage(widget.chatId, text, isGroup: widget.isGroup);
      msgController.clear();
    }
  }

  void _showDeleteOptions(
    BuildContext context, {
    required String chatId,
    required String messageId,
    required bool isSender,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded,
                    color: Colors.white70),
                title: const Text(
                  'Delete for Me',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  chatController.deleteMessage(
                    chatId: chatId,
                    messageId: messageId,
                    forEveryone: false,
                  );
                },
              ),
              if (isSender)
                ListTile(
                  leading: const Icon(Icons.delete_forever_rounded,
                      color: Colors.redAccent),
                  title: const Text(
                    'Delete for Everyone',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    chatController.deleteMessage(
                      chatId: chatId,
                      messageId: messageId,
                      forEveryone: true,
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chatName),
        backgroundColor: AppTheme.appBarColor,
        elevation: 0,
      ),
      body: Container(
        decoration: AppTheme.backgroundDecoration,
        child: SafeArea(
          child: Column(
            children: [
              // Messages List
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: chatController.getMessagesStream(widget.chatId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.textPrimary,
                        ),
                      );
                    }
                    if (snapshot.hasError) {
                      return const Center(
                        child: Text(
                          "Error loading messages.",
                          style: TextStyle(color: AppTheme.textPrimary),
                        ),
                      );
                    }

                    var messages = snapshot.data?.docs ?? [];

                    return ListView.builder(
                      reverse: true,
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msgDoc = messages[index];
                        var msgData =
                            msgDoc.data() as Map<String, dynamic>;
                        final bool isMe = msgData['senderId'] == currentUserId;

                        // ── "Delete for Me" check ──────────────────────────
                        final deletedFor =
                            List<String>.from(msgData['deletedFor'] ?? []);
                        if (deletedFor.contains(currentUserId)) {
                          return const SizedBox.shrink();
                        }

                        final bool deletedForEveryone =
                            msgData['deletedForEveryone'] == true;

                        Timestamp? t = msgData['timestamp'] as Timestamp?;
                        String timeStr =
                            t != null
                                ? DateFormat('hh:mm a').format(t.toDate())
                                : '';

                        final String messageId = msgDoc.id;

                        return GestureDetector(
                          onLongPress: () => _showDeleteOptions(
                            context,
                            chatId: widget.chatId,
                            messageId: messageId,
                            isSender: isMe,
                          ),
                          child: Align(
                            alignment:
                                isMe
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: deletedForEveryone
                                    ? Colors.white10
                                    : isMe
                                        ? AppTheme.sentMessageBg
                                        : AppTheme.receivedMessageBg,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(15),
                                  topRight: const Radius.circular(15),
                                  bottomLeft: Radius.circular(isMe ? 15 : 0),
                                  bottomRight: Radius.circular(isMe ? 0 : 15),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    isMe
                                        ? CrossAxisAlignment.end
                                        : CrossAxisAlignment.start,
                                children: [
                                  if (!isMe && widget.isGroup)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 4.0),
                                      child: Text(
                                        msgData['senderName'] ?? 'Unknown',
                                        style: TextStyle(
                                          color:
                                              isMe
                                                  ? AppTheme.sentMessageMeta
                                                  : AppTheme.textSecondary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  if (deletedForEveryone)
                                    const Text(
                                      'This message was deleted.',
                                      style: TextStyle(
                                        color: Colors.white38,
                                        fontSize: 14,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    )
                                  else ...[
                                    if (msgData['text'] != null &&
                                        (msgData['text'] as String).isNotEmpty)
                                      Text(
                                        msgData['text'] ?? '',
                                        style: TextStyle(
                                          color:
                                              isMe
                                                  ? AppTheme.sentMessageText
                                                  : AppTheme.receivedMessageText,
                                          fontSize: 16,
                                        ),
                                      ),
                                    if (msgData['imageUrl'] != null &&
                                        (msgData['imageUrl'] as String)
                                            .isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          msgData['imageUrl'],
                                          width: 200,
                                          height: 200,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (_, _, _) => const Icon(
                                                Icons.broken_image,
                                                color: Colors.white54,
                                                size: 48,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ],
                                  const SizedBox(height: 4),
                                  Text(
                                    timeStr,
                                    style: TextStyle(
                                      color:
                                          isMe
                                              ? AppTheme.sentMessageMeta
                                              : AppTheme.receivedMessageMeta,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              // Input Field
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                color: AppTheme.cardBackground,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: msgController,
                        style: const TextStyle(color: AppTheme.textPrimary),
                        decoration: InputDecoration(
                          hintText: "Type a message...",
                          hintStyle: const TextStyle(
                            color: AppTheme.textTertiary,
                          ),
                          filled: true,
                          fillColor: AppTheme.inputFillDense,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: sendMessage,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: AppTheme.fabBackground,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.send,
                          color: AppTheme.fabIconColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
