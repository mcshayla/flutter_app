import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/vendor_filter.dart';
import '../utils/app_styles.dart';

/// Lets a vendor answer the filter questions for their category.
///
/// Used by both the create form and the edit form. It exists as one widget
/// because the two pages had already drifted once: create wrote no
/// `filter_values` at all, so a vendor could finish signup and be invisible to
/// every filter until they went back and edited their profile.
///
/// Chips display `option_label` but store `option_value` — matching compares
/// the stable value, so relabelling an option never breaks a saved answer.
///
/// Range groups are skipped: they are answered by the numeric price/capacity
/// fields, which are real columns rather than `filter_values` entries.
class VendorFilterPicker extends StatelessWidget {
  /// `category_filters` rows for the chosen category, in display order.
  final List<Map<String, dynamic>> filterGroups;

  /// `filter_options` rows keyed by `filter_key`.
  final Map<String, List<Map<String, dynamic>>> optionsByKey;

  /// Current answers: `filter_key` -> selected `option_value`s.
  final Map<String, List<String>> selected;

  final void Function(String filterKey, List<String> values) onChanged;

  const VendorFilterPicker({
    required this.filterGroups,
    required this.optionsByKey,
    required this.selected,
    required this.onChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final chipGroups = filterGroups
        .where((g) => (g['filter_type'] as String?) != 'range')
        .toList();
    if (chipGroups.isEmpty) return const SizedBox.shrink();

    final rendered = <Widget>[];
    for (final def in chipGroups) {
      final key = def['filter_key'] as String?;
      if (key == null) continue;

      final groups = groupOptionsFor(def, optionsByKey[key] ?? const []);
      if (groups.isEmpty) continue;

      rendered.add(Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: _group(def, key, groups),
      ));
    }

    if (rendered.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rendered,
    );
  }

  Widget _group(
    Map<String, dynamic> def,
    String key,
    List<OptionGroup> groups,
  ) {
    final current = selected[key] ?? const <String>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          (def['filter_label'] ?? key).toString(),
          style: GoogleFonts.montserrat(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppStyles.secondaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: AppStyles.accentColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < groups.length; i++) ...[
                // A 16-option list like Amenities is unreadable as one blob;
                // the sub-headings come straight from filter_options.
                if (groups[i].title != null) ...[
                  if (i != 0) const SizedBox(height: 14),
                  Text(
                    groups[i].title!.toUpperCase(),
                    style: GoogleFonts.montserrat(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.1,
                      color: AppStyles.secondaryColor.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      groups[i].options.map((o) => _chip(key, o, current)).toList(),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _chip(String key, FilterOption option, List<String> current) {
    final isSelected = current.contains(option.value);

    return FilterChip(
      label: Text(
        option.label,
        style: GoogleFonts.montserrat(
          fontSize: 11,
          color: isSelected ? Colors.white : AppStyles.secondaryColor,
        ),
      ),
      selected: isSelected,
      onSelected: (nowSelected) {
        final next = List<String>.from(current);
        if (nowSelected) {
          if (!next.contains(option.value)) next.add(option.value);
        } else {
          next.remove(option.value);
        }
        onChanged(key, next);
      },
      selectedColor: AppStyles.secondaryColor,
      backgroundColor: AppStyles.accentColor.withValues(alpha: 0.2),
      checkmarkColor: Colors.white,
      side: BorderSide(
        color: isSelected ? AppStyles.secondaryColor : AppStyles.accentColor,
      ),
    );
  }
}
