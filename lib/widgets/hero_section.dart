import 'package:flutter/material.dart';
import '../core/responsive.dart';
import '../core/theme.dart';

/// Full-bleed background photo behind the headline, matching the reference
/// design's "Together We Can Clear The Shelters" hero. Falls back to a
/// solid dark panel if hero_home.png hasn't been added yet — see
/// assets/images/README.md for what's expected there.
class HeroSection extends StatelessWidget {
  final VoidCallback onBrowseTap;
  final VoidCallback onDonateTap;
  const HeroSection({super.key, required this.onBrowseTap, required this.onDonateTap});

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);
    final width = MediaQuery.of(context).size.width;
    final isSmallPhone = width < 380;

    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/images/hero_home.jpeg',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(color: AppColors.charcoal),
          ),
        ),
        // Left-to-right dark gradient so the headline stays legible over
        // any photo, strongest on the left where the text sits.
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.black.withOpacity(0.65),
                  Colors.black.withOpacity(isMobile ? 0.55 : 0.15),
                ],
              ),
            ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: isSmallPhone ? 18 : (isMobile ? 24 : 70),
            vertical: isMobile ? 60 : 110,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Together We Can',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isSmallPhone ? 16 : (isMobile ? 18 : 22),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isMobile ? 340 : 560),
                child: Text(
                  'CLEAR THE SHELTERS',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: isSmallPhone ? 34 : (isMobile ? 42 : 62),
                    height: 1.02,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'ADOPT  ·  DONATE  ·  VOLUNTEER  ·  CHANGE A LIFE',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: isSmallPhone ? 11 : 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
              SizedBox(height: isMobile ? 28 : 36),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  ElevatedButton(
                    onPressed: onBrowseTap,
                    child: const Text('VIEW AVAILABLE DOGS'),
                  ),
                  OutlinedButton(
                    onPressed: onDonateTap,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white),
                    ),
                    child: const Text('MAKE A DONATION'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}