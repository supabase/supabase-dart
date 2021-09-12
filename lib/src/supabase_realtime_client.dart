import 'package:realtime_client/realtime_client.dart';

import 'supabase_event_types.dart';
import 'supabase_realtime_payload.dart';

typedef SubscribeCallback = void Function(String event, {String? errorMsg});

class SupabaseRealtimeClient {
  late final RealtimeSubscription subscription;

  SupabaseRealtimeClient(
    RealtimeClient socket,
    String schema,
    String tableName,
  ) {
    final topic =
        tableName == '*' ? 'realtime:$schema' : 'realtime:$schema:$tableName';
    subscription = socket.channel(topic);
  }

  /// The event you want to listen to.
  SupabaseRealtimeClient on(
    SupabaseEventTypes event,
    void Function(SupabaseRealtimePayload payload) callback,
  ) {
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
  RealtimeSubscription subscribe([SubscribeCallback? callback]) {
    subscription
        .onError((e) => callback?.call('SUBSCRIPTION_ERROR', errorMsg: e));
    subscription.onClose(() => callback?.call('CLOSED'));
    subscription
        .subscribe()
        .receive('ok', (_) => callback?.call('SUBSCRIBED'))
        .receive(
          'error',
          (res) =>
              callback?.call('SUBSCRIPTION_ERROR', errorMsg: res.toString()),
        )
        .receive('timeout', (_) => callback?.call('RETRYING_AFTER_TIMEOUT'));
    return subscription;
  }
}
