import 'dart:async';
import 'package:collection/collection.dart';

import 'package:postgrest/postgrest.dart';
import 'package:realtime_client/realtime_client.dart';

import 'supabase_event_types.dart';
import 'supabase_realtime_client.dart';
import 'supabase_realtime_payload.dart';

typedef Callback = void Function(SupabaseRealtimePayload payload);

class SupabaseQueryBuilder extends PostgrestQueryBuilder {
  late final SupabaseRealtimeClient _subscription;
  late final RealtimeClient _realtime;
  late final StreamController<List<Map<String, dynamic>>> _streamController;
  late final List<Map<String, dynamic>> _data;
  late final RealtimeSubscription _realtimeSubscription;

  SupabaseQueryBuilder(String url, RealtimeClient realtime,
      {Map<String, String> headers = const {}, String? schema, String? table})
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

  Stream<List<Map<String, dynamic>>> stream() {
    _streamController = StreamController.broadcast(onCancel: () {
      _realtimeSubscription.unsubscribe();
    });
    _getStreamData();
    return _streamController.stream;
  }

  Future<void> _getStreamData() async {
    _data = [];
    _realtimeSubscription = on(SupabaseEventTypes.all, (payload) {
      switch (payload.eventType) {
        case 'INSERT':
          final newRecord = Map<String, dynamic>.from(payload.newRecord as Map);
          _data.add(newRecord);
          break;
        case 'UPDATE':
          final oldRecord = Map<String, dynamic>.from(payload.oldRecord as Map);
          final newRecord = Map<String, dynamic>.from(payload.newRecord as Map);
          final index = _data.indexWhere((element) =>
              const DeepCollectionEquality().equals(element, oldRecord));
          _data[index] = newRecord;
          break;
        case 'DELETE':
          final oldRecord = Map<String, dynamic>.from(payload.oldRecord as Map);
          _data.removeWhere((element) =>
              const DeepCollectionEquality().equals(element, oldRecord));
          break;
      }
      _streamController.sink.add(_data);
    }).subscribe();
    final res = await select().execute();
    final data = List<Map<String, dynamic>>.from(res.data as List);
    _data.addAll(data);
    _streamController.sink.add(_data);
  }
}
