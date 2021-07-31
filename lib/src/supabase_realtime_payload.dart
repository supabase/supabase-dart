import 'package:realtime_client/realtime_client.dart';

class SupabaseRealtimePayload {
  final String commitTimestamp;

  /// 'INSERT' | 'UPDATE' | 'DELETE'
  final String eventType;
  final String schema;
  final String table;

  /// The new record. Present for 'INSERT' and 'UPDATE' events
  final Map<String, dynamic>? newRecord;

  /// The previous record. Present for 'UPDATE' and 'DELETE' events
  final Map<String, dynamic>? oldRecord;

  /// List of columns that are set as primary key
  final List<String> primaryKeys;

  SupabaseRealtimePayload({
    required this.commitTimestamp,
    required this.eventType,
    required this.schema,
    required this.table,
    required this.newRecord,
    required this.oldRecord,
    required this.primaryKeys,
  });

  factory SupabaseRealtimePayload.fromJson(Map<String, dynamic> json) {
    final schema = json['schema'] as String;
    final table = json['table'] as String;
    final commitTimestamp = json['commit_timestamp'] as String;
    final eventType = json['type'] as String;
    final primaryKeys = (json['columns'] as List)
        .where((e) => (e['flags'] as List).contains('key'))
        .map((e) => e['name'] as String)
        .toList();
    Map<String, dynamic>? newRecord;
    if (json['type'] == 'INSERT' || json['type'] == 'UPDATE') {
      final columns = convertColumnList(json['columns'] as List<dynamic>?);
      final records = json['record'] as Map<String, dynamic>? ?? {};
      newRecord = convertChangeData(columns, records);
    }
    Map<String, dynamic>? oldRecord;
    if (json['type'] == 'UPDATE' || json['type'] == 'DELETE') {
      final columns = convertColumnList(json['columns'] as List<dynamic>?);
      final records = json['old_record'] as Map<String, dynamic>? ?? {};
      oldRecord = convertChangeData(columns, records);
    }
    return SupabaseRealtimePayload(
      table: table,
      schema: schema,
      commitTimestamp: commitTimestamp,
      eventType: eventType,
      newRecord: newRecord,
      oldRecord: oldRecord,
      primaryKeys: primaryKeys,
    );
  }

  static List<Map<String, dynamic>> convertColumnList(List<dynamic>? columns) {
    final result = <Map<String, dynamic>>[];
    if (columns != null) {
      for (final column in columns) {
        result.add(column as Map<String, dynamic>);
      }
    }
    return result;
  }
}
