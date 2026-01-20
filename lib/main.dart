import 'package:flutter/material.dart';
import 'package:say_yes/pages/web_landing_page.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pages/main_scaffold.dart';
import 'package:provider/provider.dart'; 
import 'appstate.dart'; 
import './pages/login.dart';
import 'keys.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://cocmclecxanepyheygqs.supabase.co',
     anonKey: annonKey
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const MyApp(),
    )
  );
}

class MyApp extends StatelessWidget {

  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wedding Planner App | Easiyest',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 174, 176, 129)),
        scaffoldBackgroundColor: Color(0xFFF8F5F0),
      ),
      onGenerateRoute: (RouteSettings settings) {
        String routePath = settings.name ?? '/';
        if (kIsWeb) {
          final uri = Uri.base;
          routePath = uri.path;
        }        
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => AuthCheck(routeName: routePath, hash: Uri.base.fragment),
        );
      },
    );
  }
}
class AuthCheck extends StatefulWidget {
  final String routeName;
  final String hash;
  const AuthCheck({super.key, required this.routeName, required this.hash});

  @override
  State<AuthCheck> createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final supabase = Supabase.instance.client;

    final path = widget.routeName;
    final isRecoveryRoute = path.contains('resetPassword') || 
                           widget.hash.contains('access_token');

    if (!isRecoveryRoute && supabase.auth.currentUser == null) {
      print("signed in annonymously");
      await supabase.auth.signInAnonymously();
    }

    if (!mounted) return;
    setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    
    if (!_ready) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (widget.routeName.contains('vendorRegistration')) {
      return const WebLandingPage();
    }
    if (widget.routeName.contains('resetPassword') || widget.hash.contains('access_token')) {
      return const Scaffold(
        body: Center(
          child: Text('Reset Password Page Loads Here'),
        ),
      );
    }

    return const MainScaffold();
  }
}


