import 'package:realtime_client/realtime_client.dart';

class SupabaseRealtimePayload {
  String commitTimestamp;

  /// 'INSERT' | 'UPDATE' | 'DELETE'
  String eventType;
  String schema;
  String table;

  /// The new record. Present for 'INSERT' and 'UPDATE' events
  dynamic newRecord;

  /// The previous record. Present for 'UPDATE' and 'DELETE' events
  dynamic oldRecord;

  SupabaseRealtimePayload({
    required this.commitTimestamp,
    required this.eventType,
    required this.schema,
    required this.table,
    required this.newRecord,
    required this.oldRecord,
  });

  factory SupabaseRealtimePayload.fromJson(Map<String, dynamic> json) {
    final schema = json['schema'] as String;
    final table = json['table'] as String;
    final commitTimestamp = json['commit_timestamp'] as String;
    final eventType = json['type'] as String;
    Map<dynamic, dynamic>? newRecord;
    if (json['type'] == 'INSERT' || json['type'] == 'UPDATE') {
      final columns = convertColumnList(json['columns'] as List<dynamic>?);
      final records = json['record'] as Map<String, dynamic>? ?? {};
      newRecord = convertChangeData(columns, records);
    }
    Map<dynamic, dynamic>? oldRecord;
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
