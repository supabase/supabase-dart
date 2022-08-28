import 'package:http/http.dart';
import 'package:supabase/src/supabase_stream_builder.dart';
import 'package:supabase/supabase.dart';

class SupabaseQueryBuilder extends PostgrestQueryBuilder {
  late final RealtimeChannel _channel;
  final String _schema;
  final String _table;

  SupabaseQueryBuilder(
    String url,
    RealtimeClient realtime, {
    Map<String, String> headers = const {},
    required String schema,
    required String table,
    Client? httpClient,
  })  : _channel = realtime.channel('stream'),
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
    return SupabaseStreamBuilder(
      queryBuilder: this,
      channel: _channel,
      schema: _schema,
      table: _table,
      uniqueColumns: uniqueColumns,
    );
  }
}
