import 'package:flutter/material.dart';

class BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final GlobalKey? lovedTabKey;
  final GlobalKey? diamondTabKey;
  final GlobalKey? profileTabKey;
  final bool hasVendor;

  const BottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.lovedTabKey,
    this.diamondTabKey,
    this.profileTabKey,
    this.hasVendor = false,
  });

  @override
  Widget build(BuildContext context) {
    // Build items list dynamically so indices stay consistent
    final items = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined),
        label: 'Explore',
      ),
      BottomNavigationBarItem(
        icon: Container(
          key: lovedTabKey,
          child: const Icon(Icons.favorite_border),
        ),
        label: 'Loved',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.checklist),
        label: 'Plan',
      ),
      BottomNavigationBarItem(
        icon: Container(
          key: diamondTabKey,
          child: const Icon(Icons.diamond_outlined),
        ),
        label: 'YES',
      ),
      if (hasVendor)
        const BottomNavigationBarItem(
          icon: Icon(Icons.business_outlined),
          label: 'Vendor',
        ),
    ];

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      onTap: onTap,
      backgroundColor: const Color(0xFF7B3F61),
      unselectedItemColor: Colors.white,
      selectedItemColor: const Color(0xFFDCC7AA),
      items: items,
    );
  }
}
