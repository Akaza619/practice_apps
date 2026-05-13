import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../models/receipt.dart';
import '../services/storage_service.dart';

class ReceiptDetailScreen extends StatefulWidget {
  final Receipt receipt;
  final StorageService storage;
  final bool isNew;

  const ReceiptDetailScreen({
    super.key,
    required this.receipt,
    required this.storage,
    this.isNew = false,
  });

  @override
  State<ReceiptDetailScreen> createState() => _ReceiptDetailScreenState();
}

class _ReceiptDetailScreenState extends State<ReceiptDetailScreen> {
  late Receipt _receipt;
  final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
  bool _editing = false;
  bool _showRaw = false;
  late TextEditingController _storeCtrl;
  late TextEditingController _totalCtrl;

  static const _categories = [
    'Groceries',
    'Food & dining',
    'Healthcare',
    'Electronics',
    'Fashion',
    'Fuel',
    'Utilities',
    'Entertainment',
    'Transport',
    'General',
  ];

  @override
  void initState() {
    super.initState();
    _receipt = widget.receipt;
    _storeCtrl = TextEditingController(text: _receipt.storeName);
    _totalCtrl = TextEditingController(text: _receipt.total.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _storeCtrl.dispose();
    _totalCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isNew ? 'Review receipt' : 'Receipt details'),
        actions: [
          if (!_editing)
            IconButton(icon: const Icon(Icons.share), onPressed: _share),
          IconButton(
            icon: Icon(_editing ? Icons.check : Icons.edit),
            onPressed: _editing
                ? _saveEdits
                : () => setState(() => _editing = true),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(),
            const SizedBox(height: 16),
            _buildItemsCard(),
            const SizedBox(height: 16),
            if (_receipt.imagePath != null) _buildImagePreview(),
            if (_receipt.rawText.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildRawTextCard(),
            ],
            const SizedBox(height: 16),
            if (widget.isNew)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(14),
                  ),
                  onPressed: _save,
                  icon: const Icon(Icons.save),
                  label: const Text(
                    'Save receipt',
                    style: TextStyle(fontSize: 15),
                  ),
                ),
              ),
            if (!widget.isNew)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(14),
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                  onPressed: _delete,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete receipt'),
                ),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ─── Header card ────────────────────────────────────────────────────────────

  Widget _buildHeaderCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _editing
                ? TextField(
                    controller: _storeCtrl,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Store name',
                      border: OutlineInputBorder(),
                    ),
                  )
                : Text(
                    _receipt.storeName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
            const SizedBox(height: 12),
            Row(
              children: [
                _MetaChip(
                  icon: Icons.calendar_today,
                  label: DateFormat('d MMM yyyy').format(_receipt.date),
                ),
                const SizedBox(width: 8),
                _MetaChip(
                  icon: Icons.receipt,
                  label:
                      '${_receipt.items.length} item${_receipt.items.length == 1 ? '' : 's'}',
                ),
              ],
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _categories.contains(_receipt.category)
                  ? _receipt.category
                  : 'General',
              items: _categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: _editing
                  ? (v) => setState(() => _receipt = _copyReceipt(category: v))
                  : null,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Items card ─────────────────────────────────────────────────────────────

  Widget _buildItemsCard() {
    final subtotal = _receipt.items.fold<double>(0, (s, i) => s + i.total);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Items',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            if (_receipt.items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'No items detected',
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(.5),
                  ),
                ),
              )
            else ...[
              ..._receipt.items.asMap().entries.map(
                (e) => _ItemRow(
                  item: e.value,
                  currency: _currency,
                  onEdit: _editing ? () => _editItem(e.key) : null,
                ),
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Subtotal',
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(.7),
                    ),
                  ),
                  Text(_currency.format(subtotal)),
                ],
              ),
            ],
            const Divider(height: 24, thickness: 1.5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                _editing
                    ? SizedBox(
                        width: 120,
                        child: TextField(
                          controller: _totalCtrl,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.right,
                          decoration: const InputDecoration(
                            prefixText: '₹ ',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      )
                    : Text(
                        _currency.format(_receipt.total),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Image preview ──────────────────────────────────────────────────────────

  Widget _buildImagePreview() {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              'Original image',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          Image.file(
            File(_receipt.imagePath!),
            fit: BoxFit.cover,
            width: double.infinity,
            height: 200,
            errorBuilder: (_, _, _) => const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Image not available'),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Raw OCR text ────────────────────────────────────────────────────────────

  Widget _buildRawTextCard() {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _showRaw = !_showRaw),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  const Icon(
                    Icons.text_fields_outlined,
                    size: 18,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Raw text from Gemini',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  Icon(
                    _showRaw
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
          if (_showRaw) ...[
            const Divider(height: 1),
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2E),
                borderRadius: BorderRadius.circular(8),
              ),
              constraints: const BoxConstraints(maxHeight: 250),
              child: SingleChildScrollView(
                child: SelectableText(
                  _receipt.rawText,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: Color(0xFFCDD6F4),
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Actions ─────────────────────────────────────────────────────────────────

  void _saveEdits() {
    setState(() {
      _editing = false;
      _receipt = _copyReceipt(
        storeName: _storeCtrl.text.trim(),
        total: double.tryParse(_totalCtrl.text) ?? _receipt.total,
      );
    });
    if (!widget.isNew) widget.storage.saveReceipt(_receipt);
  }

  void _editItem(int index) {
    final item = _receipt.items[index];
    final nameCtrl = TextEditingController(text: item.name);
    final priceCtrl = TextEditingController(
      text: item.price.toStringAsFixed(2),
    );
    final qtyCtrl = TextEditingController(
      text: item.quantity == item.quantity.truncateToDouble()
          ? item.quantity.toInt().toString()
          : item.quantity.toStringAsFixed(1),
    );

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Item name'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: qtyCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Quantity'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Unit price',
                prefixText: '₹ ',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _receipt.items[index] = LineItem(
                  name: nameCtrl.text.trim(),
                  price: double.tryParse(priceCtrl.text) ?? item.price,
                  quantity: double.tryParse(qtyCtrl.text) ?? item.quantity,
                );
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    await widget.storage.saveReceipt(_receipt);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete receipt?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await widget.storage.deleteReceipt(_receipt.id);
      if (mounted) Navigator.pop(context);
    }
  }

  void _share() {
    final lines = [
      _receipt.storeName,
      DateFormat('d MMM yyyy').format(_receipt.date),
      '',
      ..._receipt.items.map(
        (i) => '${i.name.padRight(28)} ${_currency.format(i.total)}',
      ),
      '',
      'Total: ${_currency.format(_receipt.total)}',
    ];
    Share.share(lines.join('\n'), subject: 'Receipt — ${_receipt.storeName}');
  }

  // ─── Helper ──────────────────────────────────────────────────────────────────

  Receipt _copyReceipt({String? storeName, double? total, String? category}) {
    return Receipt(
      id: _receipt.id,
      storeName: storeName ?? _receipt.storeName,
      date: _receipt.date,
      total: total ?? _receipt.total,
      items: _receipt.items,
      category: category ?? _receipt.category,
      imagePath: _receipt.imagePath,
      rawText: _receipt.rawText,
      scannedAt: _receipt.scannedAt,
    );
  }
}

// ─── Small widgets ────────────────────────────────────────────────────────────

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 14),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final LineItem item;
  final NumberFormat currency;
  final VoidCallback? onEdit;
  const _ItemRow({
    required this.item,
    required this.currency,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onEdit,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: Text(item.name, style: const TextStyle(fontSize: 13)),
            ),
            if (item.quantity != 1.0)
              Text(
                '×${item.quantity % 1 == 0 ? item.quantity.toInt() : item.quantity.toStringAsFixed(1)}  ',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(.5),
                ),
              ),
            Text(
              currency.format(item.total),
              style: const TextStyle(fontSize: 13),
            ),
            if (onEdit != null) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.edit,
                size: 14,
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
