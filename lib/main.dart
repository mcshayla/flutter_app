import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pages/main_scaffold.dart';
import 'package:provider/provider.dart'; 
import 'appstate.dart'; 
import './pages/login.dart';
import 'keys.dart';

// uvicorn python_scripts.embed_queries:app --reload

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://cocmclecxanepyheygqs.supabase.co',
     anonKey: annonKey
  );

  // await signInAnonymously();

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const MyApp(),
    )
  );
}

class MyApp extends StatelessWidget {

  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wedding Planner App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 174, 176, 129)),
        scaffoldBackgroundColor: Color(0xFFF8F5F0),
      ),
      home: const AuthCheck()
    );
  }
}
class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});

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
    print(supabase.auth.currentUser);
    if (supabase.auth.currentUser == null) {
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

    return const MainScaffold();
  }
}


