import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
// import 'dart:html' as html;


class WebLandingPage extends StatefulWidget {
  const WebLandingPage({Key? key}) : super(key: key);

  @override
  State<WebLandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<WebLandingPage> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _featuresKey = GlobalKey();
  final GlobalKey _pricingKey = GlobalKey();
  final GlobalKey _signupKey = GlobalKey();

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

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              children: [
                _buildHeroSection(),
                _buildStatsSection(),
                _buildFeaturesSection(),
                _buildTestimonialSection(),
                _buildCTASection(),
                _buildFooter(),
              ],
            ),
          ),
          _buildNavigationBar(),
        ],
      ),
    );
  }

  Widget _buildNavigationBar() {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Easiyest',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF7B3F61),
              ),
            ),
            Row(
              children: [
                _buildNavLink('Features', () => _scrollToSection(_featuresKey)),
                const SizedBox(width: 24),
                _buildNavLink('Pricing', () => _scrollToSection(_pricingKey)),
                const SizedBox(width: 24),
                _buildNavLink('Sign Up', () => _scrollToSection(_signupKey)),
                const SizedBox(width: 24),
                // TextButton(
                //   onPressed: () {
                //     if (kIsWeb) {
                //       html.window.history.pushState(null, '', '/');
                //     }
                //     Navigator.pushReplacementNamed(context, '/');
                //   },
                //   child: const Text(
                //     'Browse Listings',
                //     style: TextStyle(
                //       color: Color(0xFF7B3F61),
                //       fontWeight: FontWeight.w500,
                //     ),
                //   ),
                // ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavLink(String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF7B3F61),
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      margin: const EdgeInsets.only(top: 70),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 900) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 7,
                  child: _buildHeroContent(),
                ),
                const SizedBox(width: 60),
                Expanded(
                  flex: 5,
                  child: _buildSignupForm(),
                ),
              ],
            );
          } else {
            return Column(
              children: [
                _buildHeroContent(),
                const SizedBox(height: 40),
                _buildSignupForm(),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildHeroContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Grow Your Wedding Business with Real Connections',
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
            height: 1.2,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Don\'t just book more weddings—build lasting relationships with engaged couples actively searching for your services.',
          style: TextStyle(
            fontSize: 20,
            color: Color(0xFF7B3F61),
            height: 1.6,
          ),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () => _scrollToSection(_signupKey),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF7B3F61),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 0,
          ),
          child: const Text(
            'Get Started Today',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignupForm() {
    return Container(
      key: _signupKey,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Start Growing Today',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Fill out this form to join now.',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF7B3F61),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _launchURL(
              'https://docs.google.com/forms/d/e/1FAIpQLSfu9xLtzIYYSWq2G5CuzipfL5VSQG_pjxK58TzGAXQddEyX3A/viewform?usp=header',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7B3F61),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Registration Form',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
      color: const Color(0xFFF8F5F0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 900) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // _buildStatItem('2M+', 'Engaged Couples'),
                // _buildStatItem('50K+', 'Active Vendors'),
                // _buildStatItem('10M+', 'Monthly Searches'),
                // _buildStatItem('99%', 'Customer Satisfaction'),
                _buildStatItem('Built For', 'Wedding Vendors'),
                _buildStatItem('Local Focus', 'Utah County & Nearby'),
                _buildStatItem('Mobile App', 'Launching Soon'),
                _buildStatItem('Free to Start', '3 Month Free Trial'),

              ],
            );
          } else {
            return Wrap(
              spacing: 40,
              runSpacing: 40,
              alignment: WrapAlignment.center,
              children: [
                // _buildStatItem('2M+', 'Engaged Couples'),
                // _buildStatItem('50K+', 'Active Vendors'),
                // _buildStatItem('10M+', 'Monthly Searches'),
                // _buildStatItem('99%', 'Customer Satisfaction'),
                _buildStatItem('Designed For', 'Wedding Vendors'),
                _buildStatItem('Local Focus', 'Utah County & Nearby'),
                _buildStatItem('Mobile App', 'Launching Soon'),
                _buildStatItem('Free to Start', '3 Month Free Trial'),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildStatItem(String number, String label) {
    return Column(
      children: [
        Text(
          number,
          style: const TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: Color(0xFF7B3F61),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF7B3F61),
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturesSection() {
    return Container(
      key: _featuresKey,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
      child: Column(
        children: [
          const Text(
            'The Platform Built for Wedding Professionals',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 60),
          LayoutBuilder(
            builder: (context, constraints) {
              return Wrap(
                spacing: 24,
                runSpacing: 24,
                children: [
                  _buildFeatureCard(
                    'Showcase Your Work',
                    'Make the best first impression with a stunning storefront and build trust with couples searching for their perfect vendor.',
                    constraints.maxWidth > 900 ? constraints.maxWidth / 3 - 16 : constraints.maxWidth,
                  ),
                  _buildFeatureCard(
                    'Local Discovery',
                    'Be seen by couples actively planning weddings in Utah County. easiYESt focuses on local discovery—so your business reaches the right people, not a national audience you’ll never book.',
                    constraints.maxWidth > 900 ? constraints.maxWidth / 3 - 16 : constraints.maxWidth,
                  ),
                  _buildFeatureCard(
                    'Fair Vendor Visibility',
                    'No pay-to-win listings. Vendor profiles rotate so everyone gets real visibility, giving small and growing businesses a fair chance to be discovered.',
                    constraints.maxWidth > 900 ? constraints.maxWidth / 3 - 16 : constraints.maxWidth,
                  ),
                  _buildFeatureCard(
                    'High-Intent Leads',
                    'Fewer vendors and a local-only audience means couples browsing easiYESt are serious about booking—leading to higher-quality inquiries, not wasted clicks.',
                    constraints.maxWidth > 900 ? constraints.maxWidth / 3 - 16 : constraints.maxWidth,
                  ),
                  _buildFeatureCard(
                    'Affordable, No-Risk Pricing',
                    'Try easiYESt free for 3 months after launch. Then just \$20/month—no contracts, and cancel anytime.',
                    constraints.maxWidth > 900 ? constraints.maxWidth / 3 - 16 : constraints.maxWidth,
                  ),
                  _buildFeatureCard(
                    'Marketing Tools',
                    'Supercharge your marketing with visibility on our platform to expand your SEO reach, promote your business, and stand out from competitors.',
                    constraints.maxWidth > 900 ? constraints.maxWidth / 3 - 16 : constraints.maxWidth,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(String title, String description, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF8F5F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF7B3F61),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestimonialSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
      color: const Color(0xFFF8F5F0),
      child: Column(
        children: [
          const Text(
            'Trusted by Wedding Professionals',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 60),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 900) {
                return Row(
                  children: [
                    Expanded(
                      child: _buildTestimonialCard(
                        'This platform has generated so many leads for our small business! Being featured has helped us book more clients and grow our business.',
                        'Sarah Williams',
                        'Enchanted Gardens Venue',
                        'SW',
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: _buildTestimonialCard(
                        'As a wedding photographer, this platform has transformed my business. The quality of inquiries is exceptional, and the couples I meet are genuinely excited to work with me. It\'s the best investment I\'ve made for my business.',
                        'Michael Chen',
                        'Moments Photography Studio',
                        'MC',
                      ),
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildTestimonialCard(
                      'I think this is great...there\'s a huge lack of service like this for brides. Utah Valley Bride and Utah Wedding Magazine have gone higher end, which is great but they\'ve cut out a huge portion of the actual local market.',
                      'Kristy',
                      '',
                      'K',
                    ),
                    // const SizedBox(height: 24),
                    // _buildTestimonialCard(
                    //   'As a wedding photographer, this platform has transformed my business. The quality of inquiries is exceptional, and the couples I meet are genuinely excited to work with me. It\'s the best investment I\'ve made for my business.',
                    //   'Michael Chen',
                    //   'Moments Photography Studio',
                    //   'MC',
                    // ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTestimonialCard(
    String text,
    String name,
    String company,
    String initials,
  ) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '"',
            style: TextStyle(
              fontSize: 48,
              color: Color(0xFF7B3F61),
              height: 0.8,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF3E3E3E),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF7B3F61),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    company,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF7B3F61),
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

  Widget _buildCTASection() {
    return Container(
      key: _pricingKey,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
      child: Container(
        padding: const EdgeInsets.all(60),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7B3F61), Color.fromARGB(255, 80, 49, 151)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            const Text(
              'Ready to Grow Your Wedding Business?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Connect with engaged couples who are actively planning their weddings. Build real relationships, showcase your work, and be part of a platform designed for local vendors.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: Colors.white,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => _scrollToSection(_signupKey),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Start Free Trial',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF7B3F61),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      color: const Color(0xFF0F172A),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '© 2026 Easiyest. All rights reserved.',
                style: TextStyle(
                  color: Color(0xFF6E6E6E),
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 16),
              InkWell(
                onTap: () {},
                child: const Text(
                  'Terms of Use',
                  style: TextStyle(
                    color: Color(0xFF6E6E6E),
                    fontSize: 14,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              InkWell(
                onTap: () {},
                child: const Text(
                  'Privacy Policy',
                  style: TextStyle(
                    color: Color(0xFF6E6E6E),
                    fontSize: 14,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}