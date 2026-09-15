import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/responsive.dart';

/// The thin black strip above the navbar in the reference design
/// ("Free Shipping on Orders $50+ | Donate to Save a Dog Today").
/// Content here should stay honest — only mention things that are
/// actually true/live on the site.
class AnnouncementBar extends StatelessWidget {
  const AnnouncementBar({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);
    return Container(
      width: double.infinity,
      color: AppColors.black,
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: isMobile ? 12 : 24),
      child: Center(
        child: Text(
          'Every dog deserves a loving home — start your adoption journey today',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: isMobile ? 11 : 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}