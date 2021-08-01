import 'dart:async';

import 'package:postgrest/postgrest.dart';
import 'package:realtime_client/realtime_client.dart';

import 'supabase_event_types.dart';
import 'supabase_realtime_client.dart';
import 'supabase_realtime_payload.dart';

typedef Callback = void Function(SupabaseRealtimePayload payload);

class StreamPostgrestFilter {
  StreamPostgrestFilter({
    required this.column,
    required this.value,
  });

  /// Column name of the eq filter
  final String column;

  /// Value of the eq filter
  final String value;
}

class SupabaseQueryBuilder extends PostgrestQueryBuilder {
  late final SupabaseRealtimeClient _subscription;
  late final RealtimeClient _realtime;

  /// StreamController for `stream()` method.
  late final StreamController<List<Map<String, dynamic>>> _streamController;

  /// Contains the combined data of postgrest and realtime to emit as stream.
  late final List<Map<String, dynamic>> _streamData;

  /// RealtimeSubscription used in `stream()`.
  late final RealtimeSubscription _realtimeSubscription;

  /// `eq` filter used for `stream()` if there were any.
  late final StreamPostgrestFilter? _streamFilter;

  SupabaseQueryBuilder(
    String url,
    RealtimeClient realtime, {
    Map<String, String> headers = const {},
    required String? schema,
    required String? table,
    required StreamPostgrestFilter? streamFilter,
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

  /// Notifies of data at the queried table
  ///
  /// ```dart
  /// supabase.from('chats').stream().listen(_onChatsReceived);
  /// ```
  ///
  /// It can also be used with `eq` filter available for `realtime` like so.
  ///
  /// ```dart
  /// supabase.from('chats:room_id=eq.123').stream().listen(_onChatsReceived);
  /// ```
  ///
  Stream<List<Map<String, dynamic>>> stream() {
    _streamController = StreamController.broadcast(onCancel: () {
      _realtimeSubscription.unsubscribe();
    });
    _getStreamData();
    return _streamController.stream;
  }

  Future<void> _getStreamData() async {
    _streamData = [];
    _realtimeSubscription = on(SupabaseEventTypes.all, (payload) {
      switch (payload.eventType) {
        case 'INSERT':
          final newRecord = Map<String, dynamic>.from(payload.newRecord!);
          _streamData.add(newRecord);
          break;
        case 'UPDATE':
          final updatedIndex = _streamData.indexWhere(
              (element) => _isTargetRecord(record: element, payload: payload));
          if (updatedIndex >= 0) {
            _streamData[updatedIndex] = payload.newRecord!;
          } else {
            _streamController.addError('Could not find the updated record. ');
          }
          break;
        case 'DELETE':
          final deletedIndex = _streamData.indexWhere(
              (element) => _isTargetRecord(record: element, payload: payload));
          if (deletedIndex >= 0) {
            _streamData.removeAt(deletedIndex);
          } else {
            _streamController.addError('Could not find the deleted record. ');
          }
          break;
      }
      _streamController.sink.add(_streamData);
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
    _streamData.addAll(data);
    _streamController.sink.add(_streamData);
  }

  bool _isTargetRecord({
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
