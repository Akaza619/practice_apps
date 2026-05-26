import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:splitora_app/controllers/chat_controller.dart';
import 'package:splitora_app/screens/chat_detail_screen.dart';
import 'package:splitora_app/theme/app_theme.dart';

class SelectFriendScreen extends StatefulWidget {
  const SelectFriendScreen({super.key});

  @override
  State<SelectFriendScreen> createState() => _SelectFriendScreenState();
}

class _SelectFriendScreenState extends State<SelectFriendScreen> {
  final ChatController chatController = Get.put(ChatController());
  final User? user = FirebaseAuth.instance.currentUser;
  final TextEditingController searchController = TextEditingController();
  String searchQuery = "";

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Friend"),
        backgroundColor: AppTheme.appBarColor,
        elevation: 0,
      ),
      body: Container(
        decoration: AppTheme.backgroundDecoration,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(15),
              child: TextField(
                controller: searchController,
                onChanged: (val) {
                  setState(() {
                    searchQuery = val;
                  });
                },
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: "Search friends...",
                  hintStyle: const TextStyle(color: AppTheme.textTertiary),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppTheme.iconColor,
                  ),
                  filled: true,
                  fillColor: AppTheme.inputFill,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance.collection('users').snapshots(),
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
                        "Error loading friends.",
                        style: TextStyle(color: AppTheme.textPrimary),
                      ),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        "No users found",
                        style: TextStyle(color: AppTheme.textPrimary),
                      ),
                    );
                  }

                  var users =
                      snapshot.data!.docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        if (data['uid'] == user?.uid) return false;
                        if (searchQuery.isNotEmpty) {
                          String name =
                              (data['displayName'] ?? data['firstName'] ?? '')
                                  .toLowerCase();
                          String email = (data['email'] ?? '').toLowerCase();
                          if (!name.contains(searchQuery.toLowerCase()) &&
                              !email.contains(searchQuery.toLowerCase())) {
                            return false;
                          }
                        }
                        return true;
                      }).toList();

                  if (users.isEmpty) {
                    return const Center(
                      child: Text(
                        "No friends found matching search",
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      var userData =
                          users[index].data() as Map<String, dynamic>;
                      String displayName =
                          userData['displayName'] ??
                          userData['firstName'] ??
                          'Unknown';
                      return Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: AppTheme.listTileDecoration,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.avatarBackground,
                            child: Text(
                              displayName.isNotEmpty
                                  ? displayName[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          title: Text(
                            displayName,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            userData['email'] ?? '',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          onTap: () async {
                            String chatId = await chatController
                                .createOrGetChat(userData['uid'], displayName);
                            Get.off(
                              () => ChatDetailScreen(
                                chatId: chatId,
                                isGroup: false,
                                chatName: displayName,
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
