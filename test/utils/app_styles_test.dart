import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:say_yes/utils/app_styles.dart';

/// The app shares one palette and type system with the website
/// (web/site.css). These tests pin the tokens so the two can't drift apart.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppStyles colors match the website tokens', () {
    test('core palette', () {
      expect(AppStyles.plum, const Color(0xFF7B3F61));
      expect(AppStyles.plumDeep, const Color(0xFF5E2F4A));
      expect(AppStyles.plumInk, const Color(0xFF4A2239));
      expect(AppStyles.champagne, const Color(0xFFDCC7AA));
      expect(AppStyles.champagneLight, const Color(0xFFF1E6D4));
      expect(AppStyles.goldLine, const Color(0xFFB8996E));
      expect(AppStyles.blush, const Color(0xFFF2E4E1));
      expect(AppStyles.rose, const Color(0xFFC99A93));
      expect(AppStyles.cream, const Color(0xFFF8F5F0));
      expect(AppStyles.ink, const Color(0xFF3D3438));
      expect(AppStyles.inkSoft, const Color(0xFF6B6266));
    });

    test('legacy names point at the new tokens so old screens follow along', () {
      expect(AppStyles.primaryBackground, AppStyles.cream);
      expect(AppStyles.secondaryColor, AppStyles.plum);
      expect(AppStyles.accentColor, AppStyles.champagne);
      expect(AppStyles.darkWords, AppStyles.ink);
      expect(AppStyles.lightWrods, AppStyles.inkSoft);
    });
  });

  group('AppStyles type', () {
    test('display text is Playfair Display without wide letter-spacing', () {
      final style = AppStyles.display(28);
      expect(style.fontFamily, contains('PlayfairDisplay'));
      expect(style.fontSize, 28);
      expect(style.letterSpacing ?? 0, lessThanOrEqualTo(0.5));
    });

    test('the old fancy title now uses Playfair with no 2px tracking', () {
      expect(AppStyles.fancyTitle.fontFamily, contains('PlayfairDisplay'));
      expect(AppStyles.fancyTitle.letterSpacing ?? 0, lessThanOrEqualTo(0.5));
    });

    test('body text is Montserrat with no extra tracking', () {
      final style = AppStyles.body(15);
      expect(style.fontFamily, contains('Montserrat'));
      expect(style.letterSpacing ?? 0, 0);
      expect(style.color, AppStyles.ink);
    });

    test('eyebrow labels are small, letter-spaced and plum', () {
      final style = AppStyles.eyebrow();
      expect(style.fontSize, lessThanOrEqualTo(11));
      expect(style.letterSpacing, greaterThanOrEqualTo(2));
      expect(style.color, AppStyles.plum);
      expect(style.fontWeight, FontWeight.w600);
    });
  });

  group('AppStyles.isWide', () {
    test('phones and small tablets use the narrow layout', () {
      expect(AppStyles.isWide(390), isFalse);
      expect(AppStyles.isWide(899), isFalse);
    });
    test('desktop browsers and large tablets use the wide layout', () {
      expect(AppStyles.isWide(900), isTrue);
      expect(AppStyles.isWide(1440), isTrue);
    });
  });
}
