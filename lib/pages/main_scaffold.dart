import 'explore_page.dart';
import 'loved_page.dart';
import 'ai_search_page.dart';
import 'yes_page.dart';
import '../widgets/bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../appstate.dart';
import 'login.dart';
import 'profile_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';


class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0;
  late TutorialCoachMark _tutorialCoachMark;
  List<TargetFocus> _targets = [];

  @override
  void initState() {
    super.initState();
    _showTutorialIfFirstTime();
  }

  Future<void> _showTutorialIfFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeen = prefs.getBool('seen_main_tutorial') ?? false;

    if (!hasSeen) {
      _buildTargets();

      _tutorialCoachMark = TutorialCoachMark(
      targets: _targets,
      colorShadow: Colors.black,
      opacityShadow: 0.8,
      hideSkip: false, // 👈 SHOWS SKIP BUTTON
      textSkip: "Skip",
      onFinish: () async {
        await prefs.setBool('seen_main_tutorial', true);
      },
      onSkip: () {
        prefs.setBool('seen_main_tutorial', true);
        return true;
      },
    );

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _tutorialCoachMark.show(context: context);
      });
    }
  }

  // 👇 buildTargets also lives here
  void _buildTargets() {
    _targets = [
      TargetFocus(
        identify: "LovedTab",
        keyTarget: _lovedTabKey,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: const Text(
              "Tap the hearts on the cards to save vendors you love and see them here!",
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: "DiamondTab",
        keyTarget: _diamondKey,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: const Text(
              "Diamond your number one pick in each category and view them here!",
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: "Profile",
        keyTarget: _profileTabKey,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: const Text(
              "Create an account to save your favorites and come back anytime!",
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ],
      ),
    ];
  }

  final GlobalKey _lovedTabKey = GlobalKey();
  final GlobalKey _profileTabKey = GlobalKey();
  final GlobalKey _diamondKey = GlobalKey();

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
            key: _profileTabKey,
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
              
              // Clear tutorial flag for testing
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('seen_main_tutorial');
              
              await supabase.auth.signOut();

              // Navigate back to login page
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
        lovedTabKey: _lovedTabKey,
        diamondTabKey: _diamondKey,
        profileTabKey: _profileTabKey,
      )
    );
  }
}