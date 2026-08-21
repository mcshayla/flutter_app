import 'package:flutter_test/flutter_test.dart';
import 'package:say_yes/utils/amenity_icons.dart';

/// Every icon_name seeded by python_scripts/seed_venue_filters.py must resolve.
/// Flutter tree-shakes icons, so an IconData cannot be built from an arbitrary
/// runtime string — the DB stores the name, this map is the closed set.
const seededIconNames = <String>[
  'cleaning_services',
  'manage_accounts',
  'groups',
  'headphones',
  'table_restaurant',
  'speaker',
  'lightbulb',
  'videocam',
  'wifi',
  'nightlife',
  'checkroom',
  'kitchen',
  'wc',
  'thermostat',
  'accessible',
  'policy',
];

void main() {
  group('amenityIcon', () {
    test('resolves every icon name the seed script writes', () {
      for (final name in seededIconNames) {
        expect(
          amenityIcon(name),
          isNotNull,
          reason: '"$name" is seeded into filter_options but has no IconData',
        );
      }
    });

    test('returns null for an unknown name rather than throwing', () {
      expect(amenityIcon('not_a_real_icon'), isNull);
      expect(amenityIcon(null), isNull);
      expect(amenityIcon(''), isNull);
    });
  });
}
