import 'package:flutter/material.dart';

import 'amenity_row.dart';
import 'spec_card.dart';

/// Everything a vendor has actually told us about itself, rendered from the
/// generic filter system rather than from hardcoded per-category fields.
///
/// Any new filter group seeded into `category_filters` + `filter_options`
/// shows up here automatically — adding "Cuisine" to Catering is an insert,
/// not a deploy. That is the whole reason the taxonomy was normalized.
///
/// Two kinds of group are rendered differently:
///  * groups whose options carry an `icon_name` are *amenity-like* and get the
///    iconic card treatment (a sideways strip on mobile, a grouped grid on
///    web);
///  * everything else is a specification — a label over its values, set in
///    text, so the two never compete for attention.
///
/// Present-only throughout: a group the vendor left blank is omitted, not
/// shown as "None". A profile that is 30% filled should look sparse, not wrong.
class VendorDetailsSection extends StatelessWidget {
  /// The vendor's `filter_values` jsonb.
  final Map<String, dynamic> filterValues;

  /// `category_filters` rows for this vendor's category, in display order.
  final List<Map<String, dynamic>> filterGroups;

  /// `filter_options` rows keyed by `filter_key`.
  final Map<String, List<Map<String, dynamic>>> optionsByKey;

  /// Core facts (price, location, address, contacts) shown above the
  /// filter-derived specs *in the same card*, so the page has one block of
  /// facts rather than two competing ones.
  final List<SpecEntry> leadingEntries;

  /// Wide layouts group amenities and lay specs out in columns; narrow ones
  /// scroll the amenities sideways and stack the specs.
  final bool isWide;

  const VendorDetailsSection({
    required this.filterValues,
    required this.filterGroups,
    required this.optionsByKey,
    this.leadingEntries = const [],
    this.isWide = false,
    super.key,
  });

  /// The values a vendor selected for [group], resolved to their display
  /// labels. Falls back to the raw stored string for groups still using the
  /// legacy `category_filters.options` array, which has no label mapping.
  List<String> _labelsFor(Map<String, dynamic> group) {
    final key = group['filter_key'] as String?;
    if (key == null) return const [];

    final raw = filterValues[key];
    final selected = raw is List
        ? raw.map((e) => e.toString()).toList()
        : raw == null
            ? const <String>[]
            : [raw.toString()];
    if (selected.isEmpty) return const [];

    final rows = optionsByKey[key] ?? const [];
    // Keep the DB's display order rather than the order the vendor happened to
    // tick the boxes in.
    if (rows.isEmpty) return selected;

    final ordered = <String>[];
    for (final row in rows) {
      if (selected.contains(row['option_value'])) {
        ordered.add((row['option_label'] ?? row['option_value']).toString());
      }
    }
    // Anything stored that no longer maps to an option still gets shown, so a
    // renamed option does not silently erase a vendor's answer.
    final known = rows.map((r) => r['option_value'].toString()).toSet();
    ordered.addAll(selected.where((v) => !known.contains(v)));
    return ordered;
  }

  /// A group is amenity-like when its options carry icons.
  bool _isAmenityGroup(String key) =>
      (optionsByKey[key] ?? const []).any((r) => r['icon_name'] != null);

  @override
  Widget build(BuildContext context) {
    // Range groups are backed by numeric columns, not filter_values, so they
    // have nothing to contribute here.
    final chipGroups = filterGroups
        .where((g) => (g['filter_type'] as String?) != 'range')
        .toList();

    final specs = <SpecEntry>[...leadingEntries];
    final amenityGroups = <Map<String, dynamic>>[];

    for (final group in chipGroups) {
      final key = group['filter_key'] as String?;
      if (key == null) continue;

      if (_isAmenityGroup(key)) {
        if (_labelsFor(group).isNotEmpty) amenityGroups.add(group);
        continue;
      }
      final labels = _labelsFor(group);
      if (labels.isEmpty) continue;
      specs.add(SpecEntry(
        (group['filter_label'] ?? key).toString(),
        labels.join('  ·  '),
      ));
    }

    if (specs.isEmpty && amenityGroups.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SpecCard(entries: specs, isWide: isWide),
        for (final group in amenityGroups)
          AmenityRow(
            filterValues: filterValues,
            optionRows: optionsByKey[group['filter_key']] ?? const [],
            filterKey: group['filter_key'] as String,
            heading: (group['filter_label'] ?? 'Amenities').toString(),
            layout: isWide ? AmenityLayout.grouped : AmenityLayout.scroller,
          ),
      ],
    );
  }
}
