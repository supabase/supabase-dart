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

    test('''
subscribe on existing subscription fail
      1. create a subscription
      2. subscribe on existing subscription
    
      expectation: 
      - error
    ''', () {
      final subscription = client
          .from('countries')
          .on(SupabaseEventTypes.insert, (_) {})
          .subscribe(
            (event, {errorMsg}) => print('event: $event error: $errorMsg'),
          );
      expect(
        () => subscription.subscribe(),
        throwsA(const TypeMatcher<String>()),
      );
    });
    test('''
two realtime connections
    1. subscribe on table insert event
    2. subscribe on table update event

    expectation: 
    - 2 subscriptions
    ''', () {
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
    test('''
remove realtime connection
    
    1. subscribe on table insert event
    2. subscribe on table update event
    3. remove subscription on table insert event
    
    expectation: 
    - result without error
    - only one subscription
    ''', () async {
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
    test('''
remove multiple realtime connection
    
    1. subscribe on table insert event
    2. subscribe on table update event
    3. remove both subscriptions
    
    expectation:
    - result 1 without error
    - result 2 without error
    - no subscriptions
    ''', () async {
      client.realtime.onOpen(() => print('socket opened'));
      final first = client
          .from('countries')
          .on(SupabaseEventTypes.insert, (event, {error}) {})
          .subscribe(
            (event, {errorMsg}) => print('1. event: $event error: $errorMsg'),
          );
      final second = client
          .from('countries')
          .on(SupabaseEventTypes.update, (event, {error}) {})
          .subscribe(
            (event, {errorMsg}) => print('2. event: $event error: $errorMsg'),
          );
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

    test('''
remove all realtime connection
        
    1. subscribe on table insert event
    2. subscribe on table update event
    3. remove subscriptions with removeAllSubscriptions()
    
    expectation:
    - result without error
    - result with 2 items
    - no subscriptions
    ''', () async {
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
