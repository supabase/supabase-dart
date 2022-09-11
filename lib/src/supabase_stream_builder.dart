import 'dart:async';

import 'package:supabase/supabase.dart';

class StreamPostgrestFilter {
  StreamPostgrestFilter({
    required this.column,
    required this.value,
  });

  /// Column name of the eq filter
  final String column;

  /// Value of the eq filter
  final dynamic value;
}

class _Order {
  _Order({
    required this.column,
    required this.ascending,
  });
  final String column;
  final bool ascending;
}

typedef SupabaseStreamEvent = List<Map<String, dynamic>>;

class SupabaseStreamBuilder extends Stream<SupabaseStreamEvent> {
  final PostgrestQueryBuilder _queryBuilder;

  final RealtimeChannel _channel;

  final String _schema;

  final String _table;

  /// Used to identify which row has changed
  final List<String> _uniqueColumns;

  /// StreamController for `stream()` method.
  late final StreamController<SupabaseStreamEvent> _streamController;

  /// Contains the combined data of postgrest and realtime to emit as stream.
  late final SupabaseStreamEvent _streamData;

  /// `eq` filter used for both postgrest and realtime
  StreamPostgrestFilter? _streamFilter;

  /// Which column to order by and whether it's ascending
  _Order? _orderBy;

  /// Count of record to be returned
  int? _limit;

  SupabaseStreamBuilder({
    required PostgrestQueryBuilder queryBuilder,
    required RealtimeChannel channel,
    required String schema,
    required String table,
    required List<String> uniqueColumns,
  })  : _queryBuilder = queryBuilder,
        _channel = channel,
        _schema = schema,
        _table = table,
        _uniqueColumns = uniqueColumns;

  /// Filters the results where [column] equals [value].
  ///
  /// Only one filter can be applied to `.stream()` and any proceding filters will override the previous.
  ///
  /// ```dart
  /// supabase.from('users').stream(['id']).eq('name', 'Supabase');
  /// ```
  SupabaseStreamBuilder eq(String column, dynamic value) {
    _streamFilter = StreamPostgrestFilter(column: column, value: value);
    return this;
  }

  /// Orders the result with the specified [column].
  ///
  /// When `ascending` value is true, the result will be in ascending order.
  ///
  /// ```dart
  /// supabase.from('users').stream(['id']).order('username', ascending: false);
  /// ```
  SupabaseStreamBuilder order(String column, {bool ascending = false}) {
    _orderBy = _Order(column: column, ascending: ascending);
    return this;
  }

  /// Limits the result with the specified `count`.
  ///
  /// ```dart
  /// supabase.from('users').stream(['id']).limit(10);
  /// ```
  SupabaseStreamBuilder limit(int count) {
    _limit = count;
    return this;
  }

  @Deprecated('Directly listen without execute instead. Deprecated in 1.0.0')
  Stream<SupabaseStreamEvent> execute() {
    _streamController = StreamController.broadcast(
      onCancel: () {
        if (!_streamController.hasListener) {
          _channel.unsubscribe();
          _streamController.close();
        }
      },
    );
    _getStreamData();
    return _streamController.stream;
  }

  @override
  StreamSubscription<SupabaseStreamEvent> listen(
    void Function(SupabaseStreamEvent event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    _streamController = StreamController.broadcast(
      onCancel: () {
        if (!_streamController.hasListener) {
          _channel.unsubscribe();
          _streamController.close();
        }
      },
    );
    _getStreamData();
    return _streamController.stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  Future<void> _getStreamData() async {
    _streamData = [];

    _channel.on(
        RealtimeListenTypes.postgresChanges,
        ChannelFilter(
          event: 'INSERT',
          schema: _schema,
          table: _table,
          filter: _streamFilter != null
              ? '${_streamFilter!.column}=eq.${_streamFilter!.value}'
              : null,
        ), (payload, [ref]) {
      final newRecord = Map<String, dynamic>.from(payload['new']!);
      _streamData.add(newRecord);
      _addStream();
    }).on(
        RealtimeListenTypes.postgresChanges,
        ChannelFilter(
          event: 'UPDATE',
          schema: _schema,
          table: _table,
          filter: _streamFilter != null
              ? '${_streamFilter!.column}=eq.${_streamFilter!.value}'
              : null,
        ), (payload, [ref]) {
      final updatedIndex = _streamData.indexWhere(
        (element) => _isTargetRecord(record: element, payload: payload),
      );

      if (updatedIndex >= 0) {
        _streamData[updatedIndex] = payload['new']!;
      } else {
        _addError('Could not find the updated record.');
      }
      _addStream();
    }).on(
        RealtimeListenTypes.postgresChanges,
        ChannelFilter(
          event: 'DELETE',
          schema: _schema,
          table: _table,
          filter: _streamFilter != null
              ? '${_streamFilter!.column}=eq.${_streamFilter!.value}'
              : null,
        ), (payload, [ref]) {
      final deletedIndex = _streamData.indexWhere(
        (element) => _isTargetRecord(record: element, payload: payload),
      );
      if (deletedIndex >= 0) {
        _streamData.removeAt(deletedIndex);
      } else {
        _addError('Could not find the deleted record.');
      }
      _addStream();
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

    try {
      final data = await (transformQuery ?? query);
      final rows = SupabaseStreamEvent.from(data as List);
      _streamData.addAll(rows);
      _addStream();
    } on PostgrestException catch (error) {
      _addError(error.message);
    } catch (error) {
      _addError(error.toString());
    }
  }

  bool _isTargetRecord({
    required Map<String, dynamic> record,
    required Map payload,
  }) {
    late final Map<String, dynamic> targetRecord;
    if (payload['eventType'] == 'UPDATE') {
      targetRecord = payload['new']!;
    } else if (payload['eventType'] == 'DELETE') {
      targetRecord = payload['old']!;
    }
    return _uniqueColumns
        .every((column) => record[column] == targetRecord[column]);
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

  /// Will add new data to the stream if streamController is not closed
  void _addStream() {
    if (_orderBy != null) {
      _sortData();
    }
    if (!_streamController.isClosed) {
      final emitData =
          (_limit != null ? _streamData.take(_limit!) : _streamData).toList();
      _streamController.add(emitData);
    }
  }

  /// Will add error to the stream if streamController is not closed
  void _addError(String message) {
    if (!_streamController.isClosed) {
      _streamController.addError(message);
    }
  }
}
