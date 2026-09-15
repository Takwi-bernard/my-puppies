import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/customer_auth_state.dart';
import '../core/responsive.dart';
import '../core/supabase_config.dart';
import '../core/theme.dart';

class PetApplicationPage extends StatefulWidget {
  final String petId;
  final CustomerAuthState authState;
  const PetApplicationPage({super.key, required this.petId, required this.authState});

  @override
  State<PetApplicationPage> createState() => _PetApplicationPageState();
}

class _PetApplicationPageState extends State<PetApplicationPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _livingSituationController = TextEditingController();
  final _otherPetsController = TextEditingController();
  final _whyAdoptController = TextEditingController();

  bool _submitting = false;
  String? _error;
  String? _success;

  @override
  void initState() {
    super.initState();
    if (widget.authState.isLoggedIn) {
      _nameController.text = widget.authState.fullName ?? '';
      _emailController.text = widget.authState.email ?? '';
      _phoneController.text = widget.authState.phone ?? '';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
      _success = null;
    });

    try {
      await supabase.from('applications').insert({
        'pet_id': widget.petId,
        'applicant_id': widget.authState.isLoggedIn ? widget.authState.userId : null,
        'status': 'submitted',
        'answers': {
          'full_name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
          'address': _addressController.text.trim(),
          'living_situation': _livingSituationController.text.trim(),
          'other_pets': _otherPetsController.text.trim(),
          'why_adopt': _whyAdoptController.text.trim(),
        },
      });

      setState(() => _success = 'Application submitted! We\'ll review it and be in touch soon.');

      if (mounted) {
        await Future.delayed(const Duration(seconds: 2));
        context.go(widget.authState.isLoggedIn ? '/profile' : '/');
      }
    } catch (e) {
      debugPrint('Application submit failed: $e');
      setState(() => _error = "Couldn't submit your application. Please try again.");
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _livingSituationController.dispose();
    _otherPetsController.dispose();
    _whyAdoptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(isMobile ? 16 : 24, 16, isMobile ? 16 : 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
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
          const SizedBox(height: 16),
          const Text('Adoption Application', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 20),
          if (_success != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 60),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 64),
                    const SizedBox(height: 16),
                    Text(_success!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            )
          else
            Form(
              key: _formKey,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tell us about yourself', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    const Text('We want to make sure every adoption is a great match.',
                        style: TextStyle(color: Colors.black54)),
                    const SizedBox(height: 24),
                    if (widget.authState.isLoggedIn) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.orange.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_outline, size: 16, color: AppColors.orange),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Signed in as ${widget.authState.email} — your details below are filled in from your profile.',
                                style: const TextStyle(fontSize: 12, color: AppColors.orangeDark),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    _SectionLabel('Contact Information'),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder()),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _addressController,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'Address', border: OutlineInputBorder()),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 20),
                    _SectionLabel('About Your Home'),
                    TextFormField(
                      controller: _livingSituationController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Describe your living situation (apartment, house, yard, etc.)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _otherPetsController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Do you have other pets? If yes, describe them.',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _SectionLabel('Why This Dog?'),
                    TextFormField(
                      controller: _whyAdoptController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Tell us why you want to adopt this dog.',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitting ? null : _submit,
                        child: _submitting
                            ? const SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('SUBMIT APPLICATION'),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
        ],
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.orange, fontSize: 14)),
    );
  }
}