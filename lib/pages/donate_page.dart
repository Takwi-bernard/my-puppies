import 'package:flutter/material.dart';
import '../core/responsive.dart';
import '../core/theme.dart';
import '../widgets/page_header.dart';

class DonatePage extends StatelessWidget {
  const DonatePage({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);
    return Column(
      children: [
        const PageHeader(
          title: 'Support Our Mission',
          subtitle: 'Every dollar helps us rescue, care for, and rehome more dogs.',
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 60, vertical: 60),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                children: [
                  const Icon(Icons.favorite, color: AppColors.orange, size: 48),
                  const SizedBox(height: 16),
                  const Text(
                    'Online donations aren\'t connected yet — we\'re working on it. '
                    'In the meantime, reach out through our contact info below and we\'ll '
                    'let you know how to support us directly.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54, height: 1.6),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}