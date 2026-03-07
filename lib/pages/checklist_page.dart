import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../appstate.dart';
import 'checklist_item_detail.dart';
import 'budget_page.dart';
import 'guest_list_page.dart';
import 'wedding_profile_setup.dart';

class ChecklistPage extends StatefulWidget {
  const ChecklistPage({super.key});

  @override
  State<ChecklistPage> createState() => _ChecklistPageState();
}

class _ChecklistPageState extends State<ChecklistPage> {
  String _viewMode = 'category'; // 'category' or 'timeline'
  String? _filterCategory;
  // Only groups in this set are expanded (default all collapsed)
  final Set<String> _expandedCategories = {};

  static const _knownCategories = [
    'Planning', 'Venue', 'Catering', 'Photography', 'Flowers',
    'Attire', 'Music', 'Invitations', 'Decor', 'Transportation',
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        final items = appState.checklistItems;
        final progress = appState.checklistProgress;
        final completedCount = items.where((i) => i['is_completed'] == true).length;

        final categories = items.map((i) => i['category'] as String? ?? 'Other').toSet().toList()..sort();

        var displayItems = _filterCategory != null
            ? items.where((i) => i['category'] == _filterCategory).toList()
            : items;

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
                        Row(
                          children: [
                            Text(
                              'Wedding Checklist',
                              style: GoogleFonts.bodoniModa(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF7B3F61),
                              ),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(Icons.calendar_today, size: 18, color: Color(0xFF7B3F61)),
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => WeddingProfileSetup(
                                      existingProfile: appState.weddingProfile,
                                    ),
                                  ),
                                );
                                await appState.loadWeddingProfile();
                                await appState.loadChecklist();
                              },
                              tooltip: 'Edit Wedding Date',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
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
                              'No checklist yet!',
                              style: GoogleFonts.bodoniModa(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF7B3F61),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Set your wedding date to get started,\nor tap the wand to generate tasks.',
                              style: GoogleFonts.montserrat(
                                fontSize: 13,
                                color: const Color(0xFF6E6E6E),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => WeddingProfileSetup(
                                      existingProfile: appState.weddingProfile,
                                    ),
                                  ),
                                );
                                await appState.loadWeddingProfile();
                                await appState.loadChecklist();
                              },
                              icon: const Icon(Icons.calendar_today, color: Colors.white, size: 18),
                              label: Text(
                                'Set Wedding Date',
                                style: GoogleFonts.montserrat(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF7B3F61),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: grouped.keys.length,
                        itemBuilder: (context, index) {
                          final groupName = grouped.keys.elementAt(index);
                          final groupItems = grouped[groupName]!;
                          final isExpanded = _expandedCategories.contains(groupName);
                          final doneCount = groupItems.where((i) => i['is_completed'] == true).length;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    if (_expandedCategories.contains(groupName)) {
                                      _expandedCategories.remove(groupName);
                                    } else {
                                      _expandedCategories.add(groupName);
                                    }
                                  });
                                },
                                child: Padding(
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
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFDCC7AA).withOpacity(0.3),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          '$doneCount/${groupItems.length}',
                                          style: GoogleFonts.montserrat(
                                            fontSize: 11,
                                            color: const Color(0xFF6E6E6E),
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      Icon(
                                        isExpanded ? Icons.expand_less : Icons.expand_more,
                                        color: const Color(0xFF7B3F61),
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (isExpanded)
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
          floatingActionButton: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton.small(
                heroTag: 'generate_checklist',
                backgroundColor: const Color(0xFF7B3F61),
                onPressed: () => _showGenerateSheet(context, appState),
                tooltip: 'Generate Checklist',
                child: const Icon(Icons.auto_fix_high, color: Colors.white),
              ),
              const SizedBox(height: 10),
              FloatingActionButton(
                heroTag: 'add_task',
                backgroundColor: const Color(0xFF7B3F61),
                onPressed: () => _showAddTaskDialog(context, appState),
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ],
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

  void _showGenerateSheet(BuildContext context, AppState appState) async {
    final weddingDateStr = appState.weddingProfile?['wedding_date'] as String?;
    if (weddingDateStr == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Set your wedding date first')),
      );
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const WeddingProfileSetup()),
      );
      await appState.loadWeddingProfile();
      await appState.loadChecklist();
      return;
    }

    final Set<String> selectedCategories = Set.from(_knownCategories);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (_, setSheetState) {
          final allSelected = selectedCategories.length == _knownCategories.length;
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  'Build Your Checklist',
                  style: GoogleFonts.bodoniModa(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF7B3F61),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose the categories to include',
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    color: const Color(0xFF6E6E6E),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Select All',
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF3E3E3E),
                      ),
                    ),
                    Switch(
                      value: allSelected,
                      activeColor: const Color(0xFF7B3F61),
                      onChanged: (v) {
                        setSheetState(() {
                          if (v) {
                            selectedCategories.addAll(_knownCategories);
                          } else {
                            selectedCategories.clear();
                          }
                        });
                      },
                    ),
                  ],
                ),
                const Divider(),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: _knownCategories
                        .map((cat) => CheckboxListTile(
                              title: Text(
                                cat,
                                style: GoogleFonts.montserrat(fontSize: 14),
                              ),
                              value: selectedCategories.contains(cat),
                              activeColor: const Color(0xFF7B3F61),
                              dense: true,
                              onChanged: (v) {
                                setSheetState(() {
                                  if (v == true) {
                                    selectedCategories.add(cat);
                                  } else {
                                    selectedCategories.remove(cat);
                                  }
                                });
                              },
                            ))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: selectedCategories.isEmpty
                        ? null
                        : () async {
                            Navigator.pop(sheetCtx);
                            final date = DateTime.parse(weddingDateStr);
                            await appState.initializeChecklistWithCategories(
                              date,
                              selectedCategories.toList(),
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7B3F61),
                      disabledBackgroundColor: const Color(0xFFDCC7AA),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'Generate',
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context, AppState appState) {
    final titleController = TextEditingController();
    String selectedCategory = 'Other';
    DateTime? selectedDate;
    final categories = [
      'Venue', 'Catering', 'Photography', 'Flowers', 'Attire',
      'Music', 'Invitations', 'Decor', 'Transportation', 'Other'
    ];

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (_, setDialogState) => AlertDialog(
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
                onChanged: (v) => setDialogState(() => selectedCategory = v ?? 'Other'),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                    builder: (context, child) => Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.light(
                          primary: Color(0xFF7B3F61),
                          onPrimary: Colors.white,
                        ),
                      ),
                      child: child!,
                    ),
                  );
                  if (picked != null) {
                    setDialogState(() => selectedDate = picked);
                  }
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFDCC7AA)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16, color: Color(0xFF7B3F61)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          selectedDate != null
                              ? '${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}'
                              : 'Due date (optional)',
                          style: GoogleFonts.montserrat(
                            fontSize: 13,
                            color: selectedDate != null
                                ? const Color(0xFF3E3E3E)
                                : const Color(0xFF6E6E6E),
                          ),
                        ),
                      ),
                      if (selectedDate != null)
                        GestureDetector(
                          onTap: () => setDialogState(() => selectedDate = null),
                          child: const Icon(Icons.close, size: 16, color: Color(0xFF6E6E6E)),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.trim().isNotEmpty) {
                  appState.addChecklistItem(
                    titleController.text.trim(),
                    selectedCategory,
                    dueDate: selectedDate?.toIso8601String().split('T')[0],
                  );
                  Navigator.pop(dialogCtx);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7B3F61)),
              child: const Text('Add', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
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
