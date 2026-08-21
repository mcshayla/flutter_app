import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/amenity_icons.dart';
import '../utils/app_styles.dart';
import 'spec_card.dart';

/// Shared by the scroller and the grouped grid so a card is the same size
/// wherever it appears.
const double _cardHeight = 104;

/// How the confirmed amenities are laid out.
enum AmenityLayout {
  /// Pills that wrap onto as many lines as needed. The default, and what the
  /// widget tests exercise.
  wrap,

  /// Cards split into their `option_group` sub-sections, each with a heading.
  /// Used on wide layouts, where there is room to read the structure.
  grouped,

  /// A single sideways-scrolling strip of icon-over-label cards. Used on
  /// mobile, where a grouped list would push the rest of the page down.
  scroller,
}

/// Shows the amenities a vendor has confirmed, as icon + label.
///
/// Deliberately present-only. `filter_values` records what a vendor *selected*;
/// an amenity missing from it means "never filled in", not "doesn't have it".
/// Rendering a negative state for those would punish incomplete profiles and
/// tell couples something the data does not actually say.
///
/// The whole section disappears when nothing is confirmed — a bare "Amenities"
/// heading over an empty row reads as "this venue has none".
class AmenityRow extends StatelessWidget {
  /// The vendor's `filter_values` jsonb.
  final Map<String, dynamic> filterValues;

  /// `filter_options` rows for the amenities filter, in display order.
  final List<Map<String, dynamic>> optionRows;

  /// The filter group to render. Defaults to the Venue amenities group.
  final String filterKey;

  final String heading;

  final AmenityLayout layout;

  const AmenityRow({
    required this.filterValues,
    required this.optionRows,
    this.filterKey = 'venue_amenities',
    this.heading = 'Amenities',
    this.layout = AmenityLayout.wrap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final raw = filterValues[filterKey];
    final confirmed = raw is List
        ? raw.map((e) => e.toString()).toSet()
        : const <String>{};

    if (confirmed.isEmpty) return const SizedBox.shrink();

    // Follow the DB's display order, and skip anything the vendor selected
    // that is no longer an offered option.
    final present = optionRows
        .where((row) => confirmed.contains(row['option_value']))
        .toList();
    if (present.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeading(heading),
          const SizedBox(height: 14),
          switch (layout) {
            AmenityLayout.wrap => _buildWrap(present),
            AmenityLayout.grouped => _buildGrouped(present),
            AmenityLayout.scroller => _buildScroller(present),
          },
        ],
      ),
    );
  }

  // ------------------------------------------------------------------ wrap --

  Widget _buildWrap(List<Map<String, dynamic>> rows) => Wrap(
        spacing: 10,
        runSpacing: 10,
        children: rows.map(_pill).toList(),
      );

  // --------------------------------------------------------------- grouped --

  /// Preserves the DB display order of both the groups and the options inside
  /// them: [rows] arrives ordered, and LinkedHashMap keeps first-seen order.
  Widget _buildGrouped(List<Map<String, dynamic>> rows) {
    final byGroup = <String, List<Map<String, dynamic>>>{};
    for (final row in rows) {
      final group = (row['option_group'] as String?)?.trim();
      byGroup.putIfAbsent(group == null || group.isEmpty ? '' : group, () => [])
          .add(row);
    }

    final entries = byGroup.entries.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < entries.length; i++) ...[
          if (entries[i].key.isNotEmpty) ...[
            Text(
              entries[i].key.toUpperCase(),
              style: GoogleFonts.montserrat(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
                color: AppStyles.secondaryColor.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 8),
          ],
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: entries[i]
                .value
                .map((row) => _card(row, width: 116))
                .toList(),
          ),
          if (i != entries.length - 1) const SizedBox(height: 22),
        ],
      ],
    );
  }

  // -------------------------------------------------------------- scroller --

  Widget _buildScroller(List<Map<String, dynamic>> rows) => SizedBox(
        height: _cardHeight,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.zero,
          itemCount: rows.length,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (_, i) => _card(rows[i]),
        ),
      );

  /// A fixed-size tile so the strip scrolls at a steady rhythm — and, on wide
  /// layouts, so the cards tile into an even grid — regardless of how long
  /// each label is. The height must be explicit: inside a [Wrap] there is no
  /// parent to bound it, and the label below uses [Flexible].
  Widget _card(Map<String, dynamic> row, {double width = 96}) {
    final label = (row['option_label'] ?? row['option_value']).toString();
    final icon = amenityIcon(row['icon_name'] as String?) ?? amenityFallbackIcon;

    return Container(
      width: width,
      height: _cardHeight,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppStyles.accentColor.withValues(alpha: 0.6)),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppStyles.darkWords.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppStyles.accentColor.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 19, color: AppStyles.secondaryColor),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.montserrat(
                fontSize: 10.5,
                height: 1.25,
                fontWeight: FontWeight.w500,
                color: AppStyles.darkWords,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------ pill --

  Widget _pill(Map<String, dynamic> row) {
    final label = (row['option_label'] ?? row['option_value']).toString();
    final icon = amenityIcon(row['icon_name'] as String?) ?? amenityFallbackIcon;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppStyles.accentColor.withValues(alpha: 0.2),
        border: Border.all(color: AppStyles.accentColor),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppStyles.secondaryColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppStyles.secondaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
