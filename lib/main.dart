import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pages/main_scaffold.dart';
import 'package:provider/provider.dart'; 
import 'appstate.dart'; 
import './pages/login.dart';

// uvicorn python_scripts.embed_queries:app --reload

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://cocmclecxanepyheygqs.supabase.co',
     anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNvY21jbGVjeGFuZXB5aGV5Z3FzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI1MjIwNTIsImV4cCI6MjA3ODA5ODA1Mn0.hBXFO-suxe26o6mqtoX5O6kIwuK8oVKC3A5cPK3EarA',
  );

  // await signInAnonymously();

  runApp(
    ChangeNotifierProvider(
      // create: (_) => AppState()..loadInitialData(),
      // child: const MyApp(),
      create: (_) => AppState(),
      child: const MyApp(),
    )
  );
}


// Future<void> signInAnonymously() async {
//   final supabase = Supabase.instance.client;
//   try {
//     final response = await supabase.auth.signInAnonymously();

//     await supabase.from('users').upsert({
//       'user_id': response.user!.id,
//       'username': response.user!.id
//     });

//     print('Signed in anonymously! UserId: ${response.user!.id}');

//   } catch (e) {
//     print('Error signing in anonymously: $e');
//   }
// }

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
      home: const LoginSignup()
    );
  }
}


