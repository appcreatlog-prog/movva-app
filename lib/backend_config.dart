import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Configure usando --dart-define. Use apenas a chave anon/publishable; nunca service_role.
class BackendConfig {
  static const url = String.fromEnvironment('SUPABASE_URL');
  static const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static bool _ready = false;

  static bool get configured => url.startsWith('https://') && anonKey.isNotEmpty;

  static Future<void> initialize() async {
    if (!configured) {
      debugPrint('MOVVA: configure SUPABASE_URL e SUPABASE_ANON_KEY.');
      return;
    }
    await Supabase.initialize(url: url, publishableKey: anonKey);
    _ready = true;
  }

  static SupabaseClient? get client => _ready ? Supabase.instance.client : null;
}
