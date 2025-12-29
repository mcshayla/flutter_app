import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './utils/string_extensions.dart';


class AppState extends ChangeNotifier {
  Map<String, List<Map<String, dynamic>>> allCategorizedMap = {}; 
  //"Venue": [
  //   {
  //     "vendor_id": "v001",
  //     "vendor_name": "Wadley Farms",
  //     ...ALL THE THINGS 
  // "Caterer": [
  //   {
  //     "vendor_id": "c001",
  //     "vendor_name": "Gourmet Catering",
  Map<String, List<String>> lovedVendorUUIDsCategorizedMap = {};
// lovedVendorUUIDsCategorizedMap = {
//   "Venue": {"v001"}, // user hearted Wadley Farms
//   "Caterer": {}
// };
  Map<String, String> vendorIdToCategory = {};
//   vendorIdToCategory = {
//   "v001": "Venue",
//   "v002": "Venue",
//   "c001": "Caterer"
// };

  Map<String, String> diamondedCards = {};
  // diamondedCards = {
  // "venue": "pretty mountain venue"
  // "florist": "becca's floral"}
  final supabase = Supabase.instance.client;

  bool isLoaded = false;


  AppState() {
    // 👇 LISTEN TO AUTH CHANGES
    supabase.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      final user = session?.user;

      print("🔥 auth state changed, user = $user");

      if (user == null) {
        // User logged out
        clearState();
        notifyListeners();
      } else {
        // User logged in or restored → NOW load data
        loadInitialData();
      }
    });
  }

  void clearState() {
    allCategorizedMap = {};
    lovedVendorUUIDsCategorizedMap = {};
    vendorIdToCategory = {};
    diamondedCards = {};
    isLoaded = true;
  }

  Future<void> loadInitialData() async {

    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        // No signed-in user yet; avoid crashing and just set loaded=false
        isLoaded = false;
        notifyListeners();
        print('loadInitialData: no authenticated user present');
        return;
      }
      final data = await supabase.from('vendors').select(); //CHANGE TO VENDORS
      final vendors = (data as List).map((e) => e as Map<String, dynamic>).toList();
      Map<String, List<Map<String, dynamic>>> allData = {};

      for (var vendor in vendors) {
        final category = vendor['vendor_category'] ?? 'Other';
        allData.putIfAbsent(category, () => []).add(vendor);
      }

      for (var category in allData.keys) {
        allData[category]!.shuffle();
      }

      allCategorizedMap = allData;

      vendorIdToCategory.clear();

      for (var entry in allCategorizedMap.entries) {
        final category = entry.key;
        print('category $category');
        final vendors = entry.value;

        for (var vendor in vendors) {

          final id = vendor['vendor_id'];
          print('id $id');
          if (id != null) {
            vendorIdToCategory[id] = category;
          }
        }

      }

      final loved = await supabase
      .from('users_loved')
      .select('loved_vendor_id, created_at')
      .eq('loved_user_id', user.id)
      .order('created_at', ascending: false);

      Map<String, List<String>> lovedVendorsByCategory = {};

      final diamonded = await supabase
      .from('users')
      .select('venue, catering, florist, photographer')
      .eq('user_id', user.id);

      if (diamonded.isNotEmpty) {
        final row = diamonded[0] as Map<String, dynamic>;
        diamondedCards = {
          'venue': row['venue'] ?? '',
          'catering': row['catering'] ?? '',
          'florist': row['florist'] ?? '',
          'photographer': row['photographer'] ?? '',
        };
      }

      for (var row in loved) {
        final vendorId = row['loved_vendor_id'] as String;
        final category = vendorIdToCategory[vendorId] ?? 'Other';
        lovedVendorsByCategory.putIfAbsent(category, () => <String>[]).add(vendorId);
      }

      lovedVendorUUIDsCategorizedMap = lovedVendorsByCategory;
      isLoaded = true;
      notifyListeners();
    } catch (e) {
      print("error in appstate.dart $e");
    }
  
  }

  Future<void> toggleHeart(String vendorId, bool hearted) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final category = vendorIdToCategory[vendorId] ?? 'Other';

    try {
      if (hearted) {
        lovedVendorUUIDsCategorizedMap.putIfAbsent(category, () => <String>[]).insert(0, vendorId);
      } else {
        lovedVendorUUIDsCategorizedMap[category]?.remove(vendorId);
      }

      await supabase.from('users_loved').upsert({
        'loved_user_id': user.id,
        'loved_vendor_id': vendorId,
        'hearted': hearted,
      });
      notifyListeners();
    }  catch (e) {
      print("Error toggling heart: $e");
    }
  }

  Future<void> toggleDiamond(String vendorId, bool diamonded) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final category = vendorIdToCategory[vendorId]?.lowerCase() ?? 'Other';

    try {
      if (diamonded) {
        diamondedCards[category] = vendorId;
      } else {
        diamondedCards.remove(category);
      }

      await supabase.from('users').upsert({
        'user_id': user.id,
        category: vendorId,
      });

      notifyListeners();
    }  catch (e) {
      print("Error toggling diamond: $e");
    }
  }

  Map<String, List<Map<String, dynamic>>> get lovedCategorizedMap {
    final lovedMap = <String, List<Map<String, dynamic>>>{};
    allCategorizedMap.forEach((category, vendors) {
      final lovedVendors = vendors
      .where((v) => lovedVendorUUIDsCategorizedMap[category]?.contains(v['vendor_id']) ?? false)
      .toList();
    if (lovedVendors.isNotEmpty) lovedMap[category] = lovedVendors;
    });
    return lovedMap;
  }
}