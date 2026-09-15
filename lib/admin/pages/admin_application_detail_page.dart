import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/supabase_config.dart';
import '../../../core/theme.dart';
import '../../../models/application.dart';
import '../../../widgets/friendly_error.dart';

class AdminApplicationDetailPage extends StatefulWidget {
  final String applicationId;
  const AdminApplicationDetailPage({super.key, required this.applicationId});

  @override
  State<AdminApplicationDetailPage> createState() => _AdminApplicationDetailPageState();
}

class _AdminApplicationDetailPageState extends State<AdminApplicationDetailPage> {
  late Future<Application> _future;
  bool _updating = false;

  static const _statusOptions = ['submitted', 'in_review', 'meeting_scheduled', 'approved', 'completed', 'declined'];

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Application> _load() async {
    final row = await supabase
        .from('applications')
        .select('*, pets(name, cover_photo_url), profiles(full_name, email, phone)')
        .eq('id', widget.applicationId)
        .single();
    return Application.fromMap(row);
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _updating = true);
    try {
      await supabase.from('applications').update({'status': newStatus}).eq('id', widget.applicationId);
      if (mounted) setState(() => _future = _load());
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  Future<void> _open(Uri uri) async {
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Application>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(padding: EdgeInsets.symmetric(vertical: 60), child: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) return FriendlyError(onRetry: () => setState(() => _future = _load()));
        final app = snapshot.data!;
        final answers = app.answers ?? {};

        return ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back)),
                  Expanded(child: Text('Application for ${app.petName ?? "dog"}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700))),
                ],
              ),
              const SizedBox(height: 16),
              _Card(
                title: 'Applicant',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(app.displayName ?? 'Not provided', style: const TextStyle(fontWeight: FontWeight.w600)),
                        if (app.isGuest) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: AppColors.orange.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                            child: const Text('Guest — no account', style: TextStyle(fontSize: 10, color: AppColors.orangeDark, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (app.contactEmail != null)
                      _ContactRow(icon: Icons.email_outlined, label: app.contactEmail!, onTap: () => _open(Uri(scheme: 'mailto', path: app.contactEmail))),
                    if (app.contactPhone != null) ...[
                      _ContactRow(icon: Icons.phone_outlined, label: app.contactPhone!, onTap: () => _open(Uri(scheme: 'tel', path: app.contactPhone))),
                      _ContactRow(icon: Icons.chat_bubble_outline, label: 'WhatsApp', onTap: () => _open(Uri.parse('https://wa.me/${app.contactPhone!.replaceAll(RegExp(r"[^0-9]"), "")}'))),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _Card(
                title: 'Application Answers',
                child: answers.isEmpty
                    ? const Text('No additional answers submitted.', style: TextStyle(color: Colors.black54))
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: answers.entries
                            .map((e) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(_labelize(e.key), style: const TextStyle(fontSize: 11, color: Colors.black45)),
                                      Text('${e.value}', style: const TextStyle(fontSize: 14)),
                                    ],
                                  ),
                                ))
                            .toList(),
                      ),
              ),
              const SizedBox(height: 16),
              _Card(
                title: 'Status',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _statusOptions.map((s) {
                        final isCurrent = app.status == s;
                        return ChoiceChip(
                          label: Text(s.replaceAll('_', ' ')),
                          selected: isCurrent,
                          selectedColor: AppColors.orange,
                          labelStyle: TextStyle(color: isCurrent ? Colors.white : AppColors.charcoal, fontSize: 12),
                          onSelected: _updating ? null : (_) => _updateStatus(s),
                        );
                      }).toList(),
                    ),
                    if (_updating) ...[const SizedBox(height: 10), const LinearProgressIndicator()],
                    const SizedBox(height: 10),
                    const Text(
                      'Email notifications aren\'t connected yet — use the contact links above to reach out directly for now.',
                      style: TextStyle(fontSize: 11, color: Colors.black45),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  String _labelize(String key) => key.replaceAll('_', ' ').split(' ').map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
}

class _Card extends StatelessWidget {
  final String title;
  final Widget child;
  const _Card({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.black12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.orange)),
          const SizedBox(height: 10),
          child,
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
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [Icon(icon, size: 16, color: AppColors.orange), const SizedBox(width: 8), Text(label, style: const TextStyle(fontSize: 13))]),
      ),
    );
  }
}