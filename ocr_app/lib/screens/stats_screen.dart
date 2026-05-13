import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/storage_service.dart';

class StatsScreen extends StatelessWidget {
  final StorageService storage;
  const StatsScreen({super.key, required this.storage});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final receipts = storage.getAllReceipts();
    final categoryTotals = storage.getCategoryTotals();
    final monthlyTotals = storage.getMonthlyTotals();

    return Scaffold(
      appBar: AppBar(title: const Text('Spending stats')),
      body: receipts.isEmpty
          ? const Center(child: Text('No data yet. Scan some receipts!'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _SectionHeader('Overview'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: 'Total spent',
                        value: currency.format(storage.totalSpent),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        label: 'Receipts',
                        value: '${storage.receiptCount}',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        label: 'Avg/receipt',
                        value: currency.format(
                          storage.receiptCount > 0
                              ? storage.totalSpent / storage.receiptCount
                              : 0,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _SectionHeader('By category'),
                const SizedBox(height: 8),
                ..._buildCategoryBars(
                  context,
                  categoryTotals,
                  storage.totalSpent,
                  currency,
                ),
                const SizedBox(height: 24),
                _SectionHeader('Monthly breakdown'),
                const SizedBox(height: 8),
                ...monthlyTotals.entries.toList().reversed.map(
                  (e) => _MonthRow(
                    month: e.key,
                    amount: e.value,
                    currency: currency,
                  ),
                ),
              ],
            ),
    );
  }

  List<Widget> _buildCategoryBars(
    BuildContext context,
    Map<String, double> totals,
    double grandTotal,
    NumberFormat currency,
  ) {
    final sorted = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.map((e) {
      final pct = grandTotal > 0 ? e.value / grandTotal : 0.0;
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  e.key,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  currency.format(e.value),
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Stack(
              children: [
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: pct.clamp(0.0, 1.0),
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              '${(pct * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(.5),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
  );
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _MonthRow extends StatelessWidget {
  final String month;
  final double amount;
  final NumberFormat currency;
  const _MonthRow({
    required this.month,
    required this.amount,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final parts = month.split('-');
    final label = parts.length == 2
        ? DateFormat(
            'MMMM yyyy',
          ).format(DateTime(int.parse(parts[0]), int.parse(parts[1])))
        : month;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(
            currency.format(amount),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
