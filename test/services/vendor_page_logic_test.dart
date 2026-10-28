import 'package:flutter_test/flutter_test.dart';
import 'package:say_yes/services/vendor_page_logic.dart';

// Mirrors the Venue rows in category_filters / filter_options.
final venueGroups = <Map<String, dynamic>>[
  {'filter_key': 'venue_type', 'filter_label': 'Venue Type', 'filter_type': 'chips'},
  {'filter_key': 'venue_amenities', 'filter_label': 'Amenities', 'filter_type': 'chips'},
  {'filter_key': 'setting_type', 'filter_label': 'Setting Type', 'filter_type': 'chips'},
  {'filter_key': 'catering', 'filter_label': 'Catering', 'filter_type': 'chips', 'options': ['In-house only', 'Preferred list', 'BYO caterer']},
  {'filter_key': 'starting_price', 'filter_label': 'Starting Price', 'filter_type': 'range', 'range_unit': r'$'},
  {'filter_key': 'guest_capacity_range', 'filter_label': 'Guest Capacity', 'filter_type': 'range', 'range_unit': 'guests'},
];

final optionsByKey = <String, List<Map<String, dynamic>>>{
  'venue_type': [
    {'option_value': 'barn', 'option_label': 'Barns, Farms & Ranches'},
    {'option_value': 'garden', 'option_label': 'Gardens & Arboretums'},
  ],
  'setting_type': [
    {'option_value': 'indoor', 'option_label': 'Indoor'},
    {'option_value': 'both', 'option_label': 'Indoor & Outdoor'},
  ],
  'venue_amenities': [
    {'option_value': 'cleanup', 'option_label': 'Clean-Up Included', 'option_group': 'Included Services', 'icon_name': 'cleaning_services'},
    {'option_value': 'tables', 'option_label': 'Tables, Chairs & Linens', 'option_group': 'Included Services', 'icon_name': 'table_restaurant'},
    {'option_value': 'sound', 'option_label': 'Sound System', 'option_group': 'Equipment & A/V', 'icon_name': 'speaker'},
    {'option_value': 'suite', 'option_label': 'Dressing Room / Bridal Suite', 'option_group': 'Facilities', 'icon_name': 'checkroom'},
    {'option_value': 'dance', 'option_label': 'Dance Floor', 'option_group': 'Facilities', 'icon_name': 'nightlife'},
  ],
};

void main() {
  group('formatCapacity', () {
    test('a range', () => expect(formatCapacity(50, 300), '50–300'));
    test('only a maximum', () => expect(formatCapacity(null, 300), 'Up to 300'));
    test('only a minimum', () => expect(formatCapacity(50, null), '50+'));
    test('nothing', () => expect(formatCapacity(null, null), isNull));
    test('the same number twice', () => expect(formatCapacity(120, 120), '120'));
  });

  group('glancePrice', () {
    test('a numeric starting price is formatted', () {
      expect(glancePrice(3200, ''), r'$3,200');
    });
    test('falls back to the price the vendor typed', () {
      expect(glancePrice(null, r'$3,200'), r'$3,200');
      expect(glancePrice(null, 'Starting at \$2k'), 'Starting at \$2k');
    });
    test('blank or "Unknown" means no price', () {
      expect(glancePrice(null, '  '), isNull);
      expect(glancePrice(null, 'Unknown'), isNull);
    });
  });

  group('buildVendorSlots', () {
    VendorSlots build(Map<String, dynamic> values, {num? price, String priceText = '', int? capMin, int? capMax, List<Map<String, dynamic>>? groups}) =>
        buildVendorSlots(
          filterGroups: groups ?? venueGroups,
          optionsByKey: optionsByKey,
          filterValues: values,
          startingPrice: price,
          priceText: priceText,
          capacityMin: capMin,
          capacityMax: capMax,
        );

    test('at a glance holds price and guest capacity', () {
      final s = build({}, price: 3200, capMin: 50, capMax: 300);
      expect(s.glance.map((g) => (g.value, g.label)).toList(), [
        (r'$3,200', 'Starting price'),
        ('50–300', 'Guests'),
      ]);
    });

    test('guest capacity shows even though it is a range filter (it used to be hidden)', () {
      final s = build({}, capMax: 180);
      expect(s.glance.single.value, 'Up to 180');
    });

    test('capacity is left out for vendor types that do not have it', () {
      final florist = [
        {'filter_key': 'style', 'filter_label': 'Style', 'filter_type': 'chips', 'options': ['Romantic', 'Modern']},
      ];
      final s = build({'style': ['Romantic']}, price: 900, capMax: 300, groups: florist);
      expect(s.glance.map((g) => g.label), ['Starting price']);
    });

    test('choice filters without icons become details, using display labels in display order', () {
      final s = build({
        'setting_type': ['both'],
        'venue_type': ['garden', 'barn'],
        'catering': ['BYO caterer'],
      });
      expect(s.details.map((d) => (d.label, d.value)).toList(), [
        ('Venue Type', 'Barns, Farms & Ranches · Gardens & Arboretums'),
        ('Setting Type', 'Indoor & Outdoor'),
        ('Catering', 'BYO caterer'),
      ]);
    });

    test('unanswered filters are left out rather than shown as "None"', () {
      final s = build({'venue_type': ['barn']});
      expect(s.details.map((d) => d.label), ['Venue Type']);
      expect(s.included, isEmpty);
    });

    test('choice filters with icons become "What\'s included", grouped', () {
      final s = build({'venue_amenities': ['dance', 'cleanup', 'sound', 'suite']});
      expect(s.included.map((g) => g.title).toList(), ['Included Services', 'Equipment & A/V', 'Facilities']);
      expect(s.included.last.items.map((i) => i.label).toList(), ['Dressing Room / Bridal Suite', 'Dance Floor']);
      expect(s.included.first.items.single.iconName, 'cleaning_services');
    });

    test('highlights are the first three included items', () {
      final s = build({'venue_amenities': ['dance', 'cleanup', 'sound', 'suite', 'tables']});
      expect(s.highlights.map((i) => i.label).toList(), ['Clean-Up Included', 'Tables, Chairs & Linens', 'Sound System']);
    });

    test('a single answer stored as a plain string still shows', () {
      final s = build({'setting_type': 'indoor'});
      expect(s.details.single.value, 'Indoor');
    });
  });

  group('mosaicImages', () {
    test('needs at least three photos', () {
      expect(mosaicImages(['a', 'b']), isEmpty);
    });
    test('skips the first photo, which already leads the page, when there are enough', () {
      expect(mosaicImages(['a', 'b', 'c', 'd', 'e']), ['b', 'c', 'd']);
    });
    test('uses the first three when there are exactly three', () {
      expect(mosaicImages(['a', 'b', 'c']), ['a', 'b', 'c']);
    });
  });

  group('featuredReview', () {
    test('picks the newest review that has words in it', () {
      final r = featuredReview([
        {'rating': 5, 'comment': '', 'date': '2026-09-01'},
        {'rating': 4, 'comment': 'Lovely staff', 'date': '2026-05-01'},
        {'rating': 5, 'comment': 'The orchard was perfect', 'date': '2026-08-01'},
      ]);
      expect(r?['comment'], 'The orchard was perfect');
    });
    test('nothing to feature without a written review', () {
      expect(featuredReview([{'rating': 5, 'comment': ' '}]), isNull);
      expect(featuredReview(const []), isNull);
    });
  });
}
