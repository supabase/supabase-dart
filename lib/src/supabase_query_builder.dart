import 'package:http/http.dart';
import 'package:supabase/src/supabase_stream_builder.dart';
import 'package:supabase/supabase.dart';

class SupabaseQueryBuilder extends PostgrestQueryBuilder {
  final RealtimeClient _realtime;
  final String _schema;
  final String _table;

  SupabaseQueryBuilder(
    String url,
    RealtimeClient realtime, {
    Map<String, String> headers = const {},
    required String schema,
    required String table,
    Client? httpClient,
  })  : _realtime = realtime,
        _schema = schema,
        _table = table,
        super(
          url,
          headers: headers,
          schema: schema,
          httpClient: httpClient,
        );

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
    final channel = _realtime.channel('$_schema:$_table');
    return SupabaseStreamBuilder(
      queryBuilder: this,
      channel: channel,
      schema: _schema,
      table: _table,
      uniqueColumns: uniqueColumns,
    );
  }
}
