import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/responsive.dart';
import '../../../core/supabase_config.dart';
import '../../../core/theme.dart';

class _PickedImage {
  final XFile file;
  final Uint8List bytes;
  _PickedImage(this.file, this.bytes);
}

class AdminCreatePetPage extends StatefulWidget {
  const AdminCreatePetPage({super.key});

  @override
  State<AdminCreatePetPage> createState() => _AdminCreatePetPageState();
}

class _AdminCreatePetPageState extends State<AdminCreatePetPage> {
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

  final List<_PickedImage> _images = [];
  int _primaryIndex = 0;
  bool _submitting = false;
  String? _error;

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final files = await picker.pickMultiImage(imageQuality: 85);
    if (files.isEmpty) return;
    for (final f in files) {
      final bytes = await f.readAsBytes();
      _images.add(_PickedImage(f, bytes));
    }
    setState(() {});
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_images.isEmpty) {
      setState(() => _error = 'Add at least one photo before posting.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final petInsert = await supabase
          .from('pets')
          .insert({
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
            'status': 'available',
          })
          .select()
          .single();

      final petId = petInsert['id'] as String;

      String? primaryUrl;
      int uploadedCount = 0;
      String? photoWarning;
      try {
        for (var i = 0; i < _images.length; i++) {
          final img = _images[i];
          final ext = img.file.name.split('.').last;
          final path = '$petId/${DateTime.now().microsecondsSinceEpoch}_$i.$ext';

          await supabase.storage.from('pet-photos').uploadBinary(path, img.bytes);
          final publicUrl = supabase.storage.from('pet-photos').getPublicUrl(path);

          await supabase.from('pet_photos').insert({'pet_id': petId, 'photo_url': publicUrl, 'sort_order': i});

          uploadedCount++;
          if (i == _primaryIndex) primaryUrl = publicUrl;
        }
      } catch (e) {
        debugPrint('Photo upload issue after pet was created ($petId): $e');
        photoWarning = uploadedCount == 0
            ? "Dog was posted, but the photos didn't upload — add them from Manage Dogs when you're back online."
            : "Dog was posted with $uploadedCount of ${_images.length} photos — the rest didn't upload. You can retry later.";
      }

      if (primaryUrl != null) {
        try {
          await supabase.from('pets').update({'cover_photo_url': primaryUrl}).eq('id', petId);
        } catch (e) {
          debugPrint('Could not set cover photo for $petId: $e');
        }
      }

      if (!mounted) return;
      if (photoWarning != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(photoWarning), backgroundColor: AppColors.orange));
      }
      context.pop(true);
    } catch (e) {
      debugPrint('Pet creation failed: $e');
      setState(() => _error = "Couldn't post this dog. Please check your connection and try again.");
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
                const Text('Post a New Dog', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 16),
            _SectionLabel('Photos'),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (var i = 0; i < _images.length; i++)
                  _ImageTile(
                    image: _images[i],
                    isPrimary: i == _primaryIndex,
                    onSetPrimary: () => setState(() => _primaryIndex = i),
                    onRemove: () => setState(() {
                      _images.removeAt(i);
                      if (_primaryIndex >= _images.length) _primaryIndex = 0;
                    }),
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
              width: isMobile ? double.infinity : 220,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('POST DOG'),
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

class _ImageTile extends StatelessWidget {
  final _PickedImage image;
  final bool isPrimary;
  final VoidCallback onSetPrimary;
  final VoidCallback onRemove;
  const _ImageTile({required this.image, required this.isPrimary, required this.onSetPrimary, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onSetPrimary,
      child: Stack(
        children: [
          Container(
            width: 88, height: 88,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isPrimary ? AppColors.orange : Colors.black12, width: isPrimary ? 3 : 1),
              image: DecorationImage(image: MemoryImage(image.bytes), fit: BoxFit.cover),
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