import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


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
  Map<String, Set<String>> lovedVendorUUIDsCategorizedMap = {};
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
  final supabase = Supabase.instance.client;

  bool isLoaded = false;

  Future<void> loadInitialData() async {
    try {
      final user = supabase.auth.currentUser!;
      final data = await supabase.from('vendors').select();
      final vendors = (data as List).map((e) => e as Map<String, dynamic>).toList();
      Map<String, List<Map<String, dynamic>>> allData = {};

      for (var vendor in vendors) {
        final category = vendor['vendor_category'] ?? 'Other';
        allData.putIfAbsent(category, () => []).add(vendor);
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
      .select('loved_vendor_id, vendors(vendor_category)')
      .eq('loved_user_id', user.id);

      Map<String, Set<String>> lovedVendorsByCategory = {};

      // for (var row in loved) {
      //   final category = row['vendors']['vendor_category'] as String? ?? 'Other';
      //   final vendorId = row['loved_vendor_id'] as String;
      //   lovedVendorsByCategory.putIfAbsent(category, () => <String>{}).add(vendorId);
      // }

      for (var row in loved) {
        final vendorId = row['loved_vendor_id'] as String;
        final category = vendorIdToCategory[vendorId] ?? 'Other';
        lovedVendorsByCategory.putIfAbsent(category, () => <String>{}).add(vendorId);
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
        lovedVendorUUIDsCategorizedMap.putIfAbsent(category, () => {}).add(vendorId);
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