import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';


class BottomNav extends StatelessWidget {

  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNav({ 
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      backgroundColor: Color(0xFFAEB081),
      unselectedItemColor: Colors.white,
      selectedItemColor: Color(0xFF995656),
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          label: 'Explore'
        ),BottomNavigationBarItem(
          icon: Icon(Icons.favorite_border),
          label: 'Loved'
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.diamond_outlined),
          label: 'YES'
        )
      ],
      );
  }
}