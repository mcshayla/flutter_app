import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:say_yes/widgets/amenity_row.dart';

/// Absence in filter_values means "the vendor never filled this in", NOT
/// "the venue doesn't have it". So the row shows only confirmed amenities —
/// it must never render a negative state.
const _optionRows = [
  {'option_value': 'cleanup_included', 'option_label': 'Clean-Up Included', 'option_group': 'Included Services', 'icon_name': 'cleaning_services'},
  {'option_value': 'wifi', 'option_label': 'Wi-Fi', 'option_group': 'Equipment & A/V', 'icon_name': 'wifi'},
  {'option_value': 'dance_floor', 'option_label': 'Dance Floor', 'option_group': 'Facilities', 'icon_name': 'nightlife'},
  {'option_value': 'wheelchair_accessible', 'option_label': 'Wheelchair Accessible', 'option_group': 'Accessibility & Policies', 'icon_name': 'accessible'},
];

Widget wrap(Map<String, dynamic> filterValues) => MaterialApp(
      home: Scaffold(
        body: AmenityRow(
          filterValues: filterValues,
          optionRows: List<Map<String, dynamic>>.from(_optionRows),
        ),
      ),
    );

void main() {
  group('AmenityRow', () {
    testWidgets('shows only the amenities the venue confirmed',
        (tester) async {
      await tester.pumpWidget(wrap({
        'venue_amenities': ['wifi', 'dance_floor'],
      }));

      expect(find.text('Wi-Fi'), findsOneWidget);
      expect(find.text('Dance Floor'), findsOneWidget);
      expect(find.byIcon(Icons.wifi), findsOneWidget);
      expect(find.byIcon(Icons.nightlife), findsOneWidget);

      // Unconfirmed amenities are absent entirely — no greyed chip, no X.
      expect(find.text('Clean-Up Included'), findsNothing);
      expect(find.text('Wheelchair Accessible'), findsNothing);
      expect(find.byIcon(Icons.close), findsNothing);
    });

    testWidgets('renders nothing at all when filter_values is empty',
        (tester) async {
      await tester.pumpWidget(wrap({}));

      expect(find.byType(Chip), findsNothing);
      expect(find.textContaining('Amenities'), findsNothing);
    });

    testWidgets('renders nothing when the amenities key is missing',
        (tester) async {
      await tester.pumpWidget(wrap({
        'venue_type': ['barn_farm_ranch'],
      }));

      expect(find.byType(Chip), findsNothing);
    });

    testWidgets('renders nothing when the amenity list is empty',
        (tester) async {
      await tester.pumpWidget(wrap({'venue_amenities': <String>[]}));

      expect(find.byType(Chip), findsNothing);
    });

    testWidgets('shows a heading once there is something to show',
        (tester) async {
      await tester.pumpWidget(wrap({
        'venue_amenities': ['wifi'],
      }));

      expect(find.text('Amenities'), findsOneWidget);
    });

    testWidgets('an amenity with an unknown icon still shows its label',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AmenityRow(
            filterValues: const {
              'venue_amenities': ['mystery'],
            },
            optionRows: const [
              {
                'option_value': 'mystery',
                'option_label': 'Mystery Perk',
                'icon_name': 'not_a_real_icon',
              },
            ],
          ),
        ),
      ));

      expect(find.text('Mystery Perk'), findsOneWidget);
    });
  });
}
