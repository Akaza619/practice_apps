import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class GroupController extends GetxController {
  static GroupController instance = Get.put(GroupController());

  RxList<Map<String, dynamic>> users = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> filteredUsers = <Map<String, dynamic>>[].obs;
  RxList<String> selectedMemberIds = <String>[].obs;

  Rx<File?> groupImage = Rx<File?>(null);
  final ImagePicker _picker = ImagePicker();

  @override
  void onInit() {
    super.onInit();
    fetchUsers();
  }

  void fetchUsers() async {
    try {
      String currentUserId = FirebaseAuth.instance.currentUser!.uid;
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('users').get();

      List<Map<String, dynamic>> allUsers =
          snapshot.docs
              .map((doc) => doc.data() as Map<String, dynamic>)
              .where(
                (user) => user['uid'] != currentUserId,
              ) // Exclude current user
              .toList();

      users.value = allUsers;
      filteredUsers.value = allUsers;
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to fetch users: $e",
        backgroundColor: Colors.redAccent.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }

  void searchUsers(String query) {
    if (query.isEmpty) {
      filteredUsers.value = users;
    } else {
      filteredUsers.value =
          users.where((user) {
            String name = (user['displayName'] ?? '').toLowerCase();
            String email = (user['email'] ?? '').toLowerCase();
            return name.contains(query.toLowerCase()) ||
                email.contains(query.toLowerCase());
          }).toList();
    }
  }

  void toggleSelection(String uid) {
    if (selectedMemberIds.contains(uid)) {
      selectedMemberIds.remove(uid);
    } else {
      selectedMemberIds.add(uid);
    }
  }

  Future<void> pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      groupImage.value = File(image.path);
    }
  }

  Future<void> createGroup(String title, String amount, DateTime date) async {
    if (title.isEmpty) {
      Get.snackbar(
        "Error",
        "Group title is required",
        backgroundColor: Colors.redAccent.withOpacity(0.8),
        colorText: Colors.white,
      );
      return;
    }
    if (selectedMemberIds.isEmpty) {
      // Requirement says "at least two members", assuming creator + 1 other
      Get.snackbar(
        "Error",
        "Select at least one member",
        backgroundColor: Colors.redAccent.withOpacity(0.8),
        colorText: Colors.white,
      );
      return;
    }

    try {
      String groupId = FirebaseFirestore.instance.collection('groups').doc().id;
      String? imageUrl;

      if (groupImage.value != null) {
        Reference ref = FirebaseStorage.instance
            .ref()
            .child('group_images')
            .child(groupId);
        UploadTask uploadTask = ref.putFile(groupImage.value!);
        TaskSnapshot snapshot = await uploadTask;
        imageUrl = await snapshot.ref.getDownloadURL();
      }

      User currentUser = FirebaseAuth.instance.currentUser!;
      List<String> members = [currentUser.uid, ...selectedMemberIds];

      await FirebaseFirestore.instance.collection('groups').doc(groupId).set({
        'groupId': groupId,
        'title': title,
        'imageUrl': imageUrl ?? '',
        'totalAmount': amount,
        'date': Timestamp.fromDate(date),
        'createdBy': currentUser.uid,
        'members': members,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Also create a chat document for this group
      await FirebaseFirestore.instance.collection('chats').doc(groupId).set({
        'chatId': groupId,
        'isGroup': true,
        'participants': members,
        'groupName': title,
        'lastMessage': 'Group Created',
        'lastMessageTime': FieldValue.serverTimestamp(),
      });

      Get.snackbar(
        "Success",
        "Group created successfully",
        backgroundColor: Colors.green.shade200,
      );

      // Reset state
      groupImage.value = null;
      selectedMemberIds.clear();
      // Navigate back or to dashboard? For now, maybe stay or clear form.
      // Assuming we stay on screen or go back. Let's clear selection.
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to create group: $e",
        backgroundColor: Colors.redAccent.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }
}
