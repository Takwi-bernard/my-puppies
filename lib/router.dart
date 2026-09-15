import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'core/admin_auth_state.dart';
import 'core/customer_auth_state.dart';
import 'widgets/app_shell.dart';
import 'pages/home_page.dart';
import 'pages/browse_page.dart';
import 'pages/adoption_process_page.dart';
import 'pages/donate_page.dart';
import 'pages/shelters_page.dart';
import 'pages/about_page.dart';
import 'pages/pet_detail_page.dart';
import 'pages/pet_application_page.dart';
import 'pages/login_page.dart';
import 'pages/signup_page.dart';
import 'pages/profile_page.dart';
import 'admin/widgets/admin_shell.dart';
import 'admin/pages/admin_login_page.dart';
import 'admin/pages/admin_dashboard_page.dart';
import 'admin/pages/admin_pets_page.dart';
import 'admin/pages/admin_create_pet_page.dart';
import 'admin/pages/admin_edit_pet_page.dart';
import 'admin/pages/admin_pet_detail_page.dart';
import 'admin/pages/admin_applications_page.dart';
import 'admin/pages/admin_application_detail_page.dart';
import 'admin/pages/admin_testimonials_page.dart';
import 'admin/pages/admin_testimonial_form_page.dart';

CustomTransitionPage<T> _customPage<T>({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.02), end: Offset.zero)
              .animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
          child: child,
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 250),
  );
}

GoRouter buildRouter(AdminAuthState adminAuthState, CustomerAuthState customerAuthState) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: Listenable.merge([adminAuthState, customerAuthState]),
    redirect: (context, state) {
      final path = state.uri.path;
      final underAdmin = path.startsWith('/admin');
      if (!underAdmin) return null;

      if (adminAuthState.isLoading) return null;

      final isLoginPage = path == '/admin/login';
      if (!adminAuthState.isLoggedIn || !adminAuthState.isAdmin) {
        return isLoginPage ? null : '/admin/login';
      }
      if (isLoginPage) return '/admin';
      return null;
    },
    routes: [
      // Customer-facing site
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child, authState: customerAuthState),
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) => _customPage(context: context, state: state, child: const HomePage()),
          ),
          GoRoute(
            path: '/browse',
            pageBuilder: (context, state) => _customPage(context: context, state: state, child: const BrowsePage()),
          ),
          GoRoute(
            path: '/adoption-process',
            pageBuilder: (context, state) => _customPage(context: context, state: state, child: const AdoptionProcessPage()),
          ),
          GoRoute(
            path: '/donate',
            pageBuilder: (context, state) => _customPage(context: context, state: state, child: const DonatePage()),
          ),
          GoRoute(
            path: '/shelters',
            pageBuilder: (context, state) => _customPage(context: context, state: state, child: const SheltersPage()),
          ),
          GoRoute(
            path: '/about',
            pageBuilder: (context, state) => _customPage(context: context, state: state, child: const AboutPage()),
          ),
          GoRoute(
            path: '/pets/:id',
            pageBuilder: (context, state) => _customPage(
              context: context,
              state: state,
              child: PetDetailPage(petId: state.pathParameters['id']!, authState: customerAuthState),
            ),
          ),
          GoRoute(
            path: '/pets/:id/apply',
            pageBuilder: (context, state) => _customPage(
              context: context,
              state: state,
              child: PetApplicationPage(petId: state.pathParameters['id']!, authState: customerAuthState),
            ),
          ),
          GoRoute(
            path: '/login',
            pageBuilder: (context, state) => _customPage(context: context, state: state, child: LoginPage(authState: customerAuthState)),
          ),
          GoRoute(
            path: '/signup',
            pageBuilder: (context, state) => _customPage(context: context, state: state, child: SignupPage(authState: customerAuthState)),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => _customPage(context: context, state: state, child: ProfilePage(authState: customerAuthState)),
          ),
        ],
      ),

      // Admin login — no shell, standalone branded page.
      GoRoute(
        path: '/admin/login',
        pageBuilder: (context, state) => _customPage(context: context, state: state, child: AdminLoginPage(authState: adminAuthState)),
      ),

      // Admin section — guarded by the redirect above.
      ShellRoute(
        builder: (context, state, child) => AdminShell(authState: adminAuthState, child: child),
        routes: [
          GoRoute(
            path: '/admin',
            pageBuilder: (context, state) => _customPage(context: context, state: state, child: const AdminDashboardPage()),
          ),
          GoRoute(
            path: '/admin/pets',
            pageBuilder: (context, state) => _customPage(context: context, state: state, child: const AdminPetsPage()),
          ),
          GoRoute(
            path: '/admin/pets/new',
            pageBuilder: (context, state) => _customPage(context: context, state: state, child: const AdminCreatePetPage()),
          ),
          GoRoute(
            path: '/admin/pets/:id',
            pageBuilder: (context, state) => _customPage(context: context, state: state, child: AdminPetDetailPage(petId: state.pathParameters['id']!)),
          ),
          GoRoute(
            path: '/admin/pets/:id/edit',
            pageBuilder: (context, state) => _customPage(context: context, state: state, child: AdminEditPetPage(petId: state.pathParameters['id']!)),
          ),
          GoRoute(
            path: '/admin/applications',
            pageBuilder: (context, state) => _customPage(context: context, state: state, child: const AdminApplicationsPage()),
          ),
          GoRoute(
            path: '/admin/applications/:id',
            pageBuilder: (context, state) => _customPage(context: context, state: state, child: AdminApplicationDetailPage(applicationId: state.pathParameters['id']!)),
          ),
          GoRoute(
            path: '/admin/testimonials',
            pageBuilder: (context, state) => _customPage(context: context, state: state, child: const AdminTestimonialsPage()),
          ),
          GoRoute(
            path: '/admin/testimonials/new',
            pageBuilder: (context, state) => _customPage(context: context, state: state, child: const AdminTestimonialFormPage()),
          ),
          GoRoute(
            path: '/admin/testimonials/:id/edit',
            pageBuilder: (context, state) => _customPage(context: context, state: state, child: AdminTestimonialFormPage(testimonialId: state.pathParameters['id']!)),
          ),
        ],
      ),
    ],
  );
}