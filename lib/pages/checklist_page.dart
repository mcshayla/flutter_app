import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../appstate.dart';
import 'checklist_item_detail.dart';
import 'budget_page.dart';
import 'guest_list_page.dart';

class ChecklistPage extends StatefulWidget {
  const ChecklistPage({super.key});

  @override
  State<ChecklistPage> createState() => _ChecklistPageState();
}

class _ChecklistPageState extends State<ChecklistPage> {
  String _viewMode = 'category'; // 'category' or 'timeline'
  String? _filterCategory;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        final items = appState.checklistItems;
        final progress = appState.checklistProgress;
        final completedCount = items.where((i) => i['is_completed'] == true).length;

        // Get unique categories
        final categories = items.map((i) => i['category'] as String? ?? 'Other').toSet().toList()..sort();

        // Filter items
        var displayItems = _filterCategory != null
            ? items.where((i) => i['category'] == _filterCategory).toList()
            : items;

        // Group items
        Map<String, List<Map<String, dynamic>>> grouped = {};
        if (_viewMode == 'category') {
          for (var item in displayItems) {
            final key = item['category'] as String? ?? 'Other';
            grouped.putIfAbsent(key, () => []).add(item);
          }
        } else {
          for (var item in displayItems) {
            final dueDate = item['due_date'] as String?;
            final key = dueDate != null ? _getTimelineLabel(dueDate) : 'No Due Date';
            grouped.putIfAbsent(key, () => []).add(item);
          }
        }

        return Scaffold(
          body: Column(
            children: [
              // Progress header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCC7AA).withOpacity(0.15),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Wedding Checklist',
                          style: GoogleFonts.bodoniModa(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF7B3F61),
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.account_balance_wallet_outlined,
                                  color: Color(0xFF7B3F61)),
                              onPressed: () {
                                Navigator.push(context,
                                    MaterialPageRoute(builder: (_) => const BudgetPage()));
                              },
                              tooltip: 'Budget',
                            ),
                            IconButton(
                              icon: const Icon(Icons.people_outline,
                                  color: Color(0xFF7B3F61)),
                              onPressed: () {
                                Navigator.push(context,
                                    MaterialPageRoute(builder: (_) => const GuestListPage()));
                              },
                              tooltip: 'Guest List',
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 10,
                        backgroundColor: const Color(0xFFDCC7AA).withOpacity(0.3),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF7B3F61)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$completedCount of ${items.length} tasks complete',
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        color: const Color(0xFF6E6E6E),
                      ),
                    ),
                  ],
                ),
              ),

              // Filter/view controls
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    // View toggle
                    ToggleButtons(
                      isSelected: [_viewMode == 'category', _viewMode == 'timeline'],
                      onPressed: (index) {
                        setState(() {
                          _viewMode = index == 0 ? 'category' : 'timeline';
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      selectedColor: Colors.white,
                      fillColor: const Color(0xFF7B3F61),
                      color: const Color(0xFF7B3F61),
                      constraints: const BoxConstraints(minHeight: 32, minWidth: 80),
                      textStyle: GoogleFonts.montserrat(fontSize: 11),
                      children: const [
                        Text('Category'),
                        Text('Timeline'),
                      ],
                    ),
                    const Spacer(),
                    // Category filter dropdown
                    if (_viewMode == 'category')
                      DropdownButton<String?>(
                        value: _filterCategory,
                        hint: Text('All', style: GoogleFonts.montserrat(fontSize: 12)),
                        underline: const SizedBox(),
                        items: [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Text('All', style: GoogleFonts.montserrat(fontSize: 12)),
                          ),
                          ...categories.map((c) => DropdownMenuItem(
                                value: c,
                                child: Text(c, style: GoogleFonts.montserrat(fontSize: 12)),
                              )),
                        ],
                        onChanged: (v) => setState(() => _filterCategory = v),
                      ),
                  ],
                ),
              ),

              // Task list
              Expanded(
                child: items.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.checklist, size: 64, color: const Color(0xFFDCC7AA)),
                            const SizedBox(height: 16),
                            Text(
                              'Set your wedding date to get\na personalized checklist!',
                              style: GoogleFonts.montserrat(
                                fontSize: 14,
                                color: const Color(0xFF6E6E6E),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: grouped.keys.length,
                        itemBuilder: (context, index) {
                          final groupName = grouped.keys.elementAt(index);
                          final groupItems = grouped[groupName]!;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                                child: Row(
                                  children: [
                                    Text(
                                      groupName,
                                      style: GoogleFonts.bodoniModa(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF7B3F61),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${groupItems.where((i) => i['is_completed'] == true).length}/${groupItems.length}',
                                      style: GoogleFonts.montserrat(
                                        fontSize: 12,
                                        color: const Color(0xFF6E6E6E),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ...groupItems.map((item) => _ChecklistItemTile(
                                    item: item,
                                    onToggle: (completed) {
                                      appState.toggleChecklistItem(item['id'], completed);
                                    },
                                    onTap: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ChecklistItemDetail(item: item),
                                        ),
                                      );
                                      // Refresh after returning
                                      await appState.loadChecklist();
                                    },
                                  )),
                            ],
                          );
                        },
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: const Color(0xFF7B3F61),
            onPressed: () => _showAddTaskDialog(context, appState),
            child: const Icon(Icons.add, color: Colors.white),
          ),
        );
      },
    );
  }

  String _getTimelineLabel(String dateStr) {
    final date = DateTime.tryParse(dateStr);
    if (date == null) return 'No Due Date';

    final now = DateTime.now();
    final diff = date.difference(now).inDays;

    if (diff < 0) return 'Overdue';
    if (diff <= 30) return 'This Month';
    if (diff <= 60) return 'Next Month';
    if (diff <= 90) return '2-3 Months';
    if (diff <= 180) return '3-6 Months';
    if (diff <= 365) return '6-12 Months';
    return '12+ Months';
  }

  void _showAddTaskDialog(BuildContext context, AppState appState) {
    final titleController = TextEditingController();
    String selectedCategory = 'Other';
    final categories = ['Venue', 'Catering', 'Photography', 'Flowers', 'Attire',
      'Music', 'Invitations', 'Decor', 'Transportation', 'Other'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Task', style: GoogleFonts.bodoniModa(color: const Color(0xFF7B3F61))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: 'Task name',
                labelStyle: GoogleFonts.montserrat(fontSize: 13),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedCategory,
              decoration: InputDecoration(
                labelText: 'Category',
                labelStyle: GoogleFonts.montserrat(fontSize: 13),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => selectedCategory = v ?? 'Other',
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.trim().isNotEmpty) {
                appState.addChecklistItem(titleController.text.trim(), selectedCategory);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7B3F61)),
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _ChecklistItemTile extends StatelessWidget {
  final Map<String, dynamic> item;
  final Function(bool) onToggle;
  final VoidCallback onTap;

  const _ChecklistItemTile({
    required this.item,
    required this.onToggle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = item['is_completed'] == true;
    final title = item['title'] as String? ?? '';
    final dueDate = item['due_date'] as String?;
    final isOverdue = dueDate != null &&
        DateTime.tryParse(dueDate)?.isBefore(DateTime.now()) == true &&
        !isCompleted;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: const Color(0xFFDCC7AA).withOpacity(0.3)),
          ),
        ),
        child: Row(
          children: [
            Checkbox(
              value: isCompleted,
              onChanged: (v) => onToggle(v ?? false),
              activeColor: const Color(0xFF7B3F61),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isCompleted ? const Color(0xFF6E6E6E) : const Color(0xFF3E3E3E),
                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  if (dueDate != null)
                    Text(
                      dueDate,
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        color: isOverdue ? Colors.red : const Color(0xFF6E6E6E),
                      ),
                    ),
                ],
              ),
            ),
            if (isOverdue)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Overdue',
                  style: GoogleFonts.montserrat(fontSize: 10, color: Colors.red),
                ),
              ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: Color(0xFFDCC7AA), size: 20),
          ],
        ),
      ),
    );
  }
}
