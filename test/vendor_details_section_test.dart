import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:say_yes/widgets/spec_card.dart';
import 'package:say_yes/widgets/vendor_details_section.dart';

/// The section is driven entirely by the generic filter tables, so these
/// fixtures mirror `category_filters` / `filter_options` rows rather than any
/// per-category Dart model.
const _groups = [
  {'filter_key': 'venue_type', 'filter_label': 'Venue Type', 'filter_type': 'chips'},
  {'filter_key': 'venue_amenities', 'filter_label': 'Amenities', 'filter_type': 'chips'},
  // Still on the legacy category_filters.options array: no filter_options rows.
  {'filter_key': 'setting_type', 'filter_label': 'Setting Type', 'filter_type': 'chips'},
  {'filter_key': 'starting_price', 'filter_label': 'Starting Price', 'filter_type': 'range'},
];

const _options = <String, List<Map<String, dynamic>>>{
  'venue_type': [
    {'option_value': 'barn_farm_ranch', 'option_label': 'Barns, Farms & Ranches'},
    {'option_value': 'garden_arboretum', 'option_label': 'Gardens & Arboretums'},
  ],
  'venue_amenities': [
    {'option_value': 'wifi', 'option_label': 'Wi-Fi', 'option_group': 'Equipment & A/V', 'icon_name': 'wifi'},
    {'option_value': 'dance_floor', 'option_label': 'Dance Floor', 'option_group': 'Facilities', 'icon_name': 'nightlife'},
  ],
};

Widget wrap(
  Map<String, dynamic> filterValues, {
  bool isWide = true,
  List<SpecEntry> leading = const [],
}) =>
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: VendorDetailsSection(
            filterValues: filterValues,
            filterGroups: List<Map<String, dynamic>>.from(_groups),
            optionsByKey: _options,
            leadingEntries: leading,
            isWide: isWide,
          ),
        ),
      ),
    );

void main() {
  group('VendorDetailsSection', () {
    testWidgets('resolves stored values to their display labels',
        (tester) async {
      await tester.pumpWidget(wrap({
        'venue_type': ['barn_farm_ranch'],
      }));

      expect(find.text('VENUE TYPE'), findsOneWidget);
      expect(find.text('Barns, Farms & Ranches'), findsOneWidget);
      // The raw stored value must never leak into the UI.
      expect(find.text('barn_farm_ranch'), findsNothing);
    });

    testWidgets('falls back to the raw value for legacy array groups',
        (tester) async {
      // setting_type has no filter_options rows, so 'Both' is all we have.
      await tester.pumpWidget(wrap({
        'setting_type': ['Both'],
      }));

      expect(find.text('SETTING TYPE'), findsOneWidget);
      expect(find.text('Both'), findsOneWidget);
    });

    testWidgets('joins multiple values in the DB display order',
        (tester) async {
      // Deliberately stored in reverse order to prove we re-sort.
      await tester.pumpWidget(wrap({
        'venue_type': ['garden_arboretum', 'barn_farm_ranch'],
      }));

      expect(
        find.text('Barns, Farms & Ranches  ·  Gardens & Arboretums'),
        findsOneWidget,
      );
    });

    testWidgets('renders amenities iconically, not as a spec line',
        (tester) async {
      await tester.pumpWidget(wrap({
        'venue_amenities': ['wifi', 'dance_floor'],
      }));

      expect(find.text('Amenities'), findsOneWidget);
      expect(find.byIcon(Icons.wifi), findsOneWidget);
      expect(find.byIcon(Icons.nightlife), findsOneWidget);
      // Not rendered as an uppercase spec label.
      expect(find.text('AMENITIES'), findsNothing);
    });

    testWidgets('groups amenities by section when wide', (tester) async {
      await tester.pumpWidget(wrap({
        'venue_amenities': ['wifi', 'dance_floor'],
      }, isWide: true));

      expect(find.text('EQUIPMENT & A/V'), findsOneWidget);
      expect(find.text('FACILITIES'), findsOneWidget);
      expect(find.byType(ListView), findsNothing);
    });

    testWidgets('scrolls amenities sideways when narrow', (tester) async {
      await tester.pumpWidget(wrap({
        'venue_amenities': ['wifi', 'dance_floor'],
      }, isWide: false));

      final listView = tester.widget<ListView>(find.byType(ListView));
      expect(listView.scrollDirection, Axis.horizontal);
      // The strip is flat — sub-group headings would break the rhythm.
      expect(find.text('EQUIPMENT & A/V'), findsNothing);
    });

    testWidgets('ignores range groups, which live in numeric columns',
        (tester) async {
      await tester.pumpWidget(wrap({
        'starting_price': ['4500'],
      }));

      expect(find.text('STARTING PRICE'), findsNothing);
    });

    testWidgets('renders nothing when the vendor filled nothing in',
        (tester) async {
      await tester.pumpWidget(wrap({}));

      expect(find.byType(Text), findsNothing);
    });

    testWidgets('omits a group the vendor left blank rather than showing None',
        (tester) async {
      await tester.pumpWidget(wrap({
        'venue_type': ['barn_farm_ranch'],
        'setting_type': <String>[],
      }));

      expect(find.text('VENUE TYPE'), findsOneWidget);
      expect(find.text('SETTING TYPE'), findsNothing);
      expect(find.textContaining('None'), findsNothing);
    });

    testWidgets('core facts share one card with the filter-derived specs',
        (tester) async {
      await tester.pumpWidget(wrap(
        {
          'venue_type': ['barn_farm_ranch'],
        },
        leading: const [SpecEntry('Base Price', r'$4,500')],
        isWide: false,
      ));

      // One card, not two: a single SpecCard holds both kinds of fact.
      expect(find.byType(SpecCard), findsOneWidget);
      expect(find.text('BASE PRICE'), findsOneWidget);
      expect(find.text('VENUE TYPE'), findsOneWidget);
    });

    testWidgets('core facts alone still render when no filters are set',
        (tester) async {
      await tester.pumpWidget(wrap(
        const {},
        leading: const [SpecEntry('Location', 'Salt Lake City')],
      ));

      expect(find.text('LOCATION'), findsOneWidget);
      expect(find.text('Salt Lake City'), findsOneWidget);
    });

    testWidgets('still shows a value whose option was renamed away',
        (tester) async {
      await tester.pumpWidget(wrap({
        'venue_type': ['barn_farm_ranch', 'retired_option'],
      }));

      expect(
        find.text('Barns, Farms & Ranches  ·  retired_option'),
        findsOneWidget,
      );
    });
  });
}
