import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../appstate.dart';

class BudgetItemForm extends StatefulWidget {
  final Map<String, dynamic>? existingItem;
  final Map<String, dynamic>? prefillData;

  const BudgetItemForm({this.existingItem, this.prefillData, super.key});

  @override
  State<BudgetItemForm> createState() => _BudgetItemFormState();
}

class _BudgetItemFormState extends State<BudgetItemForm> {
  final _nameController = TextEditingController();
  final _estimatedController = TextEditingController();
  final _actualController = TextEditingController();
  final _notesController = TextEditingController();
  String _category = 'Venue';
  bool _isPaid = false;

  final _categories = [
    'Venue', 'Catering', 'Photography', 'Videography', 'Flowers',
    'Music', 'Attire', 'Invitations', 'Decor', 'Transportation',
    'Favors', 'Cake', 'Hair & Makeup', 'Officiant', 'Other',
  ];

  bool get _isEditing => widget.existingItem != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final item = widget.existingItem!;
      _nameController.text = item['item_name'] ?? '';
      _estimatedController.text = ((item['estimated_cost'] as num?)?.toStringAsFixed(2)) ?? '';
      _actualController.text = ((item['actual_cost'] as num?)?.toStringAsFixed(2)) ?? '';
      _notesController.text = item['notes'] ?? '';
      _category = item['category'] ?? 'Venue';
      _isPaid = item['is_paid'] == true;
    } else if (widget.prefillData != null) {
      final data = widget.prefillData!;
      _nameController.text = data['item_name'] ?? '';
      _estimatedController.text = ((data['estimated_cost'] as num?)?.toStringAsFixed(2)) ?? '';
      _category = data['category'] ?? 'Venue';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _estimatedController.dispose();
    _actualController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.montserrat(fontSize: 13, color: const Color(0xFF7B3F61)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFDCC7AA)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFDCC7AA)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF7B3F61), width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);

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
          _isEditing ? 'Edit Expense' : 'Add Expense',
          style: GoogleFonts.bodoniModa(
            color: const Color(0xFF7B3F61),
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () {
                appState.deleteBudgetItem(widget.existingItem!['id']);
                Navigator.pop(context);
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: _inputDecoration('Item Name'),
                  style: GoogleFonts.montserrat(fontSize: 14),
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: _categories.contains(_category) ? _category : 'Other',
                  decoration: _inputDecoration('Category'),
                  items: _categories.map((c) => DropdownMenuItem(
                    value: c,
                    child: Text(c, style: GoogleFonts.montserrat(fontSize: 14)),
                  )).toList(),
                  onChanged: (v) => setState(() => _category = v ?? 'Other'),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _estimatedController,
                  decoration: _inputDecoration('Estimated Cost (\$)'),
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.montserrat(fontSize: 14),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _actualController,
                  decoration: _inputDecoration('Actual Cost (\$)'),
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.montserrat(fontSize: 14),
                ),
                const SizedBox(height: 16),

                SwitchListTile(
                  title: Text('Paid', style: GoogleFonts.montserrat(fontSize: 14)),
                  value: _isPaid,
                  onChanged: (v) => setState(() => _isPaid = v),
                  activeColor: const Color(0xFF7B3F61),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _notesController,
                  decoration: _inputDecoration('Notes'),
                  maxLines: 3,
                  style: GoogleFonts.montserrat(fontSize: 14),
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7B3F61),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    _isEditing ? 'Update' : 'Add Expense',
                    style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _save() {
    final appState = Provider.of<AppState>(context, listen: false);

    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an item name')),
      );
      return;
    }

    final estimated = double.tryParse(_estimatedController.text) ?? 0;
    final actual = double.tryParse(_actualController.text);

    if (_isEditing) {
      appState.updateBudgetItem(widget.existingItem!['id'], {
        'item_name': _nameController.text.trim(),
        'category': _category,
        'estimated_cost': estimated,
        'actual_cost': actual,
        'is_paid': _isPaid,
        'notes': _notesController.text.trim(),
      });
    } else {
      appState.addBudgetItem(
        category: _category,
        itemName: _nameController.text.trim(),
        estimatedCost: estimated,
        actualCost: actual,
        notes: _notesController.text.trim(),
      );
    }

    Navigator.pop(context);
  }
}
