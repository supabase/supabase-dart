class SupabaseClientOptions {
  String schema;
  Map<String, String> headers;
  bool autoRefreshToken;

  SupabaseClientOptions(
      {this.schema, this.headers, this.autoRefreshToken = true});
}
