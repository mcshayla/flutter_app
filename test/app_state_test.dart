import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:say_yes/appstate.dart';

// Supabase must be initialized before AppState can be constructed because
// AppState holds `final supabase = Supabase.instance.client` as a field
// initializer. We use fake credentials — no real network calls are made until
// methods like .from() or .auth.signIn() are actually invoked.
//
// SharedPreferences.setMockInitialValues({}) is required because
// supabase_flutter uses shared_preferences for session storage, and the
// platform channel is unavailable in the test environment.
Future<void> _ensureSupabaseInitialized() async {
  SharedPreferences.setMockInitialValues({});
  try {
    await Supabase.initialize(
      url: 'https://test.supabase.co',
      anonKey: 'test_anon_key_for_unit_tests',
    );
  } catch (_) {
    // Already initialized (e.g. running alongside other test files).
  }
}

void main() {
  setUpAll(_ensureSupabaseInitialized);

  // Helper so each test gets a fresh AppState with no side effects from auth.
  AppState makeState() => AppState();

  // ─── lovedCategorizedMap getter ────────────────────────────────────────────

  group('AppState.lovedCategorizedMap', () {
    test('returns only the vendors whose IDs appear in lovedVendorUUIDsCategorizedMap',
        () {
      final state = makeState()
        ..allCategorizedMap = {
          'Venue': [
            {'vendor_id': 'v001', 'vendor_name': 'Venue A'},
            {'vendor_id': 'v002', 'vendor_name': 'Venue B'},
          ],
        }
        ..lovedVendorUUIDsCategorizedMap = {
          'Venue': ['v001'],
        };

      final loved = state.lovedCategorizedMap;

      expect(loved['Venue']!.length, equals(1));
      expect(loved['Venue']!.first['vendor_id'], equals('v001'));
    });

    test('excludes vendors whose IDs are not in the loved list', () {
      final state = makeState()
        ..allCategorizedMap = {
          'Venue': [
            {'vendor_id': 'v001'},
            {'vendor_id': 'v002'},
          ],
        }
        ..lovedVendorUUIDsCategorizedMap = {
          'Venue': ['v001'],
        };

      final vendorIds =
          state.lovedCategorizedMap['Venue']!.map((v) => v['vendor_id']).toList();

      expect(vendorIds, contains('v001'));
      expect(vendorIds, isNot(contains('v002')));
    });

    test('omits categories that have no loved vendors', () {
      final state = makeState()
        ..allCategorizedMap = {
          'Venue': [{'vendor_id': 'v001'}],
          'Caterer': [{'vendor_id': 'c001'}],
        }
        ..lovedVendorUUIDsCategorizedMap = {
          'Venue': ['v001'],
          // 'Caterer' intentionally absent
        };

      final loved = state.lovedCategorizedMap;

      expect(loved.containsKey('Venue'), isTrue);
      expect(loved.containsKey('Caterer'), isFalse);
    });

    test('returns empty map when nothing has been hearted', () {
      final state = makeState()
        ..allCategorizedMap = {
          'Venue': [{'vendor_id': 'v001'}],
        }
        ..lovedVendorUUIDsCategorizedMap = {};

      expect(state.lovedCategorizedMap, isEmpty);
    });

    test('handles multiple loved vendors across multiple categories', () {
      final state = makeState()
        ..allCategorizedMap = {
          'Venue': [
            {'vendor_id': 'v001'},
            {'vendor_id': 'v002'},
          ],
          'Caterer': [
            {'vendor_id': 'c001'},
            {'vendor_id': 'c002'},
          ],
          'Florist': [
            {'vendor_id': 'f001'},
          ],
        }
        ..lovedVendorUUIDsCategorizedMap = {
          'Venue': ['v001', 'v002'],
          'Caterer': ['c001'],
          // 'Florist' intentionally absent
        };

      final loved = state.lovedCategorizedMap;

      expect(loved['Venue']!.length, equals(2));
      expect(loved['Caterer']!.length, equals(1));
      expect(loved.containsKey('Florist'), isFalse);
    });

    test('returns empty map when allCategorizedMap is empty', () {
      final state = makeState()
        ..allCategorizedMap = {}
        ..lovedVendorUUIDsCategorizedMap = {'Venue': ['v001']};

      expect(state.lovedCategorizedMap, isEmpty);
    });
  });

  // ─── clearState ───────────────────────────────────────────────────────────

  group('AppState.clearState', () {
    test('resets all state maps to empty', () {
      final state = makeState()
        ..allCategorizedMap = {
          'Venue': [{'vendor_id': 'v001'}]
        }
        ..lovedVendorUUIDsCategorizedMap = {'Venue': ['v001']}
        ..vendorIdToCategory = {'v001': 'Venue'}
        ..diamondedCards = {'Venue': 'v001'};

      state.clearState();

      expect(state.allCategorizedMap, isEmpty);
      expect(state.lovedVendorUUIDsCategorizedMap, isEmpty);
      expect(state.vendorIdToCategory, isEmpty);
      expect(state.diamondedCards, isEmpty);
    });

    test('sets isLoaded to true after clearing', () {
      final state = makeState();
      state.clearState();
      expect(state.isLoaded, isTrue);
    });
  });

  // ─── toggleHeart – unauthenticated guard ──────────────────────────────────

  group('AppState.toggleHeart (no user logged in)', () {
    test('does not add a vendor to lovedVendorUUIDsCategorizedMap', () async {
      final state = makeState()
        ..vendorIdToCategory = {'v001': 'Venue'}
        ..lovedVendorUUIDsCategorizedMap = {};

      await state.toggleHeart('v001', true);

      expect(state.lovedVendorUUIDsCategorizedMap, isEmpty);
    });

    test('does not remove a vendor from lovedVendorUUIDsCategorizedMap', () async {
      final state = makeState();
      // Drain any pending async auth events (e.g. the initial signedOut
      // notification) before setting up test state, so they don't race with
      // our assertions.
      await Future.delayed(Duration.zero);

      state.vendorIdToCategory = {'v001': 'Venue'};
      state.lovedVendorUUIDsCategorizedMap = {'Venue': ['v001']};

      // Attempt to un-heart without a logged-in user.
      await state.toggleHeart('v001', false);

      // State must be preserved — the guard clause returns early.
      expect(state.lovedVendorUUIDsCategorizedMap['Venue'], contains('v001'));
    });
  });

  // ─── toggleDiamond – unauthenticated guard ────────────────────────────────

  group('AppState.toggleDiamond (no user logged in)', () {
    test('does not add an entry to diamondedCards', () async {
      final state = makeState()
        ..vendorIdToCategory = {'v001': 'Venue'}
        ..diamondedCards = {};

      await state.toggleDiamond('v001', true);

      expect(state.diamondedCards, isEmpty);
    });

    test('does not remove an entry from diamondedCards', () async {
      final state = makeState();
      // Drain any pending async auth events before setting up test state.
      await Future.delayed(Duration.zero);

      state.vendorIdToCategory = {'v001': 'Venue'};
      state.diamondedCards = {'Venue': 'v001'};

      await state.toggleDiamond('v001', false);

      // State must be preserved — the guard clause returns early.
      expect(state.diamondedCards['Venue'], equals('v001'));
    });

    test('does nothing when vendorId is empty', () async {
      final state = makeState()..diamondedCards = {};

      await state.toggleDiamond('', true);

      expect(state.diamondedCards, isEmpty);
    });
  });
}
