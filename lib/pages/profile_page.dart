import 'package:flutter/material.dart';
import '../appstate.dart';
import 'package:provider/provider.dart';
import '../utils/string_extensions.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_styles.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<Map<String, dynamic>?> _fetchUser() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) return null;

    return await supabase
        .from('users')
        .select('username, email')
        .eq('user_id', user.id)
        .single();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _fetchUser(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('No user found'));
          }

          final data = snapshot.data!;
          final supabaseUser = Supabase.instance.client.auth.currentUser;
          final isGuest = supabaseUser?.email == null;

          return Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  if (Navigator.canPop(context))
                    Row( 
                      children: [
                        IconButton(icon: const Icon(Icons.arrow_back),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Text("Back",
                        style: AppStyles.backButton
                        
                        )
                      ]
                    ),
                    Text('Username: ${data['username'] ?? 'Guest'}'),
                    const SizedBox(height: 16),
                    Text('Email: ${data['email'] ?? 'No email'}'),
                    const SizedBox(height: 32),
                    if (isGuest)
                      ElevatedButton(
                        onPressed: () {
                          // Navigate to signup
                        },
                        child: const Text('Sign Up'),
                      ),
              ],
            ),
          )
          );
        },
      ),
    );
  }
}
