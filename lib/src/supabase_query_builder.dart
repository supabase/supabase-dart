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
  /// [primaryKey] list of name of primary key column(s).
  ///
  /// ```dart
  /// supabase.from('chats').stream(primaryKey: ['my_primary_key']).execute().listen(_onChatsReceived);
  /// ```
  ///
  /// `eq`, `order`, `limit` filter are available to limit the data being queried.
  ///
  /// ```dart
  /// supabase.from('chats:room_id=eq.123').stream(primaryKey: ['my_primary_key']).order('created_at').limit(20).execute().listen(_onChatsReceived);
  /// ```
  SupabaseStreamBuilder stream({required List<String> primaryKey}) {
    assert(primaryKey.isNotEmpty, 'Please specify primary key column(s).');
    return SupabaseStreamBuilder(
      queryBuilder: this,
      realtimeClient: _realtime,
      realtimeTopic: '$_schema:$_table',
      schema: _schema,
      table: _table,
      primaryKey: primaryKey,
    );
  }
}
