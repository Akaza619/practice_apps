import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:splitora_app/controllers/chat_controller.dart';
import 'package:splitora_app/screens/chat_detail_screen.dart';
import 'package:splitora_app/screens/select_friend_screen.dart';
import 'package:splitora_app/theme/app_theme.dart';

class ChatsScreen extends StatelessWidget {
  ChatsScreen({super.key});

  final ChatController chatController = Get.put(ChatController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Chats",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.appBarColor,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Container(
        decoration: AppTheme.backgroundDecoration,
        child: StreamBuilder<QuerySnapshot>(
          stream: chatController.getChatsStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppTheme.textPrimary),
              );
            }
            if (snapshot.hasError) {
              return const Center(
                child: Text(
                  "Error loading chats.",
                  style: TextStyle(color: AppTheme.textPrimary),
                ),
              );
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text(
                  "No chats yet.",
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 18),
                ),
              );
            }

            var chats = snapshot.data!.docs;
            String currentUserId = FirebaseAuth.instance.currentUser!.uid;

            return ListView.builder(
              itemCount: chats.length,
              itemBuilder: (context, index) {
                var chatData = chats[index].data() as Map<String, dynamic>;
                String chatId = chatData['chatId'] ?? '';
                bool isGroup = chatData['isGroup'] ?? false;
                String lastMessage = chatData['lastMessage'] ?? '';
                List<dynamic> participants = chatData['participants'] ?? [];

                if (isGroup) {
                  return _buildChatTile(
                    chatData['groupName'] ?? "Group Chat",
                    lastMessage,
                    isGroup,
                    chatId,
                  );
                } else {
                  String otherUid = participants.firstWhere(
                    (id) => id != currentUserId,
                    orElse: () => '',
                  );
                  if (otherUid.isEmpty) return const SizedBox();

                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(otherUid)
                        .get(),
                    builder: (context, userSnap) {
                      String chatName = "User";
                      if (userSnap.hasData && userSnap.data!.exists) {
                        var uData =
                            userSnap.data!.data() as Map<String, dynamic>;
                        chatName =
                            uData['displayName'] ?? uData['firstName'] ?? 'User';
                      }
                      return _buildChatTile(
                        chatName,
                        lastMessage,
                        isGroup,
                        chatId,
                      );
                    },
                  );
                }
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Get.to(() => const SelectFriendScreen());
        },
        backgroundColor: AppTheme.fabBackground,
        child: const Icon(Icons.chat, color: AppTheme.fabIconColor),
      ),
    );
  }

  Widget _buildChatTile(
    String title,
    String subtitle,
    bool isGroup,
    String chatId,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: AppTheme.listTileDecoration,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.avatarBackground,
          child: Icon(
            isGroup ? Icons.group : Icons.person,
            color: AppTheme.textPrimary,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          subtitle.isEmpty ? "No messages yet" : subtitle,
          style: const TextStyle(color: AppTheme.textSecondary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        onTap: () {
          Get.to(
            () => ChatDetailScreen(
              chatId: chatId,
              isGroup: isGroup,
              chatName: title,
            ),
          );
        },
      ),
    );
  }
}
