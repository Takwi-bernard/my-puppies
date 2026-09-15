import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/responsive.dart';
import '../core/supabase_config.dart';
import '../core/theme.dart';
import '../models/pet.dart';
import '../widgets/hero_section.dart';
import '../widgets/pet_card.dart';
import '../widgets/friendly_error.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Pet>> _petsFuture;

  @override
  void initState() {
    super.initState();
    _petsFuture = _fetchPets();
  }

  // Newest first — a freshly-posted dog should be the first thing a
  // returning visitor sees.
  Future<List<Pet>> _fetchPets() async {
    final rows = await supabase
        .from('pets')
        .select()
        .eq('status', 'available')
        .order('created_at', ascending: false)
        .limit(12);
    return (rows as List).map((r) => Pet.fromMap(r)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);

    return Column(
      children: [
        HeroSection(
          onBrowseTap: () => context.go('/browse'),
          onDonateTap: () => context.go('/donate'),
        ),

        // Featured dogs — horizontal scroll, matches the reference design's
        // card-row layout and naturally avoids the page growing endlessly
        // tall as more pets get posted (each new dog just extends the row,
        // not the page).
        Padding(
          padding: EdgeInsets.fromLTRB(isMobile ? 16 : 60, 48, isMobile ? 16 : 60, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('FEATURED DOGS',
                  style: TextStyle(color: AppColors.orange, fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 1)),
              const SizedBox(height: 6),
              Text('Meet Dogs Who Need You Today',
                  style: TextStyle(fontSize: isMobile ? 22 : 30, fontWeight: FontWeight.w800, color: AppColors.charcoal)),
            ],
          ),
        ),
        SizedBox(height: 16),
        FutureBuilder<List<Pet>>(
          future: _petsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return FriendlyError(onRetry: () => setState(() => _petsFuture = _fetchPets()));
            }
            final pets = snapshot.data ?? [];
            if (pets.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                child: Text(
                  "No dogs listed yet — new arrivals will appear here as soon as they're added.",
                  style: const TextStyle(color: Colors.black54),
                ),
              );
            }
            return SizedBox(
              height: isMobile ? 300 : 340,
              child: ListView.separated(
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 60),
                scrollDirection: Axis.horizontal,
                itemCount: pets.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (context, i) => SizedBox(
                  width: isMobile ? 200 : 240,
                  child: PetCard(
                    pet: pets[i],
                    onTap: () => context.push('/pets/${pets[i].id}'),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 56),
      ],
    );
  }
}