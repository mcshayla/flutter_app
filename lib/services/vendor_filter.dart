/// Pure vendor filtering logic.
///
/// Deliberately depends on nothing but `dart:core` — no Flutter, no Supabase —
/// so it can be unit tested directly without a binding, a widget tree or a
/// network mock. Vendors are the raw `Map<String, dynamic>` rows returned by
/// `supabase.from('vendors').select()`.
///
/// `'Any'` in `vendor_state` / `vendor_county` is a vendor-side wildcard
/// meaning "serves anywhere". It matches every selection, and it is never
/// offered as a selectable option.
library;

const String _anywhere = 'Any';

/// An inclusive numeric band, e.g. a couple's budget or expected guest count.
///
/// Deliberately not Flutter's `RangeValues` so this library stays UI-free.
/// A `null` NumRange means "no preference"; a band covering the slider's full
/// extent is still a real constraint and excludes vendors with no value.
class NumRange {
  final int min;
  final int max;

  const NumRange(this.min, this.max);

  bool contains(int value) => value >= min && value <= max;

  /// Whether this band shares at least one value with `[otherMin, otherMax]`.
  bool overlaps(int? otherMin, int? otherMax) {
    final low = otherMin ?? -_unbounded;
    final high = otherMax ?? _unbounded;
    return low <= max && high >= min;
  }

  static const int _unbounded = 1 << 40;

  @override
  bool operator ==(Object other) =>
      other is NumRange && other.min == min && other.max == max;

  @override
  int get hashCode => Object.hash(min, max);

  @override
  String toString() => 'NumRange($min, $max)';
}

/// One selectable filter option, from a `filter_options` row.
class FilterOption {
  final String value;
  final String label;
  final String? iconName;

  const FilterOption({required this.value, required this.label, this.iconName});
}

/// A titled sub-section of options. [title] is null for ungrouped filters.
class OptionGroup {
  final String? title;
  final List<FilterOption> options;

  const OptionGroup({required this.title, required this.options});
}

int? _asInt(dynamic value) => value is num ? value.toInt() : null;

/// Everything a couple has narrowed by on a category page.
class VendorFilterSelection {
  final String? state;
  final String? county;

  /// filter_key -> chosen option values. OR within a key, AND across keys.
  final Map<String, Set<String>> tags;

  /// The couple's budget. Matched against the vendor's `starting_price`.
  final NumRange? priceBand;

  /// The couple's expected guest count. Overlapped with the venue's capacity.
  final NumRange? capacityBand;

  const VendorFilterSelection({
    this.state,
    this.county,
    this.tags = const {},
    this.priceBand,
    this.capacityBand,
  });

  bool get isEmpty =>
      state == null &&
      county == null &&
      priceBand == null &&
      capacityBand == null &&
      tags.values.every((s) => s.isEmpty);

  VendorFilterSelection copyWith({
    String? state,
    String? county,
    Map<String, Set<String>>? tags,
    NumRange? priceBand,
    NumRange? capacityBand,
    bool clearState = false,
    bool clearCounty = false,
    bool clearPriceBand = false,
    bool clearCapacityBand = false,
  }) {
    return VendorFilterSelection(
      state: clearState ? null : (state ?? this.state),
      county: clearCounty ? null : (county ?? this.county),
      tags: tags ?? this.tags,
      priceBand: clearPriceBand ? null : (priceBand ?? this.priceBand),
      capacityBand:
          clearCapacityBand ? null : (capacityBand ?? this.capacityBand),
    );
  }
}

/// The single entry point the UI should use: applies every active constraint.
List<Map<String, dynamic>> filterVendors(
  List<Map<String, dynamic>> vendors,
  VendorFilterSelection selection,
) {
  if (selection.isEmpty) return vendors;
  return vendors
      .where((v) =>
          matchesRegion(v, selection.state, selection.county) &&
          matchesTags(v, selection.tags) &&
          matchesPrice(v, selection.priceBand) &&
          matchesCapacity(v, selection.capacityBand))
      .toList();
}

/// Reads a column that may hold either a list or a single scalar.
List<String> _asList(dynamic value) {
  if (value == null) return const [];
  if (value is List) return value.map((e) => e.toString()).toList();
  return [value.toString()];
}

bool _servesRegion(dynamic column, String selected) {
  final values = _asList(column);
  return values.contains(_anywhere) || values.contains(selected);
}

/// Whether [vendor] serves the selected state and county.
///
/// A null selection is "no preference" and always matches. A vendor with no
/// value for a selected field does not match.
bool matchesRegion(
  Map<String, dynamic> vendor,
  String? selectedState,
  String? selectedCounty,
) {
  bool matchesState = selectedState == null;
  if (!matchesState && vendor['vendor_state'] != null) {
    matchesState = _servesRegion(vendor['vendor_state'], selectedState);
  }

  bool matchesCounty = selectedCounty == null;
  if (!matchesCounty && vendor['vendor_county'] != null) {
    matchesCounty = _servesRegion(vendor['vendor_county'], selectedCounty);
  }

  return matchesState && matchesCounty;
}

/// Every state offered in the state dropdown, sorted.
///
/// `'Any'` is excluded: it is a vendor-side wildcard, not somewhere a couple
/// can get married.
List<String> availableStates(List<Map<String, dynamic>> items) {
  final states = <String>{};
  for (final item in items) {
    states.addAll(_selectable(item['vendor_state']));
  }
  return states.toList()..sort();
}

/// Every county offered in the county dropdown, sorted.
///
/// When [selectedState] is set, only vendors serving that state (or `'Any'`)
/// contribute counties.
List<String> availableCounties(
  List<Map<String, dynamic>> items,
  String? selectedState,
) {
  final counties = <String>{};
  for (final item in items) {
    if (selectedState != null &&
        item['vendor_state'] != null &&
        !_servesRegion(item['vendor_state'], selectedState)) {
      continue;
    }
    counties.addAll(_selectable(item['vendor_county']));
  }
  return counties.toList()..sort();
}

/// Whether [vendor] satisfies the chip selections in [selected].
///
/// Semantics: OR within a filter group, AND across groups. A vendor that has
/// not answered an active filter is excluded — an unanswered filter means
/// "unknown", and a couple filtering for a dance floor should not be shown
/// venues that never said whether they have one.
bool matchesTags(
  Map<String, dynamic> vendor,
  Map<String, Set<String>> selected,
) {
  final raw = vendor['filter_values'];
  final values = raw is Map<String, dynamic> ? raw : const <String, dynamic>{};

  for (final entry in selected.entries) {
    if (entry.value.isEmpty) continue;
    final answered = _asList(values[entry.key]);
    if (answered.isEmpty) return false;
    if (!entry.value.any(answered.contains)) return false;
  }
  return true;
}

/// Whether the vendor's `starting_price` falls inside the couple's budget
/// [band].
///
/// A null [band] is "no preference" and matches everyone. Once a band is set,
/// a vendor who has not published a starting price cannot be shown to satisfy
/// it, so they are excluded.
bool matchesPrice(Map<String, dynamic> vendor, NumRange? band) {
  if (band == null) return true;
  final price = _asInt(vendor['starting_price']);
  if (price == null) return false;
  return band.contains(price);
}

/// Whether the venue's capacity range overlaps the couple's expected guest
/// count [band].
///
/// Overlap, not containment: a venue holding 50-300 is a real option for a
/// couple expecting 200-400 guests. A missing bound is treated as open-ended
/// on that side; a venue with no capacity at all is excluded once a band is
/// set.
bool matchesCapacity(Map<String, dynamic> vendor, NumRange? band) {
  if (band == null) return true;
  final min = _asInt(vendor['capacity_min']);
  final max = _asInt(vendor['capacity_max']);
  if (min == null && max == null) return false;
  return band.overlaps(min, max);
}

/// Groups `filter_options` rows into their display sub-sections.
///
/// Rows are assumed to arrive ordered by `display_order`. Section order
/// follows first appearance, so the DB controls it.
List<OptionGroup> groupOptions(List<Map<String, dynamic>> rows) {
  final byTitle = <String?, List<FilterOption>>{};
  for (final row in rows) {
    final title = row['option_group'] as String?;
    byTitle.putIfAbsent(title, () => []).add(
          FilterOption(
            value: row['option_value'].toString(),
            label: (row['option_label'] ?? row['option_value']).toString(),
            iconName: row['icon_name'] as String?,
          ),
        );
  }
  return [
    for (final entry in byTitle.entries)
      OptionGroup(title: entry.key, options: entry.value),
  ];
}

/// Options for one filter group, preferring `filter_options` rows and falling
/// back to the legacy `category_filters.options` array for categories that
/// have not been migrated yet.
List<OptionGroup> groupOptionsFor(
  Map<String, dynamic> filterDef,
  List<Map<String, dynamic>> rows,
) {
  if (rows.isNotEmpty) return groupOptions(rows);

  final legacy = filterDef['options'];
  if (legacy is! List || legacy.isEmpty) return const [];

  return [
    OptionGroup(
      title: null,
      options: [
        for (final option in legacy)
          FilterOption(value: option.toString(), label: option.toString()),
      ],
    ),
  ];
}

/// Whether [vendor] has stored coordinates and can be placed on the map
/// without geocoding.
bool hasCoordinates(Map<String, dynamic> vendor) =>
    vendor['latitude'] is num && vendor['longitude'] is num;

/// The vendors that can be drawn as map markers right now.
///
/// Also drops vendors with no usable `vendor_id`: markers are keyed by id, so
/// those would collide on the empty-string key and silently overwrite each
/// other down to a single pin.
List<Map<String, dynamic>> vendorsWithCoordinates(
  List<Map<String, dynamic>> vendors,
) {
  return vendors.where((v) {
    final id = v['vendor_id'];
    return id is String && id.isNotEmpty && hasCoordinates(v);
  }).toList();
}

/// The values of [column] a couple may actually pick: non-blank, not `'Any'`.
Iterable<String> _selectable(dynamic column) => _asList(column)
    .map((value) => value.trim())
    .where((value) => value.isNotEmpty && value != _anywhere);

/// Filters [items] by state and county. Returns [items] itself when neither
/// is selected, so the common unfiltered path allocates nothing.
List<Map<String, dynamic>> filterByRegion(
  List<Map<String, dynamic>> items,
  String? selectedState,
  String? selectedCounty,
) {
  if (selectedState == null && selectedCounty == null) return items;
  return items
      .where((item) => matchesRegion(item, selectedState, selectedCounty))
      .toList();
}
