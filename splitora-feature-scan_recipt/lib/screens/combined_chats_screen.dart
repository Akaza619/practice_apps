import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:splitora_app/controllers/chat_controller.dart';
import 'package:splitora_app/screens/chat_detail_screen.dart';
import 'package:splitora_app/screens/groups_screen.dart';
import 'package:splitora_app/screens/select_friend_screen.dart';
import 'package:splitora_app/theme/app_theme.dart';

class CombinedChatsScreen extends StatefulWidget {
  const CombinedChatsScreen({super.key});

  @override
  State<CombinedChatsScreen> createState() => _CombinedChatsScreenState();
}

class _CombinedChatsScreenState extends State<CombinedChatsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ChatController chatController = Get.put(ChatController());

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: "Chats"),
            Tab(text: "Groups"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDirectChatsTab(),
          _buildGroupsTab(),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton(
              onPressed: () => Get.to(() => const SelectFriendScreen()),
              backgroundColor: AppTheme.fabBackground,
              child: const Icon(Icons.chat, color: AppTheme.fabIconColor),
            )
          : FloatingActionButton(
              onPressed: () => Get.to(() => const GroupsScreen()),
              backgroundColor: AppTheme.fabBackground,
              child: const Icon(Icons.group_add, color: AppTheme.fabIconColor),
            ),
    );
  }

  Widget _buildDirectChatsTab() {
    return Container(
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

          final chats = (snapshot.data?.docs ?? []).where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return !(data['isGroup'] ?? false);
          }).toList();

          if (chats.isEmpty) {
            return const Center(
              child: Text(
                "No chats yet.\nTap + to start a conversation.",
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 16),
              ),
            );
          }

          final String currentUserId =
              FirebaseAuth.instance.currentUser!.uid;

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chatData =
                  chats[index].data() as Map<String, dynamic>;
              final String chatId = chatData['chatId'] ?? '';
              final String lastMessage = chatData['lastMessage'] ?? '';
              final List<dynamic> participants =
                  chatData['participants'] ?? [];

              final String otherUid = participants.firstWhere(
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
                    final uData =
                        userSnap.data!.data() as Map<String, dynamic>;
                    chatName = uData['displayName'] ??
                        uData['firstName'] ??
                        'User';
                  }
                  return _buildChatTile(
                    chatName,
                    lastMessage,
                    false,
                    chatId,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildGroupsTab() {
    return Container(
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
                "Error loading groups.",
                style: TextStyle(color: AppTheme.textPrimary),
              ),
            );
          }

          final groups = (snapshot.data?.docs ?? []).where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['isGroup'] ?? false;
          }).toList();

          if (groups.isEmpty) {
            return const Center(
              child: Text(
                "No groups yet.\nTap + to create one.",
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final chatData =
                  groups[index].data() as Map<String, dynamic>;
              final String chatId = chatData['chatId'] ?? '';
              final String lastMessage = chatData['lastMessage'] ?? '';
              final String groupName =
                  chatData['groupName'] ?? 'Group Chat';
              final String? imageUrl = chatData['imageUrl'] as String?;

              return _buildGroupTile(
                groupName,
                lastMessage,
                chatId,
                imageUrl,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildGroupTile(
    String name,
    String lastMessage,
    String chatId,
    String? imageUrl,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: AppTheme.listTileDecoration,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.avatarBackground,
          backgroundImage:
              (imageUrl != null && imageUrl.isNotEmpty)
                  ? NetworkImage(imageUrl)
                  : null,
          child: (imageUrl == null || imageUrl.isEmpty)
              ? const Icon(Icons.group, color: AppTheme.textPrimary)
              : null,
        ),
        title: Text(
          name,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          lastMessage.isEmpty ? "No messages yet" : lastMessage,
          style: const TextStyle(color: AppTheme.textSecondary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        onTap: () {
          Get.to(
            () => ChatDetailScreen(
              chatId: chatId,
              isGroup: true,
              chatName: name,
            ),
          );
        },
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
