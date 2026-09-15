import 'package:flutter/material.dart';
import '../core/responsive.dart';
import '../core/theme.dart';
import '../widgets/page_header.dart';

class SheltersPage extends StatelessWidget {
  const SheltersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);
    return Column(
      children: [
        const PageHeader(
          title: 'Our Organization',
          subtitle: 'A single, directly-managed rescue — not a marketplace of shelters.',
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 60, vertical: 40),
          child: Column(
            children: [
              _InfoRow(
                icon: Icons.groups_outlined,
                title: 'One dedicated team',
                text: 'Every dog you see here is cared for and listed directly by our team — no third-party listings.',
              ),
              const SizedBox(height: 20),
              _InfoRow(
                icon: Icons.verified_outlined,
                title: 'Every application reviewed personally',
                text: 'We read every application ourselves to make sure each dog goes to the right home.',
              ),
              const SizedBox(height: 20),
              _InfoRow(
                icon: Icons.favorite_outline,
                title: 'Support after adoption',
                text: 'We stay reachable after adoption day — questions, updates, we\'re here.',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  const _InfoRow({required this.icon, required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.orange, size: 28),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 4),
              Text(text, style: const TextStyle(color: Colors.black54)),
            ],
          ),
        ),
      ],
    );
  }
}