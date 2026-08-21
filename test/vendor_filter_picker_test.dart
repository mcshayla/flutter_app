import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:say_yes/widgets/vendor_filter_picker.dart';

const _groups = [
  {'filter_key': 'venue_type', 'filter_label': 'Venue Type', 'filter_type': 'chips', 'options': []},
  {'filter_key': 'venue_amenities', 'filter_label': 'Amenities', 'filter_type': 'chips', 'options': []},
  // Legacy: options live on the array, no filter_options rows.
  {'filter_key': 'catering', 'filter_label': 'Catering', 'filter_type': 'chips',
   'options': ['In-house only', 'BYO caterer']},
  // Answered by the numeric fields, so it must not appear as chips.
  {'filter_key': 'starting_price', 'filter_label': 'Starting Price', 'filter_type': 'range', 'options': []},
];

const _options = <String, List<Map<String, dynamic>>>{
  'venue_type': [
    {'option_value': 'barn_farm_ranch', 'option_label': 'Barns, Farms & Ranches'},
    {'option_value': 'garden_arboretum', 'option_label': 'Gardens & Arboretums'},
  ],
  'venue_amenities': [
    {'option_value': 'wifi', 'option_label': 'Wi-Fi', 'option_group': 'Equipment & A/V'},
    {'option_value': 'dance_floor', 'option_label': 'Dance Floor', 'option_group': 'Facilities'},
  ],
};

/// Drives the picker like a real form: holds the answers in state so a tap
/// actually round-trips through onChanged and back into the widget.
class _Harness extends StatefulWidget {
  final Map<String, List<String>> initial;
  const _Harness({this.initial = const {}});

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  late Map<String, List<String>> values = {
    for (final e in widget.initial.entries) e.key: List<String>.from(e.value)
  };

  @override
  Widget build(BuildContext context) => MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: VendorFilterPicker(
              filterGroups: List<Map<String, dynamic>>.from(_groups),
              optionsByKey: _options,
              selected: values,
              onChanged: (key, next) => setState(() => values[key] = next),
            ),
          ),
        ),
      );
}

void main() {
  group('VendorFilterPicker', () {
    testWidgets('offers every chip group for the category', (tester) async {
      await tester.pumpWidget(const _Harness());

      expect(find.text('Venue Type'), findsOneWidget);
      expect(find.text('Amenities'), findsOneWidget);
      expect(find.text('Barns, Farms & Ranches'), findsOneWidget);
      expect(find.text('Wi-Fi'), findsOneWidget);
    });

    testWidgets('falls back to the legacy options array', (tester) async {
      await tester.pumpWidget(const _Harness());

      expect(find.text('Catering'), findsOneWidget);
      expect(find.text('In-house only'), findsOneWidget);
      expect(find.text('BYO caterer'), findsOneWidget);
    });

    testWidgets('never renders a range group as chips', (tester) async {
      await tester.pumpWidget(const _Harness());

      expect(find.text('Starting Price'), findsNothing);
    });

    testWidgets('shows amenity sub-group headings', (tester) async {
      await tester.pumpWidget(const _Harness());

      expect(find.text('EQUIPMENT & A/V'), findsOneWidget);
      expect(find.text('FACILITIES'), findsOneWidget);
    });

    testWidgets('tapping a chip stores the option_value, not the label',
        (tester) async {
      await tester.pumpWidget(const _Harness());

      await tester.tap(find.text('Barns, Farms & Ranches'));
      await tester.pump();

      final state = tester.state<_HarnessState>(find.byType(_Harness));
      expect(state.values['venue_type'], ['barn_farm_ranch']);
    });

    testWidgets('tapping a selected chip removes it', (tester) async {
      await tester.pumpWidget(const _Harness(initial: {
        'venue_type': ['barn_farm_ranch'],
      }));

      await tester.tap(find.text('Barns, Farms & Ranches'));
      await tester.pump();

      final state = tester.state<_HarnessState>(find.byType(_Harness));
      expect(state.values['venue_type'], isEmpty);
    });

    testWidgets('selections accumulate within a group', (tester) async {
      await tester.pumpWidget(const _Harness());

      await tester.tap(find.text('Barns, Farms & Ranches'));
      await tester.pump();
      await tester.tap(find.text('Gardens & Arboretums'));
      await tester.pump();

      final state = tester.state<_HarnessState>(find.byType(_Harness));
      expect(state.values['venue_type'],
          ['barn_farm_ranch', 'garden_arboretum']);
    });

    testWidgets('groups keep separate answers', (tester) async {
      await tester.pumpWidget(const _Harness());

      await tester.tap(find.text('Barns, Farms & Ranches'));
      await tester.pump();
      await tester.tap(find.text('Wi-Fi'));
      await tester.pump();

      final state = tester.state<_HarnessState>(find.byType(_Harness));
      expect(state.values['venue_type'], ['barn_farm_ranch']);
      expect(state.values['venue_amenities'], ['wifi']);
    });

    testWidgets('pre-selected answers show as selected', (tester) async {
      await tester.pumpWidget(const _Harness(initial: {
        'venue_amenities': ['wifi'],
      }));

      final chip = tester.widget<FilterChip>(
        find.ancestor(of: find.text('Wi-Fi'), matching: find.byType(FilterChip)),
      );
      expect(chip.selected, isTrue);
    });

    testWidgets('renders nothing when the category has no filters',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: VendorFilterPicker(
            filterGroups: const [],
            optionsByKey: const {},
            selected: const {},
            onChanged: (_, _) {},
          ),
        ),
      ));

      expect(find.byType(FilterChip), findsNothing);
    });
  });
}
