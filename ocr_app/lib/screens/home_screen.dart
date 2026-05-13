// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../models/receipt.dart';
import '../services/storage_service.dart';
import 'scan_screen.dart';
import 'receipt_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  final StorageService storage;
  const HomeScreen({super.key, required this.storage});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt Reader'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearch(context, currency),
          ),
        ],
      ),
      body: ValueListenableBuilder<Box<Receipt>>(
        valueListenable: storage.listenable,
        builder: (context, _, _) {
          final receipts = storage.getAllReceipts();
          return Column(
            children: [
              _SummaryBanner(
                totalSpent: storage.totalSpent,
                receiptCount: storage.receiptCount,
                currency: currency,
              ),
              Expanded(
                child: receipts.isEmpty
                    ? _EmptyState(onScan: () => _openScan(context))
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: receipts.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, i) => _ReceiptTile(
                          receipt: receipts[i],
                          currency: currency,
                          onTap: () => _openDetail(context, receipts[i]),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openScan(context),
        icon: const Icon(Icons.document_scanner),
        label: const Text('Scan receipt'),
      ),
    );
  }

  void _openScan(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ScanScreen(storage: storage)),
    );
  }

  void _openDetail(BuildContext context, Receipt receipt) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReceiptDetailScreen(receipt: receipt, storage: storage),
      ),
    );
  }

  void _showSearch(BuildContext context, NumberFormat currency) {
    showSearch(
      context: context,
      delegate: _ReceiptSearchDelegate(
        receipts: storage.getAllReceipts(),
        currency: currency,
        onSelected: (r) => _openDetail(context, r),
      ),
    );
  }
}

// ─── Summary banner ───────────────────────────────────────────────────────────

class _SummaryBanner extends StatelessWidget {
  final double totalSpent;
  final int receiptCount;
  final NumberFormat currency;

  const _SummaryBanner({
    required this.totalSpent,
    required this.receiptCount,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.primary,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total tracked',
                  style: TextStyle(
                    color: Colors.white.withOpacity(.75),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  currency.format(totalSpent),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$receiptCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                receiptCount == 1 ? 'receipt' : 'receipts',
                style: TextStyle(
                  color: Colors.white.withOpacity(.75),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Receipt tile ─────────────────────────────────────────────────────────────

class _ReceiptTile extends StatelessWidget {
  final Receipt receipt;
  final NumberFormat currency;
  final VoidCallback onTap;

  const _ReceiptTile({
    required this.receipt,
    required this.currency,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dateStr = DateFormat('d MMM yyyy').format(receipt.date);
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        onTap: onTap,
        title: Text(
          receipt.storeName,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              '$dateStr  •  ${receipt.items.length} item${receipt.items.length == 1 ? '' : 's'}',
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurface.withOpacity(.6),
              ),
            ),
            const SizedBox(height: 4),
            if (receipt.category != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  receipt.category!,
                  style: TextStyle(fontSize: 11, color: cs.onPrimaryContainer),
                ),
              ),
          ],
        ),
        trailing: Text(
          currency.format(receipt.total),
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: cs.primary,
          ),
        ),
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onScan;
  const _EmptyState({required this.onScan});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.receipt_long,
            size: 72,
            color: Theme.of(context).colorScheme.primary.withOpacity(.3),
          ),
          const SizedBox(height: 16),
          const Text(
            'No receipts yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            'Scan your first receipt to get started',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(.6),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onScan,
            icon: const Icon(Icons.document_scanner),
            label: const Text('Scan a receipt'),
          ),
        ],
      ),
    );
  }
}

// ─── Search delegate ─────────────────────────────────────────────────────────

class _ReceiptSearchDelegate extends SearchDelegate<Receipt?> {
  final List<Receipt> receipts;
  final NumberFormat currency;
  final void Function(Receipt) onSelected;

  _ReceiptSearchDelegate({
    required this.receipts,
    required this.currency,
    required this.onSelected,
  });

  @override
  List<Widget> buildActions(BuildContext context) => [
    IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
  ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () => close(context, null),
  );

  @override
  Widget buildResults(BuildContext context) => _buildList();

  @override
  Widget buildSuggestions(BuildContext context) => _buildList();

  Widget _buildList() {
    final q = query.toLowerCase();
    final filtered = receipts
        .where(
          (r) =>
              r.storeName.toLowerCase().contains(q) ||
              (r.category ?? '').toLowerCase().contains(q),
        )
        .toList();
    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (context, i) => ListTile(
        title: Text(filtered[i].storeName),
        subtitle: Text(DateFormat('d MMM yyyy').format(filtered[i].date)),
        trailing: Text(currency.format(filtered[i].total)),
        onTap: () {
          close(context, null);
          onSelected(filtered[i]);
        },
      ),
    );
  }
}
