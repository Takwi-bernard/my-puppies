import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/responsive.dart';
import '../core/theme.dart';
import '../core/customer_auth_state.dart';
import 'announcement_bar.dart';

class MyPuppiesNavBar extends StatelessWidget implements PreferredSizeWidget {
  final CustomerAuthState authState;
  const MyPuppiesNavBar({super.key, required this.authState});

  static const _navLinks = [
    ('Browse Dogs', '/browse'),
    ('Adoption Process', '/adoption-process'),
    ('Donate', '/donate'),
    ('Shelters', '/shelters'),
    ('About', '/about'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDesktop = Breakpoints.isDesktop(context);
    final width = MediaQuery.of(context).size.width;
    final isSmallPhone = width < 380;
    final currentPath = GoRouterState.of(context).uri.path;

    return AnimatedBuilder(
      animation: authState,
      builder: (context, _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AnnouncementBar(),
            Container(
              color: Colors.white,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: isSmallPhone ? 14 : 24, vertical: 14),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () => context.go('/'),
                        child: _Logo(compact: isSmallPhone),
                      ),
                      SizedBox(width: isDesktop ? 40 : 12),
                      if (isDesktop) ...[
                        Expanded(
                          child: Row(
                            children: _navLinks
                                .map((link) => Padding(
                                      padding: const EdgeInsets.only(right: 26),
                                      child: InkWell(
                                        onTap: () => context.go(link.$2),
                                        child: Text(
                                          link.$1.toUpperCase(),
                                          style: TextStyle(
                                            color: currentPath == link.$2
                                                ? AppColors.orange
                                                : AppColors.charcoal,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.6,
                                          ),
                                        ),
                                      ),
                                    ))
                                .toList(),
                          ),
                        ),
                        _AuthAction(authState: authState),
                      ] else
                        const Spacer(),
                      if (!isDesktop)
                        IconButton(
                          onPressed: () => _openMobileMenu(context),
                          icon: const Icon(Icons.menu, color: AppColors.black),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _openMobileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => AnimatedBuilder(
        animation: authState,
        builder: (context, _) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.orange.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.home_outlined, color: AppColors.orange),
                title: const Text('Home', style: TextStyle(color: AppColors.charcoal, fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.go('/');
                },
              ),
              Divider(height: 1, color: AppColors.orange.withOpacity(0.2)),
              for (final link in _navLinks)
                ListTile(
                  title: Text(link.$1, style: const TextStyle(color: AppColors.charcoal)),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    context.go(link.$2);
                  },
                ),
              Divider(color: AppColors.orange.withOpacity(0.2)),
              if (authState.isLoggedIn) ...[
                ListTile(
                  leading: const Icon(Icons.person_outline, color: AppColors.orange),
                  title: const Text('My Profile', style: TextStyle(color: AppColors.charcoal)),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    context.go('/profile');
                  },
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                  child: OutlinedButton(
                    onPressed: () async {
                      Navigator.pop(sheetContext);
                      await authState.signOut();
                      if (context.mounted) context.go('/');
                    },
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(46)),
                    child: const Text('Sign out'),
                  ),
                ),
              ] else
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      context.go('/login');
                    },
                    style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(46)),
                    child: const Text('Log in'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(104);
}

class _AuthAction extends StatelessWidget {
  final CustomerAuthState authState;
  const _AuthAction({required this.authState});

  @override
  Widget build(BuildContext context) {
    if (!authState.isLoggedIn) {
      return ElevatedButton(
        onPressed: () => context.go('/login'),
        child: const Text('LOG IN'),
      );
    }
    final initial = (authState.fullName?.isNotEmpty ?? false) ? authState.fullName![0].toUpperCase() : '?';
    return InkWell(
      onTap: () => context.go('/profile'),
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 15,
              backgroundColor: AppColors.orange,
              child: Text(initial, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 8),
            Text(
              authState.fullName?.isNotEmpty == true ? authState.fullName!.split(' ').first : 'Profile',
              style: const TextStyle(color: AppColors.charcoal, fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  final bool compact;
  const _Logo({this.compact = false});

  @override
  Widget build(BuildContext context) {
    final markSize = compact ? 26.0 : 32.0;
    final fontSize = compact ? 16.0 : 19.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: markSize,
          height: markSize,
          decoration: const BoxDecoration(color: AppColors.black, shape: BoxShape.circle),
          child: Center(
            child: Icon(Icons.pets, color: AppColors.orange, size: markSize * 0.6),
          ),
        ),
        const SizedBox(width: 8),
        RichText(
          text: TextSpan(
            style: GoogleFonts.oswald(fontWeight: FontWeight.w800, fontSize: fontSize),
            children: const [
              TextSpan(text: 'MY ', style: TextStyle(color: AppColors.black)),
              TextSpan(text: 'PUPPIES', style: TextStyle(color: AppColors.orange)),
            ],
          ),
        ),
      ],
    );
  }
}