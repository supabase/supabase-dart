import 'package:http/http.dart';
import 'package:supabase/src/supabase_stream_builder.dart';
import 'package:supabase/supabase.dart';
import 'package:yet_another_json_isolate/yet_another_json_isolate.dart';

class SupabaseQueryBuilder extends PostgrestQueryBuilder {
  final RealtimeClient _realtime;
  final String _schema;
  final String _table;
  final int _incrementId;

  SupabaseQueryBuilder(
    String url,
    RealtimeClient realtime, {
    Map<String, String> headers = const {},
    required String schema,
    required String table,
    Client? httpClient,
    required int incrementId,
  })  : _realtime = realtime,
        _schema = schema,
        _table = table,
        _incrementId = incrementId,
        super(url,
            headers: headers,
            schema: schema,
            httpClient: httpClient,
            isolate: YAJsonIsolate()..initialize());

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
      realtimeTopic: '$_schema:$_table:$_incrementId',
      schema: _schema,
      table: _table,
      primaryKey: primaryKey,
    );
  }
}
