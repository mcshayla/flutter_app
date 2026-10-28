// The "photos can appear on easiYESt's social media" box under the listing
// photos (vendor_create.dart, vendor_edit_profile.dart).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:say_yes/widgets/social_photo_consent.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Widget wrap(bool value, ValueChanged<bool> onChanged) =>
      MaterialApp(home: Scaffold(body: SocialPhotoConsent(value: value, onChanged: onChanged)));

  testWidgets('shows the permission wording and the current answer', (tester) async {
    await tester.pumpWidget(wrap(true, (_) {}));
    expect(find.textContaining("easiYESt's social media"), findsOneWidget);
    expect(find.textContaining('credit to your business'), findsOneWidget);
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
  });

  testWidgets('tapping it reports the new answer', (tester) async {
    bool? got;
    await tester.pumpWidget(wrap(true, (v) => got = v));
    await tester.tap(find.byType(Checkbox));
    expect(got, isFalse);
  });

  test('a listing that has never been asked starts checked; a no stays a no', () {
    expect(initialSocialPhotoConsent(null), isTrue);
    expect(initialSocialPhotoConsent(true), isTrue);
    expect(initialSocialPhotoConsent(false), isFalse);
  });
}
