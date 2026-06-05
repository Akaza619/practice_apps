import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:splitora_app/controllers/bill_controller.dart';
import 'package:splitora_app/theme/app_theme.dart';

class BillEditScreen extends StatefulWidget {
  final Map<String, dynamic> data;

  const BillEditScreen({super.key, required this.data});

  @override
  State<BillEditScreen> createState() => _BillEditScreenState();
}

class _BillEditScreenState extends State<BillEditScreen> {
  late final BillController _controller;
  late final TextEditingController _searchCtrl;

  final List<_EditItem> _items = [];
  final _nameCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _amtCtrl = TextEditingController();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller = Get.put(BillController());
    _searchCtrl = TextEditingController();

    // Load existing items (manual or from scanned receipt)
    final manualItems =
        (widget.data['manualItems'] as List<dynamic>?)
            ?.cast<Map<String, dynamic>>();
    final scanData = widget.data['receiptScanData'] as Map<String, dynamic>?;

    if (manualItems != null) {
      for (final item in manualItems) {
        _items.add(
          _EditItem(
            name: item['name'] as String? ?? '',
            quantity: (item['quantity'] as num?)?.toInt() ?? 1,
            amount: (item['amount'] as num?)?.toDouble() ?? 0,
          ),
        );
      }
    } else if (scanData != null) {
      final lineItems =
          (scanData['line_items'] as List<dynamic>?)
              ?.cast<Map<String, dynamic>>();
      if (lineItems != null) {
        for (final item in lineItems) {
          final unitPrice = (item['unit_price'] as num?)?.toDouble() ?? 0;
          final totalPrice = (item['total_price'] as num?)?.toDouble() ?? 0;
          _items.add(
            _EditItem(
              name: item['name'] as String? ?? '',
              quantity: (item['quantity'] as num?)?.toInt() ?? 1,
              amount: unitPrice > 0 ? unitPrice : totalPrice,
            ),
          );
        }
      }
    }

    // Pre-select existing participants
    final participants = List<String>.from(widget.data['participants'] ?? []);
    final currentUid = FirebaseAuth.instance.currentUser!.uid;
    for (final uid in participants) {
      if (uid == currentUid) continue;
      if (!_controller.selectedUserIds.contains(uid)) {
        _controller.selectedUserIds.add(uid);
      }
    }

    _controller.isGroupMode.value =
        widget.data['groupId'] != null &&
        (widget.data['groupId'] as String).isNotEmpty;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _nameCtrl.dispose();
    _qtyCtrl.dispose();
    _amtCtrl.dispose();
    super.dispose();
  }

  void _addItem() {
    final name = _nameCtrl.text.trim();
    final qty = int.tryParse(_qtyCtrl.text.trim());
    final amt = double.tryParse(_amtCtrl.text.trim());
    if (name.isEmpty || qty == null || qty <= 0 || amt == null || amt <= 0) {
      return;
    }
    setState(() {
      _items.add(_EditItem(name: name, quantity: qty, amount: amt));
    });
    _nameCtrl.clear();
    _qtyCtrl.clear();
    _amtCtrl.clear();
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  void _updateItemName(int index, String value) {
    _items[index].name = value;
  }

  void _updateItemQty(int index, String value) {
    final qty = int.tryParse(value);
    if (qty != null && qty > 0) {
      _items[index].quantity = qty;
    }
  }

  void _updateItemAmt(int index, String value) {
    final amt = double.tryParse(value);
    if (amt != null && amt > 0) {
      _items[index].amount = amt;
    }
  }

  double _calculateTotal() {
    return _items.fold<double>(0, (sum, item) => sum + item.total);
  }

  Future<void> _save() async {
    final total = _calculateTotal();
    if (total <= 0) {
      Get.snackbar(
        "Error",
        "Add at least one item with amount.",
        backgroundColor: Colors.redAccent.withOpacity(0.8),
        colorText: Colors.white,
      );
      return;
    }

    final d = widget.data;
    final currentUid = FirebaseAuth.instance.currentUser!.uid;
    final isGroupMode = _controller.isGroupMode.value;

    List<String> participantIds;
    Map<String, dynamic> participantNames;

    if (isGroupMode) {
      participantIds = List<String>.from(d['participants'] ?? []);
      participantNames = Map<String, dynamic>.from(d['participantNames'] ?? {});
    } else {
      participantIds = [currentUid, ..._controller.selectedUserIds];
      participantNames = {};
      final meDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUid)
              .get();
      final meData = meDoc.data() as Map<String, dynamic>;
      final creatorName =
          meData['displayName'] ?? meData['firstName'] ?? 'Unknown';
      participantNames[currentUid] = creatorName;

      for (final uid in _controller.selectedUserIds) {
        final match = _controller.allUsers.firstWhereOrNull(
          (u) => u['uid'] == uid,
        );
        if (match != null) {
          participantNames[uid] =
              match['displayName'] ?? match['firstName'] ?? 'Unknown';
        }
      }
    }

    setState(() => _isSaving = true);

    final success = await _controller.updateBill(
      billId: d['billId'] ?? '',
      totalAmount: total,
      manualItems:
          _items
              .map(
                (item) => {
                  'name': item.name,
                  'quantity': item.quantity,
                  'amount': item.amount,
                },
              )
              .toList(),
      updatedParticipantIds: participantIds,
      updatedParticipantNames: participantNames,
      groupId: d['groupId'] as String?,
      groupName: d['groupName'] as String?,
    );

    setState(() => _isSaving = false);

    if (success && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;

    bool isGroupBill =
        d['groupId'] != null && (d['groupId'] as String).isNotEmpty;
    final Timestamp? ts = d['date'] as Timestamp?;
    final String dateStr =
        ts != null ? DateFormat('dd MMM yyyy').format(ts.toDate()) : '';
    final double currentTotal = _calculateTotal();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Bill"),
        backgroundColor: AppTheme.appBarColor,
        elevation: 0,
      ),
      body: Container(
        decoration: AppTheme.backgroundDecoration,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Bill Info (read-only) ─────────────────────────────────
              _SectionCard(
                title: "Bill Details",
                child: Column(
                  children: [
                    _readOnlyField("Trip Name", d['tripName'] ?? ''),
                    const SizedBox(height: 8),
                    _readOnlyField("Date", dateStr),
                    const SizedBox(height: 8),
                    _readOnlyField(
                      "Total Amount",
                      "₹${currentTotal.toStringAsFixed(2)}",
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Scanned receipt info (read-only) ───────────────────────
              if (widget.data['receiptScanData'] != null) ...[
                _buildScanInfo(
                  widget.data['receiptScanData'] as Map<String, dynamic>,
                ),
                const SizedBox(height: 16),
              ],

              // ── Items ─────────────────────────────────────────────────
              _SectionCard(
                title: "Items",
                child: Column(
                  children: [
                    if (_items.isNotEmpty) _itemList(),
                    const SizedBox(height: 8),
                    _itemInputRow(),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed:
                            _items.isEmpty ? null : () => setState(() {}),
                        icon: const Icon(Icons.calculate, size: 18),
                        label: const Text("Calculate Total"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.fabBackground,
                          foregroundColor: AppTheme.buttonForeground,
                          disabledBackgroundColor:
                              AppTheme.disabledButtonBackground,
                          disabledForegroundColor:
                              AppTheme.disabledButtonForeground,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Participants ──────────────────────────────────────────
              if (!isGroupBill)
                _SectionCard(
                  title: "Participants",
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Add or remove members for this bill.",
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _searchCtrl,
                        onChanged: _controller.searchUsers,
                        style: const TextStyle(color: AppTheme.textPrimary),
                        decoration: InputDecoration(
                          hintText: "Search by name or email...",
                          hintStyle: const TextStyle(
                            color: AppTheme.textTertiary,
                          ),
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
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 210,
                        child: Obx(() {
                          if (_controller.filteredUsers.isEmpty) {
                            return const Center(
                              child: Text(
                                "No users found",
                                style: TextStyle(color: AppTheme.textSecondary),
                              ),
                            );
                          }
                          return ListView.builder(
                            itemCount: _controller.filteredUsers.length,
                            itemBuilder: (context, index) {
                              final user = _controller.filteredUsers[index];
                              final uid = user['uid'] as String;
                              return Obx(() {
                                final bool selected = _controller
                                    .selectedUserIds
                                    .contains(uid);
                                return ListTile(
                                  dense: true,
                                  onTap: () => _controller.toggleUser(uid),
                                  leading: CircleAvatar(
                                    radius: 16,
                                    backgroundColor: AppTheme.avatarBackground,
                                    child: Text(
                                      (user['firstName'] ?? 'U')[0]
                                          .toUpperCase(),
                                      style: const TextStyle(
                                        color: AppTheme.textPrimary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    user['displayName'] ??
                                        user['firstName'] ??
                                        'Unknown',
                                    style: const TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontSize: 14,
                                    ),
                                  ),
                                  subtitle: Text(
                                    user['email'] ?? '',
                                    style: const TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 11,
                                    ),
                                  ),
                                  trailing: Checkbox(
                                    value: selected,
                                    onChanged:
                                        (_) => _controller.toggleUser(uid),
                                    activeColor: AppTheme.checkboxActive,
                                    checkColor: AppTheme.checkboxCheck,
                                    side: const BorderSide(
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                );
                              });
                            },
                          );
                        }),
                      ),
                    ],
                  ),
                )
              else
                _SectionCard(
                  title: "Group",
                  child: _readOnlyField(
                    "Group",
                    d['groupName'] as String? ?? 'Group',
                  ),
                ),
              const SizedBox(height: 24),

              // ── Save ──────────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _items.isEmpty || _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.fabBackground,
                    foregroundColor: AppTheme.buttonForeground,
                    disabledBackgroundColor: AppTheme.disabledButtonBackground,
                    disabledForegroundColor: AppTheme.disabledButtonForeground,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child:
                      _isSaving
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Text(
                            "SAVE CHANGES",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _itemList() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.inputFill,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        children: List.generate(_items.length, (i) {
          final item = _items[i];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: TextEditingController(text: item.name),
                    onChanged: (v) => _updateItemName(i, v),
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 13,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      hintText: "Name",
                      hintStyle: const TextStyle(
                        color: AppTheme.textTertiary,
                        fontSize: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: AppTheme.inputFillDense,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                SizedBox(
                  width: 50,
                  child: TextField(
                    controller: TextEditingController(
                      text: item.quantity.toString(),
                    ),
                    onChanged: (v) => _updateItemQty(i, v),
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 8,
                      ),
                      hintText: "Qty",
                      hintStyle: const TextStyle(
                        color: AppTheme.textTertiary,
                        fontSize: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: AppTheme.inputFillDense,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                SizedBox(
                  width: 70,
                  child: TextField(
                    controller: TextEditingController(
                      text: item.amount.toStringAsFixed(0),
                    ),
                    onChanged: (v) => _updateItemAmt(i, v),
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 8,
                      ),
                      hintText: "₹",
                      hintStyle: const TextStyle(
                        color: AppTheme.textTertiary,
                        fontSize: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: AppTheme.inputFillDense,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => _removeItem(i),
                  child: const Icon(
                    Icons.close,
                    size: 18,
                    color: AppTheme.errorColor,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _itemInputRow() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: _miniField(_nameCtrl, "Name", Icons.label_outline),
        ),
        const SizedBox(width: 6),
        Expanded(
          flex: 2,
          child: _miniField(
            _qtyCtrl,
            "Qty",
            Icons.format_list_numbered,
            keyboard: TextInputType.number,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          flex: 2,
          child: _miniField(
            _amtCtrl,
            "₹",
            Icons.currency_rupee,
            keyboard: TextInputType.number,
          ),
        ),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: _addItem,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.fabBackground,
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(Icons.add, color: AppTheme.buttonForeground),
          ),
        ),
      ],
    );
  }

  Widget _miniField(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    TextInputType keyboard = TextInputType.text,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboard,
      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, size: 16, color: AppTheme.iconColor),
        hintText: hint,
        hintStyle: const TextStyle(color: AppTheme.textTertiary, fontSize: 12),
        filled: true,
        fillColor: AppTheme.inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        isDense: true,
      ),
    );
  }

  Widget _buildScanInfo(Map<String, dynamic> scanData) {
    final merchantName = scanData['merchant_name'] as String? ?? '';
    final address = scanData['merchant_address'] as String? ?? '';
    final receiptNum = scanData['receipt_number'] as String? ?? '';
    final paymentMethod = scanData['payment_method'] as String? ?? '';

    if (merchantName.isEmpty && address.isEmpty && receiptNum.isEmpty) {
      return const SizedBox.shrink();
    }

    return _SectionCard(
      title: "Scanned Receipt",
      child: Column(
        children: [
          if (merchantName.isNotEmpty)
            _readOnlyField("Merchant", merchantName),
          if (address.isNotEmpty) ...[
            const SizedBox(height: 4),
            _readOnlyField("Address", address),
          ],
          if (receiptNum.isNotEmpty) ...[
            const SizedBox(height: 4),
            _readOnlyField("Receipt #", receiptNum),
          ],
          if (paymentMethod.isNotEmpty &&
              paymentMethod != 'UNKNOWN') ...[
            const SizedBox(height: 4),
            _readOnlyField("Payment", paymentMethod),
          ],
          const SizedBox(height: 8),
          const Text(
            "Items from this receipt can be edited below.",
            style: TextStyle(
              color: AppTheme.textTertiary,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _readOnlyField(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
          ),
        ),
      ],
    );
  }
}

class _EditItem {
  String name;
  int quantity;
  double amount;

  _EditItem({required this.name, required this.quantity, required this.amount});

  double get total => quantity * amount;
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
