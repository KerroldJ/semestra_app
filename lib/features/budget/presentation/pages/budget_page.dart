import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import '../../domain/entities/expense_entity.dart';
import '../../../../core/theme/app_theme.dart';

class BudgetPage extends ConsumerWidget {
  const BudgetPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenseState = ref.watch(expenseNotifierProvider);
    final theme = Theme.of(context);

    final categories = ['Food', 'Transportation', 'School Supplies', 'Printing', 'Miscellaneous'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Budget & Expense Tracker'),
      ),
      body: expenseState.when(
        data: (expenses) {
          final totalSpent = expenses.fold<double>(0.0, (prev, e) => prev + e.amount);

          // Calculate category totals
          final categoryTotals = <String, double>{};
          for (final cat in categories) {
            categoryTotals[cat] = expenses
                .where((e) => e.category.toLowerCase() == cat.toLowerCase())
                .fold<double>(0.0, (prev, e) => prev + e.amount);
          }

          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Budget Summary Card
                    _BudgetSummaryCard(totalSpent: totalSpent),
                    const SizedBox(height: 24),

                    // Category breakdown
                    Text(
                      'Category Breakdown',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    ...categories.map((cat) {
                      final amt = categoryTotals[cat] ?? 0.0;
                      final pct = totalSpent > 0 ? amt / totalSpent : 0.0;
                      return _CategoryProgressBar(
                        category: cat,
                        amount: amt,
                        percentage: pct,
                      );
                    }).toList(),
                    const SizedBox(height: 28),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Expense History',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _showAddExpenseDialog(context, ref, categories),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Log Expense'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (expenses.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40.0),
                          child: Text('No expenses recorded. Save money, track expenses!'),
                        ),
                      ),
                    ...expenses.map((exp) => _ExpenseTile(expense: exp)).toList(),
                  ]),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading budget: $err')),
      ),
    );
  }

  void _showAddExpenseDialog(BuildContext context, WidgetRef ref, List<String> categories) {
    String selectedCategory = categories.first;
    final amountController = TextEditingController();
    final descController = TextEditingController();
    DateTime expenseDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Log New Expense'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: categories.map((cat) {
                        return DropdownMenuItem(value: cat, child: Text(cat));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => selectedCategory = val);
                      },
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Amount spent',
                        prefixText: '\$ ',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(labelText: 'Description'),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      title: const Text('Date of Purchase'),
                      subtitle: Text(DateFormat('yyyy-MM-dd').format(expenseDate)),
                      trailing: const Icon(Icons.calendar_today_rounded),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: expenseDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) setState(() => expenseDate = picked);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final amount = double.tryParse(amountController.text) ?? 0.0;
                    final desc = descController.text.trim();

                    if (amount > 0 && desc.isNotEmpty) {
                      ref.read(expenseNotifierProvider.notifier).addExpense(
                            category: selectedCategory,
                            amount: amount,
                            date: expenseDate,
                            description: desc,
                          );
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Log'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _BudgetSummaryCard extends StatelessWidget {
  final double totalSpent;

  const _BudgetSummaryCard({required this.totalSpent});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: AppTheme.secondaryGradient),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TOTAL EXPENSES',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '\$${totalSpent.toStringAsFixed(2)}',
                style: theme.textTheme.displayLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 32,
                ),
              ),
            ],
          ),
          const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 36),
        ],
      ),
    );
  }
}

class _CategoryProgressBar extends StatelessWidget {
  final String category;
  final double amount;
  final double percentage;

  const _CategoryProgressBar({
    required this.category,
    required this.amount,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(category, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(
                '\$${amount.toStringAsFixed(2)} (${(percentage * 100).toStringAsFixed(1)}%)',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: percentage,
              minHeight: 8,
              backgroundColor: theme.brightness == Brightness.dark
                  ? Colors.white10
                  : Colors.black12,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF06B6D4)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpenseTile extends ConsumerWidget {
  final ExpenseEntity expense;

  const _ExpenseTile({required this.expense});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dateStr = DateFormat('MMM d, yyyy').format(expense.date);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.15),
          foregroundColor: Theme.of(context).colorScheme.secondary,
          child: const Icon(Icons.shopping_bag_rounded, size: 20),
        ),
        title: Text(expense.description, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('$dateStr | ${expense.category}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '\$${expense.amount.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
              onPressed: () {
                ref.read(expenseNotifierProvider.notifier).deleteExpense(expense.id);
              },
            ),
          ],
        ),
      ),
    );
  }
}
