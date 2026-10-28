import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:say_yes/utils/app_styles.dart';

/// Guards the brand: the app uses the website's type and palette everywhere.

/// Every `GoogleFonts.<family>(...)` call in lib/, with its argument text.
Iterable<(String file, String family, String args)> fontCalls() sync* {
  final call = RegExp(r'GoogleFonts\.(\w+)\(');
  for (final f in Directory('lib').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'))) {
    final src = f.readAsStringSync();
    for (final m in call.allMatches(src)) {
      var depth = 1, i = m.end;
      while (i < src.length && depth > 0) {
        if (src[i] == '(') depth++;
        if (src[i] == ')') depth--;
        i++;
      }
      yield (f.path, m.group(1)!, src.substring(m.end, i - 1));
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('no screen uses the old Bodoni or Cormorant faces', () {
    final old = fontCalls().where((c) => c.$2 == 'bodoniModa' || c.$2 == 'cormorantGaramond').map((c) => c.$1).toSet();
    expect(old, isEmpty, reason: 'Use AppStyles.display (Playfair Display) instead');
  });

  test('only the two brand families are used', () {
    final families = fontCalls().map((c) => c.$2).toSet();
    expect(families.difference({'playfairDisplay', 'montserrat', 'montserratTextTheme', 'config', 'pendingFonts'}), isEmpty);
  });

  test('Playfair headings are never widely letter-spaced', () {
    final spacing = RegExp(r'letterSpacing:\s*([\d.]+)');
    final wide = fontCalls()
        .where((c) => c.$2 == 'playfairDisplay')
        .where((c) => spacing.allMatches(c.$3).any((m) => double.parse(m.group(1)!) > 0.5))
        .map((c) => c.$1)
        .toSet();
    expect(wide, isEmpty);
  });

  test('no screen fills in a random stock photo for a vendor', () {
    final offenders = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart') && f.readAsStringSync().contains('picsum.photos'))
        .map((f) => f.path)
        .toList();
    expect(offenders, isEmpty, reason: 'Show a brand placeholder; a stock photo misrepresents the vendor');
  });

  group('app theme', () {
    final theme = AppStyles.theme();

    test('is built on plum, not the old olive seed', () {
      expect(theme.colorScheme.primary, AppStyles.plum);
      expect(theme.colorScheme.secondary, AppStyles.champagne);
    });

    test('pages and surfaces are cream, not tinted', () {
      expect(theme.scaffoldBackgroundColor, AppStyles.cream);
      expect(theme.colorScheme.surface, AppStyles.cream);
    });

    test('body text is Montserrat in ink', () {
      expect(theme.textTheme.bodyMedium?.fontFamily, contains('Montserrat'));
      expect(theme.textTheme.bodyMedium?.color, AppStyles.ink);
    });

    test('text buttons (like Back) are plum', () {
      final fg = theme.textButtonTheme.style?.foregroundColor?.resolve({});
      expect(fg, AppStyles.plum);
    });

    test('dialogs and inputs have square corners like the website', () {
      expect((theme.dialogTheme.shape as RoundedRectangleBorder).borderRadius, BorderRadius.zero);
      expect((theme.inputDecorationTheme.enabledBorder as OutlineInputBorder).borderRadius, BorderRadius.zero);
    });
  });
}
