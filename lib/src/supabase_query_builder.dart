import 'package:supabase/src/supabase_realtime_client.dart';
import 'package:supabase/src/supabase_stream_builder.dart';
import 'package:supabase/supabase.dart';

class SupabaseQueryBuilder extends PostgrestQueryBuilder {
  late final SupabaseRealtimeClient _subscription;
  final Map<String, String> _headers;
  final String _schema;
  final String _table;
  final RealtimeClient _realtime;
  final StreamPostgrestFilter? _streamFilter;

  SupabaseQueryBuilder(
    String url,
    RealtimeClient realtime, {
    Map<String, String> headers = const {},
    required String schema,
    required String table,
    required StreamPostgrestFilter? streamFilter,
  })  : _headers = headers,
        _schema = schema,
        _table = table,
        _realtime = realtime,
        _streamFilter = streamFilter,
        super(url, headers: headers, schema: schema);

  /// Subscribe to realtime changes in your databse.
  SupabaseRealtimeClient on(
    SupabaseEventTypes event,
    void Function(SupabaseRealtimePayload payload) callback,
  ) {
    if (_realtime.isConnected() == false) {
      _realtime.connect();
    }
    _subscription = SupabaseRealtimeClient(
      _realtime,
      _headers,
      _schema,
      _table,
    );
    return _subscription.on(event, callback);
  }

  /// Notifies of data at the queried table
  ///
  /// [uniqueColumns] can be either the primary key or a combination of unique columns.
  ///
  /// ```dart
  /// supabase.from('chats').stream(['my_primary_key']).execute().listen(_onChatsReceived);
  /// ```
  ///
  /// `eq`, `order`, `limit` filter are available to limit the data being queried.
  ///
  /// ```dart
  /// supabase.from('chats:room_id=eq.123').stream(['my_primary_key']).order('created_at').limit(20).execute().listen(_onChatsReceived);
  /// ```
  SupabaseStreamBuilder stream(List<String> uniqueColumns) {
    return SupabaseStreamBuilder(
      this,
      streamFilter: _streamFilter,
      uniqueColumns: uniqueColumns,
    );
  }
}
