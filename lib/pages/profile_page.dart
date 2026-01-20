import 'package:flutter/material.dart';
import '../appstate.dart';
import 'package:provider/provider.dart';
import '../utils/string_extensions.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_styles.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login.dart';
import 'vendor_claim.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isGuest = false;
  late Future<Map<String, dynamic>?> _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = _fetchUser();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    setState(() {
      _userFuture = _fetchUser();
    });
  }

  Future<bool> _hasClaimedVendor() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return false;

    try {
      final result = await Supabase.instance.client
          .from('vendor_profiles')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();
      
      return result != null;
    } catch (e) {
      print('Error checking vendor claim status: $e');
      return false;
    }
  }

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

  Future<void> deleteAccount() async {
    final supabase = Supabase.instance.client;
    try {
      final response = await supabase.functions.invoke('delete-user');
      
      if (response.status == 200) {
        await supabase.auth.signOut();
        if (context.mounted) {
          await Navigator.of(context, rootNavigator: true).pushReplacement(
            MaterialPageRoute(
              builder: (_) => const LoginSignup(
                redirect: LoginRedirect.home,
              ),
            ),
          );
        }
          // Navigate to login
        }
    } catch (e) {
      if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
    }
  }

  bool _isValidUsername(Map<String, dynamic> data) {
    return data['username'] != null &&
        data['username'] is String &&
        (data['username'] as String).isNotEmpty &&
        !(data['username'] as String).contains('-'); 
  }

  @override
  Widget build(BuildContext context) {
    final supabaseUser = Supabase.instance.client.auth.currentUser;
    _isGuest = supabaseUser?.isAnonymous ?? true;

    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _userFuture,
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
                                _isValidUsername(data)
                                ? (data['username'] as String).capitalize()[0]
                                : (data['email'] != null) ? 'U' : 'G',
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFDCC7AA),
                                ),
                              ),
                            )),

                            const SizedBox(height: 24),
                            Text(data['email'] == null 
                                ? 'Guest'
                                : _isValidUsername(data)
                                  ? (data['username'] as String).capitalize()
                                  : 'User', 
                                style: GoogleFonts.bodoniModa(
                                fontSize: 28,
                                fontWeight: FontWeight.w600, // Medium to Semi-Bold for impact
                                letterSpacing: 2.0,
                            )),
                            const SizedBox(height: 12),
                            Text(data['email'] ?? '', style: GoogleFonts.montserrat(
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
                          if (_isGuest )
                           ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7B3F61),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                            ),
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LoginSignup(
                                    redirect: LoginRedirect.pop,
                                  ),
                                ),
                              );

                              setState(() {
                                _userFuture = _fetchUser();
                              });
                            },
                            child: Text(
                              'Create account',
                              style: GoogleFonts.montserrat(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 1.0,
                                color: const Color(0xFFF8F5F0),
                              ),
                            ),
                          ),
                          if (!_isGuest) 
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF7B3F61),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              ),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Delete Account'),
                                    content: Text('Are you sure? This action cannot be undone.', style: AppStyles.backButton),
                                    actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: Text('Cancel', style: AppStyles.backButton),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      child: Text(
                                        'Delete',
                                        style: GoogleFonts.montserrat(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          letterSpacing: 1.0,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                await deleteAccount();
                              }
                            },
                            child: Text(
                              'Delete Account',
                              style: GoogleFonts.montserrat(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 1.0,
                                color: const Color(0xFFF8F5F0),
                              ),
                            ),
                          ),
                          )
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