import 'package:flutter/material.dart';
import '../widgets/card.dart';
import '../appstate.dart';
import 'package:provider/provider.dart';
import '../utils/string_extensions.dart';


class CategoryPageTemplate extends StatelessWidget {
  final String categoryName;
  final bool showOnlyLoved;

  const CategoryPageTemplate({
    required this.categoryName,
    required this.showOnlyLoved,
    super.key
  });

  @override
  Widget build(BuildContext context) {
    String capCategoryName = categoryName.capitalize().pluralize();
    return Consumer<AppState>(
      builder:(context, appState, child) {
          final List<Map<String, dynamic>> categoryList = showOnlyLoved
            ? (appState.lovedCategorizedMap[categoryName] ?? [])
            : (appState.allCategorizedMap[categoryName]  ?? []);

        return Scaffold(
          body: Column( 
            children: [
              if (Navigator.canPop(context))
                Row( 
                  children: [
                    IconButton(icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                    showOnlyLoved ?
                    Text("My Loved $capCategoryName") : Text(capCategoryName)
                  ]
                ),
              (categoryList.isEmpty) ? const Center(
                  child: Text(
                    "No vendors for this category to display",
                    style: TextStyle(fontSize: 16),
                  ),
                ): 
            Expanded( 
              child:Padding(
              padding: const EdgeInsets.all(12.0),
              child:GridView.builder( 
                itemCount: categoryList.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.75,
                ),
                itemBuilder:(context, index) {
                  final item = categoryList[index];
                  return CustomCard(
                    title: item['vendor_name'] ?? "",
                    description: item['vendor_description'] ?? "",
                    imageUrl: item['image_url'] ?? "",
                    isHearted: appState.lovedVendorUUIDsCategorizedMap[categoryName]?.contains(item['vendor_id']) ?? false,
                    onHeartToggled: (hearted) {
                      appState.toggleHeart(item['vendor_id'], hearted);
                    },
                    isDiamonded: appState.diamondedCards[appState.vendorIdToCategory[item['vendor_id']]?.toLowerCase()] == item['vendor_id'],
                    onDiamondToggled: (diamonded) {
                      appState.toggleDiamond(item['vendor_id'], diamonded);
                    },
                    // initialHearted: appState.lovedVendorUUIDsCategorizedMap[categoryName]?.contains(item['vendor_id']) ?? false,
                    onTap: () {
                      // navigate to detail page
                      // Navigator.push()
                    },
                  );
                },
              )
            )
            )
            ]
          )
        );
      }
    );
  }
}