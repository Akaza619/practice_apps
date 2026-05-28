import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:splitora_app/controllers/chat_controller.dart';

class BillController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Participant selection state
  RxList<Map<String, dynamic>> allUsers = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> filteredUsers = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> allGroups = <Map<String, dynamic>>[].obs;
  RxList<String> selectedUserIds = <String>[].obs;
  RxString selectedGroupId = ''.obs;
  RxString selectedGroupName = ''.obs;
  RxBool isGroupMode = false.obs;
  RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchUsers();
    fetchGroups();
  }

  void fetchUsers() async {
    try {
      final currentUserId = _auth.currentUser!.uid;
      final snapshot = await _firestore.collection('users').get();
      final list = snapshot.docs
          .map((d) => d.data())
          .where((u) => u['uid'] != currentUserId)
          .toList();
      allUsers.value = list;
      filteredUsers.value = list;
    } catch (_) {}
  }

  void fetchGroups() async {
    try {
      final currentUserId = _auth.currentUser!.uid;
      final snapshot = await _firestore
          .collection('chats')
          .where('isGroup', isEqualTo: true)
          .where('participants', arrayContains: currentUserId)
          .get();
      allGroups.value = snapshot.docs.map((d) => d.data()).toList();
    } catch (_) {}
  }

  void searchUsers(String query) {
    if (query.isEmpty) {
      filteredUsers.value = allUsers;
    } else {
      filteredUsers.value = allUsers.where((u) {
        final name =
            (u['displayName'] ?? u['firstName'] ?? '').toLowerCase();
        final email = (u['email'] ?? '').toLowerCase();
        return name.contains(query.toLowerCase()) ||
            email.contains(query.toLowerCase());
      }).toList();
    }
  }

  void toggleUser(String uid) {
    if (selectedUserIds.contains(uid)) {
      selectedUserIds.remove(uid);
    } else {
      selectedUserIds.add(uid);
    }
  }

  void selectGroup(String groupId, String groupName) {
    selectedGroupId.value = groupId;
    selectedGroupName.value = groupName;
  }

  void setGroupMode(bool val) {
    isGroupMode.value = val;
    if (!val) filteredUsers.value = allUsers;
  }

  void reset() {
    selectedUserIds.clear();
    selectedGroupId.value = '';
    selectedGroupName.value = '';
    isGroupMode.value = false;
    filteredUsers.value = allUsers;
    fetchGroups();
  }

  Future<bool> createBill({
    required String tripName,
    required double amount,
    required DateTime date,
    String note = '',
    String? receiptImageUrl,
    List<Map<String, dynamic>>? manualItems,
    Map<String, dynamic>? receiptScanData,
  }) async {
    if (tripName.isEmpty) {
      _error("Trip name is required");
      return false;
    }
    if (amount <= 0) {
      _error("Please enter a valid amount");
      return false;
    }
    if (isGroupMode.value && selectedGroupId.value.isEmpty) {
      _error("Please select a group");
      return false;
    }
    if (!isGroupMode.value && selectedUserIds.isEmpty) {
      _error("Please select at least one participant");
      return false;
    }

    isLoading.value = true;
    try {
      final currentUserId = _auth.currentUser!.uid;
      final meDoc =
          await _firestore.collection('users').doc(currentUserId).get();
      final meData = meDoc.data() as Map<String, dynamic>;
      final creatorName =
          meData['displayName'] ?? meData['firstName'] ?? 'Unknown';

      List<String> participantIds;
      Map<String, dynamic> participantNames = {};
      String? groupId;
      String? groupName;

      if (isGroupMode.value) {
        final chatDoc = await _firestore
            .collection('chats')
            .doc(selectedGroupId.value)
            .get();
        final chatData = chatDoc.data() as Map<String, dynamic>;
        participantIds =
            List<String>.from(chatData['participants'] ?? [currentUserId]);
        groupId = selectedGroupId.value;
        groupName = selectedGroupName.value;

        for (final uid in participantIds) {
          final pDoc =
              await _firestore.collection('users').doc(uid).get();
          if (pDoc.exists) {
            final pData = pDoc.data() as Map<String, dynamic>;
            participantNames[uid] =
                pData['displayName'] ?? pData['firstName'] ?? 'Unknown';
          }
        }
      } else {
        participantIds = [currentUserId, ...selectedUserIds];
        participantNames[currentUserId] = creatorName;
        for (final uid in selectedUserIds) {
          final match =
              allUsers.firstWhereOrNull((u) => u['uid'] == uid);
          if (match != null) {
            participantNames[uid] =
                match['displayName'] ?? match['firstName'] ?? 'Unknown';
          }
        }
      }

      final double perPerson = amount / participantIds.length;
      final String billId =
          _firestore.collection('bills').doc().id;

      await _firestore.collection('bills').doc(billId).set({
        'billId': billId,
        'tripName': tripName,
        'totalAmount': amount,
        'date': Timestamp.fromDate(date),
        'createdBy': currentUserId,
        'createdByName': creatorName,
        'participants': participantIds,
        'participantNames': participantNames,
        'groupId': groupId,
        'groupName': groupName,
        'perPersonAmount': perPerson,
        'settled': false,
        'note': note,
        'createdAt': FieldValue.serverTimestamp(),
        if (receiptImageUrl != null) 'receiptImageUrl': receiptImageUrl,
        if (manualItems != null) 'manualItems': manualItems,
        if (receiptScanData != null) 'receiptScanData': receiptScanData,
      });

      await _notifyChats(
        tripName: tripName,
        amount: amount,
        perPerson: perPerson,
        date: date,
        creatorId: currentUserId,
        creatorName: creatorName,
        participantIds: participantIds,
        isGroupBill: isGroupMode.value,
        groupId: groupId,
        receiptImageUrl: receiptImageUrl,
      );

      reset();
      return true;
    } catch (e) {
      _error("Failed to create bill: $e");
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _notifyChats({
    required String tripName,
    required double amount,
    required double perPerson,
    required DateTime date,
    required String creatorId,
    required String creatorName,
    required List<String> participantIds,
    required bool isGroupBill,
    String? groupId,
    String? receiptImageUrl,
  }) async {
    final chatController = Get.put(ChatController());
    final dateStr =
        "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
    final String msg;
    if (receiptImageUrl != null) {
      msg = "🧾 Scanned Receipt: $tripName\n"
          "Total: ₹${amount.toStringAsFixed(2)}  •  Per person: ₹${perPerson.toStringAsFixed(2)}\n"
          "Date: $dateStr  •  Paid by: $creatorName\n"
          "📄 This bill was generated from a scanned receipt.";
    } else {
      msg = "💰 Trip Bill: $tripName\n"
          "Total: ₹${amount.toStringAsFixed(2)}  •  Per person: ₹${perPerson.toStringAsFixed(2)}\n"
          "Date: $dateStr  •  Paid by: $creatorName";
    }

    if (isGroupBill && groupId != null) {
      await chatController.sendMessage(groupId, msg, isGroup: true, imageUrl: receiptImageUrl);
    } else {
      for (final uid in participantIds) {
        if (uid == creatorId) continue;
        final match =
            allUsers.firstWhereOrNull((u) => u['uid'] == uid);
        final name = match != null
            ? (match['displayName'] ?? match['firstName'] ?? 'User')
            : 'User';
        final chatId =
            await chatController.createOrGetChat(uid, name);
        await chatController.sendMessage(chatId, msg, isGroup: false, imageUrl: receiptImageUrl);
      }
    }
  }

  Future<void> settleBill(String billId) async {
    try {
      await _firestore
          .collection('bills')
          .doc(billId)
          .update({'settled': true});
      Get.snackbar("Done", "Bill marked as settled.",
          backgroundColor: Colors.green.shade300, colorText: Colors.black87);
    } catch (e) {
      _error("Could not settle bill: $e");
    }
  }

  /// Called after Razorpay payment success. Marks user as paid,
  /// settles bill if everyone has paid, and sends a chat notification.
  Future<void> recordPayment(String billId) async {
    try {
      final uid = _auth.currentUser!.uid;

      // Fetch current user's name
      final meDoc = await _firestore.collection('users').doc(uid).get();
      final meData = meDoc.data() as Map<String, dynamic>;
      final myName = meData['displayName'] ?? meData['firstName'] ?? 'Someone';

      // Mark this user as paid
      await _firestore.collection('bills').doc(billId).update({
        'settledBy': FieldValue.arrayUnion([uid]),
      });

      // Re-fetch to check if all non-creators have now paid
      final billDoc =
          await _firestore.collection('bills').doc(billId).get();
      final data = billDoc.data() as Map<String, dynamic>;

      final participants = List<String>.from(data['participants'] ?? []);
      final createdBy = data['createdBy'] as String;
      final settledBy = List<String>.from(data['settledBy'] ?? []);
      final perPerson = (data['perPersonAmount'] as num).toDouble();
      final tripName = data['tripName'] as String? ?? '';
      final groupId = data['groupId'] as String?;

      final allPaid = participants
          .where((p) => p != createdBy)
          .every((p) => settledBy.contains(p));

      if (allPaid) {
        await _firestore
            .collection('bills')
            .doc(billId)
            .update({'settled': true});
      }

      // Notify via chat
      final chatController = Get.put(ChatController());
      final msg =
          "✅ $myName paid ₹${perPerson.toStringAsFixed(2)} for \"$tripName\"";

      if (groupId != null && groupId.isNotEmpty) {
        await chatController.sendMessage(groupId, msg, isGroup: true);
      } else {
        // 1-on-1 with the bill creator
        final creatorDoc =
            await _firestore.collection('users').doc(createdBy).get();
        final creatorData = creatorDoc.data() as Map<String, dynamic>;
        final creatorName =
            creatorData['displayName'] ?? creatorData['firstName'] ?? 'User';
        final chatId =
            await chatController.createOrGetChat(createdBy, creatorName);
        await chatController.sendMessage(chatId, msg, isGroup: false);
      }

      Get.snackbar(
        "Payment Successful",
        "₹${perPerson.toStringAsFixed(2)} paid for $tripName",
        backgroundColor: Colors.green.shade400,
        colorText: Colors.white,
        icon: const Icon(Icons.check_circle, color: Colors.white),
      );
    } catch (e) {
      _error("Payment recording failed: $e");
    }
  }

  /// Returns all bills involving the current user (unsorted — sort client-side).
  Stream<QuerySnapshot> getBillsStream() {
    final uid = _auth.currentUser!.uid;
    return _firestore
        .collection('bills')
        .where('participants', arrayContains: uid)
        .snapshots();
  }

  void _error(String msg) {
    Get.snackbar(
      "Error",
      msg,
      backgroundColor: Colors.redAccent.withOpacity(0.8),
      colorText: Colors.white,
    );
  }
}
