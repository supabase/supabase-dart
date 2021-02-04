import 'package:realtime_client/realtime_client.dart';

class SupabaseRealtimePayload {
  String commitTimestamp;

  /// 'INSERT' | 'UPDATE' | 'DELETE'
  String eventType;
  String schema;
  String table;

  /// The new record. Present for 'INSERT' and 'UPDATE' events
  dynamic news;

  /// The previous record. Present for 'UPDATE' and 'DELETE' events
  dynamic olds;

  SupabaseRealtimePayload(
      {this.commitTimestamp,
      this.eventType,
      this.schema,
      this.table,
      this.news,
      this.olds});

  factory SupabaseRealtimePayload.fromJson(Map<String, dynamic> json) {
    final obj = SupabaseRealtimePayload();
    obj.schema = json['schema'] as String;
    obj.table = json['table'] as String;
    obj.commitTimestamp = json['commit_timestamp'] as String;
    obj.eventType = json['type'] as String;

    if (json['type'] == 'INSERT' || json['type'] == 'UPDATE') {
      final columns = obj.convertColumnList(json['columns'] as List<dynamic>);
      final records = json['record'] as Map<String, dynamic> ?? {};
      obj.news = convertChangeData(columns, records);
    }

    if (json['type'] == 'UPDATE' || json['type'] == 'DELETE') {
      final columns = obj.convertColumnList(json['columns'] as List<dynamic>);
      final records = json['old_record'] as Map<String, dynamic> ?? {};
      obj.olds = convertChangeData(columns, records);
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
