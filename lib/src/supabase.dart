import 'dart:async';

import 'package:gotrue/gotrue.dart';
import 'package:postgrest/postgrest.dart';
import 'package:realtime_client/realtime_client.dart';
import 'package:supabase/src/supabase_storage_client.dart';

import 'supabase_query_builder.dart';

class SupabaseClient {
  final String supabaseUrl;
  final String supabaseKey;
  final String schema;
  final String restUrl;
  final String realtimeUrl;
  final String authUrl;
  final String storageUrl;

  late final GoTrueClient auth;
  late final RealtimeClient realtime;

  SupabaseClient(this.supabaseUrl, this.supabaseKey,
      {String? schema, bool autoRefreshToken = true})
      : restUrl = '$supabaseUrl/rest/v1',
        realtimeUrl = '$supabaseUrl/realtime/v1'.replaceAll('http', 'ws'),
        authUrl = '$supabaseUrl/auth/v1',
        storageUrl = '$supabaseUrl/storage/v1',
        schema = schema ?? 'public' {
    auth = _initSupabaseAuthClient(autoRefreshToken: autoRefreshToken);
    realtime = _initRealtimeClient();
  }

  /// Supabase Storage allows you to manage user-generated content, such as photos or videos.
  SupabaseStorageClient get storage =>
      SupabaseStorageClient(storageUrl, _getAuthHeaders());

  /// Perform a table operation.
  SupabaseQueryBuilder from(String table) {
    final url = '$restUrl/$table';
    return SupabaseQueryBuilder(
      url,
      realtime,
      headers: _getAuthHeaders(),
      schema: schema,
      table: table,
    );
  }

  /// Perform a stored procedure call.
  PostgrestTransformBuilder rpc(String fn, {Map<String, String>? params}) {
    final rest = _initPostgRESTClient();
    return rest.rpc(fn, params: params);
  }

  /// Removes an active subscription and returns the number of open connections.
  Future<int> removeSubscription(RealtimeSubscription subscription) async {
    final completer = Completer<int>();

    await _closeSubscription(subscription);
    final openSubscriptions = getSubscriptions().length;
    if (openSubscriptions == 0) {
      realtime.disconnect();
    }
    completer.complete(openSubscriptions);

    return completer.future;
  }

  /// Returns an array of all your subscriptions.
  List<RealtimeSubscription> getSubscriptions() {
    return realtime.channels;
  }

  GoTrueClient _initSupabaseAuthClient({bool? autoRefreshToken}) {
    return GoTrueClient(
        url: authUrl,
        headers: {
          'Authorization': 'Bearer $supabaseKey',
          'apikey': supabaseKey,
        },
        autoRefreshToken: autoRefreshToken);
  }

  RealtimeClient _initRealtimeClient() {
    return RealtimeClient(realtimeUrl, params: {'apikey': supabaseKey});
  }

  PostgrestClient _initPostgRESTClient() {
    return PostgrestClient(
      restUrl,
      headers: _getAuthHeaders(),
      schema: schema,
    );
  }

  Future<void> _closeSubscription(RealtimeSubscription subscription) async {
    if (!subscription.isClosed()) {
      await _closeChannel(subscription);
    }
  }

  Map<String, String> _getAuthHeaders() {
    final Map<String, String> headers = {};
    final authBearer = auth.session()?.accessToken ?? supabaseKey;
    headers['apikey'] = supabaseKey;
    headers['Authorization'] = 'Bearer $authBearer';
    return headers;
  }

  Future<bool> _closeChannel(RealtimeSubscription subscription) {
    final completer = Completer<bool>();
    subscription.unsubscribe().receive('ok', (_) {
      realtime.remove(subscription);
      completer.complete(true);
    }).receive('error', (e) => {completer.complete(false)});
    return completer.future;
  }
}
