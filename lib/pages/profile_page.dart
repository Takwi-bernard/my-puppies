import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/customer_auth_state.dart';
import '../core/supabase_config.dart';
import '../core/theme.dart';
import '../core/responsive.dart';
import '../widgets/friendly_error.dart';

class ProfilePage extends StatefulWidget {
  final CustomerAuthState authState;
  const ProfilePage({super.key, required this.authState});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfileApplication {
  final String id;
  final String petId;
  final String? petName;
  final String? petCoverPhotoUrl;
  final String status;
  _ProfileApplication({required this.id, required this.petId, this.petName, this.petCoverPhotoUrl, required this.status});
}

class _ProfileFavorite {
  final String petId;
  final String? petName;
  final String? petCoverPhotoUrl;
  final String? species;
  _ProfileFavorite({required this.petId, this.petName, this.petCoverPhotoUrl, this.species});
}

class _ProfilePageState extends State<ProfilePage> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  bool _editingProfile = false;
  bool _savingProfile = false;

  late Future<List<_ProfileApplication>> _applicationsFuture;
  late Future<List<_ProfileFavorite>> _favoritesFuture;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.authState.fullName ?? '');
    _phoneController = TextEditingController(text: widget.authState.phone ?? '');
    _applicationsFuture = _loadApplications();
    _favoritesFuture = _loadFavorites();
  }

  Future<List<_ProfileApplication>> _loadApplications() async {
    final userId = widget.authState.userId;
    if (userId == null) return [];
    final rows = await supabase
        .from('applications')
        .select('id, pet_id, status, pets(name, cover_photo_url)')
        .eq('applicant_id', userId)
        .order('created_at', ascending: false);
    return (rows as List).map((r) {
      final pet = r['pets'] as Map<String, dynamic>?;
      return _ProfileApplication(
        id: r['id'] as String,
        petId: r['pet_id'] as String,
        petName: pet?['name'] as String?,
        petCoverPhotoUrl: pet?['cover_photo_url'] as String?,
        status: r['status'] as String? ?? 'submitted',
      );
    }).toList();
  }

  Future<List<_ProfileFavorite>> _loadFavorites() async {
    final userId = widget.authState.userId;
    if (userId == null) return [];
    final rows = await supabase
        .from('favorites')
        .select('pet_id, pets(name, cover_photo_url, species)')
        .eq('adopter_id', userId);
    return (rows as List).map((r) {
      final pet = r['pets'] as Map<String, dynamic>?;
      return _ProfileFavorite(
        petId: r['pet_id'] as String,
        petName: pet?['name'] as String?,
        petCoverPhotoUrl: pet?['cover_photo_url'] as String?,
        species: pet?['species'] as String?,
      );
    }).toList();
  }

  Future<void> _removeFavorite(String petId) async {
    final userId = widget.authState.userId;
    if (userId == null) return;
    try {
      await supabase.from('favorites').delete().eq('adopter_id', userId).eq('pet_id', petId);
      setState(() => _favoritesFuture = _loadFavorites());
    } catch (_) {}
  }

  Future<void> _saveProfile() async {
    setState(() => _savingProfile = true);
    final error = await widget.authState.updateProfile(
      fullName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
    );
    if (!mounted) return;
    setState(() {
      _savingProfile = false;
      if (error == null) _editingProfile = false;
    });
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.red));
    }
  }

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

  String _statusLabel(String status) {
    switch (status) {
      case 'submitted':
        return 'Submitted — awaiting review';
      case 'in_review':
        return 'In review';
      case 'meeting_scheduled':
        return 'Meeting scheduled';
      case 'approved':
        return 'Approved!';
      case 'completed':
        return 'Adoption complete';
      case 'declined':
        return 'Not approved';
      default:
        return status;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);

    if (!widget.authState.isLoggedIn) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.person_outline, size: 48, color: Colors.black26),
              const SizedBox(height: 12),
              const Text("You're not signed in.", style: TextStyle(color: Colors.black54)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: () => context.go('/login'), child: const Text('SIGN IN')),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('My Profile', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.black12)),
              child: _editingProfile
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder())),
                        const SizedBox(height: 12),
                        TextField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder())),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: _savingProfile ? null : _saveProfile,
                              child: _savingProfile
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Text('Save'),
                            ),
                            const SizedBox(width: 10),
                            TextButton(onPressed: () => setState(() => _editingProfile = false), child: const Text('Cancel')),
                          ],
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: AppColors.orange,
                          child: Text(
                            (widget.authState.fullName?.isNotEmpty ?? false) ? widget.authState.fullName![0].toUpperCase() : '?',
                            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.authState.fullName?.isNotEmpty == true ? widget.authState.fullName! : 'No name set',
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                              Text(widget.authState.email ?? '', style: const TextStyle(color: Colors.black54, fontSize: 13)),
                              if (widget.authState.phone?.isNotEmpty ?? false)
                                Text(widget.authState.phone!, style: const TextStyle(color: Colors.black54, fontSize: 13)),
                            ],
                          ),
                        ),
                        IconButton(onPressed: () => setState(() => _editingProfile = true), icon: const Icon(Icons.edit_outlined, color: AppColors.orange)),
                      ],
                    ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () async {
                  await widget.authState.signOut();
                  if (context.mounted) context.go('/');
                },
                icon: const Icon(Icons.logout, size: 16, color: Colors.black54),
                label: const Text('Sign out', style: TextStyle(color: Colors.black54)),
              ),
            ),

            const SizedBox(height: 12),
            const Text('My Applications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text('Every application you\'ve submitted lives here.', style: TextStyle(color: Colors.black54, fontSize: 13)),
            const SizedBox(height: 16),
            FutureBuilder<List<_ProfileApplication>>(
              future: _applicationsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(padding: EdgeInsets.symmetric(vertical: 40), child: Center(child: CircularProgressIndicator()));
                }
                if (snapshot.hasError) {
                  return FriendlyError(onRetry: () => setState(() => _applicationsFuture = _loadApplications()));
                }
                final applications = snapshot.data ?? [];
                if (applications.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(14)),
                    child: const Text("You haven't submitted any applications yet — browse dogs to get started.", style: TextStyle(color: Colors.black54)),
                  );
                }
                return Column(
                  children: applications.map((app) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black12)),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              width: 48,
                              height: 48,
                              child: app.petCoverPhotoUrl != null
                                  ? Image.network(app.petCoverPhotoUrl!, fit: BoxFit.cover)
                                  : Container(color: AppColors.cream, child: const Icon(Icons.pets, color: AppColors.orange)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(app.petName ?? 'Dog', style: const TextStyle(fontWeight: FontWeight.w700)),
                                Text(_statusLabel(app.status), style: TextStyle(color: _statusColor(app.status), fontSize: 12, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                          IconButton(onPressed: () => context.push('/pets/${app.petId}'), icon: const Icon(Icons.chevron_right, color: AppColors.orange)),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 32),
            const Text('My Favorites', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            FutureBuilder<List<_ProfileFavorite>>(
              future: _favoritesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(padding: EdgeInsets.symmetric(vertical: 40), child: Center(child: CircularProgressIndicator()));
                }
                if (snapshot.hasError) {
                  return FriendlyError(onRetry: () => setState(() => _favoritesFuture = _loadFavorites()));
                }
                final favorites = snapshot.data ?? [];
                if (favorites.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(14)),
                    child: const Text("You haven't favorited any dogs yet.", style: TextStyle(color: Colors.black54)),
                  );
                }
                return Column(
                  children: favorites.map((fav) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black12)),
                      child: Row(
                        children: [
                          InkWell(
                            onTap: () => context.push('/pets/${fav.petId}'),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SizedBox(
                                width: 48,
                                height: 48,
                                child: fav.petCoverPhotoUrl != null
                                    ? Image.network(fav.petCoverPhotoUrl!, fit: BoxFit.cover)
                                    : Container(color: AppColors.cream, child: const Icon(Icons.pets, color: AppColors.orange)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: () => context.push('/pets/${fav.petId}'),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(fav.petName ?? 'Dog', style: const TextStyle(fontWeight: FontWeight.w700)),
                                  if (fav.species != null) Text(fav.species!, style: const TextStyle(color: Colors.black54, fontSize: 12)),
                                ],
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => _removeFavorite(fav.petId),
                            icon: const Icon(Icons.favorite, color: Colors.red, size: 20),
                            tooltip: 'Remove from favorites',
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}