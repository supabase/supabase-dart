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
      final columns = json['columns'] as List<Map<String, String>>;
      final records = json['record'] as Map<String, String>;
      obj.news = convertChangeData(columns, records);
    }

    if (json['type'] == 'UPDATE' || json['type'] == 'DELETE') {
      final columns = json['columns'] as List<Map<String, String>>;
      final records = json['record'] as Map<String, String>;
      obj.olds = convertChangeData(columns, records);
    }
    return obj;
  }
}
