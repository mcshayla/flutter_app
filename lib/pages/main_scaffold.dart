import 'explore_page.dart';
import 'loved_page.dart';
import 'yes_page.dart';
import 'checklist_page.dart';
import '../widgets/bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

  // Tab indices
  static const int _exploreIdx = 0;
  static const int _lovedIdx = 1;
  static const int _planIdx = 2;
  static const int _yesIdx = 3;
  static const int _vendorIdx = 4;

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
      GlobalKey<NavigatorState>(), // Explore
      GlobalKey<NavigatorState>(), // Loved
      GlobalKey<NavigatorState>(), // Plan
      GlobalKey<NavigatorState>(), // YES
      GlobalKey<NavigatorState>(), // Vendor
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
              ...[
                _buildWebTabButton(_exploreIdx, 'Explore'),
                _buildWebTabButton(_lovedIdx, 'Loved'),
                _buildWebTabButton(_planIdx, 'Plan'),
                _buildWebTabButton(_yesIdx, 'YES'),
                if (_hasVendor) _buildWebTabButton(_vendorIdx, 'Vendor'),
                const SizedBox(width: 16),
              ]
            else
              PopupMenuButton<int>(
                icon: const Icon(Icons.menu, color: Colors.white),
                onSelected: (index) => _onTabTapped(index),
                itemBuilder: (BuildContext context) => [
                  _buildPopupMenuItem(0, 'Explore'),
                  _buildPopupMenuItem(1, 'Loved'),
                  _buildPopupMenuItem(2, 'Plan'),
                  _buildPopupMenuItem(3, 'YES'),
                  if (_hasVendor) _buildPopupMenuItem(4, 'Vendor'),
                ],
              ),
          ],

          IconButton(
            key: _profileTabKey,
            icon: const Icon(Icons.person_outline, color: Colors.white),
            onPressed: () {
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
          _buildTabNavigator(_exploreIdx, const ExplorePage()),
          _buildTabNavigator(_lovedIdx, const LovedPage()),
          _buildTabNavigator(_planIdx, const ChecklistPage()),
          _buildTabNavigator(_yesIdx, const YesPage()),
          if (_hasVendor)
            _buildTabNavigator(_vendorIdx, const VendorDashboard(isInMainScaffold: true)),
        ],
      ),
      bottomNavigationBar: kIsWeb
          ? null
          : BottomNav(
              currentIndex: _selectedIndex,
              onTap: _onTabTapped,
              lovedTabKey: _lovedTabKey,
              diamondTabKey: _diamondKey,
              profileTabKey: _profileTabKey,
              hasVendor: _hasVendor,
            ),
    );
  }

  PopupMenuItem<int> _buildPopupMenuItem(int value, String label) {
    return PopupMenuItem(
      value: value,
      child: Text(
        label,
        style: TextStyle(
          color: _selectedIndex == value ? const Color(0xFF7B3F61) : Colors.black,
          fontWeight: _selectedIndex == value ? FontWeight.bold : FontWeight.normal,
          decoration: _selectedIndex == value ? TextDecoration.underline : TextDecoration.none,
          decorationColor: const Color(0xFF7B3F61),
          decorationThickness: 2,
        ),
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
