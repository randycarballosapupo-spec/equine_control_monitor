import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  const SupabaseConfig._();

  static const url = 'https://nngzyyzgxjatoozjkdgr.supabase.co';
  static const publishableKey = 'sb_publishable_4GDcave4ozGm38KKEN9UwQ_NLER3tXX';

  static Future<void> initialize({String? urlOverride, String? keyOverride}) {
    return Supabase.initialize(
      url: urlOverride ?? url,
      publishableKey: keyOverride ?? publishableKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
