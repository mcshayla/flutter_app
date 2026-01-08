import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './main_scaffold.dart';
import 'package:google_fonts/google_fonts.dart';
import '../appstate.dart';
import 'package:provider/provider.dart';
import '../utils/app_styles.dart';

enum LoginRedirect {
  pop,
  home,
}

class LoginSignup extends StatefulWidget {
  final LoginRedirect redirect;

  const LoginSignup({super.key, this.redirect = LoginRedirect.home});

  @override
  State<LoginSignup> createState() => _LoginSignupState();
}

class _LoginSignupState extends State<LoginSignup> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  bool _isLoading = false;
  bool _isLogin = true;

  void _onAuthSuccess() {
  if (!mounted) return;

  switch (widget.redirect) {
    case LoginRedirect.pop:
      Navigator.pop(context);
      break;

    case LoginRedirect.home:
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainScaffold()),
      );
      break;
  }
}


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


     if (res.user != null) {
      // print("LOGGED IN");
      await Provider.of<AppState>(context, listen: false).loadInitialData();
      _onAuthSuccess();
      return;
    }
      
    } catch (signupError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Authentication failed. Please sign up or try again.')),
        );
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reset Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Enter your email address and we\'ll send you a link to reset your password.',
                style: GoogleFonts.montserrat(fontSize: 12),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: resetEmailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (resetEmailController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter your email')),
                  );
                  return;
                }
                
                try {
                  await Supabase.instance.client.auth.resetPasswordForEmail(
                    resetEmailController.text.trim(),
                    redirectTo: 'io.supabase.flutter://login-callback',
                  );
                  
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Password reset email sent! Check your inbox.')),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              },
              child: const Text('Send Reset Link'),
            ),
          ],
        );
      },
    );
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
    final signupRes;
    try {
        if (supabase.auth.currentSession == null) {
          signupRes = await supabase.auth.signUp(
              email: email,
              password: password,
            );
        } else {
          signupRes = await supabase.auth.updateUser(
          UserAttributes(
            email: email,
            password: password,
            data: {'username': username.isNotEmpty ? username : null},
          ),
          );
        }

        
        if (signupRes.user != null) {
          // print("SIGNED IN");
          await Provider.of<AppState>(context, listen: false).loadInitialData();
          _onAuthSuccess();
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
      floatingLabelBehavior: FloatingLabelBehavior.never,
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
            ); // CHANGE THIS
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
      appBar: widget.redirect == LoginRedirect.pop
      ? AppBar(
          backgroundColor: const Color(0xFF7B3F61),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        )
      : null,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding( padding: const EdgeInsets.all(16.0), 
              child: widget.redirect == LoginRedirect.home ?
              Center(child:Text(
                'easiYESt',
                style: GoogleFonts.bodoniModa(
                  fontSize: 72,
                  fontWeight: FontWeight.w600, // Medium to Semi-Bold for impact
                  letterSpacing: 2.0, // A little spacing for elegance
                  color: const Color(0xFFDCC7AA),
                ),
              ),): null ),
              // login vs signup:
               Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _isLogin = true),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 24),
                          decoration: BoxDecoration(
                            color: _isLogin ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
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
                      GestureDetector(
                        onTap: () => setState(() => _isLogin = false),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 24),
                          decoration: BoxDecoration(
                            color: !_isLogin ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
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
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    children: [
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
                      if (!_isLogin) const SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        decoration: _inputDecoration('Password'),
                        obscureText: true,
                      ),
                      const SizedBox(height: 8),
                      if (_isLogin)
                        Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: () => _showForgotPasswordDialog(),
                            child: Text(
                              'Forgot Password?',
                              style: GoogleFonts.montserrat(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFFDCC7AA),
                                decoration: TextDecoration.underline,
                                decorationColor: const Color(0xFFDCC7AA),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : Center(
                      child: ElevatedButton(
                        onPressed: _isLogin ? _loginAuth : _signupAuth,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 48),
                          minimumSize: const Size(0, 0),
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF7B3F61),
                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        
                        child: Text(_isLogin ? 'Login' : 'Signup'),
                      ),
                    ),
              Padding( padding: const EdgeInsets.all(24.0), 
              child: widget.redirect == LoginRedirect.home ?
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
              ),),): null),
            ],
          ),
        ),
      ),
    );
  }
}
