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

class AuthCheck extends StatelessWidget {
  const AuthCheck({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    if (user != null) {
      return const MainScaffold();
    } else {
      return const LoginSignup();
    }
  }
}


