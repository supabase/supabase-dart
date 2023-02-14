part of 'supabase_stream_builder.dart';

class SupabaseStreamOrderBuilder extends SupabaseLimitBuilder {
  SupabaseStreamOrderBuilder({
    required PostgrestQueryBuilder queryBuilder,
    required String realtimeTopic,
    required RealtimeClient realtimeClient,
    required String schema,
    required String table,
    required List<String> primaryKey,
    required StreamFilter? filter,
  }) : super(
          queryBuilder: queryBuilder,
          realtimeTopic: realtimeTopic,
          realtimeClient: realtimeClient,
          schema: schema,
          table: table,
          primaryKey: primaryKey,
          filter: filter,
          order: null,
        );

  /// Orders the result with the specified [column].
  ///
  /// When `ascending` value is true, the result will be in ascending order.
  ///
  /// ```dart
  /// supabase.from('users').stream(primaryKey: ['id']).order('username', ascending: false);
  /// ```
  SupabaseLimitBuilder order(String column, {bool ascending = false}) {
    return SupabaseLimitBuilder(
      queryBuilder: _queryBuilder,
      realtimeTopic: _realtimeTopic,
      realtimeClient: _realtimeClient,
      schema: _schema,
      table: _table,
      primaryKey: _uniqueColumns,
      filter: _filter,
      order: StreamOrder(
        column: column,
        ascending: ascending,
      ),
    );
  }
}
