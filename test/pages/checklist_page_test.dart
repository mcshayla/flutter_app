import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:say_yes/appstate.dart';
import 'package:say_yes/pages/checklist_page.dart';
import 'package:say_yes/widgets/plan_panels.dart';

Future<void> _initSupabase() async {
  SharedPreferences.setMockInitialValues({});
  try {
    await Supabase.initialize(url: 'https://test.supabase.co', anonKey: 'test_anon_key_for_unit_tests');
  } catch (_) {}
}

/// AppState clears itself when Supabase reports "no user" on startup, so the
/// plan data is filled in after that first auth event has gone by.
void fillPlan(AppState s) {
  s.weddingProfile = {'wedding_date': '2099-06-12'};
  s.checklistItems = [
    {'id': 't1', 'title': 'Book your venue', 'category': 'Venue', 'due_date': '2099-01-01', 'is_completed': false},
  ];
  s.guests = [
    {'id': 'g1', 'first_name': 'Anna', 'last_name': 'Parker', 'rsvp_status': 'accepted'},
  ];
  s.budgetItems = [
    {'id': 'b1', 'item_name': 'Venue deposit', 'category': 'Venue', 'estimated_cost': 1000},
  ];
  // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
  s.notifyListeners();
}

AppState stateWithPlan() => AppState();

Future<void> pumpPlan(WidgetTester tester, AppState state, double width) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ChangeNotifierProvider<AppState>.value(
    value: state,
    child: const MaterialApp(home: ChecklistPage()),
  ));
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
  fillPlan(state);
  await tester.pump();
}

void main() {
  setUpAll(_initSupabase);

  for (final width in [390.0, 1280.0]) {
    group('Plan tab at ${width.toInt()}px', () {
      testWidgets('shows the wedding countdown above the tabs', (tester) async {
        await pumpPlan(tester, stateWithPlan(), width);
        expect(find.byType(PlanCountdown), findsOneWidget);
        expect(find.textContaining('JUNE 12, 2099'), findsOneWidget);
      });

      testWidgets('has Checklist, Guests and Budget tabs and no round + buttons', (tester) async {
        await pumpPlan(tester, stateWithPlan(), width);
        expect(find.text('CHECKLIST'), findsOneWidget);
        expect(find.text('GUESTS'), findsWidgets);
        expect(find.text('BUDGET'), findsOneWidget);
        expect(find.byType(FloatingActionButton), findsNothing);
      });

      testWidgets('opens on the checklist with the couple\'s tasks', (tester) async {
        await pumpPlan(tester, stateWithPlan(), width);
        expect(find.byType(ChecklistPanel), findsOneWidget);
        expect(find.text('Book your venue'), findsOneWidget);
      });

      testWidgets('the Guests and Budget tabs show the real lists', (tester) async {
        await pumpPlan(tester, stateWithPlan(), width);
        await tester.tap(find.text('GUESTS').first);
        await tester.pumpAndSettle();
        expect(find.byType(GuestPanel), findsOneWidget);
        expect(find.text('Anna Parker'), findsOneWidget);

        await tester.tap(find.text('BUDGET'));
        await tester.pumpAndSettle();
        expect(find.byType(BudgetPanel), findsOneWidget);
        expect(find.text('Venue deposit'), findsOneWidget);
      });
    });
  }
}
