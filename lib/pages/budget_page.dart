import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../appstate.dart';
import 'budget_item_form.dart';

class BudgetPage extends StatelessWidget {
  final bool embedded;

  const BudgetPage({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        final totalBudget = appState.totalBudgetAmount;
        final totalEstimated = appState.totalEstimated;
        final totalActual = appState.totalActual;
        final items = appState.budgetItems;

        // Group by category
        final grouped = <String, List<Map<String, dynamic>>>{};
        for (var item in items) {
          final cat = item['category'] as String? ?? 'Other';
          grouped.putIfAbsent(cat, () => []).add(item);
        }

        final bodyContent = SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Total budget input
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7B3F61),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Total Budget',
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => _showBudgetDialog(context, appState, totalBudget),
                        child: Text(
                          totalBudget > 0 ? '\$${totalBudget.toStringAsFixed(0)}' : 'Set Budget',
                          style: GoogleFonts.bodoniModa(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildBudgetStat('Estimated', '\$${totalEstimated.toStringAsFixed(0)}', Colors.white70),
                          _buildBudgetStat('Spent', '\$${totalActual.toStringAsFixed(0)}', Colors.white70),
                          _buildBudgetStat(
                            'Remaining',
                            '\$${(totalBudget - totalActual).toStringAsFixed(0)}',
                            totalBudget > 0 && totalActual > totalBudget
                                ? Colors.redAccent
                                : const Color(0xFFDCC7AA),
                          ),
                        ],
                      ),
                      if (totalBudget > 0) ...[
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: (totalActual / totalBudget).clamp(0, 1).toDouble(),
                            minHeight: 8,
                            backgroundColor: Colors.white24,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              totalActual > totalBudget ? Colors.redAccent : const Color(0xFFDCC7AA),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Category breakdown
                if (grouped.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        children: [
                          Icon(Icons.account_balance_wallet_outlined,
                              size: 64, color: const Color(0xFFDCC7AA)),
                          const SizedBox(height: 16),
                          Text(
                            'Add expenses to track your budget',
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              color: const Color(0xFF6E6E6E),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...grouped.entries.map((entry) {
                    final catEstimated = entry.value.fold<double>(
                        0, (sum, i) => sum + ((i['estimated_cost'] as num?)?.toDouble() ?? 0));
                    final catActual = entry.value.fold<double>(
                        0, (sum, i) => sum + ((i['actual_cost'] as num?)?.toDouble() ?? 0));

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFDCC7AA).withOpacity(0.5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                entry.key,
                                style: GoogleFonts.bodoniModa(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF7B3F61),
                                ),
                              ),
                              Text(
                                '\$${catActual.toStringAsFixed(0)} / \$${catEstimated.toStringAsFixed(0)}',
                                style: GoogleFonts.montserrat(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF3E3E3E),
                                ),
                              ),
                            ],
                          ),
                          if (catEstimated > 0) ...[
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: (catActual / catEstimated).clamp(0, 1).toDouble(),
                                minHeight: 6,
                                backgroundColor: const Color(0xFFDCC7AA).withOpacity(0.3),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  catActual > catEstimated ? Colors.redAccent : const Color(0xFF7B3F61),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          ...entry.value.map((item) => InkWell(
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => BudgetItemForm(existingItem: item),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  child: Row(
                                    children: [
                                      Icon(
                                        item['is_paid'] == true
                                            ? Icons.check_circle
                                            : Icons.circle_outlined,
                                        size: 16,
                                        color: item['is_paid'] == true
                                            ? const Color(0xFF7B3F61)
                                            : const Color(0xFFDCC7AA),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          item['item_name'] ?? '',
                                          style: GoogleFonts.montserrat(fontSize: 13),
                                        ),
                                      ),
                                      Text(
                                        '\$${((item['actual_cost'] as num?)?.toDouble() ?? (item['estimated_cost'] as num?)?.toDouble() ?? 0).toStringAsFixed(0)}',
                                        style: GoogleFonts.montserrat(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: const Color(0xFF7B3F61),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Icon(Icons.edit_outlined,
                                          size: 14, color: Color(0xFF6E6E6E)),
                                    ],
                                  ),
                                ),
                              )),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          );

        if (embedded) {
          return ColoredBox(
            color: const Color(0xFFF8F5F0),
            child: bodyContent,
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF8F5F0),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF7B3F61)),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Budget',
              style: GoogleFonts.bodoniModa(
                color: const Color(0xFF7B3F61),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          body: bodyContent,
          floatingActionButton: FloatingActionButton(
            backgroundColor: const Color(0xFF7B3F61),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BudgetItemForm()),
              );
            },
            child: const Icon(Icons.add, color: Colors.white),
          ),
        );
      },
    );
  }

  Widget _buildBudgetStat(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(value,
            style: GoogleFonts.bodoniModa(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: valueColor,
            )),
        Text(label,
            style: GoogleFonts.montserrat(
              fontSize: 11,
              color: Colors.white60,
            )),
      ],
    );
  }

  void _showBudgetDialog(BuildContext context, AppState appState, double current) {
    final controller = TextEditingController(
        text: current > 0 ? current.toStringAsFixed(0) : '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Set Total Budget',
            style: GoogleFonts.bodoniModa(color: const Color(0xFF7B3F61))),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            prefixText: '\$ ',
            labelText: 'Total Budget',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(controller.text);
              if (amount != null && amount > 0) {
                appState.setTotalBudget(amount);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7B3F61)),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
