import 'package:flutter/material.dart';

class CustomCard extends StatelessWidget {

  final String title;
  final String description;
  final String imageUrl;
  final VoidCallback? onTap;

  const CustomCard({
    required this.title, required this.description, required this.imageUrl, this.onTap, super.key //the super key being the id from the database for the venue or whatever
  });

  @override
  Widget build(BuildContext context) {
    const double cardWidth = 160;
    const double cardHeight = 240;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: cardWidth,
        height: cardHeight,
        margin: EdgeInsets.all(8),
        decoration: BoxDecoration(
          // color: const Color.fromARGB(235, 111, 51, 72),
          color: const Color.fromARGB(255, 143, 96, 96),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(2,2),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image.network(imageUrl, fit: BoxFit.cover,),
              Expanded( 
                child: Image.network(
                "https://picsum.photos/200/300",
                width: double.infinity,
                fit: BoxFit.cover,
              ),
              ),
              Container(
                height: 84,
                padding: EdgeInsets.all(12),
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                  SizedBox(height: 4),
                  Text(description, overflow: TextOverflow.ellipsis)
                ],))
            ]

          )
        )
      )

    );
  }
}