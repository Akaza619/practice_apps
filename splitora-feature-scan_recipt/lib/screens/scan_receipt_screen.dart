import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:splitora_app/controllers/bill_controller.dart';
import 'package:splitora_app/services/receipt_ai_service.dart';
import 'package:splitora_app/theme/app_theme.dart';

class ScanReceiptScreen extends StatelessWidget {
  const ScanReceiptScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan Receipt"),
        backgroundColor: AppTheme.appBarColor,
        elevation: 0,
      ),
      body: Container(
        decoration: AppTheme.backgroundDecoration,
        child: const _ScanBody(),
      ),
    );
  }
}

class _ScanBody extends StatefulWidget {
  const _ScanBody();

  @override
  State<_ScanBody> createState() => _ScanBodyState();
}

class _ScanBodyState extends State<_ScanBody> {
  File? _imageFile;
  bool _isScanning = false;
  ReceiptScanResult? _result;
  String? _errorMessage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
        _result = null;
        _errorMessage = null;
      });
    }
  }

  void _showPickerOptions() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Color(0xFF0072FF),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white38,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              "Choose Source",
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _SourceButton(
                  icon: Icons.photo_library,
                  label: "Gallery",
                  onTap: () {
                    Get.back();
                    _pickImage(ImageSource.gallery);
                  },
                ),
                _SourceButton(
                  icon: Icons.camera_alt,
                  label: "Camera",
                  onTap: () {
                    Get.back();
                    _pickImage(ImageSource.camera);
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Future<void> _scanImage() async {
    if (_imageFile == null) return;

    setState(() {
      _isScanning = true;
      _result = null;
      _errorMessage = null;
    });

    try {
      final result = await ReceiptAiService.instance.scanReceiptFromFile(
        _imageFile!,
      );
      setState(() => _result = result);
    } on ReceiptScanException catch (e) {
      debugPrint('❌ ReceiptScanException: ${e.message}');
      setState(() => _errorMessage = e.message);
    } catch (e) {
      debugPrint('❌ Unexpected error: $e');
      setState(() => _errorMessage = 'Unexpected error: $e');
    } finally {
      setState(() => _isScanning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Image picker / preview container ──────────────────────────
          GestureDetector(
            onTap: _isScanning ? null : _showPickerOptions,
            child: Container(
              width: double.infinity,
              height: 605,
              decoration: AppTheme.glassCardDecoration,
              clipBehavior: Clip.antiAlias,
              child:
                  _imageFile != null
                      ? Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(_imageFile!, fit: BoxFit.contain),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: _isScanning ? null : _showPickerOptions,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.black45,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(
                                  Icons.edit,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                      : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.cloud_upload_outlined,
                            color: AppTheme.textSecondary,
                            size: 64,
                          ),
                          SizedBox(height: 16),
                          Text(
                            "Choose File",
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Tap to select an image",
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
            ),
          ),
          const SizedBox(height: 24),

          // ── Scan button ────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _imageFile != null && !_isScanning ? _scanImage : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.fabBackground,
                foregroundColor: AppTheme.buttonForeground,
                disabledBackgroundColor: AppTheme.disabledButtonBackground,
                disabledForegroundColor: AppTheme.disabledButtonForeground,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child:
                  _isScanning
                      ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppTheme.buttonForeground,
                        ),
                      )
                      : const Text(
                        "Scan Image",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
            ),
          ),

          // ── Error message ──────────────────────────────────────────────
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.redAccent,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ── Scanned result ─────────────────────────────────────────────
          if (_result != null) ...[
            const SizedBox(height: 20),
            _buildResultSection(),
            const SizedBox(height: 20),
            _buildSplitButton(),
          ],
        ],
      ),
    );
  }

  Widget _buildSplitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _showSplitBottomSheet,
        icon: const Icon(Icons.people),
        label: const Text(
          "Split Bill",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.fabBackground,
          foregroundColor: AppTheme.buttonForeground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
      ),
    );
  }

  // Future<String?> _uploadReceiptImage(String billId) async {
  //   if (_imageFile == null) return null;
  //   try {
  //     final ref = FirebaseStorage.instance
  //         .ref()
  //         .child('receipt_images')
  //         .child(billId);
  //     final uploadTask = ref.putFile(_imageFile!);
  //     final snapshot = await uploadTask;
  //     return await snapshot.ref.getDownloadURL();
  //   } catch (e) {
  //     debugPrint('Failed to upload receipt image: $e');
  //     return null;
  //   }
  // }

  void _showSplitBottomSheet() {
    final r = _result;
    if (r == null) return;

    Get.bottomSheet(
      _SplitBillSheet(
        result: r,
        imageFile: _imageFile,
        onSplitComplete: () {
          setState(() {
            _result = null;
            _imageFile = null;
          });
          Get.back();
        },
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  Widget _buildResultSection() {
    final r = _result!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Summary card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: AppTheme.glassCardDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (r.merchantName.isNotEmpty)
                _summaryRow("Merchant", r.merchantName),
              if (r.merchantAddress.isNotEmpty)
                _summaryRow("Address", r.merchantAddress),
              if (r.date.isNotEmpty) _summaryRow("Date", r.date),
              if (r.time.isNotEmpty) _summaryRow("Time", r.time),
              if (r.receiptNumber.isNotEmpty)
                _summaryRow("Receipt #", r.receiptNumber),
              if (r.paymentMethod != 'UNKNOWN')
                _summaryRow("Payment", r.paymentMethod),
              Divider(color: AppTheme.cardBorder, height: 24),
              _summaryRow(
                "Grand Total",
                "${r.currency} ${r.grandTotal.toStringAsFixed(2)}",
                isBold: true,
              ),
            ],
          ),
        ),

        // Line items table
        if (r.lineItems.isNotEmpty) ...[
          const SizedBox(height: 20),
          const Text(
            "Items",
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: AppTheme.listTileDecoration,
            padding: const EdgeInsets.all(8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(
                    Colors.white.withOpacity(0.1),
                  ),
                  columns: const [
                    DataColumn(
                      label: Text(
                        "Item",
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        "Qty",
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      numeric: true,
                    ),
                    DataColumn(
                      label: Text(
                        "Price",
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      numeric: true,
                    ),
                    DataColumn(
                      label: Text(
                        "Total",
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      numeric: true,
                    ),
                  ],
                  rows:
                      r.lineItems.map((item) {
                        return DataRow(
                          cells: [
                            DataCell(
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 140,
                                ),
                                child: Text(
                                  item.name,
                                  style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                item.quantity.toString(),
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                "${r.currency} ${item.unitPrice.toStringAsFixed(2)}",
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                "${r.currency} ${item.totalPrice.toStringAsFixed(2)}",
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                ),
              ),
            ),
          ),
        ],

        // Totals
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: AppTheme.listTileDecoration,
          child: Column(
            children: [
              if (r.subtotal > 0) _totalRow("Subtotal", r.currency, r.subtotal),
              if (r.taxAmount > 0) _totalRow("Tax", r.currency, r.taxAmount),
              if (r.discountAmount > 0)
                _totalRow("Discount", r.currency, -r.discountAmount),
              Divider(color: AppTheme.cardBorder, height: 16),
              _totalRow("TOTAL", r.currency, r.grandTotal, isBold: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 13,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _totalRow(
    String label,
    String currency,
    double amount, {
    bool isBold = false,
  }) {
    final sign = amount < 0 ? "- " : "";
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isBold ? AppTheme.textPrimary : AppTheme.textSecondary,
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            "$sign$currency ${amount.abs().toStringAsFixed(2)}",
            style: TextStyle(
              color: isBold ? AppTheme.textPrimary : AppTheme.textSecondary,
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SourceButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 36),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Split Bill Bottom Sheet ───────────────────────────────────────────────

class _SplitBillSheet extends StatefulWidget {
  final ReceiptScanResult result;
  final File? imageFile;
  final VoidCallback onSplitComplete;

  const _SplitBillSheet({
    required this.result,
    required this.imageFile,
    required this.onSplitComplete,
  });

  @override
  State<_SplitBillSheet> createState() => _SplitBillSheetState();
}

class _SplitBillSheetState extends State<_SplitBillSheet> {
  late final BillController _controller;
  late final TextEditingController _searchCtrl;
  bool _isSplitting = false;

  @override
  void initState() {
    super.initState();
    _controller = Get.put(BillController());
    _controller.reset();
    _searchCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirmSplit() async {
    setState(() => _isSplitting = true);

    final r = widget.result;
    final date =
        r.date.isNotEmpty
            ? DateTime.tryParse(r.date) ?? DateTime.now()
            : DateTime.now();
    final tripName =
        r.merchantName.isNotEmpty ? r.merchantName : 'Scanned Receipt';
    final note =
        r.rawNotes.isNotEmpty
            ? 'Scanned receipt from ${r.merchantName}'
            : 'Generated from scanned receipt';

    setState(() => _isSplitting = false);
    // Close bottom sheet first so it doesn't get stuck with loading overlay
    if (mounted) {
      Navigator.of(context).pop();
    }

    String? imageUrl;
    if (widget.imageFile != null) {
      final tempId = FirebaseFirestore.instance.collection('bills').doc().id;
      imageUrl = await _uploadReceiptImage(tempId);
    }

    final bool success = await _controller.createBill(
      tripName: tripName,
      amount: r.grandTotal,
      date: date,
      note: note,
      receiptImageUrl: imageUrl,
      receiptScanData: r.toJson(),
    );

    if (success) {
      widget.onSplitComplete();
    } else {
      // Error snackbar already shown by createBill
      // User stays on the scan receipt screen and can retry
    }
  }

  Future<String?> _uploadReceiptImage(String billId) async {
    if (widget.imageFile == null) return null;
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('receipt_images')
          .child(billId);
      final uploadTask = ref.putFile(widget.imageFile!);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Failed to upload receipt image: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white38,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                const Icon(Icons.receipt_long, color: Colors.white70, size: 20),
                const SizedBox(width: 8),
                const Text(
                  "Split Bill",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  "₹${widget.result.grandTotal.toStringAsFixed(2)}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (widget.result.merchantName.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.result.merchantName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  if (widget.result.date.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Text(
                      widget.result.date,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 8),

          // Toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Obx(() => _modeToggle()),
          ),
          const SizedBox(height: 8),

          // Search + list
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Obx(
                () =>
                    _controller.isGroupMode.value
                        ? _groupSelector()
                        : _individualSelector(),
              ),
            ),
          ),

          // Confirm button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Obx(() {
              final bool canConfirm =
                  _controller.isGroupMode.value
                      ? _controller.selectedGroupId.value.isNotEmpty
                      : _controller.selectedUserIds.isNotEmpty;
              return SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: canConfirm && !_isSplitting ? _confirmSplit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.fabBackground,
                    foregroundColor: AppTheme.buttonForeground,
                    disabledBackgroundColor: AppTheme.disabledButtonBackground,
                    disabledForegroundColor: AppTheme.disabledButtonForeground,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child:
                      _isSplitting
                          ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          )
                          : Text(
                            _controller.isGroupMode.value
                                ? "Split with Group"
                                : "Split with ${_controller.selectedUserIds.length} friend${_controller.selectedUserIds.length == 1 ? '' : 's'}",
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _modeToggle() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.inputFill,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          _ToggleOption(
            label: "Individuals",
            selected: !_controller.isGroupMode.value,
            onTap: () {
              _controller.setGroupMode(false);
              _searchCtrl.clear();
            },
          ),
          _ToggleOption(
            label: "Group",
            selected: _controller.isGroupMode.value,
            onTap: () => _controller.setGroupMode(true),
          ),
        ],
      ),
    );
  }

  Widget _individualSelector() {
    return Column(
      children: [
        TextField(
          controller: _searchCtrl,
          onChanged: _controller.searchUsers,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: "Search by name or email...",
            hintStyle: const TextStyle(color: AppTheme.textTertiary),
            prefixIcon: const Icon(Icons.search, color: AppTheme.iconColor),
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
        Expanded(
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
                return Obx(() {
                  final bool selected = _controller.selectedUserIds.contains(
                    user['uid'],
                  );
                  return ListTile(
                    dense: true,
                    onTap: () => _controller.toggleUser(user['uid']),
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: AppTheme.avatarBackground,
                      child: Text(
                        (user['firstName'] ?? 'U')[0].toUpperCase(),
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    title: Text(
                      user['displayName'] ?? user['firstName'] ?? 'Unknown',
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
                      onChanged: (_) => _controller.toggleUser(user['uid']),
                      activeColor: AppTheme.checkboxActive,
                      checkColor: AppTheme.checkboxCheck,
                      side: const BorderSide(color: AppTheme.textPrimary),
                    ),
                  );
                });
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _groupSelector() {
    return Obx(() {
      if (_controller.allGroups.isEmpty) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              "No groups found.\nCreate a group in the Chats tab first.",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
        );
      }
      return ListView.builder(
        itemCount: _controller.allGroups.length,
        itemBuilder: (context, index) {
          final group = _controller.allGroups[index];
          final String gId = group['chatId'] ?? '';
          final String gName = group['groupName'] ?? 'Group';
          return Obx(() {
            return ListTile(
              dense: true,
              onTap: () => _controller.selectGroup(gId, gName),
              leading: CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.avatarBackground,
                child: const Icon(
                  Icons.group,
                  color: AppTheme.textPrimary,
                  size: 16,
                ),
              ),
              title: Text(
                gName,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                ),
              ),
              trailing: Radio<String>(
                value: gId,
                groupValue: _controller.selectedGroupId.value,
                onChanged: (_) => _controller.selectGroup(gId, gName),
                activeColor: AppTheme.checkboxActive,
              ),
            );
          });
        },
      );
    });
  }
}

class _ToggleOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppTheme.fabBackground : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color:
                  selected ? AppTheme.buttonForeground : AppTheme.textSecondary,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
