import 'package:flutter/material.dart';
import '../widgets/card.dart';

class CategoryPageTemplate extends StatelessWidget {
  final String pageTitle;
  final Map<String, List<Map<String, dynamic>>> categories;

  const CategoryPageTemplate({
    required this.pageTitle,
    required this.categories,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final categoryKeys = categories.keys.toList();
    return Scaffold(
      // appBar: AppBar(),
      body: Column(
        children: [
          if (Navigator.canPop(context))
            IconButton(icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          // Constrain the main ListView inside Expanded so Column provides bounded height
          Expanded(
            child: ListView.builder(
              itemCount: categoryKeys.length,
              itemBuilder: (context, index) {
                final categoryName = categoryKeys[index];
                final items = categories[categoryName]!;
              
              // children: categories.entries.map((entry) {
              //   final categoryName = entry.key;
              //   final items = entry.value;

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
                              categoryName,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF7B3F61),
                                  ),
                            ),
                            GestureDetector(
                              child: Text(
                                "View All $categoryName",
                                style: const TextStyle(fontSize: 12),
                              ),
                              onTap: () {
                                // TODO: navigate to category page
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
                          // children: items.map((item) {
                            return CustomCard(
                              title: item['vendor_name'] ?? "",
                              description: item['vendor_description'] ?? "",
                              imageUrl: item['image_url'] ?? "",
                              onTap: () {
                                // navigate to detail page
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



