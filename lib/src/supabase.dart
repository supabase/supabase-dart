import 'package:gotrue/gotrue.dart';
import 'package:realtime_client/realtime_client.dart';

import 'supabase_client_options.dart';

/// Checks if you are awesome. Spoiler: you are.
class Awesome {
  bool get isAwesome => true;
}

class SupabaseClient {
  String supabaseUrl;
  String supabaseKey;
  String schema;
  String restUrl;
  String realtimeUrl;
  String authUrl;

  GoTrueClient auth;
  RealtimeClient realtime;

  SupabaseClient(
      this.supabaseUrl, this.supabaseKey, SupabaseClientOptions options) {
    if (supabaseUrl == null) throw 'supabaseUrl is required.';
    if (supabaseKey == null) throw 'supabaseKey is required.';

    restUrl = '$supabaseUrl/rest/v1';
    realtimeUrl = '$supabaseUrl/realtime/v1'.replaceAll('http', 'ws');
    authUrl = '$supabaseUrl/auth/v1';
    schema = options?.schema ?? 'public';

    auth = _initSupabaseAuthClient(autoRefreshToken: options.autoRefreshToken);
    realtime = _initRealtimeClient();
  }

  GoTrueClient _initSupabaseAuthClient({bool autoRefreshToken}) {
    return GoTrueClient(
        url: authUrl,
        headers: {
          'Authorization': 'Bearer $supabaseKey',
          'apikey': supabaseKey,
        },
        autoRefreshToken: autoRefreshToken);
  }

  RealtimeClient _initRealtimeClient() {
    return RealtimeClient(realtimeUrl, params: {'apikey': supabaseKey});
  }
}
