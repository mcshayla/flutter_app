import 'package:flutter_test/flutter_test.dart';
import 'package:say_yes/services/plan_logic.dart';

void main() {
  final today = DateTime(2026, 10, 26, 15, 30);

  group('countdownLabel', () {
    test('no date yet asks for one', () {
      expect(countdownLabel(null), 'Set your wedding date');
    });
    test('counts days to go', () {
      expect(countdownLabel(229), '229 days to go');
      expect(countdownLabel(2), '2 days to go');
    });
    test('one day uses the singular', () {
      expect(countdownLabel(1), '1 day to go');
    });
    test('the day itself', () {
      expect(countdownLabel(0), 'Today is the day');
    });
    test('after the wedding', () {
      expect(countdownLabel(-3), 'Just married');
    });
  });

  group('daysBetween', () {
    test('counts calendar days, ignoring the time of day', () {
      expect(daysBetween(today, DateTime(2027, 6, 12)), 229);
      expect(daysBetween(today, DateTime(2026, 10, 27, 1)), 1);
      expect(daysBetween(today, DateTime(2026, 10, 26)), 0);
    });
  });

  group('longDate', () {
    test('spells out the weekday and month', () {
      expect(longDate(DateTime(2027, 6, 12)), 'Saturday, June 12, 2027');
    });
  });

  group('formatMoney', () {
    test('adds a dollar sign and thousands separators, no cents', () {
      expect(formatMoney(25000), r'$25,000');
      expect(formatMoney(3200.4), r'$3,200');
      expect(formatMoney(0), r'$0');
      expect(formatMoney(1234567), r'$1,234,567');
    });
    test('negative amounts keep the sign in front', () {
      expect(formatMoney(-450), r'-$450');
    });
  });

  group('isPastDue', () {
    test('an open task due before today is past due', () {
      expect(isPastDue({'due_date': '2026-08-01', 'is_completed': false}, today), isTrue);
    });
    test('a finished task is never past due', () {
      expect(isPastDue({'due_date': '2026-08-01', 'is_completed': true}, today), isFalse);
    });
    test('a task due today is not past due yet', () {
      expect(isPastDue({'due_date': '2026-10-26', 'is_completed': false}, today), isFalse);
    });
    test('no due date, or an unreadable one, is not past due', () {
      expect(isPastDue({'is_completed': false}, today), isFalse);
      expect(isPastDue({'due_date': 'soon', 'is_completed': false}, today), isFalse);
    });
  });

  group('groupChecklist', () {
    final items = [
      {'id': 1, 'title': 'Book transportation', 'category': 'Transportation', 'due_date': '2026-11-20', 'is_completed': false},
      {'id': 2, 'title': 'Start dress shopping', 'category': 'Attire', 'due_date': '2026-08-12', 'is_completed': false},
      {'id': 3, 'title': 'Book your venue', 'category': 'Venue', 'due_date': '2026-06-12', 'is_completed': true},
      {'id': 4, 'title': 'Write vows', 'category': 'Other', 'is_completed': false},
      {'id': 5, 'title': 'Order invitations', 'category': 'Invitations', 'due_date': '2027-01-10', 'is_completed': false},
      {'id': 6, 'title': 'Mail invitations', 'category': 'Invitations', 'due_date': '2027-03-12', 'is_completed': false},
    ];

    test('timeline puts past-due work first and undated tasks last', () {
      final groups = groupChecklist(items, ChecklistView.timeline, today);
      // Buckets are calendar months from today: Nov is next month, Jan is
      // 3 months out, Mar is 5.
      expect(groups.map((g) => g.label).toList(), [
        'Past due',
        'Next month',
        'In 2–3 months',
        'In 4–6 months',
        'No due date',
        'Done',
      ]);
      expect(groups.first.items.single['id'], 2);
    });

    test('finished tasks collect under Done in the timeline', () {
      final groups = groupChecklist(items, ChecklistView.timeline, today);
      expect(groups.firstWhere((g) => g.label == 'Done').items.single['id'], 3);
    });

    test('category view is alphabetical with Other last', () {
      final groups = groupChecklist(items, ChecklistView.category, today);
      expect(groups.map((g) => g.label).toList(),
          ['Attire', 'Invitations', 'Transportation', 'Venue', 'Other']);
    });

    test('tasks inside a group are ordered by due date, undated last', () {
      final groups = groupChecklist(items, ChecklistView.category, today);
      final inv = groups.firstWhere((g) => g.label == 'Invitations');
      expect(inv.items.map((i) => i['id']).toList(), [5, 6]);
    });

    test('each group knows how many of its tasks are done', () {
      final groups = groupChecklist(items, ChecklistView.category, today);
      final venue = groups.firstWhere((g) => g.label == 'Venue');
      expect(venue.doneCount, 1);
      expect(venue.items.length, 1);
    });
  });

  group('BudgetSummary', () {
    final items = [
      {'item_name': 'Venue', 'estimated_cost': 3200, 'actual_cost': 3200, 'is_paid': true},
      {'item_name': 'Dress', 'estimated_cost': 1500, 'actual_cost': 1500, 'is_paid': true},
      {'item_name': 'Catering', 'estimated_cost': 6500},
      {'item_name': 'Photographer', 'estimated_cost': 3800},
      {'item_name': 'Florals', 'estimated_cost': 1800, 'actual_cost': null},
    ];

    test('adds up planned and spent; remaining is the total minus spent', () {
      final s = BudgetSummary.from(25000, items);
      expect(s.planned, 16800);
      expect(s.spent, 4700);
      expect(s.remaining, 20300);
      expect(s.isOverBudget, isFalse);
    });

    test('bar fractions are shares of the total budget', () {
      final s = BudgetSummary.from(25000, items);
      expect(s.spentFraction, closeTo(0.188, 0.001));
      expect(s.plannedFraction, closeTo(0.672, 0.001));
    });

    test('fractions stay between 0 and 1, and over budget is flagged', () {
      final s = BudgetSummary.from(4000, items);
      expect(s.isOverBudget, isTrue);
      expect(s.spentFraction, 1);
      expect(s.plannedFraction, 1);
    });

    test('no total budget yet means empty bars instead of dividing by zero', () {
      final s = BudgetSummary.from(0, items);
      expect(s.spentFraction, 0);
      expect(s.plannedFraction, 0);
      expect(s.isOverBudget, isFalse);
    });
  });

  group('guest RSVP status', () {
    test('labels read the way couples talk', () {
      expect(rsvpLabel('accepted'), 'Attending');
      expect(rsvpLabel('declined'), 'Not attending');
      expect(rsvpLabel('invited'), 'Waiting');
      expect(rsvpLabel('maybe'), 'Maybe');
      expect(rsvpLabel('not_sent'), 'Not sent');
      expect(rsvpLabel(null), 'Not sent');
    });
  });

  group('isYesVendorItem', () {
    test('a budget line linked to a vendor that is a YES gets the diamond', () {
      expect(isYesVendorItem({'vendor_id': 'v1'}, {'Venue': 'v1'}), isTrue);
    });
    test('other lines do not', () {
      expect(isYesVendorItem({'vendor_id': 'v2'}, {'Venue': 'v1'}), isFalse);
      expect(isYesVendorItem({'item_name': 'Dress'}, {'Venue': 'v1'}), isFalse);
    });
  });
}
