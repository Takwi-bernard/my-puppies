import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/responsive.dart';
import '../../../core/supabase_config.dart';
import '../../../core/theme.dart';
import '../../../widgets/friendly_error.dart';
import '../widgets/animated_entry.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _DashboardStats {
  final int totalPets;
  final int availablePets;
  final int adoptedPets;
  final int totalApplications;
  final int unreviewedApplications;
  _DashboardStats({required this.totalPets, required this.availablePets, required this.adoptedPets, required this.totalApplications, required this.unreviewedApplications});
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  late Future<_DashboardStats> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = _load();
  }

  Future<_DashboardStats> _load() async {
    final totalPets = await supabase.from('pets').select('id').count();
    final availablePets = await supabase.from('pets').select('id').eq('status', 'available').count();
    final adoptedPets = await supabase.from('pets').select('id').eq('status', 'adopted').count();
    final totalApplications = await supabase.from('applications').select('id').count();
    final unreviewed = await supabase.from('applications').select('id').eq('status', 'submitted').count();

    return _DashboardStats(
      totalPets: totalPets.count,
      availablePets: availablePets.count,
      adoptedPets: adoptedPets.count,
      totalApplications: totalApplications.count,
      unreviewedApplications: unreviewed.count,
    );
  }

  void _retry() => setState(() => _statsFuture = _load());

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Dashboard', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        const Text('A live snapshot of the platform.', style: TextStyle(color: Colors.black54)),
        const SizedBox(height: 24),
        FutureBuilder<_DashboardStats>(
          future: _statsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(padding: EdgeInsets.symmetric(vertical: 60), child: Center(child: CircularProgressIndicator()));
            }
            if (snapshot.hasError) return FriendlyError(onRetry: _retry);
            final s = snapshot.data!;
            final cards = [
              _StatCard(label: 'Total Dogs', value: '${s.totalPets}', icon: Icons.pets, color: AppColors.orange),
              _StatCard(label: 'Currently Available', value: '${s.availablePets}', icon: Icons.visibility_outlined, color: AppColors.orangeDark),
              _StatCard(label: 'Adopted', value: '${s.adoptedPets}', icon: Icons.home_outlined, color: Colors.green),
              _StatCard(label: 'Total Applications', value: '${s.totalApplications}', icon: Icons.assignment_outlined, color: AppColors.orange),
              _StatCard(label: 'Needs Review', value: '${s.unreviewedApplications}', icon: Icons.mark_email_unread_outlined, color: s.unreviewedApplications > 0 ? Colors.red : Colors.grey, onTap: () => context.go('/admin/applications')),
            ];
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                for (var i = 0; i < cards.length; i++)
                  AnimatedEntry(index: i, child: SizedBox(width: isMobile ? double.infinity : 220, child: cards[i])),
              ],
            );
          },
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            ElevatedButton.icon(onPressed: () => context.go('/admin/pets/new'), icon: const Icon(Icons.add), label: const Text('POST A NEW DOG')),
            const SizedBox(width: 12),
            OutlinedButton.icon(onPressed: () => context.go('/admin/applications'), icon: const Icon(Icons.assignment_outlined), label: const Text('REVIEW APPLICATIONS')),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  const _StatCard({required this.label, required this.value, required this.icon, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.black12)),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}