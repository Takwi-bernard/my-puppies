import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/responsive.dart';
import '../core/theme.dart';
import '../core/contact_info.dart';
import '../widgets/page_header.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);
    return Column(
      children: [
        const PageHeader(
          title: 'More Than a Rescue',
          subtitle: 'We\'re a movement built to bring the shelter kill rate to zero.',
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 60, vertical: 40),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Our mission', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: AppColors.orange)),
                  const SizedBox(height: 8),
                  const Text(
                    'My Puppies exists to make finding a rescue dog feel less like searching '
                    'and more like recognizing someone you already know. We list every dog '
                    'in our care clearly and honestly, and support adopters through every step '
                    'of bringing them home.',
                    style: TextStyle(color: Colors.black54, height: 1.5),
                  ),
                  const SizedBox(height: 28),
                  const Text('How we work', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: AppColors.orange)),
                  const SizedBox(height: 8),
                  const Text(
                    'We\'re a single, directly-managed rescue rather than a marketplace of '
                    'third-party shelters — one team lists every dog, reviews every application, '
                    'and stays involved from first contact to adoption day.',
                    style: TextStyle(color: Colors.black54, height: 1.5),
                  ),
                  const SizedBox(height: 28),
                  const _ContactSection(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ContactSection extends StatelessWidget {
  const _ContactSection();

  Future<void> _open(Uri uri) async {
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Get in touch', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: AppColors.orange)),
        const SizedBox(height: 12),
        _ContactTile(icon: Icons.email_outlined, label: ContactInfo.email, onTap: () => _open(Uri(scheme: 'mailto', path: ContactInfo.email))),
        _ContactTile(icon: Icons.phone_outlined, label: ContactInfo.phone, onTap: () => _open(Uri(scheme: 'tel', path: ContactInfo.phoneDialDigits))),
        _ContactTile(icon: Icons.chat_bubble_outline, label: 'Message us on Messenger', onTap: () => _open(Uri.parse(ContactInfo.messengerUrl))),
      ],
    );
  }
}

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ContactTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.orange),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(color: AppColors.charcoal, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}