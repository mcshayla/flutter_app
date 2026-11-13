import 'package:flutter_test/flutter_test.dart';
import 'package:say_yes/pages/explore_page.dart';

void main() {
  final vendors = [
    {'image_url': ['https://x/a1.jpg', 'https://x/a2.jpg']},
    {'image_url': <String>[]},
    {'image_url': ['https://x/b1.jpg']},
    {'image_url': ['https://x/c1.jpg']},
  ];

  test('the cover pool is each vendor\'s lead photo', () {
    expect(coverChoices(vendors), ['https://x/a1.jpg', 'https://x/b1.jpg', 'https://x/c1.jpg']);
  });

  test('a cover stays the same within one app session', () {
    expect(pickCover('Venue', vendors), pickCover('Venue', vendors));
  });

  test('covers vary from session to session, across different vendors', () {
    final picks = {for (var seed = 0; seed < 40; seed++) pickCover('Venue', vendors, seed: seed)};
    expect(picks.length, greaterThan(1));
    expect(picks.every(coverChoices(vendors).contains), isTrue);
  });

  test('a category with no photos has no cover', () {
    expect(pickCover('DJ', [{'image_url': <String>[]}]), isNull);
  });
}
