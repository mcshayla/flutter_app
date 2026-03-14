// vendor_signup.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'vendor_claim.dart';

class VendorSignup extends StatefulWidget {
  const VendorSignup({super.key});

  @override
  State<VendorSignup> createState() => _VendorSignupState();
}

class _VendorSignupState extends State<VendorSignup> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final supabase = Supabase.instance.client;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        data: {
          'name': _nameController.text.trim(),
        },
      );

      // No session means this email is already registered.
      // Try signing in with the same password they entered first.
      if (response.session == null) {
        await _connectExistingAccount();
        return;
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => VendorClaimPage(
              userId: response.user!.id,
            ),
          ),
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Called when signUp returns no session, meaning the email already exists.
  /// First tries the password they just typed. If that fails, shows a dialog
  /// so they can enter their existing account password.
  Future<void> _connectExistingAccount() async {
    final email = _emailController.text.trim();
    final typedPassword = _passwordController.text;

    // Try the password they entered on the signup form first.
    try {
      final signInResponse = await supabase.auth.signInWithPassword(
        email: email,
        password: typedPassword,
      );
      if (mounted && signInResponse.user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => VendorClaimPage(
              userId: signInResponse.user!.id,
            ),
          ),
        );
      }
      return;
    } on AuthException {
      // Password didn't match — fall through to the dialog below.
    }

    // The password they typed doesn't match their existing account.
    // Show a dialog explaining the situation and ask for the correct password.
    if (!mounted) return;
    final existingPasswordController = TextEditingController();
    bool dialogLoading = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: Text(
                'Account Already Exists',
                style: GoogleFonts.bodoniModa(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF7B3F61),
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This email is already linked to a easiYESt account. '
                    'Enter your existing password to connect your vendor profile to that account.',
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      color: const Color(0xFF6E6E6E),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: existingPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Existing Password',
                      labelStyle: GoogleFonts.montserrat(
                        color: const Color(0xFF7B3F61),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFDCC7AA)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF7B3F61)),
                      ),
                    ),
                    style: GoogleFonts.montserrat(fontSize: 14),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: dialogLoading
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.montserrat(
                      color: const Color(0xFF6E6E6E),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: dialogLoading
                      ? null
                      : () async {
                          final password =
                              existingPasswordController.text.trim();
                          if (password.isEmpty) return;

                          setDialogState(() => dialogLoading = true);

                          try {
                            final signInResponse =
                                await supabase.auth.signInWithPassword(
                              email: email,
                              password: password,
                            );

                            if (signInResponse.user != null) {
                              Navigator.pop(dialogContext);
                              if (mounted) {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => VendorClaimPage(
                                      userId: signInResponse.user!.id,
                                    ),
                                  ),
                                );
                              }
                            }
                          } on AuthException catch (e) {
                            setDialogState(() => dialogLoading = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(e.message),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } catch (e) {
                            setDialogState(() => dialogLoading = false);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7B3F61),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: dialogLoading
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Connect Account',
                          style: GoogleFonts.montserrat(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ],
            );
          },
        );
      },
    );

    existingPasswordController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Vendor Sign Up',
                      style: GoogleFonts.bodoniModa(
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF7B3F61),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create an account to manage your business',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        color: const Color(0xFF6E6E6E),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        labelStyle: GoogleFonts.montserrat(
                          color: const Color(0xFF7B3F61),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFDCC7AA)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF7B3F61)),
                        ),
                      ),
                      style: GoogleFonts.montserrat(fontSize: 14),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: GoogleFonts.montserrat(
                          color: const Color(0xFF7B3F61),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFDCC7AA)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF7B3F61)),
                        ),
                      ),
                      style: GoogleFonts.montserrat(fontSize: 14),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!value.contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: GoogleFonts.montserrat(
                          color: const Color(0xFF7B3F61),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFDCC7AA)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF7B3F61)),
                        ),
                      ),
                      style: GoogleFonts.montserrat(fontSize: 14),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        labelStyle: GoogleFonts.montserrat(
                          color: const Color(0xFF7B3F61),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFDCC7AA)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF7B3F61)),
                        ),
                      ),
                      style: GoogleFonts.montserrat(fontSize: 14),
                      validator: (value) {
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _signUp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7B3F61),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              'Sign Up',
                              style: GoogleFonts.montserrat(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}