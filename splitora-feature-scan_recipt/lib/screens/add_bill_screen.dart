import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:splitora_app/controllers/bill_controller.dart';
import 'package:splitora_app/theme/app_theme.dart';

class AddBillScreen extends StatefulWidget {
  /// Pre-filled when navigating from the receipt scanner.
  final double? prefilledAmount;

  const AddBillScreen({super.key, this.prefilledAmount});

  @override
  State<AddBillScreen> createState() => _AddBillScreenState();
}

class _AddBillScreenState extends State<AddBillScreen> {
  late final BillController _controller;
  final _tripCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  final _isFormValid = false.obs;
  DateTime _selectedDateTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _controller = Get.put(BillController());
    _tripCtrl.addListener(_updateFormValidity);
    _amountCtrl.addListener(_updateFormValidity);
    if (widget.prefilledAmount != null) {
      _amountCtrl.text = widget.prefilledAmount!.toStringAsFixed(2);
    }
  }

  void _updateFormValidity() {
    final tripValid = _tripCtrl.text.trim().isNotEmpty;
    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;
    _isFormValid.value = tripValid && amount > 0;
  }

  @override
  void dispose() {
    _tripCtrl.removeListener(_updateFormValidity);
    _amountCtrl.removeListener(_updateFormValidity);
    _tripCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
    );
    if (time != null) {
      setState(() {
        _selectedDateTime = DateTime(
            date.year, date.month, date.day, time.hour, time.minute);
      });
    }
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;
    final success = await _controller.createBill(
      tripName: _tripCtrl.text.trim(),
      amount: amount,
      date: _selectedDateTime,
      note: _noteCtrl.text.trim(),
    );
    if (success && mounted) {
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Bill"),
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
              // ── Bill Details ──────────────────────────────────────────
              _SectionCard(
                title: "Bill Details",
                child: Column(
                  children: [
                    _field(_tripCtrl, "Trip Name", Icons.luggage),
                    const SizedBox(height: 12),
                    _field(
                      _amountCtrl,
                      "Total Amount (₹)",
                      Icons.currency_rupee,
                      keyboard: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    _dateTimePicker(),
                    const SizedBox(height: 12),
                    _field(_noteCtrl, "Note (optional)", Icons.note_alt),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Participants ──────────────────────────────────────────
              _SectionCard(
                title: "Participants",
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Obx(() => _modeToggle()),
                    const SizedBox(height: 12),
                    Obx(() => _controller.isGroupMode.value
                        ? _groupSelector()
                        : _individualSelector()),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Submit ────────────────────────────────────────────────
              Obx(() {
                final bool hasParticipants = _controller.isGroupMode.value
                    ? _controller.selectedGroupId.value.isNotEmpty
                    : _controller.selectedUserIds.isNotEmpty;
                final bool canSubmit = _isFormValid.value &&
                    hasParticipants &&
                    !_controller.isLoading.value;
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: canSubmit ? _submit : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.fabBackground,
                      foregroundColor: AppTheme.buttonForeground,
                      disabledBackgroundColor:
                          AppTheme.disabledButtonBackground,
                      disabledForegroundColor:
                          AppTheme.disabledButtonForeground,
                      padding:
                          const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                    ),
                    child: _controller.isLoading.value
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2),
                          )
                        : const Text(
                            "ADD BILL",
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                          ),
                  ),
                );
              }),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ── Widgets ──────────────────────────────────────────────────────────

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
            prefixIcon:
                const Icon(Icons.search, color: AppTheme.iconColor),
            filled: true,
            fillColor: AppTheme.inputFill,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 10),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 210,
          child: Obx(() {
            if (_controller.filteredUsers.isEmpty) {
              return const Center(
                child: Text("No users found",
                    style:
                        TextStyle(color: AppTheme.textSecondary)),
              );
            }
            return ListView.builder(
              itemCount: _controller.filteredUsers.length,
              itemBuilder: (context, index) {
                final user = _controller.filteredUsers[index];
                return Obx(() {
                  final bool selected = _controller.selectedUserIds
                      .contains(user['uid']);
                  return ListTile(
                    dense: true,
                    onTap: () =>
                        _controller.toggleUser(user['uid']),
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: AppTheme.avatarBackground,
                      child: Text(
                        (user['firstName'] ?? 'U')[0]
                            .toUpperCase(),
                        style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 12),
                      ),
                    ),
                    title: Text(
                      user['displayName'] ??
                          user['firstName'] ??
                          'Unknown',
                      style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 14),
                    ),
                    subtitle: Text(
                      user['email'] ?? '',
                      style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11),
                    ),
                    trailing: Checkbox(
                      value: selected,
                      onChanged: (_) =>
                          _controller.toggleUser(user['uid']),
                      activeColor: AppTheme.checkboxActive,
                      checkColor: AppTheme.checkboxCheck,
                      side: const BorderSide(
                          color: AppTheme.textPrimary),
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
        return const Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text(
              "No groups found.\nCreate a group in the Chats tab first.",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
        );
      }
      return SizedBox(
        height: 210,
        child: ListView.builder(
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
                  child: const Icon(Icons.group,
                      color: AppTheme.textPrimary, size: 16),
                ),
                title: Text(gName,
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14)),
                trailing: Radio<String>(
                  value: gId,
                  groupValue: _controller.selectedGroupId.value,
                  onChanged: (_) =>
                      _controller.selectGroup(gId, gName),
                  activeColor: AppTheme.checkboxActive,
                ),
              );
            });
          },
        ),
      );
    });
  }

  Widget _dateTimePicker() {
    return GestureDetector(
      onTap: _pickDateTime,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.inputFill,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today,
                color: AppTheme.iconColor),
            const SizedBox(width: 12),
            Text(
              DateFormat('dd MMM yyyy  •  hh:mm a')
                  .format(_selectedDateTime),
              style:
                  const TextStyle(color: AppTheme.textPrimary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    TextInputType keyboard = TextInputType.text,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboard,
      style: const TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: AppTheme.iconColor),
        hintText: hint,
        hintStyle:
            const TextStyle(color: AppTheme.textTertiary),
        filled: true,
        fillColor: AppTheme.inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 20, vertical: 15),
      ),
    );
  }
}

// ── Reusable sub-widgets ──────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
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

class _ToggleOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleOption(
      {required this.label,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? AppTheme.fabBackground
                : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected
                  ? AppTheme.buttonForeground
                  : AppTheme.textSecondary,
              fontWeight: selected
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
