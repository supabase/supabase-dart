part of 'supabase_stream_builder.dart';

class SupabaseStreamFilterBuilder extends SupabaseStreamOrderBuilder {
  SupabaseStreamFilterBuilder({
    required PostgrestQueryBuilder queryBuilder,
    required String realtimeTopic,
    required RealtimeClient realtimeClient,
    required String schema,
    required String table,
    required List<String> primaryKey,
  }) : super(
          queryBuilder: queryBuilder,
          realtimeTopic: realtimeTopic,
          realtimeClient: realtimeClient,
          schema: schema,
          table: table,
          primaryKey: primaryKey,
          filter: null,
        );

  /// Filters the results where [column] equals [value].
  ///
  /// Only one filter can be applied to `.stream()`.
  ///
  /// ```dart
  /// supabase.from('users').stream(primaryKey: ['id']).eq('name', 'Supabase');
  /// ```
  SupabaseStreamOrderBuilder eq(String column, dynamic value) {
    return SupabaseStreamOrderBuilder(
      queryBuilder: _queryBuilder,
      realtimeTopic: _realtimeTopic,
      realtimeClient: _realtimeClient,
      schema: _schema,
      table: _table,
      primaryKey: _uniqueColumns,
      filter: StreamFilter(
        type: StreamFilterType.eq,
        column: column,
        value: value,
      ),
    );
  }

  /// Filters the results where [column] does not equal [value].
  ///
  /// Only one filter can be applied to `.stream()`.
  ///
  /// ```dart
  /// supabase.from('users').stream(primaryKey: ['id']).neq('name', 'Supabase');
  /// ```
  @override
  SupabaseStreamOrderBuilder neq(String column, dynamic value) {
    return SupabaseStreamOrderBuilder(
      queryBuilder: _queryBuilder,
      realtimeTopic: _realtimeTopic,
      realtimeClient: _realtimeClient,
      schema: _schema,
      table: _table,
      primaryKey: _uniqueColumns,
      filter: StreamFilter(
        type: StreamFilterType.neq,
        column: column,
        value: value,
      ),
    );
  }

  /// Filters the results where [column] is less than [value].
  ///
  /// Only one filter can be applied to `.stream()`.
  ///
  /// ```dart
  /// supabase.from('users').stream(primaryKey: ['id']).lt('likes', 100);
  /// ```
  SupabaseStreamOrderBuilder lt(String column, dynamic value) {
    return SupabaseStreamOrderBuilder(
      queryBuilder: _queryBuilder,
      realtimeTopic: _realtimeTopic,
      realtimeClient: _realtimeClient,
      schema: _schema,
      table: _table,
      primaryKey: _uniqueColumns,
      filter: StreamFilter(
        type: StreamFilterType.lt,
        column: column,
        value: value,
      ),
    );
  }

  /// Filters the results where [column] is less than or equal to [value].
  ///
  /// Only one filter can be applied to `.stream()`.
  ///
  /// ```dart
  /// supabase.from('users').stream(primaryKey: ['id']).lte('likes', 100);
  /// ```
  SupabaseStreamOrderBuilder lte(String column, dynamic value) {
    return SupabaseStreamOrderBuilder(
      queryBuilder: _queryBuilder,
      realtimeTopic: _realtimeTopic,
      realtimeClient: _realtimeClient,
      schema: _schema,
      table: _table,
      primaryKey: _uniqueColumns,
      filter: StreamFilter(
        type: StreamFilterType.lte,
        column: column,
        value: value,
      ),
    );
  }

  /// Filters the results where [column] is greater than [value].
  ///
  /// Only one filter can be applied to `.stream()`.
  ///
  /// ```dart
  /// supabase.from('users').stream(primaryKey: ['id']).gt('likes', '100');
  /// ```
  SupabaseStreamOrderBuilder gt(String column, dynamic value) {
    return SupabaseStreamOrderBuilder(
      queryBuilder: _queryBuilder,
      realtimeTopic: _realtimeTopic,
      realtimeClient: _realtimeClient,
      schema: _schema,
      table: _table,
      primaryKey: _uniqueColumns,
      filter: StreamFilter(
        type: StreamFilterType.gt,
        column: column,
        value: value,
      ),
    );
  }

  /// Filters the results where [column] is greater than or equal to [value].
  ///
  /// Only one filter can be applied to `.stream()`.
  ///
  /// ```dart
  /// supabase.from('users').stream(primaryKey: ['id']).gte('likes', 100);
  /// ```
  SupabaseStreamOrderBuilder gte(String column, dynamic value) {
    return SupabaseStreamOrderBuilder(
      queryBuilder: _queryBuilder,
      realtimeTopic: _realtimeTopic,
      realtimeClient: _realtimeClient,
      schema: _schema,
      table: _table,
      primaryKey: _uniqueColumns,
      filter: StreamFilter(
        type: StreamFilterType.gte,
        column: column,
        value: value,
      ),
    );
  }
}
