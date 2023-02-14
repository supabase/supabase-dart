part of 'supabase_stream_builder.dart';

class SupabaseLimitBuilder extends SupabaseStreamBuilder {
  SupabaseLimitBuilder({
    required PostgrestQueryBuilder queryBuilder,
    required String realtimeTopic,
    required RealtimeClient realtimeClient,
    required String schema,
    required String table,
    required List<String> primaryKey,
    required _StreamFilter? filter,
    required _StreamOrder? order,
  }) : super(
          queryBuilder: queryBuilder,
          realtimeTopic: realtimeTopic,
          realtimeClient: realtimeClient,
          schema: schema,
          table: table,
          primaryKey: primaryKey,
          filter: filter,
          order: order,
          limit: null,
        );

  /// Limits the result with the specified `count`.
  ///
  /// ```dart
  /// supabase.from('users').stream(primaryKey: ['id']).limit(10);
  /// ```
  SupabaseStreamBuilder limit(int count) {
    return SupabaseStreamBuilder(
      queryBuilder: _queryBuilder,
      realtimeTopic: _realtimeTopic,
      realtimeClient: _realtimeClient,
      schema: _schema,
      table: _table,
      primaryKey: _uniqueColumns,
      filter: _filter,
      order: _order,
      limit: count,
    );
  }
}
