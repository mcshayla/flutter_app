import 'package:flutter/material.dart';
import '../appstate.dart';
import 'package:provider/provider.dart';
import '../utils/string_extensions.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_styles.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _showSignupForm = false;
  bool _isGuest = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

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

  void _signupAuth() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final username = _usernameController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email and password cannot be empty')),
      );
      return;
    }

    try {
      await supabase.auth.updateUser(
      UserAttributes(
        email: email,
        password: password,
        data: {
          if (username.isNotEmpty) 'username': username,
        },
      ),
      );

      // OPTIONAL: update your public users table
      await supabase.from('users').update({
        'email': email,
        'username': username,
      }).eq('user_id', user!.id);

    
      setState(() {
        _isGuest = false;
        _showSignupForm = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account upgraded successfully!')),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Signup error: $error')),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    final supabaseUser = Supabase.instance.client.auth.currentUser;
    _isGuest = supabaseUser?.isAnonymous ?? true;

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
        
          bool loveSelected = false;

          return Scaffold(
            body: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                    Container(
                      padding: const EdgeInsets.all(50),
                      decoration: BoxDecoration(
                        color: Color(0xFFDCC7AA).withOpacity(0.5),
                      ),
                      child: Center(
                        child: Column ( 
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.25),
                                    blurRadius: 14,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child:
                            // Purple circle avatar
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: const Color(0xFF7B3F61), // your purple
                              child: Text(
                                ((data['email'] != null)
                                ? (data['username'] as String).capitalize()[0] : 'G'),
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFDCC7AA),
                                ),
                              ),
                            )),

                            const SizedBox(height: 24),
                            Text((data['email'] != null)
                                ? (data['username'] as String).capitalize()
                                : 'Guest', 
                                style: GoogleFonts.bodoniModa(
                                fontSize: 28,
                                fontWeight: FontWeight.w600, // Medium to Semi-Bold for impact
                                letterSpacing: 2.0,
                            )),
                            const SizedBox(height: 12),
                            Text('${data['email'] ?? ''}', style: GoogleFonts.montserrat(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 1.2,
                            )),
                          ]   
                        )
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(child:
                          Column(
                            children: [
                          if (_showSignupForm)
                            Column(
                              children: [
                                TextField(
                                  controller: _emailController,
                                  decoration: const InputDecoration(labelText: 'Email'),
                                ),
                                TextField(
                                  controller: _usernameController,
                                  decoration: const InputDecoration(labelText: 'Username'),
                                ),
                                TextField(
                                  controller: _passwordController,
                                  decoration: const InputDecoration(labelText: 'Password'),
                                  obscureText: true,
                                ),
                                const SizedBox(height: 16),
                                ActionChip(
                                  label: Text(
                                    'Sign Up',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFFF8F5F0),
                                    ),
                                  ),
                                  backgroundColor: const Color(0xFF7B3F61),
                                  onPressed: _signupAuth,
                                ),
                              ],
                            ),

                          const SizedBox(height: 12),

                          if (_isGuest && !_showSignupForm)
                            ActionChip(
                              label: Text('Sign Up', style: GoogleFonts.montserrat(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 1.0,
                                color: Color(0xFFF8F5F0)
                                )),
                              backgroundColor: const Color(0xFF7B3F61),
                              onPressed: () => setState(() => _showSignupForm = true),
                            ),
                        ]
                      ),)
                        ],
                      )
                    )
                ]
                
              )
            )
                
            );
        }
          
      ));
  }}