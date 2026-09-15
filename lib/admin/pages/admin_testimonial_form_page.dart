import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/responsive.dart';
import '../../core/supabase_config.dart';
import '../../core/theme.dart';
import '../../models/testimonial.dart';

class AdminTestimonialFormPage extends StatefulWidget {
  final String? testimonialId;
  const AdminTestimonialFormPage({super.key, this.testimonialId});

  @override
  State<AdminTestimonialFormPage> createState() => _AdminTestimonialFormPageState();
}

class _AdminTestimonialFormPageState extends State<AdminTestimonialFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _familyNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _status = 'published';

  Uint8List? _pickedImageBytes;
  String? _pickedImageExt;
  String? _existingPhotoUrl;

  bool _loading = false;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.testimonialId != null) {
      _loading = true;
      _load();
    }
  }

  Future<void> _load() async {
    try {
      final row = await supabase.from('testimonials').select().eq('id', widget.testimonialId!).single();
      final testimonial = Testimonial.fromMap(row);
      _familyNameController.text = testimonial.familyName ?? '';
      _descriptionController.text = testimonial.description;
      _status = testimonial.status;
      _existingPhotoUrl = testimonial.photoUrl;
      setState(() => _loading = false);
    } catch (e) {
      debugPrint('Failed to load testimonial for editing: $e');
      setState(() {
        _loading = false;
        _error = "Couldn't load this story.";
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(imageQuality: 85,
    source: ImageSource.gallery
    
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    final ext = file.name.split('.').last;
    setState(() {
      _pickedImageBytes = bytes;
      _pickedImageExt = ext;
    });
  }

  String? _extractStoragePath(String url) {
    const marker = '/testimonials/';
    final idx = url.indexOf(marker);
    if (idx == -1) return null;
    return Uri.decodeFull(url.substring(idx + marker.length));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      String? photoUrl = _existingPhotoUrl;

      if (_pickedImageBytes != null) {
        final path = '${DateTime.now().microsecondsSinceEpoch}.$_pickedImageExt';
        await supabase.storage.from('testimonials').uploadBinary(path, _pickedImageBytes!);
        photoUrl = supabase.storage.from('testimonials').getPublicUrl(path);
        if (_existingPhotoUrl != null) {
          final oldPath = _extractStoragePath(_existingPhotoUrl!);
          if (oldPath != null) {
            try {
              await supabase.storage.from('testimonials').remove([oldPath]);
            } catch (_) {}
          }
        }
      }

      if (widget.testimonialId == null) {
        await supabase.from('testimonials').insert({
          'photo_url': photoUrl,
          'description': _descriptionController.text.trim(),
          'family_name': _familyNameController.text.trim().isEmpty ? null : _familyNameController.text.trim(),
          'status': _status,
        });
      } else {
        await supabase.from('testimonials').update({
          'photo_url': photoUrl,
          'description': _descriptionController.text.trim(),
          'family_name': _familyNameController.text.trim().isEmpty ? null : _familyNameController.text.trim(),
          'status': _status,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', widget.testimonialId!);
      }

      if (!mounted) return;
      if (context.canPop()) {
        context.pop(true);
      } else {
        context.go('/admin/testimonials');
      }
    } catch (e) {
      debugPrint('Submit failed: $e');
      setState(() => _error = "Couldn't save this story. Please try again.");
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _familyNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(padding: EdgeInsets.symmetric(vertical: 60), child: Center(child: CircularProgressIndicator()));
    }

    if (_error != null && widget.testimonialId != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: () { setState(() { _error = null; _loading = true; }); _load(); }, child: const Text('Retry')),
          ],
        ),
      );
    }

    final isMobile = Breakpoints.isMobile(context);

    return Form(
      key: _formKey,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back)),
                Text(widget.testimonialId == null ? 'Add Adopter Story' : 'Edit Story', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 16),
            _SectionLabel('Photo'),
            SizedBox(
              height: 140,
              child: InkWell(
                onTap: _pickImage,
                child: Container(
                  decoration: BoxDecoration(border: Border.all(color: AppColors.orange), borderRadius: BorderRadius.circular(12), color: AppColors.cream),
                  child: _pickedImageBytes != null
                      ? Image.memory(_pickedImageBytes!, fit: BoxFit.cover)
                      : _existingPhotoUrl != null
                          ? Image.network(_existingPhotoUrl!, fit: BoxFit.cover)
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo_outlined, color: AppColors.orange, size: 36),
                                SizedBox(height: 8),
                                Text('Tap to add a photo', style: TextStyle(color: AppColors.orange, fontSize: 13)),
                              ],
                            ),
                ),
              ),
            ),
            const Text('Optional — tap to upload or change', style: TextStyle(fontSize: 11, color: Colors.black45)),
            const SizedBox(height: 20),
            _SectionLabel('Story Details'),
            TextFormField(controller: _familyNameController, decoration: const InputDecoration(labelText: 'Family name (optional)', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Their story',
                hintText: 'Share their adoption journey, how they\'re doing, what makes them happy...',
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Please share their story' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
              items: const ['published', 'draft', 'archived'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (v) => setState(() => _status = v!),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.red.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: isMobile ? double.infinity : 200,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(widget.testimonialId == null ? 'ADD STORY' : 'SAVE CHANGES'),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.orange)),
    );
  }
}