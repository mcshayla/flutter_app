import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../appstate.dart';
import '../templates/category_template.dart';

class ChecklistItemDetail extends StatefulWidget {
  final Map<String, dynamic> item;

  const ChecklistItemDetail({required this.item, super.key});

  @override
  State<ChecklistItemDetail> createState() => _ChecklistItemDetailState();
}

class _ChecklistItemDetailState extends State<ChecklistItemDetail> {
  late TextEditingController _notesController;
  late bool _isCompleted;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.item['notes'] ?? '');
    _isCompleted = widget.item['is_completed'] == true;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final category = widget.item['category'] as String? ?? 'Other';
    final dueDate = widget.item['due_date'] as String?;

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
          'Task Details',
          style: GoogleFonts.bodoniModa(
            color: const Color(0xFF7B3F61),
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Task?'),
                  content: const Text('This action cannot be undone.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        appState.deleteChecklistItem(widget.item['id']);
                        Navigator.pop(context); // close dialog
                        Navigator.pop(context); // go back
                      },
                      child: const Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and checkbox
            Row(
              children: [
                Checkbox(
                  value: _isCompleted,
                  onChanged: (v) {
                    setState(() => _isCompleted = v ?? false);
                    appState.toggleChecklistItem(widget.item['id'], _isCompleted);
                  },
                  activeColor: const Color(0xFF7B3F61),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                Expanded(
                  child: Text(
                    widget.item['title'] ?? '',
                    style: GoogleFonts.bodoniModa(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF7B3F61),
                      decoration: _isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Category and Due Date chips
            Wrap(
              spacing: 8,
              children: [
                Chip(
                  label: Text(category, style: GoogleFonts.montserrat(fontSize: 12, color: Colors.white)),
                  backgroundColor: const Color(0xFF7B3F61),
                ),
                if (dueDate != null)
                  Chip(
                    label: Text('Due: $dueDate',
                        style: GoogleFonts.montserrat(fontSize: 12)),
                    backgroundColor: const Color(0xFFDCC7AA).withOpacity(0.3),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Description
            if ((widget.item['description'] ?? '').toString().isNotEmpty) ...[
              Text(
                widget.item['description'],
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: const Color(0xFF6E6E6E),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Notes
            Text(
              'Notes',
              style: GoogleFonts.bodoniModa(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF7B3F61),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Add notes...',
                hintStyle: GoogleFonts.montserrat(fontSize: 13, color: const Color(0xFF6E6E6E)),
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
              ),
              onChanged: (value) {
                appState.updateChecklistItemNotes(widget.item['id'], value);
              },
            ),
            const SizedBox(height: 24),

            // Find vendors button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  // Navigate to the category page for this checklist item's category
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CategoryPageTemplate(
                        categoryName: category,
                        showOnlyLoved: false,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.search, color: Color(0xFF7B3F61)),
                label: Text(
                  'Find $category Vendors',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF7B3F61),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Color(0xFF7B3F61)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
