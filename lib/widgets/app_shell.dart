import 'package:flutter/material.dart';
import 'package:my_puppies_app/widgets/nav_bar.dart';
import 'footer.dart';
import '../core/customer_auth_state.dart';

/// Wraps every routed page. The nav bar and footer are built once here and
/// never get torn down when the route changes — only [child] swaps.
class AppShell extends StatelessWidget {
  final Widget child;
  final CustomerAuthState authState;
  const AppShell({super.key, required this.child, required this.authState});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyPuppiesNavBar(authState: authState),
      body: SingleChildScrollView(
        child: Column(
          children: [
            child,
            const MyPuppiesFooter(),
          ],
        ),
      ),
    );
  }
}