import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppState extends ChangeNotifier {
  Map<String, List<Map<String, dynamic>>> allCategorizedMap = {};
  Map<String, List<String>> lovedVendorUUIDsCategorizedMap = {};
  Map<String, String> vendorIdToCategory = {};
  Map<String, String> diamondedCards = {};
  Map<String, List<Map<String, dynamic>>> _vendorReviews = {};

  // Wedding Profile
  Map<String, dynamic>? weddingProfile;

  // Checklist
  List<Map<String, dynamic>> checklistItems = [];

  // Budget
  Map<String, dynamic>? userBudget;
  List<Map<String, dynamic>> budgetItems = [];

  // Guest List
  List<Map<String, dynamic>> guests = [];

  final supabase = Supabase.instance.client;

  bool isLoaded = false;

  bool showOnboarding = false;

  AppState() {
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
    weddingProfile = null;
    checklistItems = [];
    userBudget = null;
    budgetItems = [];
    guests = [];
    isLoaded = true;
  }

  Future<void> loadInitialData() async {

    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        isLoaded = false;
        notifyListeners();
        return;
      }
      final data = await supabase.from('vendors').select();
      final vendors = (data as List).map((e) => e as Map<String, dynamic>).toList();
      Map<String, List<Map<String, dynamic>>> allData = {};

      for (var vendor in vendors) {
        final category = vendor['vendor_category'] ?? 'Other';
        allData.putIfAbsent(category, () => []).add(vendor);
      }

      for (var category in allData.keys) {
        allData[category]!.shuffle();
      }

      final categoryRows = await supabase
          .from('categories')
          .select('name')
          .order('display_order', ascending: true);
      final orderedNames = (categoryRows as List).map((r) => r['name'] as String).toList();

      allCategorizedMap = {
        for (final name in orderedNames)
          if (allData.containsKey(name)) name: allData[name]!,
        for (final entry in allData.entries)
          if (!orderedNames.contains(entry.key)) entry.key: entry.value,
      };

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

      final diamondedRows = await supabase
          .from('user_diamonds')
          .select('vendor_id, category')
          .eq('user_id', user.id);

      diamondedCards = {
        for (final row in diamondedRows as List)
          row['category'] as String: row['vendor_id'] as String
      };

      for (var row in loved) {
        final vendorId = row['loved_vendor_id'] as String;
        final category = vendorIdToCategory[vendorId] ?? 'Other';
        lovedVendorsByCategory.putIfAbsent(category, () => <String>[]).add(vendorId);
      }

      lovedVendorUUIDsCategorizedMap = lovedVendorsByCategory;

      // Load wedding profile, checklist, budget, and guests
      await Future.wait([
        loadWeddingProfile(),
        loadChecklist(),
        loadBudget(),
        loadGuests(),
      ]);

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

    final category = vendorIdToCategory[vendorId] ?? 'Other';

    try {
      if (diamonded) {
        diamondedCards[category] = vendorId;
        await supabase.from('user_diamonds').upsert({
          'user_id': user.id,
          'vendor_id': vendorId,
          'category': category,
        });
      } else {
        diamondedCards.remove(category);
        await supabase
            .from('user_diamonds')
            .delete()
            .eq('user_id', user.id)
            .eq('category', category);
      }
      notifyListeners();
    } catch (e) {
      print('Error toggling diamond: $e');
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

// ==================== WEDDING PROFILE ====================

Future<void> loadWeddingProfile() async {
  try {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final response = await supabase
        .from('wedding_profiles')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();

    weddingProfile = response;
  } catch (e) {
    print("Error loading wedding profile: $e");
  }
}

int? get daysUntilWedding {
  if (weddingProfile == null || weddingProfile!['wedding_date'] == null) return null;
  final weddingDate = DateTime.tryParse(weddingProfile!['wedding_date']);
  if (weddingDate == null) return null;
  return weddingDate.difference(DateTime.now()).inDays;
}

// ==================== CHECKLIST ====================

Future<void> loadChecklist() async {
  try {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final response = await supabase
        .from('user_checklist_items')
        .select()
        .eq('user_id', user.id)
        .order('display_order', ascending: true);

    checklistItems = (response as List).map((e) => e as Map<String, dynamic>).toList();
  } catch (e) {
    print("Error loading checklist: $e");
  }
}

Future<void> initializeChecklist(DateTime weddingDate) async {
  try {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    // Check if user already has checklist items
    final existing = await supabase
        .from('user_checklist_items')
        .select('id')
        .eq('user_id', user.id)
        .limit(1);

    if ((existing as List).isNotEmpty) return;

    // Fetch templates
    final templates = await supabase
        .from('checklist_templates')
        .select()
        .order('display_order', ascending: true);

    final items = <Map<String, dynamic>>[];
    for (var template in templates as List) {
      final monthsBefore = template['months_before'] as int? ?? 0;
      final dueDate = weddingDate.subtract(Duration(days: monthsBefore * 30));

      items.add({
        'user_id': user.id,
        'template_id': template['id'],
        'title': template['title'],
        'description': template['description'] ?? '',
        'category': template['category'] ?? 'Other',
        'is_completed': false,
        'due_date': dueDate.toIso8601String().split('T')[0],
        'display_order': template['display_order'] ?? 0,
        'notes': '',
      });
    }

    if (items.isNotEmpty) {
      await supabase.from('user_checklist_items').insert(items);
      await loadChecklist();
      notifyListeners();
    }
  } catch (e) {
    print("Error initializing checklist: $e");
  }
}

Future<void> toggleChecklistItem(String itemId, bool completed) async {
  try {
    // Optimistic update
    final index = checklistItems.indexWhere((item) => item['id'] == itemId);
    if (index != -1) {
      checklistItems[index]['is_completed'] = completed;
      notifyListeners();
    }

    await supabase
        .from('user_checklist_items')
        .update({'is_completed': completed})
        .eq('id', itemId);
  } catch (e) {
    print("Error toggling checklist item: $e");
  }
}

Future<void> addChecklistItem(String title, String category, {String? description, String? dueDate}) async {
  try {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final maxOrder = checklistItems.isNotEmpty
        ? checklistItems.map((i) => i['display_order'] as int? ?? 0).reduce((a, b) => a > b ? a : b) + 1
        : 0;

    await supabase.from('user_checklist_items').insert({
      'user_id': user.id,
      'title': title,
      'description': description ?? '',
      'category': category,
      'is_completed': false,
      'due_date': dueDate,
      'display_order': maxOrder,
      'notes': '',
    });

    await loadChecklist();
    notifyListeners();
  } catch (e) {
    print("Error adding checklist item: $e");
  }
}

Future<void> updateChecklistItemNotes(String itemId, String notes) async {
  try {
    final index = checklistItems.indexWhere((item) => item['id'] == itemId);
    if (index != -1) {
      checklistItems[index]['notes'] = notes;
    }

    await supabase
        .from('user_checklist_items')
        .update({'notes': notes})
        .eq('id', itemId);
  } catch (e) {
    print("Error updating checklist notes: $e");
  }
}

Future<void> deleteChecklistItem(String itemId) async {
  try {
    checklistItems.removeWhere((item) => item['id'] == itemId);
    notifyListeners();

    await supabase
        .from('user_checklist_items')
        .delete()
        .eq('id', itemId);
  } catch (e) {
    print("Error deleting checklist item: $e");
  }
}

double get checklistProgress {
  if (checklistItems.isEmpty) return 0;
  final completed = checklistItems.where((i) => i['is_completed'] == true).length;
  return completed / checklistItems.length;
}

// ==================== BUDGET ====================

Future<void> loadBudget() async {
  try {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final budgetResponse = await supabase
        .from('user_budgets')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();

    userBudget = budgetResponse;

    final itemsResponse = await supabase
        .from('budget_items')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: true);

    budgetItems = (itemsResponse as List).map((e) => e as Map<String, dynamic>).toList();
  } catch (e) {
    print("Error loading budget: $e");
  }
}

Future<void> setTotalBudget(double amount) async {
  try {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    await supabase.from('user_budgets').upsert({
      'user_id': user.id,
      'total_budget': amount,
    }, onConflict: 'user_id');

    userBudget = {'user_id': user.id, 'total_budget': amount};
    notifyListeners();
  } catch (e) {
    print("Error setting budget: $e");
  }
}

Future<void> addBudgetItem({
  required String category,
  required String itemName,
  required double estimatedCost,
  double? actualCost,
  String? vendorId,
  String? notes,
}) async {
  try {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    await supabase.from('budget_items').insert({
      'user_id': user.id,
      'category': category,
      'item_name': itemName,
      'estimated_cost': estimatedCost,
      'actual_cost': actualCost,
      'vendor_id': vendorId,
      'is_paid': false,
      'notes': notes ?? '',
    });

    await loadBudget();
    notifyListeners();
  } catch (e) {
    print("Error adding budget item: $e");
  }
}

Future<void> updateBudgetItem(String itemId, Map<String, dynamic> updates) async {
  try {
    await supabase.from('budget_items').update(updates).eq('id', itemId);
    await loadBudget();
    notifyListeners();
  } catch (e) {
    print("Error updating budget item: $e");
  }
}

Future<void> deleteBudgetItem(String itemId) async {
  try {
    budgetItems.removeWhere((item) => item['id'] == itemId);
    notifyListeners();

    await supabase.from('budget_items').delete().eq('id', itemId);
  } catch (e) {
    print("Error deleting budget item: $e");
  }
}

double get totalEstimated {
  return budgetItems.fold(0, (sum, item) => sum + ((item['estimated_cost'] as num?)?.toDouble() ?? 0));
}

double get totalActual {
  return budgetItems.fold(0, (sum, item) => sum + ((item['actual_cost'] as num?)?.toDouble() ?? 0));
}

double get totalBudgetAmount {
  return (userBudget?['total_budget'] as num?)?.toDouble() ?? 0;
}

// ==================== GUEST LIST ====================

Future<void> loadGuests() async {
  try {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final response = await supabase
        .from('guests')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: true);

    guests = (response as List).map((e) => e as Map<String, dynamic>).toList();
  } catch (e) {
    print("Error loading guests: $e");
  }
}

Future<void> addGuest(Map<String, dynamic> guestData) async {
  try {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    await supabase.from('guests').insert({
      'user_id': user.id,
      ...guestData,
    });

    await loadGuests();
    notifyListeners();
  } catch (e) {
    print("Error adding guest: $e");
  }
}

Future<void> updateGuest(String guestId, Map<String, dynamic> updates) async {
  try {
    await supabase.from('guests').update(updates).eq('id', guestId);
    await loadGuests();
    notifyListeners();
  } catch (e) {
    print("Error updating guest: $e");
  }
}

Future<void> deleteGuest(String guestId) async {
  try {
    guests.removeWhere((g) => g['id'] == guestId);
    notifyListeners();

    await supabase.from('guests').delete().eq('id', guestId);
  } catch (e) {
    print("Error deleting guest: $e");
  }
}

int get guestCountByStatus {
  return guests.length;
}

Map<String, int> get guestStatusCounts {
  final counts = <String, int>{
    'not_sent': 0,
    'invited': 0,
    'accepted': 0,
    'declined': 0,
    'maybe': 0,
  };
  for (var guest in guests) {
    final status = guest['rsvp_status'] as String? ?? 'not_sent';
    counts[status] = (counts[status] ?? 0) + 1;
  }
  return counts;
}

}