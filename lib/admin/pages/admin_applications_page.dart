import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/supabase_config.dart';
import '../../../core/theme.dart';
import '../../../models/application.dart';
import '../../../widgets/friendly_error.dart';

class AdminApplicationsPage extends StatefulWidget {
  const AdminApplicationsPage({super.key});

  @override
  State<AdminApplicationsPage> createState() => _AdminApplicationsPageState();
}

class _AdminApplicationsPageState extends State<AdminApplicationsPage> {
  String _statusFilter = 'all';
  late Future<List<Application>> _future;

  static const _statuses = ['all', 'submitted', 'in_review', 'meeting_scheduled', 'approved', 'completed', 'declined'];

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Application>> _load() async {
    var query = supabase.from('applications').select('*, pets(name, cover_photo_url), profiles(full_name, email, phone)');
    if (_statusFilter != 'all') {
      query = query.eq('status', _statusFilter);
    }
    final rows = await query.order('created_at', ascending: false);
    return (rows as List).map((r) => Application.fromMap(r)).toList();
  }

  void _refetch() => setState(() => _future = _load());

  Color _statusColor(String status) {
    switch (status) {
      case 'submitted':
        return Colors.red;
      case 'in_review':
        return AppColors.orange;
      case 'meeting_scheduled':
        return Colors.blue;
      case 'approved':
      case 'completed':
        return Colors.green;
      case 'declined':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Applications', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: _statuses.map((s) {
              final selected = _statusFilter == s;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(s.replaceAll('_', ' ')),
                  selected: selected,
                  selectedColor: AppColors.orange,
                  labelStyle: TextStyle(color: selected ? Colors.white : AppColors.charcoal, fontSize: 12),
                  onSelected: (_) {
                    setState(() => _statusFilter = s);
                    _refetch();
                  },
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
        FutureBuilder<List<Application>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(padding: EdgeInsets.symmetric(vertical: 60), child: Center(child: CircularProgressIndicator()));
            }
            if (snapshot.hasError) return FriendlyError(onRetry: _refetch);
            final apps = snapshot.data ?? [];
            if (apps.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: Text('No applications in this status yet.', style: TextStyle(color: Colors.black54)),
              );
            }
            return Column(
              children: apps.map((a) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black12)),
                  child: ListTile(
                    onTap: () async {
                      await context.push('/admin/applications/${a.id}');
                      _refetch();
                    },
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 44, height: 44,
                        child: a.petCoverPhotoUrl != null
                            ? Image.network(a.petCoverPhotoUrl!, fit: BoxFit.cover)
                            : Container(color: AppColors.cream, child: const Icon(Icons.pets, color: AppColors.orange, size: 18)),
                      ),
                    ),
                    title: Text('${a.displayName ?? "Unnamed applicant"} → ${a.petName ?? "Unknown dog"}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: _statusColor(a.status).withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                      child: Text(a.status.replaceAll('_', ' '), style: TextStyle(color: _statusColor(a.status), fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}