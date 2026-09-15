import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/responsive.dart';
import '../../../core/supabase_config.dart';
import '../../../core/theme.dart';
import '../../../widgets/friendly_error.dart';

class AdminPetDetailPage extends StatefulWidget {
  final String petId;
  const AdminPetDetailPage({super.key, required this.petId});

  @override
  State<AdminPetDetailPage> createState() => _AdminPetDetailPageState();
}

class _PetDetail {
  final Map<String, dynamic> pet;
  final List<String> photoUrls;
  _PetDetail({required this.pet, required this.photoUrls});
}

class _AdminPetDetailPageState extends State<AdminPetDetailPage> {
  late Future<_PetDetail> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_PetDetail> _load() async {
    final pet = await supabase.from('pets').select().eq('id', widget.petId).single();
    final photos = await supabase.from('pet_photos').select('photo_url').eq('pet_id', widget.petId).order('sort_order');
    return _PetDetail(pet: pet, photoUrls: (photos as List).map((p) => p['photo_url'] as String).toList());
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'available':
        return Colors.green;
      case 'pending':
        return AppColors.orange;
      case 'adopted':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);

    return FutureBuilder<_PetDetail>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(padding: EdgeInsets.symmetric(vertical: 60), child: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) return FriendlyError(onRetry: () => setState(() => _future = _load()));

        final pet = snapshot.data!.pet;
        final photoUrls = snapshot.data!.photoUrls;

        return ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back)),
                  Expanded(child: Text(pet['name'] as String? ?? 'Dog', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700))),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final edited = await context.push<bool>('/admin/pets/${widget.petId}/edit');
                      if (edited == true) setState(() => _future = _load());
                    },
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('EDIT'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (photoUrls.isNotEmpty)
                SizedBox(
                  height: isMobile ? 220 : 320,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: photoUrls.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, i) => ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(photoUrls[i], width: isMobile ? 220 : 320, fit: BoxFit.cover),
                    ),
                  ),
                )
              else
                Container(
                  height: 160,
                  decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(14)),
                  child: const Center(child: Icon(Icons.pets, color: AppColors.orange, size: 40)),
                ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: _statusColor(pet['status'] as String? ?? '').withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                    child: Text(pet['status'] as String? ?? '', style: TextStyle(color: _statusColor(pet['status'] as String? ?? ''), fontWeight: FontWeight.w700, fontSize: 12)),
                  ),
                  if (pet['adoption_fee'] != null) _Chip('\$${pet['adoption_fee']} adoption fee'),
                ],
              ),
              const SizedBox(height: 20),
              _Card(
                title: 'Details',
                child: Wrap(
                  spacing: 24,
                  runSpacing: 12,
                  children: [
                    _Field('Species', pet['species'] as String?),
                    _Field('Breed', pet['breed'] as String?),
                    _Field('Age', pet['age_category'] as String?),
                    _Field('Gender', pet['gender'] as String?),
                    _Field('Size', pet['size'] as String?),
                    _Field('Color', pet['color'] as String?),
                    _Field('Location', [pet['location_city'], pet['location_state']].where((e) => e != null && (e as String).isNotEmpty).join(', ')),
                  ],
                ),
              ),
              if ((pet['bio'] as String?)?.isNotEmpty == true) ...[
                const SizedBox(height: 16),
                _Card(title: 'Bio', child: Text(pet['bio'] as String, style: const TextStyle(color: Colors.black87, height: 1.5))),
              ],
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }
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

class _Field extends StatelessWidget {
  final String label;
  final String? value;
  const _Field(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      width: 140,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.black45)),
          Text(value!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}