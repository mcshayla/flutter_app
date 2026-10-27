import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_styles.dart';
import '../widgets/plan_panels.dart';
import 'package:provider/provider.dart';
import '../appstate.dart';
import '../widgets/category_selection_sheet.dart' show showCategorySelectionSheet;
import 'checklist_item_detail.dart';
import 'budget_page.dart';
import 'guest_list_page.dart';
import 'wedding_profile_setup.dart';

class ChecklistPage extends StatefulWidget {
  const ChecklistPage({super.key});

  @override
  State<ChecklistPage> createState() => _ChecklistPageState();
}

class _ChecklistPageState extends State<ChecklistPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _editWeddingDate(AppState appState) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WeddingProfileSetup(existingProfile: appState.weddingProfile),
      ),
    );
    await appState.loadWeddingProfile();
    await appState.loadChecklist();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        final dateStr = appState.weddingProfile?['wedding_date'] as String?;
        return Scaffold(
          backgroundColor: AppStyles.cream,
          body: Column(
            children: [
              PlanCountdown(
                weddingDate: dateStr == null ? null : DateTime.tryParse(dateStr),
                now: DateTime.now(),
                onTap: () => _editWeddingDate(appState),
              ),
              Material(
                color: Colors.white,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: TabBar(
                      controller: _tabController,
                      indicatorColor: AppStyles.plum,
                      indicatorWeight: 2,
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelColor: AppStyles.plum,
                      unselectedLabelColor: AppStyles.inkSoft,
                      labelStyle: AppStyles.eyebrow(size: 10.5),
                      unselectedLabelStyle: AppStyles.eyebrow(size: 10.5, color: AppStyles.inkSoft),
                      dividerColor: AppStyles.champagne,
                      tabs: const [
                        Tab(text: 'CHECKLIST'),
                        Tab(text: 'GUESTS'),
                        Tab(text: 'BUDGET'),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    ChecklistPanel(
                      items: appState.checklistItems,
                      now: DateTime.now(),
                      onToggle: (item, completed) => appState.toggleChecklistItem(item['id'], completed),
                      onOpen: (item) async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ChecklistItemDetail(item: item)),
                        );
                        await appState.loadChecklist();
                      },
                      onAddTask: () => _showAddTaskDialog(context, appState),
                      onGenerate: () => _showGenerateSheet(context, appState),
                    ),
                    const GuestListPage(embedded: true),
                    const BudgetPage(embedded: true),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showGenerateSheet(BuildContext context, AppState appState) async {
    var weddingDateStr =
        appState.weddingProfile?['wedding_date'] as String?;
    if (weddingDateStr == null) {
      await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => WeddingProfileSetup(
                existingProfile: appState.weddingProfile)),
      );
      await appState.loadWeddingProfile();
      weddingDateStr = appState.weddingProfile?['wedding_date'] as String?;
      if (weddingDateStr == null) return;
    }

    final hasExisting = appState.checklistItems.isNotEmpty;

    if (hasExisting) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Regenerate Checklist?',
              style:
                  GoogleFonts.bodoniModa(color: const Color(0xFF7B3F61))),
          content: Text(
            'Regenerating will replace all existing tasks. Custom tasks and notes will be lost.',
            style: GoogleFonts.montserrat(
                fontSize: 14, color: const Color(0xFF3E3E3E)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7B3F61)),
              child: const Text('Continue',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    if (!context.mounted) return;
    final categories = await showCategorySelectionSheet(
      context,
      categories: appState.categoryNames,
      isRegenerate: hasExisting,
    );

    if (categories == null || categories.isEmpty) return;

    final date = DateTime.parse(weddingDateStr);
    if (hasExisting) {
      await appState.deleteAllChecklistItems();
    }
    await appState.initializeChecklistWithCategories(date, categories);
  }

  void _showAddTaskDialog(BuildContext context, AppState appState) {
    final titleController = TextEditingController();
    String selectedCategory = 'Other';
    DateTime? selectedDate;
    final categories = [...appState.categoryNames, 'Other'];

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (_, setDialogState) => AlertDialog(
          title: Text('Add Task',
              style:
                  GoogleFonts.bodoniModa(color: const Color(0xFF7B3F61))),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Task name',
                  labelStyle: GoogleFonts.montserrat(fontSize: 13),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Category',
                  labelStyle: GoogleFonts.montserrat(fontSize: 13),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                items: categories
                    .map((c) =>
                        DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) =>
                    setDialogState(() => selectedCategory = v ?? 'Other'),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now()
                        .add(const Duration(days: 365 * 5)),
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFDCC7AA)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          size: 16, color: Color(0xFF7B3F61)),
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
                          onTap: () =>
                              setDialogState(() => selectedDate = null),
                          child: const Icon(Icons.close,
                              size: 16, color: Color(0xFF6E6E6E)),
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
                    dueDate: selectedDate
                        ?.toIso8601String()
                        .split('T')[0],
                  );
                  Navigator.pop(dialogCtx);
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7B3F61)),
              child: const Text('Add',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
