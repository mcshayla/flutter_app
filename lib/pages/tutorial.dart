import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TutorialOverlay extends StatefulWidget {
  final VoidCallback onComplete;

  const TutorialOverlay({
    required this.onComplete,
    super.key,
  });

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay> {
  int _currentStep = 0;

  final List<TutorialStep> _steps = [
    TutorialStep(
      icon: Icons.favorite_border,
      title: "Support Our Vendors",
      description:
          "If you find a vendor on here, we'd forever be grateful if you mentioned easiYESt to them.",
    ),
    TutorialStep(
      icon: Icons.favorite,
      title: "Heart Your Favorites",
      description:
          "Heart the vendors you're interested in to save them to your Loved page.",
    ),
    TutorialStep(
      icon: Icons.diamond_outlined,
      title: "Diamond Your Picks",
      description:
          "Diamond the ones you've chosen! See all your final selections on the YES page.",
    ),
    TutorialStep(
      icon: Icons.person_outline,
      title: "Create a Profile",
      description:
          "Create a profile to save your favorites and access them from any device.",
    ),
  ];

  void _next() {
    if (_currentStep < _steps.length - 1) {
      setState(() => _currentStep++);
    } else {
      widget.onComplete();
    }
  }

  void _skip() {
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_currentStep];
    final isLastStep = _currentStep == _steps.length - 1;

    return Material(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F5F0),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7B3F61).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    step.icon,
                    size: 48,
                    color: const Color(0xFF7B3F61),
                  ),
                ),
                const SizedBox(height: 24),

                // Title
                Text(
                  step.title,
                  style: GoogleFonts.bodoniModa(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                    color: const Color(0xFF7B3F61),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Description
                Text(
                  step.description,
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    height: 1.5,
                    color: Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Progress indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _steps.length,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: index == _currentStep ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: index == _currentStep
                            ? const Color(0xFF7B3F61)
                            : const Color(0xFFDCC7AA),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: _skip,
                      child: Text(
                        'Skip',
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7B3F61),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: Text(
                        isLastStep ? 'Get Started' : 'Next',
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TutorialStep {
  final IconData icon;
  final String title;
  final String description;

  TutorialStep({
    required this.icon,
    required this.title,
    required this.description,
  });
}