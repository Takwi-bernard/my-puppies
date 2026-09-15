import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/responsive.dart';
import '../../../core/theme.dart';
import '../../../core/admin_auth_state.dart';

class AdminShell extends StatelessWidget {
  final Widget child;
  final AdminAuthState authState;
  const AdminShell({super.key, required this.child, required this.authState});

  static const _navItems = [
    ('Dashboard', Icons.dashboard_outlined, '/admin'),
    ('Manage Dogs', Icons.pets, '/admin/pets'),
    ('Applications', Icons.assignment_outlined, '/admin/applications'),
    ('Adopter Stories', Icons.favorite_outline, '/admin/testimonials'),
  ];

  Widget _animatedContent(BuildContext context, String currentPath) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (widget, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.02), end: Offset.zero).animate(animation),
          child: widget,
        ),
      ),
      child: KeyedSubtree(key: ValueKey(currentPath), child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Breakpoints.isDesktop(context);
    final currentPath = GoRouterState.of(context).uri.path;

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            SizedBox(
              width: 240,
              child: _AdminNav(currentPath: currentPath, authState: authState, items: _navItems, closeDrawerOnNavigate: false),
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: Column(
                children: [
                  const _AdminTopBar(),
                  Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: _animatedContent(context, currentPath))),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.orange,
        title: const Text('My Puppies Admin', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      drawer: Drawer(
        child: _AdminNav(currentPath: currentPath, authState: authState, items: _navItems, closeDrawerOnNavigate: true),
      ),
      body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: _animatedContent(context, currentPath)),
    );
  }
}

class _AdminTopBar extends StatelessWidget {
  const _AdminTopBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: Colors.black12))),
      child: const Row(children: [Text('My Puppies Admin', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16))]),
    );
  }
}

class _AdminNav extends StatelessWidget {
  final String currentPath;
  final AdminAuthState authState;
  final List<(String, IconData, String)> items;
  final bool closeDrawerOnNavigate;
  const _AdminNav({required this.currentPath, required this.authState, required this.items, required this.closeDrawerOnNavigate});

  void _navigate(BuildContext context, String path) {
    if (closeDrawerOnNavigate) Navigator.of(context).pop();
    context.go(path);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.black,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text('MY PUPPIES', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: 0.5)),
            ),
            for (final item in items)
              _NavTile(label: item.$1, icon: item.$2, selected: currentPath == item.$3, onTap: () => _navigate(context, item.$3)),
            const Spacer(),
            _NavTile(
              label: 'Log out',
              icon: Icons.logout,
              selected: false,
              onTap: () async {
                if (closeDrawerOnNavigate) Navigator.of(context).pop();
                await authState.signOut();
                if (context.mounted) context.go('/admin/login');
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _NavTile({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: selected ? Colors.white.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onTap,
            child: ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              leading: Icon(icon, color: selected ? AppColors.orange : Colors.white70),
              title: Text(label, style: TextStyle(color: Colors.white, fontWeight: selected ? FontWeight.w700 : FontWeight.w400)),
            ),
          ),
        ),
      ),
    );
  }
}