import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';

/// Tracks whether someone is logged in AND whether their profile has
/// role = 'admin'. GoRouter's redirect uses this to guard every /admin/*
/// route — nothing under /admin is reachable without passing both checks.
class AdminAuthState extends ChangeNotifier {
  bool isLoading = true;
  bool isLoggedIn = false;
  bool isAdmin = false;
  String? lastError;

  AdminAuthState() {
    _init();
  }

  Future<void> _init() async {
    await _refresh();
    supabase.auth.onAuthStateChange.listen((_) => _refresh());
  }

  Future<void> _refresh() async {
    final session = supabase.auth.currentSession;
    isLoggedIn = session != null;

    if (!isLoggedIn) {
      isAdmin = false;
      isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final profile = await supabase
          .from('profiles')
          .select('role')
          .eq('id', session!.user.id)
          .maybeSingle();
      isAdmin = profile != null && profile['role'] == 'admin';
    } catch (_) {
      isAdmin = false;
    }
    isLoading = false;
    notifyListeners();
  }

  Future<String?> signIn(String email, String password) async {
    lastError = null;
    try {
      await supabase.auth.signInWithPassword(email: email, password: password);
      await _refresh();
      if (!isAdmin) {
        await supabase.auth.signOut();
        lastError = 'This account is not set up as an admin.';
        return lastError;
      }
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
}