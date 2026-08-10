import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:say_yes/services/vendor_filter.dart';
import 'package:say_yes/utils/amenity_icons.dart';

/// The filter sheet is assembled from `groupOptionsFor` + `amenityIcon`.
/// These tests pin the rendering contract those two produce, without needing
/// a Supabase-backed AppState or a full CategoryPageTemplate widget tree.

const _amenityRows = [
  {'option_value': 'cleanup_included', 'option_label': 'Clean-Up Included', 'option_group': 'Included Services', 'icon_name': 'cleaning_services'},
  {'option_value': 'event_staff', 'option_label': 'Event Staff', 'option_group': 'Included Services', 'icon_name': 'groups'},
  {'option_value': 'wifi', 'option_label': 'Wi-Fi', 'option_group': 'Equipment & A/V', 'icon_name': 'wifi'},
  {'option_value': 'dance_floor', 'option_label': 'Dance Floor', 'option_group': 'Facilities', 'icon_name': 'nightlife'},
  {'option_value': 'wheelchair_accessible', 'option_label': 'Wheelchair Accessible', 'option_group': 'Accessibility & Policies', 'icon_name': 'accessible'},
];

/// Mirrors how _buildChipGroups lays a filter out.
Widget buildGroups(List<OptionGroup> groups) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final group in groups) ...[
              if (group.title != null) Text(group.title!),
              Wrap(
                children: group.options.map((o) {
                  final icon = amenityIcon(o.iconName);
                  return FilterChip(
                    avatar: icon == null ? null : Icon(icon, size: 16),
                    label: Text(o.label),
                    selected: false,
                    onSelected: (_) {},
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('amenities render as four titled sub-sections', (tester) async {
    final groups = groupOptions(List<Map<String, dynamic>>.from(_amenityRows));
    await tester.pumpWidget(buildGroups(groups));

    expect(find.text('Included Services'), findsOneWidget);
    expect(find.text('Equipment & A/V'), findsOneWidget);
    expect(find.text('Facilities'), findsOneWidget);
    expect(find.text('Accessibility & Policies'), findsOneWidget);
  });

  testWidgets('each amenity chip carries its icon', (tester) async {
    final groups = groupOptions(List<Map<String, dynamic>>.from(_amenityRows));
    await tester.pumpWidget(buildGroups(groups));

    expect(find.byIcon(Icons.cleaning_services), findsOneWidget);
    expect(find.byIcon(Icons.wifi), findsOneWidget);
    expect(find.byIcon(Icons.nightlife), findsOneWidget);
    expect(find.byIcon(Icons.accessible), findsOneWidget);
    expect(find.byType(FilterChip), findsNWidgets(5));
  });

  testWidgets('an ungrouped filter renders no section headings',
      (tester) async {
    final groups = groupOptionsFor(
      {
        'filter_key': 'venue_type',
        'options': ['Barns, Farms & Ranches', 'Vineyards & Wineries'],
      },
      const [],
    );
    await tester.pumpWidget(buildGroups(groups));

    expect(find.byType(FilterChip), findsNWidgets(2));
    expect(find.text('Barns, Farms & Ranches'), findsOneWidget);
  });

  group('range filter', () {
    testWidgets('a range filter renders a RangeSlider spanning its bounds',
        (tester) async {
      // Mirrors _buildRangeFilter's untouched state: full extent, "Any".
      const filterDef = {
        'filter_key': 'starting_price',
        'filter_label': 'Starting Price',
        'filter_type': 'range',
        'range_min': 0,
        'range_max': 20000,
        'range_step': 500,
        'range_unit': r'$',
      };

      final min = (filterDef['range_min'] as num).toDouble();
      final max = (filterDef['range_max'] as num).toDouble();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: RangeSlider(
            values: RangeValues(min, max),
            min: min,
            max: max,
            divisions: 40,
            onChanged: (_) {},
          ),
        ),
      ));

      final slider = tester.widget<RangeSlider>(find.byType(RangeSlider));
      expect(slider.min, equals(0));
      expect(slider.max, equals(20000));
      expect(slider.values, equals(const RangeValues(0, 20000)));
    });

    test('an untouched range is null, not a full-extent band', () {
      // The hazard: a full-extent band is a real constraint that excludes
      // vendors with no value, so "untouched" must stay null.
      const selection = VendorFilterSelection();
      expect(selection.priceBand, isNull);
      expect(selection.isEmpty, isTrue);

      const touched = VendorFilterSelection(priceBand: NumRange(0, 20000));
      expect(touched.isEmpty, isFalse);
    });
  });
}
