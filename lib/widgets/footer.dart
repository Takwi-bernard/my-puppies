import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/responsive.dart';
import '../core/theme.dart';
import '../core/contact_info.dart';

class MyPuppiesFooter extends StatelessWidget {
  const MyPuppiesFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);

    return Container(
      width: double.infinity,
      color: AppColors.black,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 60, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 60,
            runSpacing: 24,
            children: [
              const SizedBox(
                width: 220,
                child: Text(
                  'MY PUPPIES',
                  style: TextStyle(color: AppColors.orange, fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: 0.5),
                ),
              ),
              _FooterColumn(title: 'Quick Links', items: const [
                'Home',
                'Browse Dogs',
                'Adoption Process',
                'About Us',
              ]),
              const _ContactColumn(),
            ],
          ),
          const SizedBox(height: 32),
          const Divider(color: Colors.white24),
          const SizedBox(height: 12),
          const Text('© 2026 My Puppies. All rights reserved.',
              style: TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }
}

class _FooterColumn extends StatelessWidget {
  final String title;
  final List<String> items;
  const _FooterColumn({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 10),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(item, style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ),
        ],
      ),
    );
  }
}

class _ContactColumn extends StatelessWidget {
  const _ContactColumn();

  Future<void> _open(Uri uri) async {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Contact', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 10),
          _ContactRow(
            icon: Icons.email_outlined,
            label: ContactInfo.email,
            onTap: () => _open(Uri(scheme: 'mailto', path: ContactInfo.email)),
          ),
          _ContactRow(
            icon: Icons.phone_outlined,
            label: ContactInfo.phone,
            onTap: () => _open(Uri(scheme: 'tel', path: ContactInfo.phoneDialDigits)),
          ),
          _ContactRow(
            icon: Icons.chat_bubble_outline,
            label: 'Message us',
            onTap: () => _open(Uri.parse(ContactInfo.messengerUrl)),
          ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ContactRow({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 15, color: AppColors.orange),
            const SizedBox(width: 8),
            Expanded(child: Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12))),
          ],
        ),
      ),
    );
  }
}