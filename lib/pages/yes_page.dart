import 'package:flutter/material.dart';
import '../templates/collection_page_template.dart';


class YesPage extends StatelessWidget {
  const YesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final data = {
      "Venues": [
      {
        "name": "Grand Hall",
        "description": "Elegant venue",
        "imageUrl": "https://picsum.photos/150?random=1"
      },
      {
        "name": "Rosewood Gardens",
        "description": "Outdoor garden venue",
        "imageUrl": "https://picsum.photos/150?random=1"
      },
    ],
    "Florists": [
      {
        "name": "Petal & Stem",
        "description": "Local florist",
        "imageUrl": "https://picsum.photos/150?random=1"
      },
      {
        "name": "Bloom Co.",
        "description": "High-end wedding flowers",
        "imageUrl": "https://picsum.photos/150?random=1"
      },
      {
        "name": "Bloom bloom",
        "description": "lotsa lotsa lotsa flowers",
        "imageUrl": "https://picsum.photos/150?random=1"
      },
    ],
    "Caterers": [
      {
        "name": "Yum Catering",
        "description": "Gourmet menu",
        "imageUrl": "https://picsum.photos/150?random=1"
      },
      {
        "name": "Feast & Fun",
        "description": "Buffet style",
        "imageUrl": "https://picsum.photos/150?random=1"
      },
      {
        "name": "Yum Yum",
        "description": "oh yeah",
        "imageUrl": "https://picsum.photos/150?random=1"
      },
      {
        "name": "lets eat",
        "description": "yay yay yay",
        "imageUrl": "https://picsum.photos/150?random=1"
      },
    ],
    };

    return CollectionPageTemplate(
      pageTitle: "Yes",
      categories: data,
      isLovedPage: true,
    );
  }
}