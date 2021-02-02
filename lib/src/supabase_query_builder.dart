import 'package:postgrest/postgrest.dart';
import 'package:realtime_client/realtime_client.dart';

import 'supabase_realtime_client.dart';
import 'supabase_realtime_payload.dart';

typedef Callback = void Function(SupabaseRealtimePayload payload);

class SupabaseQueryBuilder extends PostgrestQueryBuilder {
  SupabaseRealtimeClient _subscription;
  RealtimeClient _realtime;

  SupabaseQueryBuilder(String url, RealtimeClient realtime,
      {Map<String, String> headers = const {}, String schema, String table})
      : super(url, headers: headers, schema: schema) {
    _subscription =
        SupabaseRealtimeClient(realtime, schema ?? 'public', table ?? '*');
    _realtime = realtime;
  }

  /// Subscribe to realtime changes in your databse.
  SupabaseRealtimeClient on(SupabaseEventTypes event, Callback callback) {
    if (_realtime.isConnected() == false) {
      _realtime.connect();
    }
    return _subscription.on(event, callback);
  }
}
