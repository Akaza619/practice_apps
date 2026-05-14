import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/receipt_provider.dart';
import '../models/receipt_item_model.dart';
import '../widgets/custom_button.dart';

class EditReceiptScreen extends ConsumerStatefulWidget {
  const EditReceiptScreen({super.key});

  @override
  ConsumerState<EditReceiptScreen> createState() => _EditReceiptScreenState();
}

class _EditReceiptScreenState extends ConsumerState<EditReceiptScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _billNameController;
  late TextEditingController _totalAmountController;
  late TextEditingController _gstPercentController;
  late TextEditingController _gstAmountController;
  List<ReceiptItem> _items = [];

  @override
  void initState() {
    super.initState();
    final receipt = ref.read(scannedReceiptProvider).value;
    _billNameController = TextEditingController(text: receipt?.billName ?? '');
    _totalAmountController = TextEditingController(text: receipt?.totalAmount?.toString() ?? '');
    _gstPercentController = TextEditingController(text: receipt?.gstPercent?.toString() ?? '');
    _gstAmountController = TextEditingController(text: receipt?.gstAmount?.toString() ?? '');
    _items = List.from(receipt?.items ?? []);
  }

  @override
  void dispose() {
    _billNameController.dispose();
    _totalAmountController.dispose();
    _gstPercentController.dispose();
    _gstAmountController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    if (_formKey.currentState!.validate()) {
      final currentReceipt = ref.read(scannedReceiptProvider).value;
      if (currentReceipt != null) {
        final updatedReceipt = currentReceipt.copyWith(
          billName: _billNameController.text,
          totalAmount: num.tryParse(_totalAmountController.text),
          gstPercent: num.tryParse(_gstPercentController.text),
          gstAmount: num.tryParse(_gstAmountController.text),
          items: _items,
        );
        ref.read(scannedReceiptProvider.notifier).updateReceipt(updatedReceipt);
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Receipt')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _billNameController,
              decoration: const InputDecoration(labelText: 'Store Name'),
            ),
            const SizedBox(height: 16),
            const Text('Items', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ..._items.asMap().entries.map((entry) {
              int idx = entry.key;
              ReceiptItem item = entry.value;
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      TextFormField(
                        initialValue: item.itemName,
                        decoration: const InputDecoration(labelText: 'Item Name'),
                        onChanged: (val) {
                          _items[idx] = _items[idx].copyWith(itemName: val);
                        },
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: item.itemCount?.toString(),
                              decoration: const InputDecoration(labelText: 'Qty'),
                              keyboardType: TextInputType.number,
                              onChanged: (val) {
                                _items[idx] = _items[idx].copyWith(itemCount: num.tryParse(val));
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              initialValue: item.unitPrice?.toString(),
                              decoration: const InputDecoration(labelText: 'Unit Price (₹)'),
                              keyboardType: TextInputType.number,
                              onChanged: (val) {
                                _items[idx] = _items[idx].copyWith(unitPrice: num.tryParse(val));
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),
            TextFormField(
              controller: _gstPercentController,
              decoration: const InputDecoration(labelText: 'GST Percent'),
              keyboardType: TextInputType.number,
            ),
            TextFormField(
              controller: _gstAmountController,
              decoration: const InputDecoration(labelText: 'GST Amount (₹)'),
              keyboardType: TextInputType.number,
            ),
            TextFormField(
              controller: _totalAmountController,
              decoration: const InputDecoration(labelText: 'Total Amount (₹)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: 'Save Changes',
              onPressed: _saveChanges,
            ),
          ],
        ),
      ),
    );
  }
}
