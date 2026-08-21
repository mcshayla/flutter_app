import 'package:flutter_test/flutter_test.dart';
import 'package:say_yes/services/vendor_filter.dart';

/// Pure unit tests: no Supabase, no widgets, no network, no mocks.
/// Vendors are the same raw `Map<String, dynamic>` shape the app gets back
/// from `supabase.from('vendors').select()`.
Map<String, dynamic> vendor({
  String id = 'v1',
  dynamic state,
  dynamic county,
}) {
  return {
    'vendor_id': id,
    if (state != null) 'vendor_state': state,
    if (county != null) 'vendor_county': county,
  };
}

void main() {
  group('matchesRegion', () {
    test('matches when the selected state is in the vendor state list', () {
      final v = vendor(state: ['Utah', 'Idaho']);
      expect(matchesRegion(v, 'Utah', null), isTrue);
    });

    test('does not match a state the vendor does not serve', () {
      final v = vendor(state: ['Utah']);
      expect(matchesRegion(v, 'Idaho', null), isFalse);
    });

    test("'Any' in vendor_state is a wildcard that matches every state", () {
      final v = vendor(state: ['Any']);
      expect(matchesRegion(v, 'Idaho', null), isTrue);
      expect(matchesRegion(v, 'Utah', null), isTrue);
    });

    test("'Any' in vendor_county is a wildcard that matches every county", () {
      final v = vendor(state: ['Utah'], county: ['Any']);
      expect(matchesRegion(v, 'Utah', 'Summit'), isTrue);
    });

    test('tolerates vendor_state stored as a bare string instead of a list', () {
      final v = vendor(state: 'Utah');
      expect(matchesRegion(v, 'Utah', null), isTrue);
      expect(matchesRegion(v, 'Idaho', null), isFalse);
    });

    test('excludes a vendor with no vendor_state when a state is selected', () {
      expect(matchesRegion(vendor(), 'Utah', null), isFalse);
    });

    test('state and county are ANDed together', () {
      final v = vendor(state: ['Utah'], county: ['Summit']);
      expect(matchesRegion(v, 'Utah', 'Summit'), isTrue);
      expect(matchesRegion(v, 'Utah', 'Weber'), isFalse);
      expect(matchesRegion(v, 'Idaho', 'Summit'), isFalse);
    });

    test('matches everything when neither state nor county is selected', () {
      expect(matchesRegion(vendor(), null, null), isTrue);
      expect(matchesRegion(vendor(state: ['Utah']), null, null), isTrue);
    });
  });

  group('filterByRegion', () {
    test('returns the list untouched when nothing is selected', () {
      final items = [vendor(id: 'a'), vendor(id: 'b', state: ['Utah'])];
      expect(filterByRegion(items, null, null), same(items));
    });

    test('keeps only the vendors serving the selected state', () {
      final items = [
        vendor(id: 'a', state: ['Utah']),
        vendor(id: 'b', state: ['Idaho']),
        vendor(id: 'c', state: ['Any']),
        vendor(id: 'd'),
      ];
      final kept = filterByRegion(items, 'Utah', null)
          .map((v) => v['vendor_id'])
          .toList();
      expect(kept, equals(['a', 'c']));
    });
  });

  group('availableStates', () {
    test('collects every state, sorted and de-duplicated', () {
      final items = [
        vendor(id: 'a', state: ['Utah', 'Idaho']),
        vendor(id: 'b', state: ['Utah']),
        vendor(id: 'c', state: 'Nevada'),
      ];
      expect(availableStates(items), equals(['Idaho', 'Nevada', 'Utah']));
    });

    test("never offers 'Any' as a selectable state", () {
      final items = [
        vendor(id: 'a', state: ['Any']),
        vendor(id: 'b', state: ['Utah']),
      ];
      expect(availableStates(items), equals(['Utah']));
    });

    test('skips null and blank entries', () {
      final items = [
        vendor(id: 'a', state: ['Utah', '', '  ']),
        vendor(id: 'b'),
      ];
      expect(availableStates(items), equals(['Utah']));
    });
  });

  group('availableCounties', () {
    test('returns every county when no state is selected', () {
      final items = [
        vendor(id: 'a', state: ['Utah'], county: ['Summit']),
        vendor(id: 'b', state: ['Idaho'], county: ['Ada']),
      ];
      expect(availableCounties(items, null), equals(['Ada', 'Summit']));
    });

    test('narrows to the counties of the selected state', () {
      final items = [
        vendor(id: 'a', state: ['Utah'], county: ['Summit']),
        vendor(id: 'b', state: ['Idaho'], county: ['Ada']),
      ];
      expect(availableCounties(items, 'Utah'), equals(['Summit']));
    });

    test("includes counties of a vendor whose state is 'Any'", () {
      final items = [
        vendor(id: 'a', state: ['Idaho'], county: ['Ada']),
        vendor(id: 'b', state: ['Any'], county: ['Statewide']),
      ];
      expect(availableCounties(items, 'Utah'), equals(['Statewide']));
    });

    test("never offers 'Any' as a selectable county", () {
      final items = [
        vendor(id: 'a', state: ['Utah'], county: ['Any', 'Summit']),
      ];
      expect(availableCounties(items, 'Utah'), equals(['Summit']));
    });
  });

  group('matchesTags', () {
    Map<String, dynamic> tagged(Map<String, List<String>> values) =>
        {'vendor_id': 'v1', 'filter_values': values};

    test('matches everything when no tags are selected', () {
      expect(matchesTags(tagged({}), {}), isTrue);
    });

    test('matches when the vendor has one of the selected options (OR)', () {
      final v = tagged({
        'venue_type': ['barn_farm_ranch'],
      });
      expect(
        matchesTags(v, {
          'venue_type': {'ballroom_banquet_hall', 'barn_farm_ranch'},
        }),
        isTrue,
      );
    });

    test('does not match when the vendor has none of the selected options', () {
      final v = tagged({
        'venue_type': ['barn_farm_ranch'],
      });
      expect(
        matchesTags(v, {
          'venue_type': {'vineyard_winery'},
        }),
        isFalse,
      );
    });

    test('separate filter groups are ANDed', () {
      final v = tagged({
        'venue_type': ['barn_farm_ranch'],
        'venue_amenities': ['dance_floor'],
      });
      expect(
        matchesTags(v, {
          'venue_type': {'barn_farm_ranch'},
          'venue_amenities': {'dance_floor'},
        }),
        isTrue,
      );
      expect(
        matchesTags(v, {
          'venue_type': {'barn_farm_ranch'},
          'venue_amenities': {'wifi'},
        }),
        isFalse,
      );
    });

    test('excludes a vendor that has not answered an active filter', () {
      final v = tagged({
        'venue_type': ['barn_farm_ranch'],
      });
      expect(
        matchesTags(v, {
          'venue_amenities': {'wifi'},
        }),
        isFalse,
      );
    });

    test('an empty selection set for a key is ignored', () {
      final v = tagged({
        'venue_type': ['barn_farm_ranch'],
      });
      expect(matchesTags(v, {'venue_amenities': <String>{}}), isTrue);
    });

    test('tolerates a missing or non-map filter_values', () {
      expect(
        matchesTags({'vendor_id': 'v1'}, {
          'venue_type': {'barn_farm_ranch'},
        }),
        isFalse,
      );
      expect(
        matchesTags({'vendor_id': 'v1', 'filter_values': 'nonsense'}, {
          'venue_type': {'barn_farm_ranch'},
        }),
        isFalse,
      );
    });
  });

  group('hasCoordinates', () {
    Map<String, dynamic> at({dynamic lat, dynamic lng, String id = 'v1'}) => {
          'vendor_id': id,
          'latitude': lat,
          'longitude': lng,
        };

    test('true when both latitude and longitude are numbers', () {
      expect(hasCoordinates(at(lat: 40.76, lng: -111.89)), isTrue);
    });

    test('true for integer coordinates', () {
      expect(hasCoordinates(at(lat: 40, lng: -111)), isTrue);
    });

    test('false when either coordinate is missing', () {
      expect(hasCoordinates(at(lat: 40.76, lng: null)), isFalse);
      expect(hasCoordinates(at(lat: null, lng: -111.89)), isFalse);
      expect(hasCoordinates(at()), isFalse);
      expect(hasCoordinates({'vendor_id': 'v1'}), isFalse);
    });

    test('false when a coordinate is a non-numeric value', () {
      expect(hasCoordinates(at(lat: 'forty', lng: -111.89)), isFalse);
    });
  });

  group('vendorsWithCoordinates', () {
    test('keeps only vendors that can actually be placed on a map', () {
      final items = [
        {'vendor_id': 'a', 'latitude': 40.7, 'longitude': -111.8},
        {'vendor_id': 'b', 'latitude': null, 'longitude': null},
        {'vendor_id': 'c', 'latitude': 41.2, 'longitude': -111.9},
      ];
      expect(
        vendorsWithCoordinates(items).map((v) => v['vendor_id']),
        equals(['a', 'c']),
      );
    });

    test('drops vendors with a null or blank vendor_id', () {
      // These would otherwise collide on the '' key and overwrite each other
      // down to a single marker.
      final items = [
        {'vendor_id': null, 'latitude': 40.7, 'longitude': -111.8},
        {'vendor_id': '', 'latitude': 41.0, 'longitude': -111.5},
        {'vendor_id': 'real', 'latitude': 41.2, 'longitude': -111.9},
      ];
      expect(
        vendorsWithCoordinates(items).map((v) => v['vendor_id']),
        equals(['real']),
      );
    });

    test('returns an empty list when nothing has coordinates', () {
      final items = [
        {'vendor_id': 'a', 'address': '123 Main St'},
        {'vendor_id': 'b', 'vendor_location': 'Provo, UT'},
      ];
      expect(vendorsWithCoordinates(items), isEmpty);
    });
  });

  group('matchesPrice', () {
    Map<String, dynamic> priced(dynamic price) =>
        {'vendor_id': 'v1', 'starting_price': price};

    test('matches everything when no band is set', () {
      expect(matchesPrice(priced(5000), null), isTrue);
      expect(matchesPrice(priced(null), null), isTrue);
    });

    test('matches a starting price inside the band', () {
      expect(matchesPrice(priced(5000), const NumRange(2000, 8000)), isTrue);
    });

    test('band boundaries are inclusive', () {
      expect(matchesPrice(priced(2000), const NumRange(2000, 8000)), isTrue);
      expect(matchesPrice(priced(8000), const NumRange(2000, 8000)), isTrue);
    });

    test('excludes a starting price outside the band', () {
      expect(matchesPrice(priced(1999), const NumRange(2000, 8000)), isFalse);
      expect(matchesPrice(priced(8001), const NumRange(2000, 8000)), isFalse);
    });

    test('excludes vendors with no starting price once a band is set', () {
      // A null band means "no preference" and keeps them (above); an explicit
      // band cannot be satisfied by an unknown price.
      expect(matchesPrice(priced(null), const NumRange(2000, 8000)), isFalse);
      expect(matchesPrice({'vendor_id': 'v1'}, const NumRange(0, 20000)),
          isFalse);
    });

    test('a full-extent band is still a real band, not "no preference"', () {
      // The hazard: if a full-extent band were treated as null, every
      // priceless vendor would silently reappear.
      expect(matchesPrice(priced(null), const NumRange(0, 20000)), isFalse);
      expect(matchesPrice(priced(500), const NumRange(0, 20000)), isTrue);
    });
  });

  group('matchesCapacity', () {
    Map<String, dynamic> holds(dynamic min, dynamic max) => {
          'vendor_id': 'v1',
          'capacity_min': min,
          'capacity_max': max,
        };

    test('matches everything when no band is set', () {
      expect(matchesCapacity(holds(50, 300), null), isTrue);
      expect(matchesCapacity(holds(null, null), null), isTrue);
    });

    test('matches when the venue range overlaps the requested range', () {
      expect(matchesCapacity(holds(50, 300), const NumRange(200, 400)), isTrue);
      expect(matchesCapacity(holds(200, 400), const NumRange(50, 300)), isTrue);
    });

    test('matches when the venue range fully contains the request', () {
      expect(matchesCapacity(holds(0, 1000), const NumRange(150, 200)), isTrue);
    });

    test('matches when the request fully contains the venue range', () {
      expect(matchesCapacity(holds(150, 200), const NumRange(0, 1000)), isTrue);
    });

    test('does not match a venue range that misses the request entirely', () {
      expect(
          matchesCapacity(holds(50, 100), const NumRange(200, 400)), isFalse);
      expect(
          matchesCapacity(holds(500, 900), const NumRange(200, 400)), isFalse);
    });

    test('touching at a single guest still counts as overlap', () {
      expect(
          matchesCapacity(holds(50, 200), const NumRange(200, 400)), isTrue);
      expect(
          matchesCapacity(holds(400, 900), const NumRange(200, 400)), isTrue);
    });

    test('treats a missing bound as open-ended on that side', () {
      expect(
          matchesCapacity(holds(null, 100), const NumRange(50, 80)), isTrue);
      expect(
          matchesCapacity(holds(500, null), const NumRange(600, 800)), isTrue);
      expect(
          matchesCapacity(holds(null, 100), const NumRange(200, 400)), isFalse);
    });

    test('excludes a venue with no capacity at all once a band is set', () {
      expect(
          matchesCapacity(holds(null, null), const NumRange(200, 400)),
          isFalse);
    });
  });

  group('groupOptions', () {
    test('splits amenity rows into their sub-sections, preserving order', () {
      final rows = [
        {'option_value': 'cleanup_included', 'option_label': 'Clean-Up Included', 'option_group': 'Included Services', 'display_order': 0},
        {'option_value': 'wifi', 'option_label': 'Wi-Fi', 'option_group': 'Equipment & A/V', 'display_order': 30},
        {'option_value': 'event_staff', 'option_label': 'Event Staff', 'option_group': 'Included Services', 'display_order': 20},
        {'option_value': 'dance_floor', 'option_label': 'Dance Floor', 'option_group': 'Facilities', 'display_order': 90},
      ];
      final groups = groupOptions(rows);

      expect(groups.map((g) => g.title),
          equals(['Included Services', 'Equipment & A/V', 'Facilities']));
      expect(groups.first.options.map((o) => o.value),
          equals(['cleanup_included', 'event_staff']));
    });

    test('ungrouped rows land in a single untitled section', () {
      final rows = [
        {'option_value': 'barn_farm_ranch', 'option_label': 'Barns, Farms & Ranches', 'option_group': null, 'display_order': 10},
        {'option_value': 'vineyard_winery', 'option_label': 'Vineyards & Wineries', 'option_group': null, 'display_order': 20},
      ];
      final groups = groupOptions(rows);

      expect(groups, hasLength(1));
      expect(groups.single.title, isNull);
      expect(groups.single.options.map((o) => o.label),
          equals(['Barns, Farms & Ranches', 'Vineyards & Wineries']));
    });

    test('falls back to the legacy options array when there are no rows', () {
      final groups = groupOptionsFor(
        {'filter_key': 'catering_service', 'options': ['buffet', 'plated']},
        const [],
      );

      expect(groups, hasLength(1));
      expect(groups.single.title, isNull);
      expect(groups.single.options.map((o) => o.value),
          equals(['buffet', 'plated']));
      // Legacy options are their own label.
      expect(groups.single.options.first.label, equals('buffet'));
    });

    test('prefers filter_options rows over the legacy array', () {
      final groups = groupOptionsFor(
        {'filter_key': 'venue_type', 'options': ['stale_option']},
        [
          {'option_value': 'barn_farm_ranch', 'option_label': 'Barns, Farms & Ranches', 'option_group': null, 'display_order': 0},
        ],
      );

      expect(groups.single.options.map((o) => o.value),
          equals(['barn_farm_ranch']));
    });

    test('returns nothing when there are neither rows nor legacy options', () {
      expect(groupOptionsFor({'filter_key': 'empty'}, const []), isEmpty);
    });
  });

  group('filterVendors', () {
    final venues = [
      {
        'vendor_id': 'barn',
        'vendor_state': ['Utah'],
        'vendor_county': ['Summit'],
        'filter_values': {
          'venue_type': ['barn_farm_ranch'],
          'venue_amenities': ['dance_floor', 'wifi'],
        },
        'starting_price': 3000,
        'capacity_min': 50,
        'capacity_max': 200,
      },
      {
        'vendor_id': 'ballroom',
        'vendor_state': ['Utah'],
        'vendor_county': ['Salt Lake'],
        'filter_values': {
          'venue_type': ['ballroom_banquet_hall'],
          'venue_amenities': ['dance_floor'],
        },
        'starting_price': 9000,
        'capacity_min': 200,
        'capacity_max': 600,
      },
      {
        'vendor_id': 'winery',
        'vendor_state': ['Idaho'],
        'filter_values': {
          'venue_type': ['vineyard_winery'],
        },
        'starting_price': 4500,
        'capacity_min': 40,
        'capacity_max': 150,
      },
    ];

    List<String> ids(List<Map<String, dynamic>> v) =>
        v.map((e) => e['vendor_id'] as String).toList();

    test('an empty selection keeps everyone', () {
      expect(ids(filterVendors(venues, const VendorFilterSelection())),
          equals(['barn', 'ballroom', 'winery']));
    });

    test('combines region, tags, price and capacity', () {
      final result = filterVendors(
        venues,
        const VendorFilterSelection(
          state: 'Utah',
          priceBand: NumRange(0, 5000),
          capacityBand: NumRange(100, 250),
        ),
      );
      expect(ids(result), equals(['barn']));
    });

    test('price band alone narrows correctly', () {
      final result = filterVendors(
        venues,
        const VendorFilterSelection(priceBand: NumRange(4000, 10000)),
      );
      expect(ids(result), equals(['ballroom', 'winery']));
    });

    test('amenity tags alone narrow correctly', () {
      final result = filterVendors(
        venues,
        VendorFilterSelection(tags: {
          'venue_amenities': {'wifi'},
        }),
      );
      expect(ids(result), equals(['barn']));
    });
  });
}
