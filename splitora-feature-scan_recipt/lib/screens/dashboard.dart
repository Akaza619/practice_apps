import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:splitora_app/controllers/bill_controller.dart';
import 'package:splitora_app/theme/app_theme.dart';
import 'package:splitora_app/widgets/bill_detail_dialog.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  bool showAllBills = false;
  final User? user = FirebaseAuth.instance.currentUser;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: AppTheme.backgroundDecoration,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Greeting Section
                FutureBuilder<DocumentSnapshot>(
                  future:
                      FirebaseFirestore.instance
                          .collection('users')
                          .doc(user?.uid)
                          .get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Text(
                        "Hi...",
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }
                    if (snapshot.hasData && snapshot.data!.exists) {
                      var userData =
                          snapshot.data!.data() as Map<String, dynamic>;
                      String firstName = userData['firstName'] ?? 'User';
                      return Text(
                        "Hi, $firstName",
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }
                    return const Text(
                      "Hi, User",
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 30),

                // Pending Bills Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Pending Bills",
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          showAllBills = !showAllBills;
                        });
                      },
                      child: Text(
                        showAllBills ? "View Less" : "View More",
                        style: const TextStyle(color: AppTheme.textSecondary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildPendingBillsList(),

                const SizedBox(height: 30),

                // History Bills Section
                const Text(
                  "History",
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                _buildHistoryBills(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPendingBillsList() {
    final billController = Get.put(BillController());
    final String currentUserId = user?.uid ?? '';

    return StreamBuilder<QuerySnapshot>(
      stream: billController.getBillsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppTheme.textPrimary,
            ),
          );
        }

        // Only show bills that are unsettled AND the current user hasn't paid yet
        final pending = (snapshot.data?.docs ?? []).where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['settled'] == true) return false;
          final bool iCreated = data['createdBy'] == currentUserId;
          if (iCreated) return true; // creator waits until everyone pays
          final settledBy = List<String>.from(data['settledBy'] ?? []);
          return !settledBy.contains(currentUserId);
        }).toList();

        if (pending.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: AppTheme.listTileDecoration,
            child: const Text(
              "No pending bills 🎉  You're all settled up!",
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          );
        }

        final int itemCount =
            showAllBills ? pending.length : min(2, pending.length);

        return Column(
          children: List.generate(itemCount, (index) {
            final data =
                pending[index].data() as Map<String, dynamic>;
            final bool iCreated = data['createdBy'] == currentUserId;
            final double total =
                (data['totalAmount'] as num).toDouble();
            final double perPerson =
                (data['perPersonAmount'] as num).toDouble();
            final int memberCount =
                (data['participants'] as List?)?.length ?? 1;
            final String tripName = data['tripName'] ?? '';

            final docData =
                pending[index].data() as Map<String, dynamic>;
            return GestureDetector(
              onTap: () => showBillDetail(context, docData),
              child: Container(
              margin: const EdgeInsets.only(bottom: 15),
              padding: const EdgeInsets.all(15),
              decoration: AppTheme.listTileDecoration,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tripName,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "$memberCount members",
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "₹${iCreated ? total.toStringAsFixed(2) : perPerson.toStringAsFixed(2)}",
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        iCreated ? "Owes you" : "You owe",
                        style: TextStyle(
                          color: iCreated
                              ? AppTheme.owedColor
                              : AppTheme.owesColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            );
          }),
        );
      },
    );
  }

  Widget _buildHistoryBills() {
    final billController = Get.put(BillController());
    final String currentUserId = user?.uid ?? '';

    return StreamBuilder<QuerySnapshot>(
      stream: billController.getBillsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.textPrimary),
          );
        }

        final settled = (snapshot.data?.docs ?? []).where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['settled'] == true;
        }).toList()
          ..sort((a, b) {
            final at = (a.data() as Map)['createdAt'] as Timestamp?;
            final bt = (b.data() as Map)['createdAt'] as Timestamp?;
            if (at == null || bt == null) return 0;
            return bt.compareTo(at);
          });

        if (settled.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: AppTheme.listTileDecoration,
            child: const Text(
              "No history yet. Settled bills will appear here.",
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          );
        }

        return Column(
          children: settled.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final bool iCreated = data['createdBy'] == currentUserId;
            final double total = (data['totalAmount'] as num).toDouble();
            final double perPerson = (data['perPersonAmount'] as num).toDouble();
            final String tripName = data['tripName'] ?? '';
            final String? groupName = data['groupName'] as String?;
            final Timestamp? ts = data['createdAt'] as Timestamp?;
            final String dateStr = ts != null
                ? "${ts.toDate().day}/${ts.toDate().month}/${ts.toDate().year}"
                : '';

            return GestureDetector(
              onTap: () => showBillDetail(context, data),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: AppTheme.listTileDecoration,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: Colors.greenAccent,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tripName,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            (groupName != null && groupName.isNotEmpty)
                                ? "Group: $groupName  •  $dateStr"
                                : dateStr,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "₹${(iCreated ? total : perPerson).toStringAsFixed(2)}",
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          "Settled ✓",
                          style: TextStyle(
                            color: Colors.greenAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
