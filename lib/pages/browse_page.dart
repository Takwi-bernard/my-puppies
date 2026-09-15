import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/responsive.dart';
import '../core/supabase_config.dart';
import '../core/theme.dart';
import '../models/pet.dart';
import '../widgets/page_header.dart';
import '../widgets/pet_card.dart';
import '../widgets/friendly_error.dart';

class BrowsePage extends StatefulWidget {
  const BrowsePage({super.key});

  @override
  State<BrowsePage> createState() => _BrowsePageState();
}

class _BrowsePageState extends State<BrowsePage> {
  String _species = 'all';
  String _searchText = '';
  late Future<List<Pet>> _petsFuture;
  List<Pet> _allPets = [];

  static const _speciesOptions = ['all', 'dog', 'cat', 'bird', 'rabbit', 'other'];

  @override
  void initState() {
    super.initState();
    _petsFuture = _fetch();
  }

  Future<List<Pet>> _fetch() async {
    final rows = await supabase
        .from('pets')
        .select()
        .eq('status', 'available')
        .order('created_at', ascending: false);
    _allPets = (rows as List).map((r) => Pet.fromMap(r)).toList();
    return _allPets;
  }

  void _refetch() => setState(() => _petsFuture = _fetch());

  List<Pet> get _filteredPets {
    final query = _searchText.trim().toLowerCase();
    return _allPets.where((pet) {
      final matchesSpecies = _species == 'all' || pet.species == _species;
      final matchesQuery = query.isEmpty ||
          pet.name.toLowerCase().contains(query) ||
          (pet.breed?.toLowerCase().contains(query) ?? false);
      return matchesSpecies && matchesQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);

    return Column(
      children: [
        const PageHeader(
          title: 'Find Your Perfect Companion',
          subtitle: 'Browse adoptable dogs — search by name or filter by type.',
        ),
        Padding(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: isMobile ? double.infinity : 280,
                    child: TextField(
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        hintText: 'Search by name or breed…',
                        isDense: true,
                        border: const OutlineInputBorder(),
                        suffixIcon: _searchText.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: () => setState(() => _searchText = ''),
                              )
                            : null,
                      ),
                      onChanged: (v) => setState(() => _searchText = v),
                    ),
                  ),
                  DropdownButton<String>(
                    value: _species,
                    items: _speciesOptions
                        .map((s) => DropdownMenuItem(value: s, child: Text(_label(s))))
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _species = v);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              FutureBuilder<List<Pet>>(
                future: _petsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snapshot.hasError) {
                    return FriendlyError(onRetry: _refetch);
                  }
                  final pets = _filteredPets;
                  if (pets.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Text("No dogs match this search yet — try a different name or type.",
                          style: TextStyle(color: Colors.black54)),
                    );
                  }
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: GridView.builder(
                      key: ValueKey('${_species}_$_searchText'),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: Breakpoints.gridColumns(context),
                        mainAxisSpacing: isMobile ? 12 : 16,
                        crossAxisSpacing: isMobile ? 12 : 16,
                        childAspectRatio: Breakpoints.gridChildAspectRatio(context),
                      ),
                      itemCount: pets.length,
                      itemBuilder: (context, i) => PetCard(
                        pet: pets[i],
                        onTap: () => context.push('/pets/${pets[i].id}'),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _label(String s) {
    switch (s) {
      case 'dog':
        return 'Dogs';
      case 'cat':
        return 'Cats';
      case 'bird':
        return 'Birds';
      case 'rabbit':
        return 'Rabbits';
      case 'other':
        return 'Other';
      default:
        return 'All Species';
    }
  }
}