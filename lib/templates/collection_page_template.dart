import 'package:flutter/material.dart';
import 'package:say_yes/utils/string_extensions.dart';
import '../widgets/card.dart';
import '../appstate.dart';
import 'package:provider/provider.dart';
import 'category_template.dart';
import '../utils/string_extensions.dart';

class CollectionPageTemplate extends StatelessWidget {
  final String pageTitle;
  final Map<String, List<Map<String, dynamic>>> categories;
  final Function(String vendorId, bool isHearted)? onHeartToggled;
  final bool isLovedPage;

  const CollectionPageTemplate({
    required this.pageTitle,
    required this.categories,
    this.onHeartToggled,
    required this.isLovedPage,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final categoryKeys = categories.keys.toList();
    return Scaffold(
      // appBar: AppBar(),
      body: Column(
        children: [
          Expanded(
            child: categoryKeys.isEmpty
              ? const Center(
                  child: Text(
                    "No vendors to display",
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : ListView.builder(
              itemCount: categoryKeys.length,
              itemBuilder: (context, index) {
                final categoryName = categoryKeys[index];
                final items = categories[categoryName]!;
                String capCategoryName = categoryName.capitalize().pluralize();
                return Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              capCategoryName,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF7B3F61),
                                  ),
                            ),
                            GestureDetector(
                              child: Text(
                                "View All $capCategoryName",
                                style: const TextStyle(fontSize: 12),
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:(_) => CategoryPageTemplate(
                                      categoryName: categoryName,
                                      showOnlyLoved: isLovedPage,
                                    )
                                )
                                );
                              },
                            )
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 220,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: items.length,
                          itemBuilder: (context, itemIndex) {

                            final item = items[itemIndex];
                            // bool isLoved = appState.lovedVendorUUIDsCategorizedMap[categoryName]?.contains(item['vendor_id']) ?? false;
                            return CustomCard(
                              title: item['vendor_name'] ?? "",
                              description: item['vendor_description'] ?? "",
                              imageUrl: item['image_url'] ?? "",
                              isHearted: appState.lovedVendorUUIDsCategorizedMap[categoryName]?.contains(item['vendor_id']) ?? false,
                              isDiamonded: appState.diamondedCards[appState.vendorIdToCategory[item['vendor_id']]?.toLowerCase()] == item['vendor_id'],
                              onHeartToggled: (hearted) {
                                appState.toggleHeart(item['vendor_id'], hearted);
                              },
                              onDiamondToggled: (diamonded) {
                                appState.toggleDiamond(item['vendor_id'], diamonded);
                              },
                              onTap: () {
                                // navigate to detail page
                                // Navigator.push()
                              },
                            );
                          })
                        ),
                    ],
                  ),
                );
              })
            ),
        ],
      ),
    );
  }
}



