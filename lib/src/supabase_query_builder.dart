import 'package:supabase/src/supabase_realtime_client.dart';
import 'package:supabase/src/supabase_stream_builder.dart';
import 'package:supabase/supabase.dart';

class SupabaseQueryBuilder extends PostgrestQueryBuilder {
  late final SupabaseRealtimeClient _subscription;
  late final RealtimeClient _realtime;
  late final StreamPostgrestFilter? _streamFilter;

  SupabaseQueryBuilder(
    String url,
    RealtimeClient realtime, {
    Map<String, String> headers = const {},
    required String? schema,
    required String? table,
    required StreamPostgrestFilter? streamFilter,
  }) : super(url, headers: headers, schema: schema) {
    _subscription = SupabaseRealtimeClient(
      realtime,
      headers,
      schema ?? 'public',
      table ?? '*',
    );
    _realtime = realtime;
    _streamFilter = streamFilter;
  }

  /// Subscribe to realtime changes in your databse.
  SupabaseRealtimeClient on(
    SupabaseEventTypes event,
    void Function(SupabaseRealtimePayload payload) callback,
  ) {
    if (_realtime.isConnected() == false) {
      _realtime.connect();
    }
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
