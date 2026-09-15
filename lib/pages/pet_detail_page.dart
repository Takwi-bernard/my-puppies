import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/responsive.dart';
import '../core/supabase_config.dart';
import '../core/theme.dart';
import '../core/customer_auth_state.dart';
import '../models/pet.dart';
import '../widgets/friendly_error.dart';

class PetDetailPage extends StatefulWidget {
  final String petId;
  final CustomerAuthState authState;
  const PetDetailPage({super.key, required this.petId, required this.authState});

  @override
  State<PetDetailPage> createState() => _PetDetailPageState();
}

class _PetWithPhotos {
  final Pet pet;
  final List<String> photoUrls;
  _PetWithPhotos({required this.pet, required this.photoUrls});
}

class _PetDetailPageState extends State<PetDetailPage> {
  late Future<_PetWithPhotos> _future;
  bool _isFavorite = false;
  bool _checkingFavorite = true;

  @override
  void initState() {
    super.initState();
    _future = _load();
    _checkFavorite();
  }

  Future<_PetWithPhotos> _load() async {
    final pet = await supabase.from('pets').select().eq('id', widget.petId).single();
    final photos = await supabase
        .from('pet_photos')
        .select('photo_url')
        .eq('pet_id', widget.petId)
        .order('sort_order');
    return _PetWithPhotos(
      pet: Pet.fromMap(pet),
      photoUrls: (photos as List).map((p) => p['photo_url'] as String).toList(),
    );
  }

  Future<void> _checkFavorite() async {
    if (!widget.authState.isLoggedIn) {
      setState(() => _checkingFavorite = false);
      return;
    }
    try {
      final row = await supabase
          .from('favorites')
          .select('pet_id')
          .eq('adopter_id', widget.authState.userId!)
          .eq('pet_id', widget.petId)
          .maybeSingle();
      if (mounted) setState(() => _isFavorite = row != null);
    } catch (_) {
      // Non-fatal — heart just starts unfilled.
    } finally {
      if (mounted) setState(() => _checkingFavorite = false);
    }
  }

  Future<void> _toggleFavorite() async {
    if (!widget.authState.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Sign in to save favorites.'),
          action: SnackBarAction(label: 'Sign in', onPressed: () => context.go('/login')),
        ),
      );
      return;
    }

    final newValue = !_isFavorite;
    setState(() => _isFavorite = newValue); // optimistic

    try {
      if (newValue) {
        await supabase.from('favorites').insert({
          'adopter_id': widget.authState.userId,
          'pet_id': widget.petId,
        });
      } else {
        await supabase
            .from('favorites')
            .delete()
            .eq('adopter_id', widget.authState.userId!)
            .eq('pet_id', widget.petId);
      }
    } catch (e) {
      if (mounted) setState(() => _isFavorite = !newValue); // rollback
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);

    return FutureBuilder<_PetWithPhotos>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 80),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return FriendlyError(onRetry: () => setState(() => _future = _load()));
        }

        final pet = snapshot.data!.pet;
        final photoUrls = snapshot.data!.photoUrls;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(isMobile ? 16 : 24, 16, 16, 0),
              child: InkWell(
                onTap: () => context.pop(),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_back, size: 18, color: AppColors.orange),
                    SizedBox(width: 6),
                    Text('Back', style: TextStyle(color: AppColors.orange, fontSize: 13)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            if (photoUrls.isNotEmpty)
              SizedBox(
                height: isMobile ? 300 : 400,
                child: Stack(
                  children: [
                    PageView.builder(
                      itemCount: photoUrls.length,
                      itemBuilder: (context, i) => Image.network(photoUrls[i], fit: BoxFit.cover),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: GestureDetector(
                        onTap: _checkingFavorite ? null : _toggleFavorite,
                        child: AnimatedScale(
                          scale: _isFavorite ? 1.1 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          child: CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.white,
                            child: Icon(
                              _isFavorite ? Icons.favorite : Icons.favorite_border,
                              color: _isFavorite ? Colors.red : AppColors.orange,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                height: isMobile ? 300 : 400,
                color: AppColors.cream,
                child: const Center(child: Icon(Icons.pets, color: AppColors.orange, size: 64)),
              ),

            Padding(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pet.name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 12,
                    children: [
                      _Badge(pet.species),
                      _Badge(pet.ageCategory.toString()),
                      _Badge(pet.gender.toString()),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _DetailsGrid(pet: pet),
                  const SizedBox(height: 24),
                  if ((pet.bio?.isNotEmpty ?? false)) ...[
                    Text('About ${pet.name}',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.orange)),
                    const SizedBox(height: 8),
                    Text(pet.bio!, style: const TextStyle(fontSize: 14, height: 1.6, color: Colors.black87)),
                    const SizedBox(height: 24),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => context.push('/pets/${widget.petId}/apply'),
                      icon: const Icon(Icons.pets),
                      label: const Text('START ADOPTION APPLICATION'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('BACK TO BROWSE'),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  const _Badge(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.orange)),
    );
  }
}

class _DetailsGrid extends StatelessWidget {
  final Pet pet;
  const _DetailsGrid({required this.pet});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Breed', pet.breed ?? '—'),
      ('Size', pet.size),
      ('Color', pet.color ?? '—'),
      ('Location', '${pet.locationCity ?? '—'}, ${pet.locationState ?? ''}'),
    ];
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 2.2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: items
          .map((item) => Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(10)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(item.$1, style: const TextStyle(fontSize: 11, color: Colors.black45)),
                    Text(item.$2.toString(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ))
          .toList(),
    );
  }
}