import 'dart:async';

import 'package:functions_client/functions_client.dart';
import 'package:gotrue/gotrue.dart';
import 'package:http/http.dart';
import 'package:postgrest/postgrest.dart';
import 'package:realtime_client/realtime_client.dart';
import 'package:storage_client/storage_client.dart';
import 'package:supabase/src/constants.dart';
import 'package:supabase/src/remove_subscription_result.dart';
import 'package:supabase/src/supabase_query_builder.dart';
import 'package:supabase/src/supabase_realtime_error.dart';
import 'package:supabase/src/supabase_stream_builder.dart';

class SupabaseClient {
  final String supabaseUrl;
  final String supabaseKey;
  final String schema;
  final String restUrl;
  final String realtimeUrl;
  final String authUrl;
  final String storageUrl;
  final String functionsUrl;
  final Map<String, String> _headers;
  final Client? _httpClient;

  late final GoTrueClient auth;
  late final RealtimeClient realtime;
  String? changedAccessToken;

  SupabaseClient(
    this.supabaseUrl,
    this.supabaseKey, {
    String? schema,
    bool autoRefreshToken = true,
    Map<String, String> headers = Constants.defaultHeaders,
    Client? httpClient,
  })  : restUrl = '$supabaseUrl/rest/v1',
        realtimeUrl = '$supabaseUrl/realtime/v1'.replaceAll('http', 'ws'),
        authUrl = '$supabaseUrl/auth/v1',
        storageUrl = '$supabaseUrl/storage/v1',
        functionsUrl = RegExp(r'(supabase\.co)|(supabase\.in)')
                .hasMatch(supabaseUrl)
            ? '${supabaseUrl.split('.')[0]}.functions.${supabaseUrl.split('.')[1]}.${supabaseUrl.split('.')[2]}'
            : '$supabaseUrl/functions/v1',
        schema = schema ?? 'public',
        _headers = headers,
        _httpClient = httpClient {
    auth = _initSupabaseAuthClient(
      autoRefreshToken: autoRefreshToken,
      headers: headers,
    );
    realtime = _initRealtimeClient(headers: headers);

    _listenForAuthEvents();
  }

  /// Supabase Functions allows you to deploy and invoke edge functions.
  FunctionsClient get functions => FunctionsClient(
        functionsUrl,
        _getAuthHeaders(),
        httpClient: _httpClient,
      );

  /// Supabase Storage allows you to manage user-generated content, such as photos or videos.
  SupabaseStorageClient get storage => SupabaseStorageClient(
        storageUrl,
        _getAuthHeaders(),
        httpClient: _httpClient,
      );

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
      httpClient: _httpClient,
    );
  }

  /// Perform a stored procedure call.
  PostgrestFilterBuilder rpc(String fn, {Map<String, dynamic>? params}) {
    final rest = _initPostgRESTClient();
    return rest.rpc(fn, params: params);
  }

  /// Closes and removes all subscriptions and returns a list of removed
  /// subscriptions and their errors.
  Future<List<RealtimeSubscription>> removeAllSubscriptions() async {
    final allSubs = [...getSubscriptions()];
    final allSubsFutures = allSubs.map((sub) => removeSubscription(sub));
    final allRemovedSubs = await Future.wait(allSubsFutures);
    final removed = <RealtimeSubscription>[];
    for (var i = 0; i < allRemovedSubs.length; i++) {
      removed.add(allSubs[i]);
    }
    return removed;
  }

  /// Closes and removes a subscription and returns the number of open subscriptions.
  /// [subscription]: subscription The subscription you want to close and remove.
  Future<RemoveSubscriptionResult> removeSubscription(
    RealtimeSubscription subscription,
  ) async {
    final completer = Completer<int>();

    final closeSubscriptionResult = await _closeSubscription(subscription);
    final allSubs = [...getSubscriptions()];
    final openSubsCount =
        allSubs.where((sub) => sub.isJoined()).toList().length;
    if (openSubsCount == 0) {
      realtime.disconnect(reason: 'all subscriptions closed');
    }
    completer.complete(openSubsCount);

    return RemoveSubscriptionResult(
      openSubscriptions: openSubsCount,
      error: closeSubscriptionResult,
    );
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
      httpClient: _httpClient,
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
      httpClient: _httpClient,
    );
  }

  Future<SupabaseRealtimeError?> _closeSubscription(
    RealtimeSubscription subscription,
  ) async {
    SupabaseRealtimeError? error;
    if (!subscription.isClosed()) {
      error = await _unsubscribeSubscription(subscription);
    }
    realtime.remove(subscription);
    return error;
  }

  Map<String, String> _getAuthHeaders() {
    final headers = {..._headers};
    final authBearer = auth.currentSession?.accessToken ?? supabaseKey;
    headers['apikey'] = supabaseKey;
    headers['Authorization'] = 'Bearer $authBearer';
    return headers;
  }

  /// Close channel [subscription] and return the result.
  ///
  /// in case of unsubscribe, remove the realtime connection and return null
  /// in case of error return the error
  Future<SupabaseRealtimeError?> _unsubscribeSubscription(
    RealtimeSubscription subscription,
  ) {
    final completer = Completer<SupabaseRealtimeError?>();
    subscription.unsubscribe().receive(
      'ok',
      (_) {
        completer.complete(null);
      },
    ).receive(
      'error',
      (e) {
        completer.completeError(SupabaseRealtimeError(e.toString()));
      },
    ).receive(
      'timeout',
      (e) {
        completer.completeError(SupabaseRealtimeError(e.toString()));
      },
    );
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
