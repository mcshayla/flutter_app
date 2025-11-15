import 'explore_page.dart';
import 'loved_page.dart';
import 'yes_page.dart';
import '../widgets/bottom_nav.dart';
import 'package:flutter/material.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0;

  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  void _onTabTapped(int index) {
    if (_selectedIndex == index) {
      _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
    } else {
      setState(() => _selectedIndex = index);
    }
  }

  Widget _buildTabNavigator(int index, Widget child) {
    return Navigator(
      key: _navigatorKeys[index],
      onGenerateRoute: (settings) => MaterialPageRoute(
        builder: (context) => child,
      ),
    );
  }
 

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text("Yes-said-easy", style: TextStyle(fontFamily: 'GreatVibes', color:Color(0xFFDCC7AA) )),
        backgroundColor:Color(0xFF7B3F61) ,
        centerTitle: true,
        elevation: 4.0

      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildTabNavigator(0, const ExplorePage()),
          _buildTabNavigator(1, const LovedPage()),
          _buildTabNavigator(2, const YesPage()),
        ]
      ),
      bottomNavigationBar: BottomNav(
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
      )
    );
  }
}