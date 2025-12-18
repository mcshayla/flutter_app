import 'explore_page.dart';
import 'loved_page.dart';
import 'ai_search_page.dart';
import 'yes_page.dart';
import '../widgets/bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login.dart';
import 'profile_page.dart';

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
        title: Text(
          'easiYESt',
          style: GoogleFonts.bodoniModa(
            fontSize: 36,
            fontWeight: FontWeight.w600, // Medium to Semi-Bold for impact
            letterSpacing: 2.0, // A little spacing for elegance
            color: const Color(0xFFDCC7AA),
          ),
        ),
        actions: [
           IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.white),
            onPressed: () {
               _navigatorKeys[_selectedIndex].currentState?.push(
                  MaterialPageRoute(builder: (_) => const ProfilePage()),
                );
            },
            tooltip: 'Profile',
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              final supabase = Supabase.instance.client;
              await supabase.auth.signOut();

              // Navigate back to login page
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginSignup()),
                  (route) => false, // removes all previous routes
                );
              }
            },
            tooltip: 'Logout',
          ),
          ],
        // title: Text("Easy-yest", style: TextStyle(fontFamily: 'GreatVibes', color:Color(0xFFDCC7AA) )),
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
          _buildTabNavigator(3, const AISearchPage())
        ]
      ),
      bottomNavigationBar: BottomNav(
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
      )
    );
  }
}