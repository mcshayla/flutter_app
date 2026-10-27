import 'package:flutter/material.dart';
import '../services/plan_logic.dart';
import '../utils/app_styles.dart';
import 'stationery.dart';

/// The Plan tab's three screens as presentation widgets: data in, callbacks
/// out. ChecklistPage wires them to AppState; tests drive them directly.
///
/// Every panel has two layouts. Narrow (phones): the summary card scrolls
/// above the list. Wide (desktop, large tablets): the summary is a fixed
/// column beside the list.

// ------------------------------------------------------------------ shared

class _Split extends StatelessWidget {
  final Widget summary;
  final List<Widget> list;
  const _Split({required this.summary, required this.list});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final wide = AppStyles.isWide(c.maxWidth);
      final summaryBox = KeyedSubtree(key: const ValueKey('plan-summary'), child: summary);
      final listBox = Column(
        key: const ValueKey('plan-list'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: list,
      );
      if (!wide) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          children: [summaryBox, const SizedBox(height: 20), listBox],
        );
      }
      return Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppStyles.maxContentWidth),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(32, 28, 32, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 320, child: SingleChildScrollView(child: summaryBox)),
                const SizedBox(width: 36),
                Expanded(child: SingleChildScrollView(padding: const EdgeInsets.only(bottom: 40), child: listBox)),
              ],
            ),
          ),
        ),
      );
    });
  }
}

/// White card with the website's inset double hairline.
class _Card extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const _Card({required this.child, this.padding = const EdgeInsets.all(20)});

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppStyles.champagne)),
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: DecoratedBox(
            decoration: BoxDecoration(border: Border.all(color: AppStyles.champagne.withValues(alpha: 0.6))),
            child: Padding(padding: padding, child: child),
          ),
        ),
      );
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _Stat(this.value, this.label, {this.color = AppStyles.ink});

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: AppStyles.display(22, color: color)),
          const SizedBox(height: 2),
          Text(label.toUpperCase(), textAlign: TextAlign.center, style: AppStyles.eyebrow(size: 8.5, color: AppStyles.inkSoft)),
        ],
      );
}

class _Tag extends StatelessWidget {
  final String text;
  final Color fg;
  final Color? bg;
  final Color? border;
  const _Tag(this.text, {required this.fg, this.bg, this.border});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(color: bg, border: border == null ? null : Border.all(color: border!)),
        child: Text(text.toUpperCase(), style: AppStyles.eyebrow(size: 8, color: fg).copyWith(letterSpacing: 1.4)),
      );
}

class _GroupHeader extends StatelessWidget {
  final String label;
  final String trailing;
  final bool expanded;
  final VoidCallback? onTap;
  const _GroupHeader({required this.label, required this.trailing, this.expanded = true, this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppStyles.champagne))),
          child: Row(children: [
            Expanded(child: Text(label, style: AppStyles.display(18, color: AppStyles.plum, italic: true))),
            Text(trailing, style: AppStyles.body(12, color: AppStyles.inkSoft)),
            if (onTap != null) ...[
              const SizedBox(width: 6),
              Icon(expanded ? Icons.expand_less : Icons.expand_more, size: 18, color: AppStyles.plum),
            ],
          ]),
        ),
      );
}

class _Segmented extends StatelessWidget {
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;
  const _Segmented({required this.labels, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < labels.length; i++)
            InkWell(
              onTap: () => onChanged(i),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: i == selected ? AppStyles.plumInk : Colors.white,
                  border: Border.all(color: AppStyles.plumInk),
                ),
                child: Text(labels[i].toUpperCase(),
                    style: AppStyles.eyebrow(size: 9, color: i == selected ? Colors.white : AppStyles.plumInk)),
              ),
            ),
        ],
      );
}

// ------------------------------------------------------------------ countdown

class PlanCountdown extends StatelessWidget {
  final DateTime? weddingDate;
  final DateTime now;
  final VoidCallback onTap;
  const PlanCountdown({required this.weddingDate, required this.now, required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    final days = weddingDate == null ? null : daysBetween(now, weddingDate!);
    final label = countdownLabel(days);
    final match = RegExp(r'^(\d+) (.*)$').firstMatch(label);
    return Material(
      color: AppStyles.blush,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(children: [
            Eyebrow(weddingDate == null ? 'Your wedding' : longDate(weddingDate!), textAlign: TextAlign.center),
            const SizedBox(height: 4),
            if (match != null)
              Text.rich(TextSpan(children: [
                TextSpan(text: '${match.group(1)} ', style: AppStyles.display(24)),
                TextSpan(text: match.group(2), style: AppStyles.display(24, color: AppStyles.plum, italic: true)),
              ]))
            else
              Text(label, style: AppStyles.display(22, color: weddingDate == null ? AppStyles.plum : AppStyles.ink, italic: weddingDate == null)),
          ]),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ checklist

class ChecklistPanel extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final DateTime now;
  final void Function(Map<String, dynamic> item, bool completed) onToggle;
  final void Function(Map<String, dynamic> item) onOpen;
  final VoidCallback onAddTask;
  final VoidCallback onGenerate;

  const ChecklistPanel({
    required this.items,
    required this.now,
    required this.onToggle,
    required this.onOpen,
    required this.onAddTask,
    required this.onGenerate,
    super.key,
  });

  @override
  State<ChecklistPanel> createState() => _ChecklistPanelState();
}

class _ChecklistPanelState extends State<ChecklistPanel> {
  ChecklistView _view = ChecklistView.timeline;
  final Set<String> _collapsed = {'Done'};

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return _empty();

    final done = widget.items.where((i) => i['is_completed'] == true).length;
    final total = widget.items.length;
    final groups = groupChecklist(widget.items, _view, widget.now);

    final summary = _Card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Eyebrow('Your checklist'),
        const SizedBox(height: 8),
        Text('$done of $total tasks done', style: AppStyles.display(19)),
        const SizedBox(height: 10),
        ClipRect(
          child: SizedBox(
            height: 3,
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : done / total,
              backgroundColor: AppStyles.champagneLight,
              valueColor: const AlwaysStoppedAnimation(AppStyles.plum),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _Segmented(
          labels: const ['Timeline', 'Category'],
          selected: _view == ChecklistView.timeline ? 0 : 1,
          onChanged: (i) => setState(() => _view = i == 0 ? ChecklistView.timeline : ChecklistView.category),
        ),
        const SizedBox(height: 16),
        Wrap(spacing: 6, runSpacing: 6, children: [
          StationeryButton(label: 'Add task', icon: Icons.add, variant: StationeryVariant.plum, compact: true, onPressed: widget.onAddTask),
          StationeryButton(label: 'Regenerate', icon: Icons.auto_awesome_outlined, compact: true, onPressed: widget.onGenerate),
        ]),
      ]),
    );

    final list = <Widget>[];
    for (final g in groups) {
      final open = !_collapsed.contains(g.label);
      list.add(_GroupHeader(
        label: g.label,
        trailing: '${g.doneCount}/${g.items.length}',
        expanded: open,
        onTap: () => setState(() => open ? _collapsed.add(g.label) : _collapsed.remove(g.label)),
      ));
      if (open) list.addAll(g.items.map(_taskRow));
    }
    return _Split(summary: summary, list: list);
  }

  Widget _taskRow(Map<String, dynamic> item) {
    final doneTask = item['is_completed'] == true;
    final due = item['due_date'] is String ? DateTime.tryParse(item['due_date']) : null;
    final meta = [
      if (_view == ChecklistView.timeline && (item['category'] as String?)?.isNotEmpty == true) item['category'] as String,
      if (due != null) 'Due ${shortDate(due)}',
    ].join(' · ');
    return InkWell(
      onTap: () => widget.onOpen(item),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 11),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFEFE7DC)))),
        child: Row(children: [
          InkWell(
            key: ValueKey('task-check-${item['id']}'),
            onTap: () => widget.onToggle(item, !doneTask),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: doneTask ? AppStyles.plumInk : Colors.white,
                  border: Border.all(color: AppStyles.plumInk),
                ),
                child: doneTask ? const Icon(Icons.check, size: 13, color: Colors.white) : null,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                item['title'] as String? ?? '',
                style: AppStyles.body(14, weight: FontWeight.w500, color: doneTask ? AppStyles.inkSoft : AppStyles.ink)
                    .copyWith(decoration: doneTask ? TextDecoration.lineThrough : null),
              ),
              if (meta.isNotEmpty) Text(meta, style: AppStyles.body(11.5, color: AppStyles.inkSoft)),
            ]),
          ),
          if (isPastDue(item, widget.now)) ...[
            const SizedBox(width: 8),
            const _Tag('Past due', fg: AppStyles.error, border: AppStyles.error),
          ],
          const Icon(Icons.chevron_right, size: 18, color: AppStyles.champagne),
        ]),
      ),
    );
  }

  Widget _empty() => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Eyebrow('Your checklist'),
              const SizedBox(height: 10),
              Text('Every task, in the right order', textAlign: TextAlign.center, style: AppStyles.display(24)),
              const SizedBox(height: 12),
              const HeartRule(width: 180),
              const SizedBox(height: 12),
              Text(
                'Pick the vendors you need and we\'ll build a timeline of tasks counted back from your wedding date.',
                textAlign: TextAlign.center,
                style: AppStyles.body(14, color: AppStyles.inkSoft),
              ),
              const SizedBox(height: 20),
              StationeryButton(label: 'Generate my checklist', icon: Icons.auto_awesome_outlined, variant: StationeryVariant.plum, onPressed: widget.onGenerate),
              const SizedBox(height: 8),
              StationeryButton(label: 'Add a task myself', compact: true, onPressed: widget.onAddTask),
            ]),
          ),
        ),
      );
}

// ------------------------------------------------------------------ guests

class GuestPanel extends StatefulWidget {
  final List<Map<String, dynamic>> guests;
  final int headcount;
  final Map<String, int> statusCounts;
  final VoidCallback onAddGuest;
  final void Function(Map<String, dynamic> guest) onOpenGuest;
  final VoidCallback onRsvpLinks;
  final VoidCallback onMeals;
  final VoidCallback onExport;

  const GuestPanel({
    required this.guests,
    required this.headcount,
    required this.statusCounts,
    required this.onAddGuest,
    required this.onOpenGuest,
    required this.onRsvpLinks,
    required this.onMeals,
    required this.onExport,
    super.key,
  });

  @override
  State<GuestPanel> createState() => _GuestPanelState();
}

class _GuestPanelState extends State<GuestPanel> {
  String _query = '';
  String? _status;
  String? _group;

  static const _statuses = ['not_sent', 'invited', 'accepted', 'declined', 'maybe'];

  @override
  Widget build(BuildContext context) {
    final groups = widget.guests
        .map((g) => g['group_name'] as String? ?? '')
        .where((g) => g.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    final shown = widget.guests.where((g) {
      final name = '${g['first_name'] ?? ''} ${g['last_name'] ?? ''}'.toLowerCase();
      if (_query.isNotEmpty && !name.contains(_query.toLowerCase())) return false;
      if (_status != null && (g['rsvp_status'] ?? 'not_sent') != _status) return false;
      if (_group != null && g['group_name'] != _group) return false;
      return true;
    }).toList();

    final summary = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _Card(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Row(children: [
          Expanded(child: _Stat('${widget.headcount}', 'Guests')),
          Expanded(child: _Stat('${widget.statusCounts['accepted'] ?? 0}', 'Attending', color: AppStyles.plum)),
          Expanded(child: _Stat('${widget.statusCounts['declined'] ?? 0}', 'Declined')),
          Expanded(child: _Stat('${widget.statusCounts['invited'] ?? 0}', 'Waiting')),
        ]),
      ),
      const SizedBox(height: 12),
      Wrap(spacing: 6, runSpacing: 6, children: [
        StationeryButton(label: 'RSVP link', icon: Icons.link, compact: true, onPressed: widget.onRsvpLinks),
        StationeryButton(label: 'Meals', icon: Icons.restaurant_menu, compact: true, onPressed: widget.onMeals),
        StationeryButton(label: 'Export', icon: Icons.download_outlined, compact: true, onPressed: widget.onExport),
      ]),
      const SizedBox(height: 10),
      Align(
        alignment: Alignment.centerLeft,
        child: StationeryButton(label: 'Add guest', icon: Icons.person_add_alt, variant: StationeryVariant.plum, compact: true, onPressed: widget.onAddGuest),
      ),
    ]);

    final list = <Widget>[
      Row(children: [
        Expanded(
          child: TextField(
            onChanged: (v) => setState(() => _query = v),
            style: AppStyles.body(14),
            decoration: InputDecoration(
              hintText: 'Search guests',
              hintStyle: AppStyles.body(14, color: AppStyles.inkSoft),
              prefixIcon: const Icon(Icons.search, size: 18, color: AppStyles.plum),
              isDense: true,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              enabledBorder: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppStyles.goldLine)),
              focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppStyles.plum, width: 1.5)),
            ),
          ),
        ),
        _FilterMenu(
          tooltip: 'Filter by RSVP',
          icon: Icons.filter_list,
          active: _status != null,
          options: {null: 'All RSVPs', for (final s in _statuses) s: rsvpLabel(s)},
          onSelected: (v) => setState(() => _status = v),
        ),
        if (groups.isNotEmpty)
          _FilterMenu(
            tooltip: 'Filter by group',
            icon: Icons.groups_outlined,
            active: _group != null,
            options: {null: 'All groups', for (final g in groups) g: g},
            onSelected: (v) => setState(() => _group = v),
          ),
      ]),
      const SizedBox(height: 6),
      if (widget.guests.isEmpty)
        _emptyNote('Your guest list starts here', 'Add guests one by one, or share your RSVP link and let them add themselves.')
      else if (shown.isEmpty)
        _emptyNote('No matches', 'Try a different name or clear the filters.')
      else
        ...shown.map(_guestRow),
    ];

    return _Split(summary: summary, list: list);
  }

  Widget _guestRow(Map<String, dynamic> g) {
    final name = '${g['first_name'] ?? ''} ${g['last_name'] ?? ''}'.trim();
    final status = g['rsvp_status'] as String?;
    final plus = (g['plus_one_count'] as num?)?.toInt() ?? 0;
    final diet = (g['dietary_restrictions'] ?? '').toString().trim();
    final meta = [if ((g['group_name'] ?? '').toString().isNotEmpty) g['group_name'], if (diet.isNotEmpty) diet].join(' · ');
    final (Color fg, Color? bg, Color? border) = switch (status) {
      'accepted' => (Colors.white, AppStyles.plumInk, null),
      'declined' => (AppStyles.inkSoft, null, AppStyles.inkSoft),
      'invited' || 'maybe' => (AppStyles.plumInk, AppStyles.champagneLight, null),
      _ => (AppStyles.inkSoft, null, AppStyles.champagne),
    };
    return InkWell(
      onTap: () => widget.onOpenGuest(g),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFEFE7DC)))),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(child: Text(name.isEmpty ? 'Unnamed guest' : name, style: AppStyles.body(14, weight: FontWeight.w600))),
                if (plus > 0) ...[
                  const SizedBox(width: 6),
                  Text('+$plus', style: AppStyles.body(12, color: AppStyles.inkSoft)),
                ],
              ]),
              if (meta.isNotEmpty) Text(meta, style: AppStyles.body(11.5, color: AppStyles.inkSoft)),
            ]),
          ),
          _Tag(rsvpLabel(status), fg: fg, bg: bg, border: border),
        ]),
      ),
    );
  }
}

class _FilterMenu extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final bool active;
  final Map<String?, String> options;
  final ValueChanged<String?> onSelected;
  const _FilterMenu({required this.tooltip, required this.icon, required this.active, required this.options, required this.onSelected});

  @override
  Widget build(BuildContext context) => PopupMenuButton<String?>(
        tooltip: tooltip,
        icon: Icon(icon, color: active ? AppStyles.plum : AppStyles.inkSoft),
        onSelected: onSelected,
        itemBuilder: (_) => [
          for (final e in options.entries)
            PopupMenuItem<String?>(value: e.key, child: Text(e.value, style: AppStyles.body(14))),
        ],
      );
}

Widget _emptyNote(String title, String body) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 12),
      child: Column(children: [
        Text(title, textAlign: TextAlign.center, style: AppStyles.display(20)),
        const SizedBox(height: 6),
        Text(body, textAlign: TextAlign.center, style: AppStyles.body(13.5, color: AppStyles.inkSoft)),
      ]),
    );

// ------------------------------------------------------------------ budget

class BudgetPanel extends StatelessWidget {
  final double totalBudget;
  final List<Map<String, dynamic>> items;

  /// category -> vendor_id of the couple's YES in that category.
  final Map<String, String> yesByCategory;
  final VoidCallback onSetBudget;
  final VoidCallback onAddExpense;
  final void Function(Map<String, dynamic> item) onOpenItem;

  const BudgetPanel({
    required this.totalBudget,
    required this.items,
    required this.yesByCategory,
    required this.onSetBudget,
    required this.onAddExpense,
    required this.onOpenItem,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final s = BudgetSummary.from(totalBudget, items);
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final i in items) {
      grouped.putIfAbsent((i['category'] as String?) ?? 'Other', () => []).add(i);
    }

    final summary = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _Card(
        child: Column(children: [
          const Eyebrow('Total budget'),
          const SizedBox(height: 6),
          if (totalBudget > 0)
            InkWell(
              onTap: onSetBudget,
              child: Text(formatMoney(totalBudget), style: AppStyles.display(32)),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: StationeryButton(label: 'Set your budget', compact: true, onPressed: onSetBudget),
            ),
          const SizedBox(height: 12),
          _BudgetBar(spent: s.spentFraction, planned: s.plannedFraction, over: s.isOverBudget),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _Stat(formatMoney(s.planned), 'Planned')),
            Expanded(child: _Stat(formatMoney(s.spent), 'Spent', color: AppStyles.plum)),
            Expanded(child: _Stat(formatMoney(s.remaining), 'Remaining', color: s.isOverBudget ? AppStyles.error : AppStyles.ink)),
          ]),
          if (s.isOverBudget) ...[
            const SizedBox(height: 10),
            Text('Over budget', style: AppStyles.body(12.5, color: AppStyles.error, weight: FontWeight.w600)),
          ],
        ]),
      ),
      const SizedBox(height: 12),
      Align(
        alignment: Alignment.centerLeft,
        child: StationeryButton(label: 'Add expense', icon: Icons.add, variant: StationeryVariant.plum, compact: true, onPressed: onAddExpense),
      ),
    ]);

    final list = <Widget>[
      if (items.isEmpty)
        _emptyNote('Nothing added yet', 'Add expenses as you book. When you say YES to a vendor, you can add them here from their page.')
      else
        for (final e in grouped.entries) ...[
          _GroupHeader(
            label: e.key,
            trailing: '${formatMoney(BudgetSummary.from(0, e.value).spent)} of ${formatMoney(BudgetSummary.from(0, e.value).planned)}',
          ),
          ...e.value.map((i) => _itemRow(i)),
        ],
    ];

    return _Split(summary: summary, list: list);
  }

  Widget _itemRow(Map<String, dynamic> item) {
    final yes = isYesVendorItem(item, yesByCategory);
    final paid = item['is_paid'] == true;
    final amount = (item['actual_cost'] as num?) ?? (item['estimated_cost'] as num?) ?? 0;
    return InkWell(
      onTap: () => onOpenItem(item),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFEFE7DC)))),
        child: Row(children: [
          if (yes)
            Icon(Icons.diamond, key: ValueKey('yes-diamond-${item['id']}'), size: 16, color: AppStyles.plum)
          else
            Icon(paid ? Icons.check_circle : Icons.circle_outlined, size: 16, color: paid ? AppStyles.plum : AppStyles.goldLine),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item['item_name'] as String? ?? '', style: AppStyles.body(14, weight: FontWeight.w600)),
              Text([if (yes) 'Your YES', paid ? 'Paid' : 'Planned'].join(' · '), style: AppStyles.body(11.5, color: AppStyles.inkSoft)),
            ]),
          ),
          Text(formatMoney(amount), style: AppStyles.body(14, weight: FontWeight.w600).copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, size: 18, color: AppStyles.champagne),
        ]),
      ),
    );
  }
}

/// One thin bar: spent (plum) inside planned (rose) inside the total.
class _BudgetBar extends StatelessWidget {
  final double spent;
  final double planned;
  final bool over;
  const _BudgetBar({required this.spent, required this.planned, required this.over});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, c) => Container(
          height: 4,
          color: AppStyles.champagneLight,
          alignment: Alignment.centerLeft,
          child: Stack(children: [
            Container(width: c.maxWidth * planned, color: AppStyles.rose),
            Container(width: c.maxWidth * spent, color: over ? AppStyles.error : AppStyles.plum),
          ]),
        ),
      );
}
