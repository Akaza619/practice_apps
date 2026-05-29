import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:splitora_app/controllers/bill_controller.dart';
import 'package:splitora_app/screens/bill_edit_screen.dart';
import 'package:splitora_app/theme/app_theme.dart';

const _kRazorpayKey = 'rzp_test_SUOCoHmBlkGdb7';

class BillDetailScreen extends StatefulWidget {
  final Map<String, dynamic> data;

  const BillDetailScreen({super.key, required this.data});

  @override
  State<BillDetailScreen> createState() => _BillDetailScreenState();
}

class _BillDetailScreenState extends State<BillDetailScreen> {
  late final Razorpay _razorpay;
  late final BillController _controller;
  bool _paying = false;

  @override
  void initState() {
    super.initState();
    _controller = Get.put(BillController());
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _onPaymentSuccess(PaymentSuccessResponse response) async {
    setState(() => _paying = true);
    final billId = widget.data['billId'] as String? ?? '';
    await _controller.recordPayment(billId);
    setState(() => _paying = false);
  }

  void _onPaymentError(PaymentFailureResponse response) {
    Get.snackbar(
      "Payment Failed",
      response.message ?? "Something went wrong",
      backgroundColor: Colors.redAccent.withOpacity(0.85),
      colorText: Colors.white,
    );
  }

  void _onExternalWallet(ExternalWalletResponse response) {
    Get.snackbar(
      "External Wallet",
      "Payment via ${response.walletName}",
      backgroundColor: Colors.orange.withOpacity(0.85),
      colorText: Colors.white,
    );
  }

  void _confirmDelete(BuildContext context, Map<String, dynamic> d) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          "Delete Bill",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "This will permanently remove this bill for all members. This action cannot be undone.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final billId = d['billId'] as String? ?? '';
              final deleted = await _controller.deleteBill(billId);
              if (deleted && mounted) {
                Navigator.of(context).pop();
              }
            },
            child: const Text(
              "Delete",
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openRazorpay() {
    final perPerson = (widget.data['perPersonAmount'] as num).toDouble();
    final tripName = widget.data['tripName'] ?? 'Trip Bill';
    final createdByName = widget.data['createdByName'] ?? 'the organiser';

    final options = {
      'key': _kRazorpayKey,
      'amount': (perPerson * 100).toInt(),
      'name': 'Splitora',
      'description': 'Payment for $tripName to $createdByName',
      'prefill': {
        'contact': '',
        'email': FirebaseAuth.instance.currentUser?.email ?? '',
      },
      'theme': {'color': '#0072FF'},
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      _onPaymentError(PaymentFailureResponse(0, e.toString(), null));
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final String currentUid = FirebaseAuth.instance.currentUser!.uid;

    final bool iCreated = d['createdBy'] == currentUid;
    final bool settled = d['settled'] ?? false;
    final settledBy = List<String>.from(d['settledBy'] ?? []);
    final bool iHavePaid = iCreated || settledBy.contains(currentUid);

    final double total = (d['totalAmount'] as num).toDouble();
    final double perPerson = (d['perPersonAmount'] as num).toDouble();
    final String tripName = d['tripName'] ?? '';
    final String createdByName = d['createdByName'] ?? 'Unknown';
    final String? groupName = d['groupName'] as String?;
    final String? note = d['note'] as String?;
    final Timestamp? ts = d['date'] as Timestamp?;
    final String dateStr =
        ts != null
            ? DateFormat('dd MMM yyyy, hh:mm a').format(ts.toDate())
            : '-';

    final Map<String, dynamic> participantNames = Map<String, dynamic>.from(
      d['participantNames'] ?? {},
    );
    final List<String> participants = List<String>.from(
      d['participants'] ?? [],
    );

    final manualItems =
        (d['manualItems'] as List<dynamic>?)?.cast<Map<String, dynamic>>();
    final receiptScanData = d['receiptScanData'] as Map<String, dynamic>?;

    final bool canEdit = iCreated && !settled;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Bill Details"),
        backgroundColor: AppTheme.appBarColor,
        elevation: 0,
        actions: [
          if (canEdit) ...[
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: "Delete Bill",
              onPressed: () => _confirmDelete(context, d),
            ),
            IconButton(
              icon: const Icon(Icons.edit_rounded),
              tooltip: "Edit Bill",
              onPressed: () async {
                final result = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => BillEditScreen(data: d),
                  ),
                );
                if (result == true && mounted) {
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        ],
      ),
      body: Container(
        decoration: AppTheme.backgroundDecoration,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  MediaQuery.of(context).size.height -
                  AppBar().preferredSize.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Status badge ────────────────────────────────────────────
                _StatusBadge(
                  settled: settled,
                  iCreated: iCreated,
                  iHavePaid: iHavePaid,
                ),
                const SizedBox(height: 16),

                // ── Trip name & amount ──────────────────────────────────────
                _SectionCard(
                  title: tripName,
                  child: Column(
                    children: [
                      _AmountRow(total: total, perPerson: perPerson),
                      const SizedBox(height: 12),
                      _DetailRow(
                        icon: Icons.person_rounded,
                        label: "Paid by",
                        value: createdByName,
                      ),
                      _DetailRow(
                        icon: Icons.calendar_today_rounded,
                        label: "Date",
                        value: dateStr,
                      ),
                      if (groupName != null && groupName.isNotEmpty)
                        _DetailRow(
                          icon: Icons.group_rounded,
                          label: "Group",
                          value: groupName,
                        ),
                      if (note != null && note.isNotEmpty)
                        _DetailRow(
                          icon: Icons.notes_rounded,
                          label: "Note",
                          value: note,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Scanned receipt data ────────────────────────────────────
                if (receiptScanData != null) ...[
                  _buildScanDetails(receiptScanData),
                  const SizedBox(height: 16),
                ],

              // ── Manual items (hide if already shown in scan details) ─────
              if (manualItems != null && manualItems.isNotEmpty && receiptScanData == null) ...[
                _buildManualItems(manualItems),
                const SizedBox(height: 16),
              ],

                // ── Participants ────────────────────────────────────────────
                _buildParticipants(
                  participants,
                  participantNames,
                  d['createdBy'],
                  settledBy,
                ),
                const SizedBox(height: 24),

                // ── Actions ─────────────────────────────────────────────────
                if (!settled) ...[
                  if (!iCreated && !iHavePaid)
                    _ActionButton(
                      label:
                          _paying
                              ? "Processing..."
                              : "Pay Now  ₹${perPerson.toStringAsFixed(2)}",
                      icon: Icons.payment_rounded,
                      color: Colors.greenAccent.shade400,
                      textColor: Colors.black87,
                      onPressed: _paying ? null : _openRazorpay,
                    ),
                  if (iCreated)
                    _ActionButton(
                      label: "Mark as Settled",
                      icon: Icons.check_circle_outline_rounded,
                      color: Colors.white24,
                      textColor: Colors.white,
                      onPressed: () async {
                        await _controller.settleBill(d['billId'] ?? '');
                        if (mounted) Navigator.of(context).pop();
                      },
                    ),
                  if (!iCreated && iHavePaid) _paidAlreadyBanner(),
                ] else
                  _settledBanner(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScanDetails(Map<String, dynamic> scanData) {
    final currency = scanData['currency'] as String? ?? 'INR';
    final lineItems =
        (scanData['line_items'] as List<dynamic>?)
            ?.cast<Map<String, dynamic>>();
    final subtotal = (scanData['subtotal'] as num?)?.toDouble() ?? 0;
    final taxAmount = (scanData['tax_amount'] as num?)?.toDouble() ?? 0;
    final discountAmount =
        (scanData['discount_amount'] as num?)?.toDouble() ?? 0;

    return _SectionCard(
      title: "Receipt Details",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if ((scanData['merchant_name'] as String?)?.isNotEmpty == true)
            _detailRow("Merchant", scanData['merchant_name'] as String),
          if ((scanData['merchant_address'] as String?)?.isNotEmpty == true)
            _detailRow("Address", scanData['merchant_address'] as String),
          if ((scanData['receipt_number'] as String?)?.isNotEmpty == true)
            _detailRow("Receipt #", scanData['receipt_number'] as String),
          if ((scanData['payment_method'] as String?)?.isNotEmpty == true &&
              scanData['payment_method'] != 'UNKNOWN')
            _detailRow("Payment", scanData['payment_method'] as String),

          if (lineItems != null && lineItems.isNotEmpty) ...[
            Divider(color: AppTheme.cardBorder, height: 24),
            ...lineItems.map((item) {
              final name = item['name'] as String? ?? '';
              final qty = (item['quantity'] as num?)?.toInt() ?? 1;
              final totalPrice = (item['total_price'] as num?)?.toDouble() ?? 0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        name,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (qty > 1)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(
                          "×$qty",
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    Text(
                      "$currency ${totalPrice.toStringAsFixed(2)}",
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],

          if (subtotal > 0 || taxAmount > 0 || discountAmount > 0) ...[
            Divider(color: AppTheme.cardBorder, height: 16),
            if (subtotal > 0) _totalRow("Subtotal", currency, subtotal),
            if (taxAmount > 0) _totalRow("Tax", currency, taxAmount),
            if (discountAmount > 0)
              _totalRow("Discount", currency, -discountAmount),
          ],
        ],
      ),
    );
  }

  Widget _buildManualItems(List<Map<String, dynamic>> items) {
    return _SectionCard(
      title: "Items",
      child: Column(
        children:
            items.map((item) {
              final name = item['name'] as String? ?? '';
              final qty = (item['quantity'] as num?)?.toInt() ?? 1;
              final amt = (item['amount'] as num?)?.toDouble() ?? 0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        name,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      "×$qty",
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      "₹${amt.toStringAsFixed(0)}",
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildParticipants(
    List<String> participants,
    Map<String, dynamic> participantNames,
    String? createdBy,
    List<String> settledBy,
  ) {
    return _SectionCard(
      title: "Members (${participants.length})",
      child: Column(
        children:
            participants.map((uid) {
              final name = (participantNames[uid] ?? uid).toString();
              final hasPaid = uid == createdBy || settledBy.contains(uid);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Icon(
                      hasPaid
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: hasPaid ? Colors.greenAccent : Colors.white38,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        name,
                        style: TextStyle(
                          color:
                              hasPaid
                                  ? AppTheme.textPrimary
                                  : AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Text(
                      hasPaid ? "Paid" : "Pending",
                      style: TextStyle(
                        color: hasPaid ? Colors.greenAccent : Colors.redAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _totalRow(String label, String currency, double amount) {
    final sign = amount < 0 ? "- " : "";
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
          Text(
            "$sign$currency ${amount.abs().toStringAsFixed(2)}",
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _paidAlreadyBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(30),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 18),
          SizedBox(width: 8),
          Text(
            "You've already paid",
            style: TextStyle(
              color: Colors.greenAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _settledBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(30),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.verified_rounded, color: Colors.greenAccent, size: 18),
          SizedBox(width: 8),
          Text(
            "Bill Settled ✓",
            style: TextStyle(
              color: Colors.greenAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final bool settled;
  final bool iCreated;
  final bool iHavePaid;

  const _StatusBadge({
    required this.settled,
    required this.iCreated,
    required this.iHavePaid,
  });

  @override
  Widget build(BuildContext context) {
    String text;
    Color color;
    IconData icon;

    if (settled) {
      text = "Settled";
      color = Colors.greenAccent;
      icon = Icons.verified_rounded;
    } else if (iCreated) {
      text = "You paid";
      color = Colors.greenAccent;
      icon = Icons.payment_rounded;
    } else if (iHavePaid) {
      text = "Paid";
      color = Colors.greenAccent;
      icon = Icons.check_circle_rounded;
    } else {
      text = "Pending";
      color = Colors.redAccent;
      icon = Icons.pending_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
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

class _AmountRow extends StatelessWidget {
  final double total;
  final double perPerson;

  const _AmountRow({required this.total, required this.perPerson});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _AmountBox(
            label: "Total Bill",
            value: "₹${total.toStringAsFixed(2)}",
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _AmountBox(
            label: "Per Person",
            value: "₹${perPerson.toStringAsFixed(2)}",
            highlight: true,
          ),
        ),
      ],
    );
  }
}

class _AmountBox extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _AmountBox({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: highlight ? Colors.white.withOpacity(0.18) : Colors.white10,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: highlight ? Colors.white38 : Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white60, fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: highlight ? 18 : 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white54, size: 16),
          const SizedBox(width: 8),
          Text(
            "$label: ",
            style: const TextStyle(color: Colors.white60, fontSize: 13),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color textColor;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.textColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 0,
        ),
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ),
    );
  }
}
