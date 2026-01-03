import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';


class BottomNav extends StatelessWidget {

  final int currentIndex;
  final ValueChanged<int> onTap;
  final GlobalKey? lovedTabKey;
  final GlobalKey? diamondTabKey;
  final GlobalKey? profileTabKey;


  const BottomNav({super.key,  
    required this.currentIndex,
    required this.onTap,
    this.lovedTabKey,
    this.diamondTabKey,
    this.profileTabKey

  });

  @override
  Widget build(BuildContext context) {

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      onTap: onTap,
      backgroundColor: Color(0xFF7B3F61),
      unselectedItemColor: Colors.white,
      selectedItemColor: Color(0xFFDCC7AA),
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          label: 'Explore'
        ),BottomNavigationBarItem(
          icon: Container(
            key: lovedTabKey, // ← Loved tab key
            child: Icon(Icons.favorite_border),
          ),
          label: 'Loved'
        ),
        BottomNavigationBarItem(
          icon: Container(
            key: diamondTabKey, // ← Diamond tab key
            child: Icon(Icons.diamond_outlined),
          ),
          label: 'YES'
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.lightbulb_outline),
          label: 'Search'
        ),
      ],
      );
  }
}