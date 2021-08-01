import 'dart:async';

import 'package:postgrest/postgrest.dart';
import 'package:realtime_client/realtime_client.dart';

import 'supabase_event_types.dart';
import 'supabase_realtime_client.dart';
import 'supabase_realtime_payload.dart';

typedef Callback = void Function(SupabaseRealtimePayload payload);

class StreamFilter {
  StreamFilter({
    required this.column,
    required this.value,
  });

  final String column;
  final String value;
}

class SupabaseQueryBuilder extends PostgrestQueryBuilder {
  late final SupabaseRealtimeClient _subscription;
  late final RealtimeClient _realtime;
  late final StreamController<List<Map<String, dynamic>>> _streamController;
  late final List<Map<String, dynamic>> _data;
  late final RealtimeSubscription _realtimeSubscription;
  late final StreamFilter? _streamFilter;

  SupabaseQueryBuilder(
    String url,
    RealtimeClient realtime, {
    Map<String, String> headers = const {},
    required String? schema,
    required String? table,
    required StreamFilter? streamFilter,
  }) : super(url, headers: headers, schema: schema) {
    _subscription =
        SupabaseRealtimeClient(realtime, schema ?? 'public', table ?? '*');
    _realtime = realtime;
    _streamFilter = streamFilter;
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
          final newRecord = Map<String, dynamic>.from(payload.newRecord!);
          _data.add(newRecord);
          break;
        case 'UPDATE':
          final index = _data.indexWhere((element) =>
              _findTargetRecord(record: element, payload: payload));
          if (index >= 0) {
            _data[index] = payload.newRecord!;
          } else {
            _streamController.addError('Could not find the updated record. ');
          }
          break;
        case 'DELETE':
          final index = _data.indexWhere((element) =>
              _findTargetRecord(record: element, payload: payload));
          if (index >= 0) {
            _data.removeAt(index);
          } else {
            _streamController.addError('Could not find the deleted record. ');
          }
          break;
      }
      _streamController.sink.add(_data);
    }).subscribe();
    late final PostgrestResponse res;
    if (_streamFilter != null) {
      res = await select()
          .eq(_streamFilter!.column, _streamFilter!.value)
          .execute();
    } else {
      res = await select().execute();
    }
    if (res.error != null) {
      _streamController.sink.addError(res.error!.message);
      return;
    }
    final data = List<Map<String, dynamic>>.from(res.data as List);
    _data.addAll(data);
    _streamController.sink.add(_data);
  }

  bool _findTargetRecord({
    required Map<String, dynamic> record,
    required SupabaseRealtimePayload payload,
  }) {
    late final Map<String, dynamic> targetRecord;
    if (payload.eventType == 'UPDATE') {
      targetRecord = payload.newRecord!;
    } else if (payload.eventType == 'DELETE') {
      targetRecord = payload.oldRecord!;
    }

    bool isTarget = true;
    for (final primaryKey in payload.primaryKeys) {
      if (record[primaryKey] != targetRecord[primaryKey]) {
        isTarget = false;
      }
    }
    return isTarget;
  }
}
