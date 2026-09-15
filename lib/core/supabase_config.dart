import 'package:supabase_flutter/supabase_flutter.dart';

/// TODO: replace these with the real values from your new Supabase
/// project (Project Settings → API). Do NOT use the service_role key here
/// — only the anon/publishable key belongs in client code.
class SupabaseConfig {
  static const String url = 'https://mkkkznyhwyehfvxfpejo.supabase.co';
  static const String anonKey = 'sb_publishable_-EuHJHSu_EU3g45XQVMLYQ_NFLYMLhq';

  static Future<void> init() async {
    await Supabase.initialize(url: url, publishableKey: anonKey);
  }
}

SupabaseClient get supabase => Supabase.instance.client;