import 'dart:async';

import 'package:gotrue/gotrue.dart';
import 'package:postgrest/postgrest.dart';
import 'package:realtime_client/realtime_client.dart';
import 'package:storage_client/storage_client.dart';
import 'package:supabase/src/constants.dart';
import 'package:supabase/src/supabase_query_builder.dart';
import 'package:supabase/src/supabase_stream_builder.dart';

class SupabaseClient {
  final String supabaseUrl;
  final String supabaseKey;
  final String schema;
  final String restUrl;
  final String realtimeUrl;
  final String authUrl;
  final String storageUrl;
  final Map<String, String> _headers;

  late final GoTrueClient auth;
  late final RealtimeClient realtime;
  String? changedAccessToken;

  SupabaseClient(
    this.supabaseUrl,
    this.supabaseKey, {
    String? schema,
    bool autoRefreshToken = true,
    Map<String, String> headers = Constants.defaultHeaders,
  })  : restUrl = '$supabaseUrl/rest/v1',
        realtimeUrl = '$supabaseUrl/realtime/v1'.replaceAll('http', 'ws'),
        authUrl = '$supabaseUrl/auth/v1',
        storageUrl = '$supabaseUrl/storage/v1',
        schema = schema ?? 'public',
        _headers = headers {
    auth = _initSupabaseAuthClient(
      autoRefreshToken: autoRefreshToken,
      headers: headers,
    );
    realtime = _initRealtimeClient(headers: headers);

    _listenForAuthEvents();
  }

  /// Supabase Storage allows you to manage user-generated content, such as photos or videos.
  SupabaseStorageClient get storage =>
      SupabaseStorageClient(storageUrl, _getAuthHeaders());

  /// Perform a table operation.
  SupabaseQueryBuilder from(String table) {
    late final String url;
    StreamPostgrestFilter? streamFilter;

    /// Check whether there is realtime filter or not
    if (RegExp(r'^.*:.*\=eq\..*$').hasMatch(table)) {
      final tableName = table.split(':').first;
      url = '$restUrl/$tableName';
      final colVals = table.split(':').last.split('=eq.');
      streamFilter =
          StreamPostgrestFilter(column: colVals.first, value: colVals.last);
    } else {
      url = '$restUrl/$table';
    }
    return SupabaseQueryBuilder(
      url,
      realtime,
      headers: _getAuthHeaders(),
      schema: schema,
      table: table,
      streamFilter: streamFilter,
    );
  }

  /// Perform a stored procedure call.
  PostgrestFilterBuilder rpc(String fn, {Map<String, dynamic>? params}) {
    final rest = _initPostgRESTClient();
    return rest.rpc(fn, params: params);
  }

  /// Remove all subscriptions.
  Future removeAllSubscriptions() async {
    final subscriptions = getSubscriptions();
    final futures = subscriptions.map((sub) => removeSubscription(sub));
    await Future.wait(futures);
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

  GoTrueClient _initSupabaseAuthClient({
    bool? autoRefreshToken,
    required Map<String, String> headers,
  }) {
    final authHeaders = {...headers};
    authHeaders['apikey'] = supabaseKey;
    authHeaders['Authorization'] = 'Bearer $supabaseKey';

    return GoTrueClient(
      url: authUrl,
      headers: authHeaders,
      autoRefreshToken: autoRefreshToken,
    );
  }

  RealtimeClient _initRealtimeClient({
    required Map<String, String> headers,
  }) {
    return RealtimeClient(
      realtimeUrl,
      params: {'apikey': supabaseKey},
      headers: headers,
    );
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
    final headers = {..._headers};
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

  void _listenForAuthEvents() {
    auth.onAuthStateChange((event, session) {
      _handleTokenChanged(event, session?.accessToken);
    });
  }

  void _handleTokenChanged(AuthChangeEvent event, String? token) {
    if (event == AuthChangeEvent.tokenRefreshed ||
        event == AuthChangeEvent.signedIn && changedAccessToken != token) {
      // Token has changed
      changedAccessToken = token;
      realtime.setAuth(token);
    } else if (event == AuthChangeEvent.signedOut) {
      // Token is removed
      removeAllSubscriptions();
    }
  }
}
