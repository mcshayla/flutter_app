import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:say_yes/widgets/plan_panels.dart';

final now = DateTime(2026, 10, 26, 12);

/// Pumps [child] in a screen of the given width so layout can be checked.
Future<void> pumpAt(WidgetTester tester, double width, Widget child, {double height = 1000}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
  await tester.pump();
}

List<Map<String, dynamic>> tasks() => [
      {'id': 'a', 'title': 'Start dress shopping', 'category': 'Attire', 'due_date': '2026-08-12', 'is_completed': false},
      {'id': 'b', 'title': 'Book your venue', 'category': 'Venue', 'due_date': '2026-06-12', 'is_completed': true},
      {'id': 'c', 'title': 'Send save-the-dates', 'category': 'Invitations', 'due_date': '2026-11-12', 'is_completed': false},
    ];

void main() {
  group('PlanCountdown', () {
    testWidgets('shows the wedding date and days to go', (tester) async {
      await pumpAt(tester, 390, PlanCountdown(weddingDate: DateTime(2027, 6, 12), now: now, onTap: () {}));
      expect(find.text('SATURDAY, JUNE 12, 2027'), findsOneWidget);
      expect(find.text('229 days to go'), findsOneWidget);
    });

    testWidgets('the blush band spans the full width of the screen', (tester) async {
      await pumpAt(tester, 1280, Column(children: [
        PlanCountdown(weddingDate: DateTime(2027, 6, 12), now: now, onTap: () {}),
      ]));
      expect(tester.getSize(find.byType(PlanCountdown)).width, 1280);
    });

    testWidgets('without a date it asks for one, and tapping opens the date setup', (tester) async {
      var taps = 0;
      await pumpAt(tester, 390, PlanCountdown(weddingDate: null, now: now, onTap: () => taps++));
      expect(find.text('Set your wedding date'), findsOneWidget);
      await tester.tap(find.byType(PlanCountdown));
      expect(taps, 1);
    });
  });

  group('ChecklistPanel', () {
    Widget panel({
      List<Map<String, dynamic>>? items,
      void Function(Map<String, dynamic>, bool)? onToggle,
      VoidCallback? onAddTask,
      VoidCallback? onGenerate,
    }) =>
        ChecklistPanel(
          items: items ?? tasks(),
          now: now,
          onToggle: onToggle ?? (_, __) {},
          onOpen: (_) {},
          onAddTask: onAddTask ?? () {},
          onGenerate: onGenerate ?? () {},
        );

    testWidgets('shows progress as tasks done out of the total', (tester) async {
      await pumpAt(tester, 390, panel());
      expect(find.text('1 of 3 tasks done'), findsOneWidget);
    });

    testWidgets('marks open tasks that are past their due date', (tester) async {
      await pumpAt(tester, 390, panel());
      expect(find.text('Start dress shopping'), findsOneWidget);
      expect(find.text('PAST DUE'), findsOneWidget);
    });

    testWidgets('checking a task reports it as completed', (tester) async {
      Map<String, dynamic>? toggled;
      bool? value;
      await pumpAt(tester, 390, panel(onToggle: (i, v) {
        toggled = i;
        value = v;
      }));
      await tester.tap(find.byKey(const ValueKey('task-check-c')));
      expect(toggled?['id'], 'c');
      expect(value, isTrue);
    });

    testWidgets('switches between timeline and category groups', (tester) async {
      await pumpAt(tester, 390, panel());
      expect(find.text('Past due'), findsOneWidget);
      await tester.tap(find.text('CATEGORY'));
      await tester.pump();
      expect(find.text('Past due'), findsNothing);
      expect(find.text('Attire'), findsWidgets);
    });

    testWidgets('has labeled Add task and Regenerate buttons instead of round icons', (tester) async {
      var add = 0, gen = 0;
      await pumpAt(tester, 390, panel(onAddTask: () => add++, onGenerate: () => gen++));
      await tester.tap(find.text('ADD TASK'));
      await tester.tap(find.text('REGENERATE'));
      expect(add, 1);
      expect(gen, 1);
      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('empty state offers to generate a checklist', (tester) async {
      var gen = 0;
      await pumpAt(tester, 390, panel(items: const [], onGenerate: () => gen++));
      await tester.tap(find.text('GENERATE MY CHECKLIST'));
      expect(gen, 1);
    });

    testWidgets('on a phone the progress sits above the tasks', (tester) async {
      await pumpAt(tester, 390, panel());
      final summary = tester.getRect(find.byKey(const ValueKey('plan-summary')));
      final list = tester.getRect(find.byKey(const ValueKey('plan-list')));
      expect(summary.bottom, lessThanOrEqualTo(list.top + 1));
    });

    testWidgets('on desktop the progress sits beside the tasks', (tester) async {
      await pumpAt(tester, 1280, panel());
      final summary = tester.getRect(find.byKey(const ValueKey('plan-summary')));
      final list = tester.getRect(find.byKey(const ValueKey('plan-list')));
      expect(summary.right, lessThanOrEqualTo(list.left + 1));
      expect(summary.top, closeTo(list.top, 40));
    });
  });

  group('GuestPanel', () {
    final guests = [
      {'id': 'g1', 'first_name': 'Anna', 'last_name': 'Parker', 'group_name': "Bride's family", 'rsvp_status': 'accepted', 'plus_one_count': 1},
      {'id': 'g2', 'first_name': 'Marcus', 'last_name': 'Lee', 'group_name': "Groom's friends", 'rsvp_status': 'invited'},
      {'id': 'g3', 'first_name': 'June', 'last_name': 'Ortega', 'group_name': "Groom's family", 'rsvp_status': 'declined', 'dietary_restrictions': 'Vegetarian'},
    ];
    Widget panel({VoidCallback? onRsvp, VoidCallback? onMeals, VoidCallback? onExport, VoidCallback? onAdd}) => GuestPanel(
          guests: guests,
          headcount: 4,
          statusCounts: const {'accepted': 1, 'declined': 1, 'invited': 1},
          onAddGuest: onAdd ?? () {},
          onOpenGuest: (_) {},
          onRsvpLinks: onRsvp ?? () {},
          onMeals: onMeals ?? () {},
          onExport: onExport ?? () {},
        );

    testWidgets('shows headcount and RSVP totals', (tester) async {
      await pumpAt(tester, 390, panel());
      expect(find.text('4'), findsOneWidget);
      expect(find.text('GUESTS'), findsOneWidget);
      expect(find.text('ATTENDING'), findsWidgets);
      expect(find.text('WAITING'), findsWidgets);
    });

    testWidgets('RSVP link, meals and export are labeled buttons', (tester) async {
      var r = 0, m = 0, e = 0;
      await pumpAt(tester, 390, panel(onRsvp: () => r++, onMeals: () => m++, onExport: () => e++));
      await tester.tap(find.text('RSVP LINK'));
      await tester.tap(find.text('MEALS'));
      await tester.tap(find.text('EXPORT'));
      expect([r, m, e], [1, 1, 1]);
    });

    testWidgets('each guest shows their group and RSVP status', (tester) async {
      await pumpAt(tester, 390, panel());
      expect(find.text('Anna Parker'), findsOneWidget);
      expect(find.textContaining("Bride's family"), findsOneWidget);
      expect(find.text('+1'), findsOneWidget);
      expect(find.text('NOT ATTENDING'), findsOneWidget);
    });

    testWidgets('search narrows the list by name', (tester) async {
      await pumpAt(tester, 390, panel());
      await tester.enterText(find.byType(TextField), 'mar');
      await tester.pump();
      expect(find.text('Marcus Lee'), findsOneWidget);
      expect(find.text('Anna Parker'), findsNothing);
    });

    testWidgets('Add guest is a labeled button', (tester) async {
      var add = 0;
      await pumpAt(tester, 390, panel(onAdd: () => add++));
      await tester.tap(find.text('ADD GUEST'));
      expect(add, 1);
    });

    testWidgets('on desktop the totals sit beside the list', (tester) async {
      await pumpAt(tester, 1280, panel());
      final summary = tester.getRect(find.byKey(const ValueKey('plan-summary')));
      final list = tester.getRect(find.byKey(const ValueKey('plan-list')));
      expect(summary.right, lessThanOrEqualTo(list.left + 1));
    });
  });

  group('BudgetPanel', () {
    final items = [
      {'id': 'b1', 'item_name': 'The Barn at Wall Brothers', 'category': 'Venue', 'estimated_cost': 3200, 'actual_cost': 3200, 'is_paid': true, 'vendor_id': 'v1'},
      {'id': 'b2', 'item_name': 'Catering', 'category': 'Catering', 'estimated_cost': 6500},
    ];
    Widget panel({double total = 25000, VoidCallback? onSet, VoidCallback? onAdd}) => BudgetPanel(
          totalBudget: total,
          items: items,
          yesByCategory: const {'Venue': 'v1'},
          onSetBudget: onSet ?? () {},
          onAddExpense: onAdd ?? () {},
          onOpenItem: (_) {},
        );

    testWidgets('shows the total with planned, spent and remaining', (tester) async {
      await pumpAt(tester, 390, panel());
      expect(find.text(r'$25,000'), findsOneWidget);
      expect(find.text(r'$9,700'), findsOneWidget); // planned
      expect(find.text(r'$3,200'), findsWidgets); // spent, and the venue line
      expect(find.text(r'$21,800'), findsOneWidget); // remaining
    });

    testWidgets('marks lines for YES vendors with the diamond', (tester) async {
      await pumpAt(tester, 390, panel());
      expect(find.byKey(const ValueKey('yes-diamond-b1')), findsOneWidget);
      expect(find.byKey(const ValueKey('yes-diamond-b2')), findsNothing);
    });

    testWidgets('with no total yet, tapping the card sets one', (tester) async {
      var set = 0;
      await pumpAt(tester, 390, panel(total: 0, onSet: () => set++));
      await tester.tap(find.text('SET YOUR BUDGET'));
      expect(set, 1);
    });

    testWidgets('flags spending over the total', (tester) async {
      await pumpAt(tester, 390, panel(total: 3000));
      expect(find.text('Over budget'), findsOneWidget);
    });

    testWidgets('Add expense is a labeled button', (tester) async {
      var add = 0;
      await pumpAt(tester, 390, panel(onAdd: () => add++));
      await tester.tap(find.text('ADD EXPENSE'));
      expect(add, 1);
    });

    testWidgets('on desktop the summary sits beside the expenses', (tester) async {
      await pumpAt(tester, 1280, panel());
      final summary = tester.getRect(find.byKey(const ValueKey('plan-summary')));
      final list = tester.getRect(find.byKey(const ValueKey('plan-list')));
      expect(summary.right, lessThanOrEqualTo(list.left + 1));
    });
  });
}
