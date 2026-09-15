import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'core/supabase_config.dart';
import 'core/theme.dart';
import 'core/admin_auth_state.dart';
import 'core/customer_auth_state.dart';
import 'router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  await SupabaseConfig.init();
  runApp(const MyPuppiesApp());
}

class MyPuppiesApp extends StatefulWidget {
  const MyPuppiesApp({super.key});

  @override
  State<MyPuppiesApp> createState() => _MyPuppiesAppState();
}

class _MyPuppiesAppState extends State<MyPuppiesApp> {
  late final AdminAuthState _adminAuthState;
  late final CustomerAuthState _customerAuthState;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _adminAuthState = AdminAuthState();
    _customerAuthState = CustomerAuthState();
    _router = buildRouter(_adminAuthState, _customerAuthState);
  }

  @override
  void dispose() {
    _adminAuthState.dispose();
    _customerAuthState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'My Puppies',
      debugShowCheckedModeBanner: false,
      theme: buildMyPuppiesTheme(),
      routerConfig: _router,
    );
  }
}