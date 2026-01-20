import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  Map<String, List<Map<String, dynamic>>> _vendorReviews = {};

  final supabase = Supabase.instance.client;

  bool isLoaded = false;

  bool showOnboarding = false;

  AppState() {
    // 👇 LISTEN TO AUTH CHANGES
    supabase.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      final user = session?.user;

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

  Future<void> loadOnboardingFlag() async {
    final prefs = await SharedPreferences.getInstance();
    showOnboarding = !(prefs.getBool('seen_onboarding') ?? false);
    notifyListeners();
  }

  Future<void> markOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_onboarding', true);
    showOnboarding = false;
    notifyListeners();
  }

  void clearState() {
    allCategorizedMap = {};
    lovedVendorUUIDsCategorizedMap = {};
    vendorIdToCategory = {};
    diamondedCards = {};
    isLoaded = true;
  }

  String _transformCategoryKey(String dbColumnName) {
        if (dbColumnName == 'dj') return 'DJ';
        
        return dbColumnName
            .split('_')
            .map((word) => word == 'and' ? '&' : word.capitalize())
            .join(' ');
      }

  Future<void> loadInitialData() async {

    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        isLoaded = false;
        notifyListeners();
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
        final vendors = entry.value;

        for (var vendor in vendors) {

          final id = vendor['vendor_id'];
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
      .select('*')
      .eq('user_id', user.id)
      .single();

      const ignoreFields = {'user_id', 'email', 'username', 'created_at'};

      diamondedCards = {
        for (var entry in diamonded.entries)
          if (!ignoreFields.contains(entry.key))
            _transformCategoryKey(entry.key): entry.value ?? ''
      };

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


  Future<void> trackCardClick(String vendorId) async {
    final supabase = Supabase.instance.client;

    await supabase.rpc(
      'increment_vendor_click',
      params: {
        'vendor_uuid': vendorId,
        'field_name': 'clicks_on_card',
      },
      );
    }

  Future<void> trackLinksClick(String vendorId) async {
    final supabase = Supabase.instance.client;

    await supabase.rpc(
      'increment_vendor_click',
      params: {
        'vendor_uuid': vendorId,
        'field_name': 'clicks_on_links',
      },
      );
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
    if (user == null || vendorId.isEmpty) return;

    final displayCategory = (vendorIdToCategory[vendorId] ?? 'other');
    final dbCategory = (vendorIdToCategory[vendorId] ?? 'other')
      .toLowerCase()
      .replaceAll(' ', '_')
      .replaceAll('&', 'and');

    try {
      if (diamonded) {
        diamondedCards[displayCategory] = vendorId;
      } else {
        diamondedCards.remove(displayCategory);
      }

      await supabase.from('users').upsert({
        'user_id': user.id,
        dbCategory: diamonded ? vendorId : null,
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

// Get reviews for a specific vendor
Future<List<Map<String, dynamic>>?> getReviewsForVendor(String vendorId) async {
  final supabase = Supabase.instance.client;
  
  try {
    // Fetch reviews from database
    final response = await supabase
        .from('reviews')
        .select()
        .eq('vendor_id', vendorId)
        .order('created_at', ascending: false);
    
    // Transform the data
    final reviews = (response as List).map((review) {
      return {
        'id': review['id'],
        'rating': review['rating'],
        'comment': review['comment'] ?? '',
        'userName': 'User', // You can fetch user names separately if needed
        'date': DateTime.parse(review['created_at']),
        'userId': review['user_id'],
      };
    }).toList();
    
    // Cache in memory
    _vendorReviews[vendorId] = reviews;
    
    return reviews;
  } catch (e) {
    print("Error fetching reviews: $e");
    // Return cached data if available
    return _vendorReviews[vendorId];
  }
}

// Submit a new review
Future<void> submitReview(String vendorId, int rating, String comment) async {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;
  
  if (user == null) return;
  
  try {
    // Insert or update review
    await supabase.from('reviews').upsert({
      'user_id': user.id,
      'vendor_id': vendorId,
      'rating': rating,
      'comment': comment,
      'created_at': DateTime.now().toIso8601String(),
    });
    
    // Refresh reviews for this vendor
    await getReviewsForVendor(vendorId);
    
    notifyListeners();
  } catch (e) {
    print("Error submitting review: $e");
  }
}

// Optional: Get average rating without fetching all reviews
Future<double> getAverageRating(String vendorId) async {
  final supabase = Supabase.instance.client;
  
  try {
    final response = await supabase
        .rpc('get_average_rating', params: {'vendor_uuid': vendorId});
    
    return (response ?? 0.0).toDouble();
  } catch (e) {
    print("Error getting average rating: $e");
    return 0.0;
  }
}

}