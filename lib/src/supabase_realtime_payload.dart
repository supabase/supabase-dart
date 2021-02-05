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

  SupabaseRealtimePayload(
      {this.commitTimestamp,
      this.eventType,
      this.schema,
      this.table,
      this.newRecord,
      this.oldRecord});

  factory SupabaseRealtimePayload.fromJson(Map<String, dynamic> json) {
    final obj = SupabaseRealtimePayload();
    obj.schema = json['schema'] as String;
    obj.table = json['table'] as String;
    obj.commitTimestamp = json['commit_timestamp'] as String;
    obj.eventType = json['type'] as String;

    if (json['type'] == 'INSERT' || json['type'] == 'UPDATE') {
      final columns = obj.convertColumnList(json['columns'] as List<dynamic>);
      final records = json['record'] as Map<String, dynamic> ?? {};
      obj.newRecord = convertChangeData(columns, records);
    }

    if (json['type'] == 'UPDATE' || json['type'] == 'DELETE') {
      final columns = obj.convertColumnList(json['columns'] as List<dynamic>);
      final records = json['old_record'] as Map<String, dynamic> ?? {};
      obj.oldRecord = convertChangeData(columns, records);
    }
    return obj;
  }

  List<Map<String, dynamic>> convertColumnList(List<dynamic> columns) {
    final result = <Map<String, dynamic>>[];
    if (columns != null) {
      for (final column in columns) {
        result.add(column as Map<String, dynamic>);
      }
    }
    return result;
  }
}
