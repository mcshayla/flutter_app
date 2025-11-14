import 'package:flutter/material.dart';
import '../templates/collection_page_template.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key});

  Future<Map<String, List<Map<String, dynamic>>>> fetchExploreData() async {
    final supabase = Supabase.instance.client;
    try {
      final data = await supabase.from('vendors').select();

      final vendors = (data as List).map((e) => e as Map<String, dynamic>).toList();
      final Map<String, List<Map<String, dynamic>>> categorized = {};

      for (var vendor in vendors) {
        final category = vendor['vendor_category'] ?? 'Other';
        categorized.putIfAbsent(category, () => []).add(vendor);
      }
      return categorized;

    } catch (e) {
      print("Error fetching vendors: $e");
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
      future: fetchExploreData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          print("Future completed with error: ${snapshot.error}");
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          print("Future completed but no data!");
          return const Center(child: Text('No data found'));
        }

        final categoriesMap = snapshot.data!;

        return CollectionPageTemplate(
          pageTitle: "Explore",
          categories: categoriesMap,
          onHeartToggled: (vendorId, hearted) async {
            final supabase = Supabase.instance.client;

            try {
              await supabase
              .from('users_loved')
              .upsert({
                'loved_user_id': supabase.auth.currentUser!.id,
                'loved_vendor_id': vendorId,
                'hearted': hearted
              });
            } catch (e) {
              print("error in explore onheartoggled ${e}");
            }
          }
        );
      },
    );
  }
}
