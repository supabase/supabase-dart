import 'dart:async';

import 'package:realtime_client/realtime_client.dart';
import 'package:supabase/src/supabase_query_builder.dart';
import 'package:supabase/src/supabase_realtime_payload.dart';

import '../supabase.dart';

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

class _Order {
  _Order({
    required this.column,
    required this.ascending,
  });
  final String column;
  final bool ascending;
}

class SupabaseStreamBuilder {
  final SupabaseQueryBuilder _queryBuilder;

  /// StreamController for `stream()` method.
  late final StreamController<List<Map<String, dynamic>>> _streamController;

  /// Contains the combined data of postgrest and realtime to emit as stream.
  late final List<Map<String, dynamic>> _streamData;

  /// RealtimeSubscription used in `stream()`.
  late final RealtimeSubscription _supabaseRealtimeClient;

  /// `eq` filter used for both postgrest and realtime
  late final StreamPostgrestFilter? _streamFilter;

  SupabaseStreamBuilder(
    SupabaseQueryBuilder queryBuilder, {
    required StreamPostgrestFilter? streamFilter,
  })  : _queryBuilder = queryBuilder,
        _streamFilter = streamFilter;

  /// Which column to order by and whether it's ascending
  _Order? _orderBy;

  /// Count of record to be returned
  int? _limit;

  /// Orders the result with the specified [column].
  ///
  /// When `ascending` value is true, the result will be in ascending order.
  ///
  /// ```dart
  /// supabase.from('users').stream().order('username', ascending: false);
  /// ```
  SupabaseStreamBuilder order(String column, {bool ascending = false}) {
    _orderBy = _Order(column: column, ascending: ascending);
    return this;
  }

  /// Limits the result with the specified `count`.
  ///
  /// ```dart
  /// supabase.from('users').stream().limit(10);
  /// ```
  SupabaseStreamBuilder limit(int count) {
    _limit = count;
    return this;
  }

  /// Sends the request and returns a Stream.
  Stream<List<Map<String, dynamic>>> execute() {
    _streamController = StreamController.broadcast(onCancel: () {
      if (!_streamController.hasListener) {
        _supabaseRealtimeClient.unsubscribe();
        _streamController.close();
      }
    });
    _getStreamData();
    return _streamController.stream;
  }

  Future<void> _getStreamData() async {
    _streamData = [];
    _supabaseRealtimeClient =
        _queryBuilder.on(SupabaseEventTypes.all, (payload) {
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
            _streamController.addError('Could not find the updated record.');
          }
          break;
        case 'DELETE':
          final deletedIndex = _streamData.indexWhere(
              (element) => _isTargetRecord(record: element, payload: payload));
          if (deletedIndex >= 0) {
            _streamData.removeAt(deletedIndex);
          } else {
            _streamController.addError('Could not find the deleted record.');
          }
          break;
      }
      if (_orderBy != null) {
        _sortData();
      }
      final emitData =
          (_limit != null ? _streamData.take(_limit!) : _streamData).toList();
      _streamController.sink.add(emitData);
    }).subscribe();

    PostgrestFilterBuilder query = _queryBuilder.select();
    if (_streamFilter != null) {
      query = query.eq(_streamFilter!.column, _streamFilter!.value);
    }
    PostgrestTransformBuilder? transformQuery;
    if (_orderBy != null) {
      transformQuery =
          query.order(_orderBy!.column, ascending: _orderBy!.ascending);
    }
    if (_limit != null) {
      transformQuery = (transformQuery ?? query).limit(_limit!);
    }

    final res = await (transformQuery ?? query).execute();
    if (res.error != null) {
      _streamController.sink.addError(res.error!.message);
      return;
    }
    final data = List<Map<String, dynamic>>.from(res.data as List);
    _streamData.addAll(data);
    _streamController.sink.add(_streamData);
  }

  static bool _isTargetRecord({
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

  void _sortData() {
    final orderModifier = _orderBy!.ascending ? 1 : -1;
    _streamData.sort((a, b) {
      if (a[_orderBy!.column] is String && b[_orderBy!.column] is String) {
        return orderModifier *
            (a[_orderBy!.column] as String)
                .compareTo(b[_orderBy!.column] as String);
      } else if (a[_orderBy!.column] is int && b[_orderBy!.column] is int) {
        return orderModifier *
            (a[_orderBy!.column] as int).compareTo(b[_orderBy!.column] as int);
      } else {
        return 0;
      }
    });
  }
}
