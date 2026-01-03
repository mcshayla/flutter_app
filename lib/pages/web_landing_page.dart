import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:html' as html;

class WebLandingPage extends StatefulWidget {
  const WebLandingPage({super.key});

  @override
  State<WebLandingPage> createState() => _WebLandingPageState();
}

class _WebLandingPageState extends State<WebLandingPage>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late AnimationController _floatController;
  bool _showScrollTop = false;

  // Color scheme
  static const Color primaryColor = Color(0xFF7B3F61);
  static const Color primaryDark = Color(0xFF3d2031);
  static const Color secondaryColor = Color(0xFFF8F5F0);
  static const Color accentRose = Color(0xFFFFDCC7);
  static const Color textDark = Color(0xFF2c2c2c);
  static const Color bgCream = Color(0xFFF8F5F0);

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _scrollController.addListener(() {
      if (_scrollController.offset > 300 && !_showScrollTop) {
        setState(() => _showScrollTop = true);
      } else if (_scrollController.offset <= 300 && _showScrollTop) {
        setState(() => _showScrollTop = false);
      }
    });
  }

  @override
  void dispose() {
    _floatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch URL')),
        );
      }
    }
  }

  void _scrollToSection(GlobalKey key) {
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final featuresKey = GlobalKey();
    final pricingKey = GlobalKey();
    final signupKey = GlobalKey();

    return Scaffold(
      backgroundColor: bgCream,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Navigation Bar
              SliverAppBar(
                pinned: true,
                backgroundColor: Colors.white.withOpacity(0.95),
                elevation: 2,
                expandedHeight: 0,
                toolbarHeight: 80,
                flexibleSpace: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Row(
                        children: [
                          Text(
                            'Easiyest',
                            style: GoogleFonts.cormorantGaramond(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: primaryColor,
                              letterSpacing: 1,
                            ),
                          ),
                          const Spacer(),
                          _NavLink(
                            'Features',
                            onTap: () => _scrollToSection(featuresKey),
                          ),
                          const SizedBox(width: 40),
                          _NavLink(
                            'Pricing',
                            onTap: () => _scrollToSection(pricingKey),
                          ),
                          const SizedBox(width: 40),
                          _NavLink(
                            'Sign Up',
                            onTap: () => _scrollToSection(signupKey),
                          ),
                          const SizedBox(width: 40),
                          _NavLink(
                            'Browse Listings',
                            onTap: () => {
                              if (kIsWeb) {
                                html.window.history.pushState(null, '', '/')
                              },
                              Navigator.pushReplacementNamed(context, '/')
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Hero Section
              SliverToBoxAdapter(
                child: _HeroSection(
                  signupKey: signupKey,
                  floatAnimation: _floatController,
                  onLaunchURL: _launchURL,
                ),
              ),

              // Stats Section
              const SliverToBoxAdapter(child: _StatsSection()),

              // Features Section
              SliverToBoxAdapter(
                child: _FeaturesSection(key: featuresKey),
              ),

              // Testimonial Section
              const SliverToBoxAdapter(child: _TestimonialSection()),

              // CTA Section
              SliverToBoxAdapter(
                child: _CTASection(
                  key: pricingKey,
                  onGetStarted: () => _scrollToSection(signupKey),
                ),
              ),

              // Footer
              const SliverToBoxAdapter(child: _Footer()),
            ],
          ),

          // Scroll to top button
          if (_showScrollTop)
            Positioned(
              right: 40,
              bottom: 40,
              child: FloatingActionButton(
                onPressed: () {
                  _scrollController.animateTo(
                    0,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                  );
                },
                backgroundColor: primaryColor,
                child: const Icon(Icons.arrow_upward, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}

// Navigation Link Widget
class _NavLink extends StatefulWidget {
  final String text;
  final VoidCallback onTap;

  const _NavLink(this.text, {required this.onTap});

  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.text,
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: _isHovering
                    ? _WebLandingPageState.primaryColor
                    : _WebLandingPageState.textDark,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 2,
              width: _isHovering ? 60 : 0,
              decoration: const BoxDecoration(
                color: _WebLandingPageState.primaryColor,
                borderRadius: BorderRadius.all(Radius.circular(1)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Primary Button Widget
class _PrimaryButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final bool large;

  const _PrimaryButton({
    required this.text,
    required this.onPressed,
    this.large = false,
  });

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        transform: Matrix4.identity()
          ..translate(0.0, _isHovering ? -2.0 : 0.0),
        child: ElevatedButton(
          onPressed: widget.onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: _WebLandingPageState.primaryColor,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(
              horizontal: widget.large ? 48 : 32,
              vertical: widget.large ? 20 : 12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50),
            ),
            elevation: _isHovering ? 10 : 4,
            shadowColor: _WebLandingPageState.accentRose.withOpacity(0.4),
          ),
          child: Text(
            widget.text,
            style: GoogleFonts.montserrat(
              fontSize: widget.large ? 18 : 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

// Hero Section
class _HeroSection extends StatelessWidget {
  final GlobalKey signupKey;
  final AnimationController floatAnimation;
  final Function(String) onLaunchURL;

  const _HeroSection({
    required this.signupKey,
    required this.floatAnimation,
    required this.onLaunchURL,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFF4E8E1).withOpacity(0.9),
            _WebLandingPageState.accentRose.withOpacity(0.2),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Floating background circles
          Positioned(
            top: -200,
            right: -50,
            child: AnimatedBuilder(
              animation: floatAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(
                    0,
                    -30 * (0.5 - (floatAnimation.value - 0.5).abs()),
                  ),
                  child: Container(
                    width: 500,
                    height: 500,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          _WebLandingPageState.accentRose.withOpacity(0.15),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            bottom: -150,
            left: -50,
            child: AnimatedBuilder(
              animation: floatAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(
                    0,
                    30 * (0.5 - (floatAnimation.value - 0.5).abs()),
                  ),
                  child: Container(
                    width: 400,
                    height: 400,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          _WebLandingPageState.primaryColor.withOpacity(0.1),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 80),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Left side - Hero content
                  Expanded(
                    flex: 7,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 1000),
                          curve: Curves.easeOut,
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: value,
                              child: Transform.translate(
                                offset: Offset(0, 30 * (1 - value)),
                                child: child,
                              ),
                            );
                          },
                          child: Text(
                            'Grow Your Wedding Business with Real Connections',
                            style: GoogleFonts.cormorantGaramond(
                              fontSize: 56,
                              fontWeight: FontWeight.w700,
                              color: _WebLandingPageState.textDark,
                              height: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 1000),
                          curve: Curves.easeOut,
                          // delay: const Duration(milliseconds: 200),
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: value,
                              child: Transform.translate(
                                offset: Offset(0, 30 * (1 - value)),
                                child: child,
                              ),
                            );
                          },
                          child: Text(
                            'Don\'t just book more weddings—build lasting relationships with engaged couples actively searching for your services.',
                            style: GoogleFonts.montserrat(
                              fontSize: 20,
                              color: _WebLandingPageState.textDark,
                              height: 1.6,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 1000),
                          curve: Curves.easeOut,
                          // delay: const Duration(milliseconds: 400),
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: value,
                              child: Transform.translate(
                                offset: Offset(0, 30 * (1 - value)),
                                child: child,
                              ),
                            );
                          },
                          child: _PrimaryButton(
                            text: 'Get Started Today',
                            large: true,
                            onPressed: () {
                              Scrollable.ensureVisible(
                                signupKey.currentContext!,
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeInOut,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 60),

                  // Right side - Signup form
                  Expanded(
                    flex: 5,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.easeOut,
                      // delay: const Duration(milliseconds: 600),
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 30 * (1 - value)),
                            child: child,
                          ),
                        );
                      },
                      child: Container(
                        key: signupKey,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 40,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 5,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    _WebLandingPageState.primaryColor,
                                    _WebLandingPageState.accentRose,
                                  ],
                                ),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  topRight: Radius.circular(20),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(48),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Start Growing Today',
                                    style: GoogleFonts.cormorantGaramond(
                                      fontSize: 40,
                                      fontWeight: FontWeight.w600,
                                      color: _WebLandingPageState.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Fill out this form to learn more about advertising opportunities.',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 16,
                                      color: _WebLandingPageState.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 32),
                                  _PrimaryButton(
                                    text: 'Open Registration Form',
                                    onPressed: () => onLaunchURL(
                                      'https://docs.google.com/forms/d/e/1FAIpQLSfu9xLtzIYYSWq2G5CuzipfL5VSQG_pjxK58TzGAXQddEyX3A/viewform?usp=header',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Stats Section
class _StatsSection extends StatelessWidget {
  const _StatsSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _WebLandingPageState.primaryColor,
            _WebLandingPageState.primaryDark,
          ],
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: const [
              _StatItem(number: '2M+', label: 'Engaged Couples'),
              _StatItem(number: '50K+', label: 'Active Vendors'),
              _StatItem(number: '10M+', label: 'Monthly Searches'),
              _StatItem(number: '99%', label: 'Customer Satisfaction'),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String number;
  final String label;

  const _StatItem({required this.number, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Text(
            number,
            style: GoogleFonts.cormorantGaramond(
              fontSize: 56,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.95),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// Features Section
class _FeaturesSection extends StatelessWidget {
  const _FeaturesSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _WebLandingPageState.bgCream,
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              Text(
                'The Platform Built for Wedding Professionals',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 48,
                  fontWeight: FontWeight.w600,
                  color: _WebLandingPageState.textDark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                width: 80,
                height: 3,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      _WebLandingPageState.primaryColor,
                      _WebLandingPageState.accentRose,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 60),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 24,
                mainAxisSpacing: 24,
                childAspectRatio: 1.1,
                children: const [
                  _FeatureCard(
                    title: 'Showcase Your Work',
                    description:
                        'Make the best first impression with a stunning storefront and build trust with couples searching for their perfect vendor.',
                  ),
                  _FeatureCard(
                    title: 'Targeted Visibility',
                    description:
                        'Be seen by couples actively planning their weddings in your area. Our advanced matching system connects you with high-intent leads ready to book.',
                  ),
                  _FeatureCard(
                    title: 'Analytics & Insights',
                    description:
                        'Track your profile performance to monitor real business insights like impressions and leads generated from your page.',
                  ),
                  _FeatureCard(
                    title: 'Direct Communication',
                    description:
                        'Connect instantly with interested couples who message you from our system. Respond quickly to inquiries and convert leads into bookings.',
                  ),
                  _FeatureCard(
                    title: 'Reviews & Reputation',
                    description:
                        'Build credibility with verified reviews from real couples. Showcase your five-star ratings and testimonials to attract more clients.',
                  ),
                  _FeatureCard(
                    title: 'Marketing Tools',
                    description:
                        'Supercharge your marketing with visibility on our platform to expand your SEO reach, promote your business, and stand out from competitors.',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatefulWidget {
  final String title;
  final String description;

  const _FeatureCard({
    required this.title,
    required this.description,
  });

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        transform: Matrix4.identity()
          ..translate(0.0, _isHovering ? -10.0 : 0.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(_isHovering ? 0.15 : 0.05),
              blurRadius: _isHovering ? 40 : 25,
              offset: Offset(0, _isHovering ? 15 : 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _WebLandingPageState.primaryColor,
                    _WebLandingPageState.accentRose,
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              width: _isHovering ? double.infinity : 0,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: _WebLandingPageState.textDark,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.description,
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        color: _WebLandingPageState.textDark.withOpacity(0.8),
                        height: 1.8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Testimonial Section
class _TestimonialSection extends StatelessWidget {
  const _TestimonialSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _WebLandingPageState.secondaryColor,
            _WebLandingPageState.bgCream,
          ],
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              Text(
                'Trusted by Wedding Professionals',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 48,
                  fontWeight: FontWeight.w600,
                  color: _WebLandingPageState.textDark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                width: 80,
                height: 3,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      _WebLandingPageState.primaryColor,
                      _WebLandingPageState.accentRose,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 60),
              Row(
                children: const [
                  Expanded(
                    child: _TestimonialCard(
                      quote:
                          'This platform has generated so many leads for our small business! Being featured has helped us book more clients and grow our business.',
                      authorName: 'Sarah Williams',
                      authorRole: 'Enchanted Gardens Venue',
                      authorInitials: 'SW',
                    ),
                  ),
                  SizedBox(width: 24),
                  Expanded(
                    child: _TestimonialCard(
                      quote:
                          'As a wedding photographer, this platform has transformed my business. The quality of inquiries is exceptional, and the couples I meet are genuinely excited to work with me. It\'s the best investment I\'ve made for my business.',
                      authorName: 'Michael Chen',
                      authorRole: 'Moments Photography Studio',
                      authorInitials: 'MC',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TestimonialCard extends StatelessWidget {
  final String quote;
  final String authorName;
  final String authorRole;
  final String authorInitials;

  const _TestimonialCard({
    required this.quote,
    required this.authorName,
    required this.authorRole,
    required this.authorInitials,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 40,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '"',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 64,
              color: _WebLandingPageState.primaryColor.withOpacity(0.3),
              height: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            quote,
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontStyle: FontStyle.italic,
              color: _WebLandingPageState.textDark,
              height: 1.8,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _WebLandingPageState.primaryColor,
                      _WebLandingPageState.accentRose,
                    ],
                  ),
                ),
                child: Center(
                  child: Text(
                    authorInitials,
                    style: GoogleFonts.montserrat(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    authorName,
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: _WebLandingPageState.textDark,
                    ),
                  ),
                  Text(
                    authorRole,
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _WebLandingPageState.primaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// CTA Section
class _CTASection extends StatelessWidget {
  final VoidCallback onGetStarted;

  const _CTASection({Key? key, required this.onGetStarted}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _WebLandingPageState.bgCream,
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFF4E8E1).withOpacity(0.5),
                  _WebLandingPageState.primaryColor.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _WebLandingPageState.accentRose.withOpacity(0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 40,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            padding: const EdgeInsets.all(64),
            child: Column(
              children: [
                Text(
                  'Ready to Grow Your Wedding Business?',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 44,
                    fontWeight: FontWeight.w600,
                    color: _WebLandingPageState.textDark,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Text(
                  'Join thousands of wedding professionals who are booking more weddings and building lasting relationships with engaged couples. Get started today or speak with our team to learn about pricing and advertising options.',
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    color: _WebLandingPageState.textDark.withOpacity(0.9),
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                _PrimaryButton(
                  text: 'Start Free Trial',
                  large: true,
                  onPressed: onGetStarted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Footer
class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _WebLandingPageState.textDark,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              Divider(
                color: Colors.white.withOpacity(0.1),
                thickness: 1,
              ),
              const SizedBox(height: 32),
              Text(
                '© 2026 Easiyest. All rights reserved.',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      'Terms of Use',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      'Privacy Policy',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Extension for delayed animations
extension DelayedAnimation on TweenAnimationBuilder {
  TweenAnimationBuilder delay(Duration delay) {
    return TweenAnimationBuilder(
      tween: tween,
      duration: duration,
      curve: curve,
      builder: builder,
      child: child,
    );
  }
}