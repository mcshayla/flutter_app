import 'package:flutter/material.dart';
import '../widgets/card.dart';

class CollectionPageTemplate extends StatelessWidget {
  final String pageTitle;
  final Map<String, List<Map<String, String>>> categories;

  const CollectionPageTemplate({
    required this.pageTitle,
    required this.categories,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        children: categories.entries.map((entry) {
          final categoryName = entry.key;
          final items = entry.value;

          return Padding(
            padding: EdgeInsets.all(8),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding( 
                padding: const EdgeInsets.all(8.0),
                child: Text(categoryName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color:Color(0xFF995656),
                  )),
                  
              ),
              SizedBox(
                height: 220,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: items.map((item) {
                    return CustomCard(
                      title: item['name'] ?? "",
                      description: item['description'] ?? "",
                      imageUrl: item['imageUrl'] ?? "",
                      onTap: () {
                        //navigate to detail page
                      },


                    );
                  }).toList(),
                ),
              )
            ]
            )
          );
        }).toList(),
      ),
      // bottomNavigationBar: BottomNav( 
      //       onExploreTap: () {},
      //       onLovedTap: () {},
      //       onYesTap: () {},
      //     ),
    );
  }
}



