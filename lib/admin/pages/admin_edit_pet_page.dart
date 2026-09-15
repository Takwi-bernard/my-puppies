import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/responsive.dart';
import '../../../core/supabase_config.dart';
import '../../../core/theme.dart';
import '../../../widgets/friendly_error.dart';

class _PhotoSlot {
  final String? photoId;
  final String? url;
  final Uint8List? bytes;
  final String? fileExt;
  _PhotoSlot.existing({required this.photoId, required this.url}) : bytes = null, fileExt = null;
  _PhotoSlot.newFile({required this.bytes, required this.fileExt}) : photoId = null, url = null;
  bool get isExisting => url != null;
}

class AdminEditPetPage extends StatefulWidget {
  final String petId;
  const AdminEditPetPage({super.key, required this.petId});

  @override
  State<AdminEditPetPage> createState() => _AdminEditPetPageState();
}

class _AdminEditPetPageState extends State<AdminEditPetPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _colorController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _bioController = TextEditingController();
  final _feeController = TextEditingController();

  String _species = 'dog';
  String _ageCategory = 'young';
  String _gender = 'female';
  String _size = 'medium';
  String _status = 'available';

  final List<_PhotoSlot> _photos = [];
  final List<String> _removedPhotoIds = [];
  int _primaryIndex = 0;

  bool _loading = true;
  bool _submitting = false;
  String? _loadError;
  String? _submitError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final pet = await supabase.from('pets').select().eq('id', widget.petId).single();
      final photoRows = await supabase.from('pet_photos').select().eq('pet_id', widget.petId).order('sort_order');

      _nameController.text = pet['name'] as String? ?? '';
      _breedController.text = pet['breed'] as String? ?? '';
      _colorController.text = pet['color'] as String? ?? '';
      _cityController.text = pet['location_city'] as String? ?? '';
      _stateController.text = pet['location_state'] as String? ?? '';
      _bioController.text = pet['bio'] as String? ?? '';
      _feeController.text = pet['adoption_fee']?.toString() ?? '';
      _species = pet['species'] as String? ?? 'dog';
      _ageCategory = pet['age_category'] as String? ?? 'young';
      _gender = pet['gender'] as String? ?? 'female';
      _size = pet['size'] as String? ?? 'medium';
      _status = pet['status'] as String? ?? 'available';

      final coverUrl = pet['cover_photo_url'] as String?;
      _photos.clear();
      for (final row in (photoRows as List)) {
        _photos.add(_PhotoSlot.existing(photoId: row['id'] as String, url: row['photo_url'] as String));
      }
      if (coverUrl != null) {
        final idx = _photos.indexWhere((p) => p.url == coverUrl);
        if (idx != -1) _primaryIndex = idx;
      }

      setState(() => _loading = false);
    } catch (e) {
      debugPrint('Failed to load pet ${widget.petId} for editing: $e');
      setState(() {
        _loading = false;
        _loadError = "Couldn't load this dog.";
      });
    }
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final files = await picker.pickMultiImage(imageQuality: 85);
    if (files.isEmpty) return;
    for (final f in files) {
      final bytes = await f.readAsBytes();
      final ext = f.name.split('.').last;
      _photos.add(_PhotoSlot.newFile(bytes: bytes, fileExt: ext));
    }
    setState(() {});
  }

  void _removePhotoAt(int index) {
    final photo = _photos[index];
    if (photo.isExisting && photo.photoId != null) {
      _removedPhotoIds.add(photo.photoId!);
    }
    setState(() {
      _photos.removeAt(index);
      if (_photos.isEmpty) {
        _primaryIndex = 0;
      } else if (_primaryIndex >= _photos.length) {
        _primaryIndex = _photos.length - 1;
      }
    });
  }

  String? _extractStoragePath(String url) {
    const marker = '/pet-photos/';
    final idx = url.indexOf(marker);
    if (idx == -1) return null;
    return Uri.decodeFull(url.substring(idx + marker.length));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_photos.isEmpty) {
      setState(() => _submitError = 'Keep at least one photo.');
      return;
    }

    setState(() {
      _submitting = true;
      _submitError = null;
    });

    try {
      await supabase.from('pets').update({
        'name': _nameController.text.trim(),
        'species': _species,
        'breed': _breedController.text.trim().isEmpty ? null : _breedController.text.trim(),
        'age_category': _ageCategory,
        'gender': _gender,
        'size': _size,
        'color': _colorController.text.trim().isEmpty ? null : _colorController.text.trim(),
        'location_city': _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
        'location_state': _stateController.text.trim().isEmpty ? null : _stateController.text.trim(),
        'bio': _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
        'adoption_fee': double.tryParse(_feeController.text.trim()),
        'status': _status,
      }).eq('id', widget.petId);

      if (_removedPhotoIds.isNotEmpty) {
        final rows = await supabase.from('pet_photos').select('id, photo_url').inFilter('id', _removedPhotoIds);
        final paths = (rows as List).map((r) => _extractStoragePath(r['photo_url'] as String)).whereType<String>().toList();
        if (paths.isNotEmpty) {
          await supabase.storage.from('pet-photos').remove(paths);
        }
        await supabase.from('pet_photos').delete().inFilter('id', _removedPhotoIds);
      }

      for (var i = 0; i < _photos.length; i++) {
        final photo = _photos[i];
        if (photo.isExisting) continue;
        final path = '${widget.petId}/${DateTime.now().microsecondsSinceEpoch}_$i.${photo.fileExt}';
        await supabase.storage.from('pet-photos').uploadBinary(path, photo.bytes!);
        final publicUrl = supabase.storage.from('pet-photos').getPublicUrl(path);
        final inserted = await supabase.from('pet_photos').insert({'pet_id': widget.petId, 'photo_url': publicUrl, 'sort_order': i}).select().single();
        _photos[i] = _PhotoSlot.existing(photoId: inserted['id'] as String, url: publicUrl);
      }

      final primaryUrl = _photos.isNotEmpty ? _photos[_primaryIndex].url : null;
      if (primaryUrl != null) {
        await supabase.from('pets').update({'cover_photo_url': primaryUrl}).eq('id', widget.petId);
      }

      if (!mounted) return;
      context.pop(true);
    } catch (e) {
      debugPrint('Edit failed for ${widget.petId}: $e');
      setState(() => _submitError = "Couldn't save these changes. Please try again.");
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _colorController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _bioController.dispose();
    _feeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(padding: EdgeInsets.symmetric(vertical: 60), child: Center(child: CircularProgressIndicator()));
    }
    if (_loadError != null) {
      return FriendlyError(message: _loadError!, onRetry: () { setState(() => _loading = true); _load(); });
    }

    final isMobile = Breakpoints.isMobile(context);

    return Form(
      key: _formKey,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back)),
                const Text('Edit Dog', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 16),
            _SectionLabel('Photos'),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (var i = 0; i < _photos.length; i++)
                  _EditImageTile(
                    photo: _photos[i],
                    isPrimary: i == _primaryIndex,
                    onSetPrimary: () => setState(() => _primaryIndex = i),
                    onRemove: () => _removePhotoAt(i),
                  ),
                InkWell(
                  onTap: _pickImages,
                  child: Container(
                    width: 88, height: 88,
                    decoration: BoxDecoration(border: Border.all(color: AppColors.orange), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.add_a_photo_outlined, color: AppColors.orange),
                  ),
                ),
              ],
            ),
            const Text('Tap a photo to set it as the primary (cover) image.', style: TextStyle(fontSize: 11, color: Colors.black45)),
            const SizedBox(height: 20),
            _SectionLabel('Basic Info'),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _species,
                    decoration: const InputDecoration(labelText: 'Species', border: OutlineInputBorder()),
                    items: const ['dog', 'cat', 'bird', 'rabbit', 'other'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (v) => setState(() => _species = v!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: TextFormField(controller: _breedController, decoration: const InputDecoration(labelText: 'Breed', border: OutlineInputBorder()))),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _ageCategory,
                    decoration: const InputDecoration(labelText: 'Age', border: OutlineInputBorder()),
                    items: const ['baby', 'young', 'adult', 'senior'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (v) => setState(() => _ageCategory = v!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _gender,
                    decoration: const InputDecoration(labelText: 'Gender', border: OutlineInputBorder()),
                    items: const ['male', 'female'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (v) => setState(() => _gender = v!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _size,
                    decoration: const InputDecoration(labelText: 'Size', border: OutlineInputBorder()),
                    items: const ['small', 'medium', 'large'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (v) => setState(() => _size = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(controller: _colorController, decoration: const InputDecoration(labelText: 'Color', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
              items: const ['available', 'pending', 'adopted'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (v) => setState(() => _status = v!),
            ),
            const SizedBox(height: 20),
            _SectionLabel('Location'),
            Row(
              children: [
                Expanded(child: TextFormField(controller: _cityController, decoration: const InputDecoration(labelText: 'City', border: OutlineInputBorder()))),
                const SizedBox(width: 12),
                Expanded(child: TextFormField(controller: _stateController, decoration: const InputDecoration(labelText: 'State', border: OutlineInputBorder()))),
              ],
            ),
            const SizedBox(height: 20),
            _SectionLabel('About'),
            TextFormField(controller: _bioController, maxLines: 4, decoration: const InputDecoration(labelText: 'Bio / description', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextFormField(controller: _feeController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Adoption fee (USD)', border: OutlineInputBorder())),
            if (_submitError != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.red.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                child: Text(_submitError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: isMobile ? double.infinity : 220,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('SAVE CHANGES'),
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

class _EditImageTile extends StatelessWidget {
  final _PhotoSlot photo;
  final bool isPrimary;
  final VoidCallback onSetPrimary;
  final VoidCallback onRemove;
  const _EditImageTile({required this.photo, required this.isPrimary, required this.onSetPrimary, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final imageProvider = photo.isExisting ? NetworkImage(photo.url!) as ImageProvider : MemoryImage(photo.bytes!);

    return InkWell(
      onTap: onSetPrimary,
      child: Stack(
        children: [
          Container(
            width: 88, height: 88,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isPrimary ? AppColors.orange : Colors.black12, width: isPrimary ? 3 : 1),
              image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
            ),
          ),
          if (isPrimary)
            Positioned(
              top: 4, left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: AppColors.orange, borderRadius: BorderRadius.circular(6)),
                child: const Text('Primary', style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          Positioned(
            top: 2, right: 2,
            child: InkWell(
              onTap: onRemove,
              child: const CircleAvatar(radius: 10, backgroundColor: Colors.black54, child: Icon(Icons.close, size: 12, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}