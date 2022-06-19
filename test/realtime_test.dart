// ignore_for_file: depend_on_referenced_packages

import 'dart:io';

import 'package:supabase/supabase.dart';
import 'package:test/test.dart';
import 'package:web_socket_channel/io.dart';

// TODO: @zoocityboy prepare mocked version of SupabaseClient
void main() {
  late HttpServer mockServer;
  late SupabaseClient client;

  group('Realtime subscriptions: ', () {
    setUp(() async {
      mockServer = await HttpServer.bind('localhost', 0);

      mockServer.transform(WebSocketTransformer()).listen((webSocket) {
        final channel = IOWebSocketChannel(webSocket);
        channel.stream.listen((request) {
          channel.sink.add(request);
        });
      });

      client = SupabaseClient(
        'http://${mockServer.address.host}:${mockServer.port}',
        'supabaseKey',
      );
    });
    tearDown(() async {
      await mockServer.close();
    });

    /// subscribe on existing subscription fail
    ///
    /// 1. create a subscription
    /// 2. subscribe on existing subscription
    ///
    /// expectation:
    /// - error
    test('subscribe on existing subscription fail', () {
      final subscription = client
          .from('countries')
          .on(SupabaseEventTypes.insert, (_) {})
          .subscribe(
            (event, {errorMsg}) {},
          );
      expect(
        () => subscription.subscribe(),
        throwsA(const TypeMatcher<String>()),
      );
    });

    /// two realtime connections
    ///
    /// 1. subscribe on table insert event
    /// 2. subscribe on table update event
    ///
    /// expectation:
    /// - 2 subscriptions
    test('two realtime connections', () {
      client
          .from('countries')
          .on(SupabaseEventTypes.insert, (_) {})
          .subscribe();
      client
          .from('countries')
          .on(SupabaseEventTypes.update, (_) {})
          .subscribe();
      final subscriptions = client.getSubscriptions();
      expect(
        subscriptions.length,
        2,
      );
    });

    /// remove realtime connection
    ///
    /// 1. subscribe on table insert event
    /// 2. subscribe on table update event
    /// 3. remove subscription on table insert event

    /// expectation:
    /// - result without error
    /// - only one subscription
    test('remove realtime connection', () async {
      final first = client
          .from('countries')
          .on(SupabaseEventTypes.insert, (event, {error}) {})
          .subscribe();

      client
          .from('countries')
          .on(SupabaseEventTypes.update, (event, {error}) {})
          .subscribe();
      final result = await client.removeSubscription(first);
      expect(
        result.error,
        isNull,
      );

      expect(
        client.getSubscriptions().length,
        1,
      );
    });

    /// remove multiple realtime connection
    ///
    /// 1. subscribe on table insert event
    /// 2. subscribe on table update event
    /// 3. remove both subscriptions
    ///
    /// expectation:
    /// - result 1 without error
    /// - result 2 without error
    /// - no subscriptions
    test('remove multiple realtime connection', () async {
      final first = client
          .from('countries')
          .on(SupabaseEventTypes.insert, (event, {error}) {})
          .subscribe();
      final second = client
          .from('countries')
          .on(SupabaseEventTypes.update, (event, {error}) {})
          .subscribe();
      await Future.delayed(const Duration(seconds: 2), () {});

      final result1 = await client.removeSubscription(first);
      final result2 = await client.removeSubscription(second);

      expect(
        result1.error,
        isNull,
      );
      expect(
        result2.error,
        isNull,
      );

      expect(
        client.getSubscriptions().length,
        0,
      );
    });

    /// remove all realtime connection
    ///
    /// 1. subscribe on table insert event
    /// 2. subscribe on table update event
    /// 3. remove subscriptions with removeAllSubscriptions()
    ///
    /// expectation:
    /// - result without error
    /// - result with 2 items
    /// - no subscriptions
    test('remove all realtime connection', () async {
      client
          .from('countries')
          .on(SupabaseEventTypes.insert, (event, {error}) {})
          .subscribe();

      client
          .from('countries')
          .on(SupabaseEventTypes.update, (event, {error}) {})
          .subscribe();

      final result1 = await client.removeAllSubscriptions();
      expect(
        result1,
        isNotEmpty,
      );
      expect(
        result1.length,
        2,
      );

      expect(
        client.getSubscriptions().length,
        0,
      );
    });
  });
}
