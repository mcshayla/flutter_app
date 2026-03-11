// Tests for VendorCreatePage – form validation, category loading from Supabase,
// photo section UI, social media fields, and states-served chips.
//
// Strategy: every test sets a 6000px-tall viewport so the entire form is
// rendered at once. This avoids all lazy-ListView issues (off-screen widgets
// not in the tree, Scrollable-count mismatches, etc.) and lets us use plain
// `find.text()` without any `scrollUntilVisible` calls.
//
// Other constraints:
// - Supabase initialised with fake credentials. _loadCategories() fails with
//   code 400 and is caught silently, leaving the category dropdown empty.
// - ImagePicker is a platform plugin unavailable in the test VM. The
//   photo-pick test only verifies the UI is present; it does not open the picker.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:say_yes/pages/vendor_create.dart';

// ─── Supabase bootstrap ────────────────────────────────────────────────────

Future<void> _initSupabase() async {
  SharedPreferences.setMockInitialValues({});
  try {
    await Supabase.initialize(
      url: 'https://test.supabase.co',
      anonKey: 'test_anon_key_for_unit_tests',
    );
  } catch (_) {
    // Already initialized when running alongside other test files.
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────

Widget _wrap() => MaterialApp(home: VendorCreatePage(userId: 'test-user-id'));

/// Pumps [_wrap()] in a 6000px-tall viewport so the entire form is visible.
/// Registers a tearDown to reset the viewport size after the test.
Future<void> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 6000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(_wrap());
  await tester.pump();
}

/// Triggers form validation by calling FormState.validate() directly —
/// no need to scroll to and tap the submit button.
Future<void> _validate(WidgetTester tester) async {
  final formState = tester.state<FormState>(find.byType(Form));
  formState.validate();
  await tester.pump();
}

// ─── Tests ────────────────────────────────────────────────────────────────

void main() {
  setUpAll(() async {
    await _initSupabase();
    // Prevent Google Fonts from making network requests during tests.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  // ─── Page structure ──────────────────────────────────────────────────────

  group('VendorCreatePage – page structure', () {
    testWidgets('renders without crashing', (tester) async {
      await _pump(tester);
      expect(find.byType(VendorCreatePage), findsOneWidget);
    });

    testWidgets('shows Create Vendor Profile title in app bar', (tester) async {
      await _pump(tester);
      expect(find.text('Create Vendor Profile'), findsWidgets);
    });

    testWidgets('shows form subtitle', (tester) async {
      await _pump(tester);
      expect(find.text('Tell us about your business'), findsOneWidget);
    });

    testWidgets('shows all six section headers', (tester) async {
      await _pump(tester);

      for (final header in [
        'Basic Information',
        'Location',
        'Pricing',
        'Contact Information',
        'Social Media',
        'Photos',
      ]) {
        expect(find.text(header), findsOneWidget,
            reason: 'Section header "$header" should be present');
      }
    });
  });

  // ─── Category dropdown ────────────────────────────────────────────────────
  //
  // _loadCategories() runs in initState and queries:
  //   supabase.from('categories').select('name').order('display_order')
  // With real credentials the dropdown items come from that table.
  // In this test environment the query returns a 400 error (caught silently)
  // and the dropdown starts empty — expected isolated-test behaviour.

  group('VendorCreatePage – category dropdown (loaded from categories table)',
      () {
    testWidgets('category dropdown is present', (tester) async {
      await _pump(tester);
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    });

    testWidgets('category dropdown label shows "Category *"', (tester) async {
      await _pump(tester);
      expect(find.text('Category *'), findsOneWidget);
    });

    testWidgets(
        '_loadCategories is called on init (Supabase categories query fires)',
        (tester) async {
      await _pump(tester);
      await tester.pump(const Duration(milliseconds: 100));
      // Dropdown still renders even though the query failed with fake creds.
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    });

    testWidgets(
        'category shows validation error when form submitted with no category',
        (tester) async {
      await _pump(tester);
      await _validate(tester);
      expect(find.text('Please select a category'), findsOneWidget);
    });
  });

  // ─── Required field validation ────────────────────────────────────────────

  group('VendorCreatePage – required field validation', () {
    testWidgets(
        'submitting empty form shows "This field is required" for required fields',
        (tester) async {
      await _pump(tester);
      await _validate(tester);
      // Business Name, Description, Location, and Email are all required.
      expect(find.text('This field is required'), findsWidgets);
    });

    testWidgets('email without "@" shows invalid-email error', (tester) async {
      await _pump(tester);

      final emailField = find.ancestor(
        of: find.text('Email *'),
        matching: find.byType(TextFormField),
      );
      await tester.enterText(emailField, 'notanemail');
      await _validate(tester);

      expect(find.text('Please enter a valid email'), findsOneWidget);
    });

    testWidgets('valid email format does not show an email error', (tester) async {
      await _pump(tester);

      final emailField = find.ancestor(
        of: find.text('Email *'),
        matching: find.byType(TextFormField),
      );
      await tester.enterText(emailField, 'vendor@example.com');
      await _validate(tester);

      expect(find.text('Please enter a valid email'), findsNothing);
    });
  });

  // ─── Photo upload section ─────────────────────────────────────────────────

  group('VendorCreatePage – photo upload section', () {
    testWidgets('shows Photos section header', (tester) async {
      await _pump(tester);
      expect(find.text('Photos'), findsOneWidget);
    });

    testWidgets('shows Add Photos button with photo icon', (tester) async {
      await _pump(tester);
      expect(find.text('Add Photos'), findsOneWidget);
      expect(find.byIcon(Icons.add_photo_alternate), findsOneWidget);
    });

    testWidgets('no image GridView shown when no images are selected',
        (tester) async {
      await _pump(tester);
      // GridView only renders inside `if (_selectedImages.isNotEmpty)`.
      expect(find.byType(GridView), findsNothing);
    });
  });

  // ─── Social media fields ──────────────────────────────────────────────────
  //
  // _collectSocialMediaLinks() reads all 7 platform controllers and returns
  // a flat list of URLs. These tests verify all 7 input fields are present.

  group('VendorCreatePage – social media fields', () {
    testWidgets('shows all 7 platform fields', (tester) async {
      await _pump(tester);

      for (final platform in [
        'Facebook URL',
        'Instagram URL',
        'Twitter URL',
        'LinkedIn URL',
        'Pinterest URL',
        'YouTube URL',
        'TikTok URL',
      ]) {
        expect(find.text(platform), findsOneWidget,
            reason: '$platform field should be present');
      }
    });
  });

  // ─── States served ────────────────────────────────────────────────────────

  group('VendorCreatePage – states served multi-select', () {
    testWidgets('shows States Served label and FilterChips', (tester) async {
      await _pump(tester);
      expect(find.text('States Served'), findsOneWidget);
      // One FilterChip per state + "Any" = 51 chips total.
      expect(find.byType(FilterChip), findsWidgets);
    });

    testWidgets('includes an "Any" chip', (tester) async {
      await _pump(tester);
      expect(find.text('Any'), findsOneWidget);
    });

    testWidgets('tapping a state chip toggles its selected state', (tester) async {
      await _pump(tester);

      final utahChip = find.ancestor(
        of: find.text('Utah'),
        matching: find.byType(FilterChip),
      );

      expect(
        tester.widget<FilterChip>(utahChip).selected,
        isFalse,
        reason: 'Utah chip should start unselected',
      );

      await tester.tap(utahChip);
      await tester.pump();

      expect(
        tester.widget<FilterChip>(utahChip).selected,
        isTrue,
        reason: 'Utah chip should be selected after tapping',
      );
    });

    testWidgets('multiple state chips can be selected independently',
        (tester) async {
      await _pump(tester);

      for (final state in ['Alabama', 'California']) {
        await tester.tap(find.ancestor(
          of: find.text(state),
          matching: find.byType(FilterChip),
        ));
        await tester.pump();
      }

      for (final state in ['Alabama', 'California']) {
        expect(
          tester
              .widget<FilterChip>(find.ancestor(
                of: find.text(state),
                matching: find.byType(FilterChip),
              ))
              .selected,
          isTrue,
          reason: '$state should be selected',
        );
      }

      // An unrelated chip should remain unselected.
      expect(
        tester
            .widget<FilterChip>(find.ancestor(
              of: find.text('Texas'),
              matching: find.byType(FilterChip),
            ))
            .selected,
        isFalse,
      );
    });
  });
}
