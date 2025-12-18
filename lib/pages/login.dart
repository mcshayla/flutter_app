import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './main_scaffold.dart';
import 'package:google_fonts/google_fonts.dart';
import '../appstate.dart';
import 'package:provider/provider.dart';

class LoginSignup extends StatefulWidget {
  const LoginSignup({super.key});

  @override
  State<LoginSignup> createState() => _LoginSignupState();
}

class _LoginSignupState extends State<LoginSignup> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  bool _isLoading = false;
  bool _isLogin = true;

  void _loginAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email and password cannot be empty')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final supabase = Supabase.instance.client;

    try {
      // Try login first
      final res = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      await Provider.of<AppState>(context, listen: false).loadInitialData();


      if (res.user != null) {
        
        print("LOGGED IN");
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MainScaffold()),
          );
        }
        return;
      }
      
    } catch (signupError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Authentication failed. Please sign up or try again.')),
        );
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _signupAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final username = _usernameController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email and password cannot be empty')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final supabase = Supabase.instance.client;

    try {
        final signupRes = await supabase.auth.signUp(
          email: email,
          password: password,
          data: {'username': username.isNotEmpty ? username : null},
        );

        await Provider.of<AppState>(context, listen: false).loadInitialData();
        if (signupRes.user != null) {

          print("SIGNED IN");
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const MainScaffold()),
            );
          }
        }
      } catch (signupError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('signupError $signupError')),
        );
        if (mounted) setState(() => _isLoading = false);
      }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  Future<void> signInGuest() async {
    final supabase = Supabase.instance.client;
    try {
      final response = await supabase.auth.signInAnonymously();

      await supabase.from('users').upsert({
        'user_id': response.user!.id,
        'username': response.user!.id
      });
      if (mounted) {
       Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const MainScaffold()),
            );
      }

      print('Signed in anonymously! UserId: ${response.user!.id}');

    } catch (e) {
      print('Error signing in anonymously: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF7B3F61),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding( padding: const EdgeInsets.all(16.0), 
              child:
              Center(child:Text(
                'easiYESt',
                style: GoogleFonts.bodoniModa(
                  fontSize: 72,
                  fontWeight: FontWeight.w600, // Medium to Semi-Bold for impact
                  letterSpacing: 2.0, // A little spacing for elegance
                  color: const Color(0xFFDCC7AA),
                ),
              ),),),
              // login vs signup:
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _isLogin = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                      decoration: BoxDecoration(
                        color: _isLogin ? Colors.white : Colors.transparent, // active tab color
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white), // optional border
                      ),
                      child: Text(
                        'Login',
                        style: TextStyle(
                          color: _isLogin ? const Color(0xFF7B3F61) : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => setState(() => _isLogin = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                      decoration: BoxDecoration(
                        color: !_isLogin ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white),
                      ),
                      child: Text(
                        'Sign Up',
                        style: TextStyle(
                          color: !_isLogin ? const Color(0xFF7B3F61) : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                decoration: _inputDecoration('Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              if (!_isLogin) 
                TextField(
                  controller: _usernameController,
                  decoration: _inputDecoration('Optional Username'),
                ),
              if(!_isLogin)
                const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: _inputDecoration('Password'),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : ElevatedButton(
                      onPressed: _isLogin ? _loginAuth : _signupAuth,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        minimumSize: const Size(0, 0), 
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF7B3F61),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      
                      child: Text(_isLogin ? 'Login' : 'Signup'),
                    ),
              Padding( padding: const EdgeInsets.all(24.0), 
              child:
              GestureDetector(
                onTap: () {
                  signInGuest();
                },
                child:Center(child:Text(
                'Sign in as guest',
                style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.2,
                      color: const Color(0xFFDCC7AA),
                      decoration: TextDecoration.underline,
                      decorationColor: const Color(0xFFDCC7AA),
                    ),
              ),),),),
            ],
          ),
        ),
      ),
    );
  }
}
