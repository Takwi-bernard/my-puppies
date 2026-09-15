import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';

/// Tracks whether a customer (adopter) is logged in and holds their
/// profile. Used to auto-fill application forms and to show a profile
/// link in the navbar instead of "Log in" once someone's signed in.
class CustomerAuthState extends ChangeNotifier {
  bool isLoading = true;
  bool isLoggedIn = false;
  String? userId;
  String? fullName;
  String? email;
  String? phone;
  String? lastError;

  CustomerAuthState() {
    _init();
  }

  Future<void> _init() async {
    await _refresh();
    supabase.auth.onAuthStateChange.listen((_) => _refresh());
  }

  Future<void> _refresh() async {
    final session = supabase.auth.currentSession;
    isLoggedIn = session != null;
    userId = session?.user.id;

    if (!isLoggedIn) {
      fullName = null;
      email = null;
      phone = null;
      isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final profile = await supabase
          .from('profiles')
          .select('full_name, email, phone')
          .eq('id', userId!)
          .maybeSingle();
      fullName = profile?['full_name'] as String?;
      email = profile?['email'] as String?;
      phone = profile?['phone'] as String?;
    } catch (_) {
      // Non-fatal — the person is still logged in even if the profile
      // fetch hiccups; forms just won't auto-fill this time.
    }
    isLoading = false;
    notifyListeners();
  }

  Future<String?> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    lastError = null;
    try {
      final res = await supabase.auth.signUp(email: email, password: password);
      final user = res.user;
      if (user != null) {
        // The DB trigger (see migration_002) already inserts a profiles
        // row with the email filled in — this just adds the name.
        await supabase.from('profiles').update({'full_name': fullName}).eq('id', user.id);
      }
      await _refresh();
      return null;
    } on AuthException catch (e) {
      lastError = e.message;
      return lastError;
    } catch (e) {
      lastError = 'Something went wrong creating your account. Please try again.';
      return lastError;
    }
  }

  Future<String?> signIn(String email, String password) async {
    lastError = null;
    try {
      await supabase.auth.signInWithPassword(email: email, password: password);
      await _refresh();
      return null;
    } on AuthException catch (e) {
      lastError = e.message;
      return lastError;
    } catch (e) {
      lastError = 'Something went wrong signing in. Please try again.';
      return lastError;
    }
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
    await _refresh();
  }

  Future<String?> updateProfile({String? fullName, String? phone}) async {
    if (userId == null) return 'Not signed in.';
    try {
      await supabase.from('profiles').update({
        if (fullName != null) 'full_name': fullName,
        if (phone != null) 'phone': phone,
      }).eq('id', userId!);
      await _refresh();
      return null;
    } catch (e) {
      return "Couldn't save your changes. Please try again.";
    }
  }
}