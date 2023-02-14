import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:supabase/supabase.dart';

part 'supabase_stream_filter_builder.dart';
part 'supabase_stream_limit_builder.dart';
part 'supabase_stream_order_builder.dart';

enum _StreamFilterType { eq, neq, lt, lte, gt, gte }

class _StreamFilter {
  _StreamFilter({
    required this.column,
    required this.value,
    required this.type,
  });

  /// Column name of the eq filter
  final String column;

  /// Value of the eq filter
  final dynamic value;

  /// Type of the filer being applied
  final _StreamFilterType type;
}

class _StreamOrder {
  _StreamOrder({
    required this.column,
    required this.ascending,
  });
  final String column;
  final bool ascending;
}

typedef SupabaseStreamEvent = List<Map<String, dynamic>>;

class SupabaseStreamBuilder extends Stream<SupabaseStreamEvent> {
  final PostgrestQueryBuilder _queryBuilder;

  final RealtimeClient _realtimeClient;

  final String _realtimeTopic;

  RealtimeChannel? _channel;

  final String _schema;

  final String _table;

  /// Used to identify which row has changed
  final List<String> _uniqueColumns;

  /// StreamController for `stream()` method.
  BehaviorSubject<SupabaseStreamEvent>? _streamController;

  /// Contains the combined data of postgrest and realtime to emit as stream.
  SupabaseStreamEvent _streamData = [];

  /// `eq` filter used for both postgrest and realtime
  final _StreamFilter? _filter;

  /// Which column to order by and whether it's ascending
  final _StreamOrder? _order;

  /// Count of record to be returned
  final int? _limit;

  SupabaseStreamBuilder({
    required PostgrestQueryBuilder queryBuilder,
    required String realtimeTopic,
    required RealtimeClient realtimeClient,
    required String schema,
    required String table,
    required List<String> primaryKey,
    required _StreamFilter? filter,
    required _StreamOrder? order,
    required int? limit,
  })  : _queryBuilder = queryBuilder,
        _realtimeTopic = realtimeTopic,
        _realtimeClient = realtimeClient,
        _schema = schema,
        _table = table,
        _uniqueColumns = primaryKey,
        _filter = filter,
        _order = order,
        _limit = limit;

  @Deprecated('Directly listen without execute instead. Deprecated in 1.0.0')
  Stream<SupabaseStreamEvent> execute() {
    _setupStream();
    return _streamController!.stream;
  }

  @override
  StreamSubscription<SupabaseStreamEvent> listen(
    void Function(SupabaseStreamEvent event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    _setupStream();
    return _streamController!.stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  /// Sets up the stream controller and calls the method to get data as necessary
  void _setupStream() {
    _streamController ??= BehaviorSubject(
      onListen: () {
        _getStreamData();
      },
      onCancel: () {
        _channel?.unsubscribe();
        _streamController?.close();
        _streamController = null;
      },
    );
  }

  Future<void> _getStreamData() async {
    final currentStreamFilter = _filter;
    _streamData = [];
    String? realtimeFilter;
    if (currentStreamFilter != null) {
      realtimeFilter =
          '${currentStreamFilter.column}=${currentStreamFilter.type.name}.${currentStreamFilter.value}';
    }

    _channel = _realtimeClient.channel(_realtimeTopic);
    _channel!.on(
        RealtimeListenTypes.postgresChanges,
        ChannelFilter(
          event: 'INSERT',
          schema: _schema,
          table: _table,
          filter: realtimeFilter,
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
          filter: realtimeFilter,
        ), (payload, [ref]) {
      final updatedIndex = _streamData.indexWhere(
        (element) => _isTargetRecord(record: element, payload: payload),
      );

      final updatedRecord = Map<String, dynamic>.from(payload['new']!);
      if (updatedIndex >= 0) {
        _streamData[updatedIndex] = updatedRecord;
      } else {
        _streamData.add(updatedRecord);
      }
      _addStream();
    }).on(
        RealtimeListenTypes.postgresChanges,
        ChannelFilter(
          event: 'DELETE',
          schema: _schema,
          table: _table,
          filter: realtimeFilter,
        ), (payload, [ref]) {
      final deletedIndex = _streamData.indexWhere(
        (element) => _isTargetRecord(record: element, payload: payload),
      );
      if (deletedIndex >= 0) {
        /// Delete the data from in memory cache if it was found
        _streamData.removeAt(deletedIndex);
        _addStream();
      }
    }).subscribe();

    PostgrestFilterBuilder query = _queryBuilder.select();
    if (_filter != null) {
      switch (_filter!.type) {
        case _StreamFilterType.eq:
          query = query.eq(_filter!.column, _filter!.value);
          break;
        case _StreamFilterType.neq:
          query = query.neq(_filter!.column, _filter!.value);
          break;
        case _StreamFilterType.lt:
          query = query.lt(_filter!.column, _filter!.value);
          break;
        case _StreamFilterType.lte:
          query = query.lte(_filter!.column, _filter!.value);
          break;
        case _StreamFilterType.gt:
          query = query.gt(_filter!.column, _filter!.value);
          break;
        case _StreamFilterType.gte:
          query = query.gte(_filter!.column, _filter!.value);
          break;
      }
    }
    PostgrestTransformBuilder? transformQuery;
    if (_order != null) {
      transformQuery =
          query.order(_order!.column, ascending: _order!.ascending);
    }
    if (_limit != null) {
      transformQuery = (transformQuery ?? query).limit(_limit!);
    }

    try {
      final data = await (transformQuery ?? query);
      final rows = SupabaseStreamEvent.from(data as List);
      _streamData.addAll(rows);
      _addStream();
    } catch (error, stackTrace) {
      _addException(error, stackTrace);
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
    final orderModifier = _order!.ascending ? 1 : -1;
    _streamData.sort((a, b) {
      if (a[_order!.column] is String && b[_order!.column] is String) {
        return orderModifier *
            (a[_order!.column] as String)
                .compareTo(b[_order!.column] as String);
      } else if (a[_order!.column] is int && b[_order!.column] is int) {
        return orderModifier *
            (a[_order!.column] as int).compareTo(b[_order!.column] as int);
      } else {
        return 0;
      }
    });
  }

  /// Will add new data to the stream if streamController is not closed
  void _addStream() {
    if (_order != null) {
      _sortData();
    }
    if (!(_streamController?.isClosed ?? true)) {
      final emitData =
          (_limit != null ? _streamData.take(_limit!) : _streamData).toList();
      _streamController!.add(emitData);
    }
  }

  /// Will add error to the stream if streamController is not closed
  void _addException(Object error, [StackTrace? stackTrace]) {
    if (!(_streamController?.isClosed ?? true)) {
      _streamController?.addError(error, stackTrace ?? StackTrace.current);
    }
  }

  @override
  bool get isBroadcast => true;

  @override
  Stream<E> asyncMap<E>(
      FutureOr<E> Function(SupabaseStreamEvent event) convert) {
    // Copied from [Stream.asyncMap]

    final controller = BehaviorSubject<E>();

    controller.onListen = () {
      StreamSubscription<SupabaseStreamEvent> subscription = listen(null,
          onError: controller.addError, // Avoid Zone error replacement.
          onDone: controller.close);
      FutureOr<void> add(E value) {
        controller.add(value);
      }

      final addError = controller.addError;
      final resume = subscription.resume;
      subscription.onData((SupabaseStreamEvent event) {
        FutureOr<E> newValue;
        try {
          newValue = convert(event);
        } catch (e, s) {
          controller.addError(e, s);
          return;
        }
        if (newValue is Future<E>) {
          subscription.pause();
          newValue.then(add, onError: addError).whenComplete(resume);
        } else {
          controller.add(newValue as dynamic);
        }
      });
      controller.onCancel = subscription.cancel;
      if (!isBroadcast) {
        controller
          ..onPause = subscription.pause
          ..onResume = resume;
      }
    };
    return controller.stream;
  }

  @override
  Stream<E> asyncExpand<E>(
      Stream<E>? Function(SupabaseStreamEvent event) convert) {
    //Copied from [Stream.asyncExpand]
    final controller = BehaviorSubject<E>();
    controller.onListen = () {
      StreamSubscription<SupabaseStreamEvent> subscription = listen(null,
          onError: controller.addError, // Avoid Zone error replacement.
          onDone: controller.close);
      subscription.onData((SupabaseStreamEvent event) {
        Stream<E>? newStream;
        try {
          newStream = convert(event);
        } catch (e, s) {
          controller.addError(e, s);
          return;
        }
        if (newStream != null) {
          subscription.pause();
          controller.addStream(newStream).whenComplete(subscription.resume);
        }
      });
      controller.onCancel = subscription.cancel;
      if (!isBroadcast) {
        controller
          ..onPause = subscription.pause
          ..onResume = subscription.resume;
      }
    };
    return controller.stream;
  }
}
