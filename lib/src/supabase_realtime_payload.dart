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

  void parsePayload(dynamic payload) {
    schema = payload['schema'] as String;
    table = payload['table'] as String;
    commitTimestamp = payload['commit_timestamp'] as String;
    eventType = payload['type'] as String;

    // TODO: update realtime_client.transformers to handle List<Map<string, dynamic>>
    if (payload['type'] == 'INSERT' || payload['type'] == 'UPDATE') {
      // records['new'] = convertChangeData(payload['columns'], payload['record']);
    }

    if (payload.type == 'UPDATE' || payload.type == 'DELETE') {
      // records['old'] = convertChangeData(payload.columns, payload.old_record);
    }
  }
}
