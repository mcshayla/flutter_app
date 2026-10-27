/// Decides what goes where on a vendor's page, for every vendor type.
///
/// Each vendor type defines its own filters in `category_filters` (+
/// `filter_options`). Rather than a page design per type, every filter lands
/// in one of three slots:
///
///  * **At a glance** – the numbers couples check first: starting price, and
///    guest capacity for types that filter by it.
///  * **Details** – choice filters whose options have no icon (venue type,
///    setting, catering policy, flower style...).
///  * **What's included** – choice filters whose options carry an icon,
///    grouped by `option_group`; the first three are also the highlights.
///
/// A filter added for a new vendor type shows up on its pages with no app
/// update. Unanswered filters are omitted, never shown as "None".
library;

import 'plan_logic.dart' show formatMoney;

class GlanceItem {
  final String value;
  final String label;
  const GlanceItem(this.value, this.label);
}

class DetailItem {
  final String label;
  final String value;
  const DetailItem(this.label, this.value);
}

class IncludedItem {
  final String label;
  final String? iconName;
  const IncludedItem(this.label, this.iconName);
}

class IncludedGroup {
  final String? title;
  final List<IncludedItem> items;
  const IncludedGroup(this.title, this.items);
}

class VendorSlots {
  final List<GlanceItem> glance;
  final List<DetailItem> details;
  final List<IncludedGroup> included;
  const VendorSlots({required this.glance, required this.details, required this.included});

  List<IncludedItem> get highlights => included.expand((g) => g.items).take(3).toList();
  bool get isEmpty => glance.isEmpty && details.isEmpty && included.isEmpty;
}

String? formatCapacity(int? min, int? max) {
  if (min == null && max == null) return null;
  if (min == null) return 'Up to $max';
  if (max == null) return '$min+';
  if (min == max) return '$min';
  return '$min–$max';
}

String? glancePrice(num? startingPrice, String priceText) {
  if (startingPrice != null) return formatMoney(startingPrice);
  final t = priceText.trim();
  if (t.isEmpty || t == 'Unknown') return null;
  return t;
}

List<String> _answers(dynamic raw) {
  if (raw == null) return const [];
  if (raw is List) return raw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
  final s = raw.toString();
  return s.isEmpty ? const [] : [s];
}

VendorSlots buildVendorSlots({
  required List<Map<String, dynamic>> filterGroups,
  required Map<String, List<Map<String, dynamic>>> optionsByKey,
  required Map<String, dynamic> filterValues,
  num? startingPrice,
  String priceText = '',
  int? capacityMin,
  int? capacityMax,
}) {
  final glance = <GlanceItem>[];
  final price = glancePrice(startingPrice, priceText);
  if (price != null) glance.add(GlanceItem(price, 'Starting price'));

  final hasCapacityFilter = filterGroups.any((g) =>
      g['filter_type'] == 'range' && (g['filter_key'] as String? ?? '').contains('capacity'));
  final capacity = formatCapacity(capacityMin, capacityMax);
  if (hasCapacityFilter && capacity != null) glance.add(GlanceItem(capacity, 'Guests'));

  final details = <DetailItem>[];
  final included = <IncludedGroup>[];

  for (final group in filterGroups) {
    if (group['filter_type'] == 'range') continue;
    final key = group['filter_key'] as String?;
    if (key == null) continue;
    final answered = _answers(filterValues[key]);
    if (answered.isEmpty) continue;

    final rows = optionsByKey[key] ?? const [];
    final label = (group['filter_label'] ?? key).toString();

    // Resolve to display labels in the database's display order. Answers that
    // no longer match an option are still shown, so a renamed option never
    // silently erases a vendor's answer.
    final known = <String>{};
    final picked = <Map<String, dynamic>>[];
    for (final row in rows) {
      final v = row['option_value'].toString();
      known.add(v);
      if (answered.contains(v)) picked.add(row);
    }
    final orphans = answered.where((a) => !known.contains(a)).toList();

    final hasIcons = rows.any((r) => r['icon_name'] != null);
    if (hasIcons) {
      final byGroup = <String?, List<IncludedItem>>{};
      for (final row in picked) {
        byGroup.putIfAbsent(row['option_group'] as String?, () => []).add(
              IncludedItem((row['option_label'] ?? row['option_value']).toString(), row['icon_name'] as String?),
            );
      }
      if (orphans.isNotEmpty) {
        byGroup.putIfAbsent(null, () => []).addAll(orphans.map((o) => IncludedItem(o, null)));
      }
      byGroup.forEach((title, items) => included.add(IncludedGroup(title, items)));
    } else {
      final legacy = group['options'] is List ? (group['options'] as List).map((e) => e.toString()).toList() : const <String>[];
      final labels = rows.isNotEmpty
          ? [...picked.map((r) => (r['option_label'] ?? r['option_value']).toString()), ...orphans]
          : [
              ...legacy.where(answered.contains),
              ...answered.where((a) => !legacy.contains(a)),
            ];
      details.add(DetailItem(label, labels.join(' · ')));
    }
  }

  return VendorSlots(glance: glance, details: details, included: included);
}

/// Photos for the mosaic further down the page. The first photo already leads
/// the page, so it is skipped when there are enough others.
List<String> mosaicImages(List<String> images) {
  if (images.length < 3) return const [];
  if (images.length >= 4) return images.sublist(1, 4);
  return images.sublist(0, 3);
}

/// The newest review with written words, set large as a pull quote.
Map<String, dynamic>? featuredReview(List<Map<String, dynamic>> reviews) {
  final written = reviews.where((r) => (r['comment'] ?? '').toString().trim().isNotEmpty).toList();
  if (written.isEmpty) return null;
  written.sort((a, b) => (b['date'] ?? '').toString().compareTo((a['date'] ?? '').toString()));
  return written.first;
}
