import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../appstate.dart';
import 'budget_item_form.dart';
import '../utils/app_styles.dart';
import '../widgets/plan_panels.dart';

class BudgetPage extends StatelessWidget {
  final bool embedded;

  const BudgetPage({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        final panel = BudgetPanel(
          totalBudget: appState.totalBudgetAmount,
          items: appState.budgetItems,
          yesByCategory: appState.diamondedCards,
          onSetBudget: () => _showBudgetDialog(context, appState, appState.totalBudgetAmount),
          onAddExpense: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BudgetItemForm()),
          ),
          onOpenItem: (item) => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => BudgetItemForm(existingItem: item)),
          ),
        );

        if (embedded) {
          return ColoredBox(color: AppStyles.cream, child: panel);
        }
        return Scaffold(
          backgroundColor: AppStyles.cream,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppStyles.plum),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text('Budget', style: AppStyles.display(22)),
          ),
          body: panel,
        );
      },
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
