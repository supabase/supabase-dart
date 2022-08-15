import 'package:realtime_client/realtime_client.dart';
import 'package:supabase/src/supabase_event_types.dart';
import 'package:supabase/src/supabase_realtime_payload.dart';

typedef SubscribeCallback = void Function(String event, {String? errorMsg});

class SupabaseRealtimeClient {
  late final RealtimeChannel subscription;

  SupabaseRealtimeClient(
    RealtimeClient socket,
    Map<String, String> headers,
    String schema,
    String tableName,
  ) {
    final chanParams = <String, String>{};
    final topic =
        tableName == '*' ? 'realtime:$schema' : 'realtime:$schema:$tableName';
    final userToken = headers['Authorization']?.split(' ')[1];
    if (userToken != null) {
      chanParams['user_token'] = userToken;
    }
    subscription = socket.channel(topic, chanParams);
  }

  /// The event you want to listen to.
  SupabaseRealtimeClient on(
    SupabaseEventTypes event,
    void Function(SupabaseRealtimePayload payload) callback,
  ) {
    subscription.on(event.name(), {}, (payload, [ref]) {
      if (payload is Map) {
        final json = payload as Map<String, dynamic>;
        final enrichedPayload = SupabaseRealtimePayload.fromJson(json);
        callback(enrichedPayload);
      }
    });

    return this;
  }

  /// Enables the subscription.
  RealtimeChannel subscribe([SubscribeCallback? callback]) {
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
