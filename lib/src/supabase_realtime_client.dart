import 'package:realtime_client/realtime_client.dart';

import 'supabase_event_types.dart';
import 'supabase_realtime_payload.dart';

typedef Callback = void Function(SupabaseRealtimePayload payload);

typedef SubscribeCallback = void Function(String event, {String errorMsg});

class SupabaseRealtimeClient {
  RealtimeSubscription subscription;

  SupabaseRealtimeClient(
      RealtimeClient socket, String schema, String tableName) {
    final topic =
        tableName == '*' ? 'realtime:$schema' : 'realtime:$schema:$tableName';
    subscription = socket.channel(topic);
  }

  /// The event you want to listen to.
  SupabaseRealtimeClient on(SupabaseEventTypes event, Callback callback) {
    subscription.on(event.name(), (payload, {ref}) {
      if (payload is Map) {
        final json = payload as Map<String, dynamic>;
        final enrichedPayload = SupabaseRealtimePayload.fromJson(json);
        callback(enrichedPayload);
      }
    });

    return this;
  }

  /// Enables the subscription.
  RealtimeSubscription subscribe([SubscribeCallback callback]) {
    subscription.onError((e) => callback('SUBSCRIPTION_ERROR', errorMsg: e));
    subscription.onClose(() => callback('CLOSED'));
    subscription
        .subscribe()
        .receive('ok', (_) => callback('SUBSCRIBED'))
        .receive('error',
            (res) => callback('SUBSCRIPTION_ERROR', errorMsg: res.toString()))
        .receive('timeout', (_) => callback('RETRYING_AFTER_TIMEOUT'));
    return subscription;
  }
}
