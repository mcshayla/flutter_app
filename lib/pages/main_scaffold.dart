import 'explore_page.dart';
import 'loved_page.dart';
import 'ai_search_page.dart';
import 'yes_page.dart';
import '../widgets/bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../appstate.dart';
import 'login.dart';
import 'profile_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'tutorial.dart';
import 'vendor_dashboard.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0;
  bool _hasVendor = false;
  late List<GlobalKey<NavigatorState>> _navigatorKeys;

  @override
  void initState() {
    super.initState();
    _initializeNavigatorKeys();
    _showTutorialIfFirstTime();
    _checkVendorStatus();
  }

  Future<void> _checkVendorStatus() async {
    final hasVendor = await _hasClaimedVendor();
    setState(() {
      _hasVendor = hasVendor;
    });
  }

  Future<bool> _hasClaimedVendor() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return false;

    try {
      final result = await Supabase.instance.client
          .from('vendor_profiles')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();
      
      return result != null;
    } catch (e) {
      print('Error checking vendor claim status: $e');
      return false;
    }
  }

  void _initializeNavigatorKeys() {
    _navigatorKeys = [
      GlobalKey<NavigatorState>(),
      GlobalKey<NavigatorState>(),
      GlobalKey<NavigatorState>(),
      GlobalKey<NavigatorState>(), // Vendor tab key (always create it)
    ];
  }

  Future<void> _showTutorialIfFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeen = prefs.getBool('seen_main_tutorial') ?? false;

    if (!hasSeen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => TutorialOverlay(
            onComplete: () async {
              await prefs.setBool('seen_main_tutorial', true);
              if (mounted) Navigator.of(context).pop();
            },
          ),
        );
      });
    }
  }

  final GlobalKey _lovedTabKey = GlobalKey();
  final GlobalKey _profileTabKey = GlobalKey();
  final GlobalKey _diamondKey = GlobalKey();

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
            fontWeight: FontWeight.w600,
            letterSpacing: 2.0,
            color: const Color(0xFFDCC7AA),
          ),
        ),
        actions: [
          if (kIsWeb) ...[
            if (MediaQuery.of(context).size.width > 800)
              // Wide screen: Show tabs directly
              ...[
                _buildWebTabButton(0, 'Explore'),
                _buildWebTabButton(1, 'Loved'),
                _buildWebTabButton(2, 'YES'),
                if (_hasVendor) _buildWebTabButton(3, 'Vendor'),
                const SizedBox(width: 16),
              ]
            else
              // Narrow screen: Show hamburger menu
              PopupMenuButton<int>(
                icon: const Icon(Icons.menu, color: Colors.white),
                onSelected: (index) => _onTabTapped(index),
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem(
                    value: 0,
                    child: Text(
                      'Explore',
                      style: TextStyle(
                        color: _selectedIndex == 0 ? const Color(0xFF7B3F61) : Colors.black,
                        fontWeight: _selectedIndex == 0 ? FontWeight.bold : FontWeight.normal,
                        decoration: _selectedIndex == 0 ? TextDecoration.underline : TextDecoration.none,
                        decorationColor: const Color(0xFF7B3F61),
                        decorationThickness: 2,
                      ),
                    ),
                  ),
                  PopupMenuItem(
                    value: 1,
                    child: Text(
                      'Loved',
                      style: TextStyle(
                        color: _selectedIndex == 1 ? const Color(0xFF7B3F61) : Colors.black,
                        fontWeight: _selectedIndex == 1 ? FontWeight.bold : FontWeight.normal,
                        decoration: _selectedIndex == 1 ? TextDecoration.underline : TextDecoration.none,
                        decorationColor: const Color(0xFF7B3F61),
                        decorationThickness: 2,
                      ),
                    ),
                  ),
                  PopupMenuItem(
                    value: 2,
                    child: Text(
                      'YES',
                      style: TextStyle(
                        color: _selectedIndex == 2 ? const Color(0xFF7B3F61) : Colors.black,
                        fontWeight: _selectedIndex == 2 ? FontWeight.bold : FontWeight.normal,
                        decoration: _selectedIndex == 2 ? TextDecoration.underline : TextDecoration.none,
                        decorationColor: const Color(0xFF7B3F61),
                        decorationThickness: 2,
                      ),
                    ),
                  ),
                  if (_hasVendor)
                    PopupMenuItem(
                      value: 3,
                      child: Text(
                        'Vendor',
                        style: TextStyle(
                          color: _selectedIndex == 3 ? const Color(0xFF7B3F61) : Colors.black,
                          fontWeight: _selectedIndex == 3 ? FontWeight.bold : FontWeight.normal,
                          decoration: _selectedIndex == 3 ? TextDecoration.underline : TextDecoration.none,
                          decorationColor: const Color(0xFF7B3F61),
                          decorationThickness: 2,
                        ),
                      ),
                    ),
                ],
              ),
          ],
          IconButton(
            key: _profileTabKey,
            icon: const Icon(Icons.person_outline, color: Colors.white),
            onPressed: () {
              // Use the current selected index, but make sure it's valid
              final navigatorIndex = _selectedIndex < _navigatorKeys.length 
                  ? _selectedIndex 
                  : 0;
              _navigatorKeys[navigatorIndex].currentState?.push(
                MaterialPageRoute(builder: (_) => const ProfilePage()),
              );
            },
            tooltip: 'Profile',
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              final supabase = Supabase.instance.client;
              
              // When commented out, this is making the flags basically appear for device. They logout and then login, won't see tutorial again. But not connected to user.
              // final prefs = await SharedPreferences.getInstance();
              // await prefs.remove('seen_main_tutorial');
              
              await supabase.auth.signOut();

              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LoginSignup(
                      redirect: LoginRedirect.home,
                    ),
                  ),
                );
              }
            },
            tooltip: 'Logout',
          ),
        ],
        backgroundColor: const Color(0xFF7B3F61),
        centerTitle: true,
        elevation: kIsWeb ? 8.0 : 4.0,
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildTabNavigator(0, const ExplorePage()),
          _buildTabNavigator(1, const LovedPage()),
          _buildTabNavigator(2, const YesPage()),
          if (_hasVendor) _buildTabNavigator(3, const VendorDashboard()),
        ],
      ),
      bottomNavigationBar: kIsWeb ? null : BottomNav(
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
        lovedTabKey: _lovedTabKey,
        diamondTabKey: _diamondKey,
        profileTabKey: _profileTabKey,
        hasVendor: _hasVendor,
      ),
    );
  }

  Widget _buildWebTabButton(int index, String label) {
    final isSelected = _selectedIndex == index;
    
    return TextButton(
      onPressed: () => _onTabTapped(index),
      style: TextButton.styleFrom(
        backgroundColor: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 14,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}