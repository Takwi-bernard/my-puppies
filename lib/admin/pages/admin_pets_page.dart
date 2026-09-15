import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/responsive.dart';
import '../../../core/supabase_config.dart';
import '../../../core/theme.dart';
import '../../../models/pet.dart';
import '../../../widgets/friendly_error.dart';
import '../widgets/animated_entry.dart';

class AdminPetsPage extends StatefulWidget {
  const AdminPetsPage({super.key});

  @override
  State<AdminPetsPage> createState() => _AdminPetsPageState();
}

class _AdminPetsPageState extends State<AdminPetsPage> {
  late Future<List<Pet>> _petsFuture;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _petsFuture = _load();
  }

  Future<List<Pet>> _load() async {
    final rows = await supabase.from('pets').select().order('created_at', ascending: false);
    return (rows as List).map((r) => Pet.fromMap(r)).toList();
  }

  void _refetch() => setState(() => _petsFuture = _load());

  void _success(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.green));
  }

  void _failure(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
  }

  String? _extractStoragePath(String url) {
    const marker = '/pet-photos/';
    final idx = url.indexOf(marker);
    if (idx == -1) return null;
    return Uri.decodeFull(url.substring(idx + marker.length));
  }

  Future<void> _confirmDelete(Pet pet) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this dog?'),
        content: Text('This permanently deletes "${pet.name}", all of its photos, and any applications or favorites tied to it. This can\'t be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed != true) return;
    await _deletePet(pet);
  }

  Future<void> _deletePet(Pet pet) async {
    setState(() => _deleting = true);
    try {
      final photoRows = await supabase.from('pet_photos').select('photo_url').eq('pet_id', pet.id);
      final paths = (photoRows as List).map((r) => _extractStoragePath(r['photo_url'] as String)).whereType<String>().toList();
      if (paths.isNotEmpty) {
        await supabase.storage.from('pet-photos').remove(paths);
      }
      await supabase.from('pets').delete().eq('id', pet.id);
      _success('${pet.name} was deleted.');
      _refetch();
    } catch (e) {
      debugPrint('Delete failed for ${pet.id}: $e');
      _failure("Couldn't delete this dog. Please try again.");
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: Text('Manage Dogs', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700))),
            ElevatedButton.icon(
              onPressed: () async {
                final posted = await context.push<bool>('/admin/pets/new');
                if (posted == true) _success('Dog posted successfully!');
                _refetch();
              },
              icon: const Icon(Icons.add),
              label: Text(isMobile ? 'Add' : 'ADD DOG'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (_deleting) const LinearProgressIndicator(),
        FutureBuilder<List<Pet>>(
          future: _petsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(padding: EdgeInsets.symmetric(vertical: 60), child: Center(child: CircularProgressIndicator()));
            }
            if (snapshot.hasError) return FriendlyError(onRetry: _refetch);
            final pets = snapshot.data ?? [];
            if (pets.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: Text('No dogs posted yet — tap "Add Dog" to post the first one.', style: TextStyle(color: Colors.black54)),
              );
            }
            return Column(
              children: [
                for (var i = 0; i < pets.length; i++)
                  AnimatedEntry(
                    index: i,
                    child: _PetRow(
                      pet: pets[i],
                      onOpen: () async {
                        final changed = await context.push<bool>('/admin/pets/${pets[i].id}');
                        if (changed == true) _refetch();
                      },
                      onEdit: () async {
                        final edited = await context.push<bool>('/admin/pets/${pets[i].id}/edit');
                        if (edited == true) _success('${pets[i].name} was updated.');
                        _refetch();
                      },
                      onDelete: () => _confirmDelete(pets[i]),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _PetRow extends StatelessWidget {
  final Pet pet;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _PetRow({required this.pet, required this.onOpen, required this.onEdit, required this.onDelete});

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
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 48, height: 48,
                  child: pet.coverPhotoUrl != null
                      ? Image.network(pet.coverPhotoUrl!, fit: BoxFit.cover)
                      : Container(color: AppColors.cream, child: const Icon(Icons.pets, color: AppColors.orange)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pet.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(pet.species, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: _statusColor(pet.status).withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                child: Text(pet.status, style: TextStyle(color: _statusColor(pet.status), fontSize: 12, fontWeight: FontWeight.w600)),
              ),
              IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.orange), tooltip: 'Edit'),
              IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red), tooltip: 'Delete'),
            ],
          ),
        ),
      ),
    );
  }
}