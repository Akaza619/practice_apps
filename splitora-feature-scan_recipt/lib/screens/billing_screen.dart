import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:splitora_app/controllers/bill_controller.dart';
import 'package:splitora_app/screens/add_bill_screen.dart';
import 'package:splitora_app/screens/scan_receipt_screen.dart';
import 'package:splitora_app/theme/app_theme.dart';
import 'package:splitora_app/widgets/bill_detail_dialog.dart';

class BillingScreen extends StatelessWidget {
  const BillingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(BillController());
    final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Billing",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.appBarColor,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Container(
        decoration: AppTheme.backgroundDecoration,
        child: Column(
          children: [
            // ── Add options ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.edit_note_rounded,
                      label: "Add Manually",
                      onTap: () {
                        controller.reset();
                        Get.to(() => const AddBillScreen());
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.document_scanner_rounded,
                      label: "Scan Receipt",
                      onTap: () {
                        controller.reset();
                        Get.to(() => const ScanReceiptScreen());
                      },
                    ),
                  ),
                ],
              ),
            ),

            // ── Section header ────────────────────────────────────────
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "All Bills",
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // ── Bill list ─────────────────────────────────────────────
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: controller.getBillsStream(),
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
                        "Error loading bills.",
                        style: TextStyle(color: AppTheme.textPrimary),
                      ),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return const Center(
                      child: Text(
                        "No bills yet.\nUse the options above to add one!",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                        ),
                      ),
                    );
                  }

                  // Sort newest first client-side (avoids composite index)
                  final sorted = [...docs]..sort((a, b) {
                    final at = (a.data() as Map)['createdAt'] as Timestamp?;
                    final bt = (b.data() as Map)['createdAt'] as Timestamp?;
                    if (at == null || bt == null) return 0;
                    return bt.compareTo(at);
                  });

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    itemCount: sorted.length,
                    itemBuilder: (context, index) {
                      final data = sorted[index].data() as Map<String, dynamic>;
                      final bool iCreated = data['createdBy'] == currentUserId;
                      final bool settled = data['settled'] ?? false;
                      final double total =
                          (data['totalAmount'] as num).toDouble();
                      final double perPerson =
                          (data['perPersonAmount'] as num).toDouble();
                      final String tripName = data['tripName'] ?? '';
                      final String? groupName = data['groupName'] as String?;
                      final int memberCount =
                          (data['participants'] as List?)?.length ?? 1;
                      final Timestamp? ts = data['date'] as Timestamp?;
                      final String dateStr =
                          ts != null
                              ? DateFormat('dd MMM yyyy').format(ts.toDate())
                              : '';
                      final String billId = data['billId'] ?? sorted[index].id;

                      return GestureDetector(
                        onTap: () => showBillDetail(context, data),
                        child: _BillTile(
                          tripName: tripName,
                          groupName: groupName,
                          dateStr: dateStr,
                          total: total,
                          perPerson: perPerson,
                          memberCount: memberCount,
                          iCreated: iCreated,
                          settled: settled,
                          billId: billId,
                          controller: controller,
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

// ── Action card ───────────────────────────────────────────────────────

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 12),
        decoration: AppTheme.glassCardDecoration,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppTheme.textPrimary, size: 38),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bill tile ─────────────────────────────────────────────────────────

class _BillTile extends StatelessWidget {
  final String tripName;
  final String? groupName;
  final String dateStr;
  final double total;
  final double perPerson;
  final int memberCount;
  final bool iCreated;
  final bool settled;
  final String billId;
  final BillController controller;

  const _BillTile({
    required this.tripName,
    required this.groupName,
    required this.dateStr,
    required this.total,
    required this.perPerson,
    required this.memberCount,
    required this.iCreated,
    required this.settled,
    required this.billId,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final String statusLabel =
        settled
            ? "Settled ✓"
            : iCreated
            ? "You paid"
            : "You owe ₹${perPerson.toStringAsFixed(2)}";

    final Color statusColor =
        settled
            ? Colors.grey
            : iCreated
            ? AppTheme.owedColor
            : AppTheme.owesColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: AppTheme.listTileDecoration,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    tripName,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  "₹${total.toStringAsFixed(2)}",
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  (groupName != null && groupName!.isNotEmpty)
                      ? "Group: $groupName"
                      : "$memberCount members  •  $dateStr",
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
                Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (!settled && iCreated) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () => controller.settleBill(billId),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.greenAccent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.greenAccent.withOpacity(0.4),
                      ),
                    ),
                    child: const Text(
                      "Mark as Settled",
                      style: TextStyle(
                        color: AppTheme.successColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
