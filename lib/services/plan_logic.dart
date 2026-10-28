/// Pure logic behind the Plan tab (checklist, guest list, budget).
///
/// No Flutter or Supabase imports, so it is unit tested directly. Rows are the
/// raw `Map<String, dynamic>` records AppState loads from Supabase.
library;

// ---------------------------------------------------------------- countdown

/// Whole calendar days from [from] to [to], ignoring the time of day.
int daysBetween(DateTime from, DateTime to) {
  final a = DateTime.utc(from.year, from.month, from.day);
  final b = DateTime.utc(to.year, to.month, to.day);
  return b.difference(a).inDays;
}

String countdownLabel(int? daysToGo) {
  if (daysToGo == null) return 'Set your wedding date';
  if (daysToGo < 0) return 'Just married';
  if (daysToGo == 0) return 'Today is the day';
  if (daysToGo == 1) return '1 day to go';
  return '$daysToGo days to go';
}

const _weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
const _months = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];
const _shortMonths = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

/// "Saturday, June 12, 2027"
String longDate(DateTime d) => '${_weekdays[d.weekday - 1]}, ${_months[d.month - 1]} ${d.day}, ${d.year}';

/// "Jun 12, 2027"
String shortDate(DateTime d) => '${_shortMonths[d.month - 1]} ${d.day}, ${d.year}';

// ---------------------------------------------------------------- money

/// "$25,000" — whole dollars, which is how couples think about a budget.
String formatMoney(num amount) {
  final whole = amount.round();
  final digits = whole.abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write(',');
    buf.write(digits[i]);
  }
  return '${whole < 0 ? '-' : ''}\$$buf';
}

double _num(dynamic v) => v is num ? v.toDouble() : 0;

// ---------------------------------------------------------------- checklist

enum ChecklistView { timeline, category }

class ChecklistGroup {
  final String label;
  final List<Map<String, dynamic>> items;
  const ChecklistGroup(this.label, this.items);

  int get doneCount => items.where((i) => i['is_completed'] == true).length;
}

DateTime? _due(Map<String, dynamic> item) {
  final raw = item['due_date'];
  return raw is String ? DateTime.tryParse(raw) : null;
}

bool isPastDue(Map<String, dynamic> item, DateTime now) {
  if (item['is_completed'] == true) return false;
  final due = _due(item);
  return due != null && daysBetween(now, due) < 0;
}

const _pastDue = 'Past due';
const _noDate = 'No due date';
const _done = 'Done';
const _timelineOrder = [
  _pastDue, 'This month', 'Next month', 'In 2–3 months', 'In 4–6 months',
  'In 7–12 months', 'A year or more', _noDate, _done,
];

String _timelineBucket(Map<String, dynamic> item, DateTime now) {
  if (item['is_completed'] == true) return _done;
  final due = _due(item);
  if (due == null) return _noDate;
  if (isPastDue(item, now)) return _pastDue;
  final months = (due.year - now.year) * 12 + due.month - now.month;
  if (months <= 0) return 'This month';
  if (months == 1) return 'Next month';
  if (months <= 3) return 'In 2–3 months';
  if (months <= 6) return 'In 4–6 months';
  if (months <= 12) return 'In 7–12 months';
  return 'A year or more';
}

int _byDue(Map<String, dynamic> a, Map<String, dynamic> b) {
  final da = _due(a), db = _due(b);
  if (da == null && db == null) return 0;
  if (da == null) return 1;
  if (db == null) return -1;
  return da.compareTo(db);
}

/// Groups tasks for display. Timeline: past due first, then by month, then
/// undated, then done. Category: alphabetical, with "Other" last.
List<ChecklistGroup> groupChecklist(
  List<Map<String, dynamic>> items,
  ChecklistView view,
  DateTime now,
) {
  final map = <String, List<Map<String, dynamic>>>{};
  for (final item in items) {
    final key = view == ChecklistView.timeline
        ? _timelineBucket(item, now)
        : ((item['category'] as String?)?.trim().isNotEmpty == true ? item['category'] as String : 'Other');
    map.putIfAbsent(key, () => []).add(item);
  }
  final keys = map.keys.toList();
  if (view == ChecklistView.timeline) {
    keys.sort((a, b) => _timelineOrder.indexOf(a).compareTo(_timelineOrder.indexOf(b)));
  } else {
    keys.sort((a, b) {
      if (a == 'Other') return 1;
      if (b == 'Other') return -1;
      return a.toLowerCase().compareTo(b.toLowerCase());
    });
  }
  return [for (final k in keys) ChecklistGroup(k, map[k]!..sort(_byDue))];
}

// ---------------------------------------------------------------- budget

class BudgetSummary {
  final double total;
  final double planned;
  final double spent;
  const BudgetSummary(this.total, this.planned, this.spent);

  factory BudgetSummary.from(double total, List<Map<String, dynamic>> items) {
    var planned = 0.0, spent = 0.0;
    for (final i in items) {
      planned += _num(i['estimated_cost']);
      spent += _num(i['actual_cost']);
    }
    return BudgetSummary(total, planned, spent);
  }

  /// Matches the app's existing rule: what is left of the total after money
  /// actually spent.
  double get remaining => total - spent;
  bool get isOverBudget => total > 0 && spent > total;
  double get spentFraction => total <= 0 ? 0 : (spent / total).clamp(0, 1).toDouble();
  double get plannedFraction => total <= 0 ? 0 : (planned / total).clamp(0, 1).toDouble();
}

/// A budget line for a vendor the couple said YES to.
bool isYesVendorItem(Map<String, dynamic> item, Map<String, String> yesByCategory) {
  final id = item['vendor_id'];
  return id is String && id.isNotEmpty && yesByCategory.values.contains(id);
}

// ---------------------------------------------------------------- guests

String rsvpLabel(String? status) => switch (status) {
      'accepted' => 'Attending',
      'declined' => 'Not attending',
      'invited' => 'Waiting',
      'maybe' => 'Maybe',
      _ => 'Not sent',
    };
