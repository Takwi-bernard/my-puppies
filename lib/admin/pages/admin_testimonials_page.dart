import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/responsive.dart';
import '../../../core/supabase_config.dart';
import '../../../core/theme.dart';
import '../../../models/testimonial.dart';
import '../../../widgets/friendly_error.dart';
import '../widgets/animated_entry.dart';

class AdminTestimonialsPage extends StatefulWidget {
  const AdminTestimonialsPage({super.key});

  @override
  State<AdminTestimonialsPage> createState() => _AdminTestimonialsPageState();
}

class _AdminTestimonialsPageState extends State<AdminTestimonialsPage> {
  late Future<List<Testimonial>> _future;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Testimonial>> _load() async {
    final rows = await supabase.from('testimonials').select().order('created_at', ascending: false);
    return (rows as List).map((r) => Testimonial.fromMap(r)).toList();
  }

  void _refetch() => setState(() => _future = _load());

  void _success(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.green));
  }

  void _failure(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
  }

  String? _extractStoragePath(String url) {
    const marker = '/testimonials/';
    final idx = url.indexOf(marker);
    if (idx == -1) return null;
    return Uri.decodeFull(url.substring(idx + marker.length));
  }

  Future<void> _confirmDelete(Testimonial testimonial) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this story?'),
        content: const Text('This adopter story will be permanently removed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed != true) return;
    await _deleteTestimonial(testimonial);
  }

  Future<void> _deleteTestimonial(Testimonial testimonial) async {
    setState(() => _deleting = true);
    try {
      if (testimonial.photoUrl != null) {
        final path = _extractStoragePath(testimonial.photoUrl!);
        if (path != null) {
          try {
            await supabase.storage.from('testimonials').remove([path]);
          } catch (_) {}
        }
      }
      await supabase.from('testimonials').delete().eq('id', testimonial.id);
      _success('Story deleted.');
      _refetch();
    } catch (e) {
      debugPrint('Delete failed for ${testimonial.id}: $e');
      _failure("Couldn't delete this story.");
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
            const Expanded(child: Text('Adopter Stories', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700))),
            ElevatedButton.icon(
              onPressed: () async {
                final added = await context.push<bool>('/admin/testimonials/new');
                if (added == true) _success('Story added!');
                _refetch();
              },
              icon: const Icon(Icons.add),
              label: Text(isMobile ? 'Add' : 'ADD STORY'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (_deleting) const LinearProgressIndicator(),
        FutureBuilder<List<Testimonial>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(padding: EdgeInsets.symmetric(vertical: 60), child: Center(child: CircularProgressIndicator()));
            }
            if (snapshot.hasError) return FriendlyError(onRetry: _refetch);
            final testimonials = snapshot.data ?? [];
            if (testimonials.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: Text('No adopter stories yet — tap "Add Story" to post the first one.', style: TextStyle(color: Colors.black54)),
              );
            }
            return Column(
              children: [
                for (var i = 0; i < testimonials.length; i++)
                  AnimatedEntry(
                    index: i,
                    child: _TestimonialRow(
                      testimonial: testimonials[i],
                      onEdit: () async {
                        final edited = await context.push<bool>('/admin/testimonials/${testimonials[i].id}/edit');
                        if (edited == true) _success('Story updated.');
                        _refetch();
                      },
                      onDelete: () => _confirmDelete(testimonials[i]),
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

class _TestimonialRow extends StatelessWidget {
  final Testimonial testimonial;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _TestimonialRow({required this.testimonial, required this.onEdit, required this.onDelete});

  Color _statusColor(String status) {
    switch (status) {
      case 'published':
        return Colors.green;
      case 'draft':
        return AppColors.orange;
      case 'archived':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black12)),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 48, height: 48,
              child: testimonial.photoUrl != null
                  ? Image.network(testimonial.photoUrl!, fit: BoxFit.cover)
                  : Container(color: AppColors.cream, child: const Icon(Icons.image_outlined, color: AppColors.orange)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(testimonial.familyName ?? 'Unnamed family', style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(
                  testimonial.description.length > 50 ? '${testimonial.description.substring(0, 50)}...' : testimonial.description,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: _statusColor(testimonial.status).withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
            child: Text(testimonial.status, style: TextStyle(color: _statusColor(testimonial.status), fontSize: 12, fontWeight: FontWeight.w600)),
          ),
          IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.orange), tooltip: 'Edit'),
          IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red), tooltip: 'Delete'),
        ],
      ),
    );
  }
}