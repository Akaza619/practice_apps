import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:splitora_app/controllers/bill_controller.dart';
import 'package:splitora_app/theme/app_theme.dart';

// ⚠️  Replace with your Razorpay key. Keep test key out of production builds.
// Use --dart-define=RAZORPAY_KEY=rzp_live_xxx for production.
const _kRazorpayKey = 'rzp_test_SUOCoHmBlkGdb7';

/// Shows a bottom-sheet style dialog with full bill details.
/// Call this helper from any bill tile's onTap.
void showBillDetail(BuildContext context, Map<String, dynamic> data) {
  showDialog(
    context: context,
    barrierColor: Colors.black54,
    builder: (_) => BillDetailDialog(data: data),
  );
}

class BillDetailDialog extends StatefulWidget {
  final Map<String, dynamic> data;

  const BillDetailDialog({super.key, required this.data});

  @override
  State<BillDetailDialog> createState() => _BillDetailDialogState();
}

class _BillDetailDialogState extends State<BillDetailDialog> {
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

  // ── Razorpay callbacks ───────────────────────────────────────────────

  void _onPaymentSuccess(PaymentSuccessResponse response) async {
    setState(() => _paying = true);
    final billId = widget.data['billId'] as String? ?? '';
    await _controller.recordPayment(billId);
    setState(() => _paying = false);
    if (mounted) Navigator.of(context).pop();
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

  // ── Open Razorpay checkout ───────────────────────────────────────────

  void _openRazorpay() {
    final perPerson = (widget.data['perPersonAmount'] as num).toDouble();
    final tripName = widget.data['tripName'] ?? 'Trip Bill';
    final createdByName = widget.data['createdByName'] ?? 'the organiser';

    // Razorpay amount is in paise (₹1 = 100 paise)
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
      _onPaymentError(
        PaymentFailureResponse(0, e.toString(), null),
      );
    }
  }

  // ── Build ────────────────────────────────────────────────────────────

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
        ts != null ? DateFormat('dd MMM yyyy, hh:mm a').format(ts.toDate()) : '-';

    final Map<String, dynamic> participantNames =
        Map<String, dynamic>.from(d['participantNames'] ?? {});
    final List<String> participants =
        List<String>.from(d['participants'] ?? []);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──────────────────────────────────────────────
            _Header(
              tripName: tripName,
              settled: settled,
              iHavePaid: iHavePaid,
              iCreated: iCreated,
            ),

            // ── Body ────────────────────────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Amount row
                    _AmountRow(total: total, perPerson: perPerson),
                    const SizedBox(height: 16),

                    // Details
                    _DetailRow(
                      icon: Icons.calendar_today_rounded,
                      label: "Date",
                      value: dateStr,
                    ),
                    _DetailRow(
                      icon: Icons.person_rounded,
                      label: "Paid by",
                      value: createdByName,
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

                    const SizedBox(height: 16),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 8),

                    // Members list
                    Text(
                      "Members (${participants.length})",
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...participants.map((uid) {
                      final name = (participantNames[uid] ?? uid).toString();
                      final hasPaid =
                          uid == d['createdBy'] || settledBy.contains(uid);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Icon(
                              hasPaid
                                  ? Icons.check_circle_rounded
                                  : Icons.radio_button_unchecked_rounded,
                              color: hasPaid
                                  ? Colors.greenAccent
                                  : Colors.white38,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                name,
                                style: TextStyle(
                                  color: hasPaid
                                      ? AppTheme.textPrimary
                                      : AppTheme.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            Text(
                              hasPaid ? "Paid" : "Pending",
                              style: TextStyle(
                                color: hasPaid
                                    ? Colors.greenAccent
                                    : Colors.redAccent,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                    const SizedBox(height: 20),

                    // ── Action button ──────────────────────────────
                    if (!settled) ...[
                      if (!iCreated && !iHavePaid)
                        _ActionButton(
                          label: _paying
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
                            final nav = Navigator.of(context);
                            await _controller.settleBill(d['billId'] ?? '');
                            nav.pop();
                          },
                        ),
                      if (!iCreated && iHavePaid)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white12,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_rounded,
                                  color: Colors.greenAccent, size: 18),
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
                        ),
                    ] else
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.verified_rounded,
                                color: Colors.greenAccent, size: 18),
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
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final String tripName;
  final bool settled;
  final bool iHavePaid;
  final bool iCreated;

  const _Header({
    required this.tripName,
    required this.settled,
    required this.iHavePaid,
    required this.iCreated,
  });

  @override
  Widget build(BuildContext context) {
    String badge;
    Color badgeColor;
    if (settled) {
      badge = "Settled ✓";
      badgeColor = Colors.greenAccent.shade400;
    } else if (iCreated) {
      badge = "You paid";
      badgeColor = Colors.greenAccent.shade400;
    } else if (iHavePaid) {
      badge = "Paid";
      badgeColor = Colors.greenAccent.shade400;
    } else {
      badge = "Pending";
      badgeColor = Colors.redAccent.shade200;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(bottom: BorderSide(color: Colors.white24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long_rounded,
                  color: Colors.white70, size: 18),
              const SizedBox(width: 6),
              const Text(
                "Bill Details",
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: const Icon(Icons.close_rounded,
                    color: Colors.white70, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  tripName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: badgeColor.withOpacity(0.6)),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
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
        border: Border.all(
          color: highlight ? Colors.white38 : Colors.white24,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
                  const TextStyle(color: Colors.white60, fontSize: 11)),
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
            style:
                const TextStyle(color: Colors.white60, fontSize: 13),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                  color: Colors.white, fontSize: 13),
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
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
