import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:supabase/supabase.dart';
import 'package:test/test.dart';

void main() {
  late SupabaseClient client;
  late SupabaseClient customHeadersClient;
  late HttpServer mockServer;
  late String apiKey;
  const customApiKey = 'customApiKey';
  const customHeaders = {'customfield': 'customvalue', 'apikey': customApiKey};
  String ref = "1";
  WebSocket? webSocket;
  bool hasListener = false;
  bool hasSentData = false;
  StreamSubscription<dynamic>? listener;

  Future<void> handleRequests(HttpServer server) async {
    await for (final HttpRequest request in server) {
      print(request.uri.toString());
      final headers = request.headers;
      if (headers.value('X-Client-Info') != 'supabase-flutter/0.0.0') {
        throw 'Proper header not set';
      }
      final url = request.uri.toString();
      if (url.startsWith("/rest")) {
        final foundApiKey = headers.value('apikey');
        expect(foundApiKey, apiKey);
        if (foundApiKey == customApiKey) {
          expect(headers.value('customfield'), 'customvalue');
        }
      }
      if (url == '/rest/v1/todos?select=task%2Cstatus') {
        final jsonString = jsonEncode([
          {'task': 'task 1', 'status': true},
          {'task': 'task 2', 'status': false}
        ]);
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.json
          ..write(jsonString)
          ..close();
      } else if (url == '/rest/v1/todos?select=%2A' ||
          url == '/rest/v1/rpc/todos?select=%2A') {
        final jsonString = jsonEncode([
          {'id': 1, 'task': 'task 1', 'status': true},
          {'id': 2, 'task': 'task 2', 'status': false}
        ]);
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.json
          ..write(jsonString)
          ..close();
      } else if (url == '/rest/v1/todos?select=%2A&status=eq.true') {
        final jsonString = jsonEncode([
          {'id': 1, 'task': 'task 1', 'status': true},
        ]);
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.json
          ..write(jsonString)
          ..close();
      } else if (url == '/rest/v1/todos?select=%2A&order=id.desc.nullslast') {
        final jsonString = jsonEncode([
          {'id': 2, 'task': 'task 2', 'status': false},
          {'id': 1, 'task': 'task 1', 'status': true},
        ]);
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.json
          ..write(jsonString)
          ..close();
      } else if (url ==
          '/rest/v1/todos?select=%2A&order=id.desc.nullslast&limit=2') {
        final jsonString = jsonEncode([
          {'id': 2, 'task': 'task 2', 'status': false},
          {'id': 1, 'task': 'task 1', 'status': true},
        ]);
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.json
          ..write(jsonString)
          ..close();
      } else if (url.contains('realtime')) {
        webSocket = await WebSocketTransformer.upgrade(request);
        if (hasListener) {
          return;
        }
        hasListener = true;
        listener = webSocket!.listen((request) async {
          if (hasSentData) {
            return;
          }
          hasSentData = true;

          /// `filter` might be there or not depending on whether is a filter set
          /// to the realtime subscription, so include the filter if the request
          /// includes a filter.
          final requestJson = jsonDecode(request);
          final String? postgresFilter = requestJson['payload']['config']
                  ['postgres_changes']
              .first['filter'];

          final replyString = jsonEncode({
            'event': 'phx_reply',
            'payload': {
              'response': {
                'postgres_changes': [
                  {
                    'id': 77086988,
                    'event': 'INSERT',
                    'schema': 'public',
                    'table': 'todos',
                    if (postgresFilter != null) 'filter': postgresFilter,
                  },
                  {
                    'id': 25993878,
                    'event': 'UPDATE',
                    'schema': 'public',
                    'table': 'todos',
                    if (postgresFilter != null) 'filter': postgresFilter,
                  },
                  {
                    'id': 48673474,
                    'event': 'DELETE',
                    'schema': 'public',
                    'table': 'todos',
                    if (postgresFilter != null) 'filter': postgresFilter,
                  }
                ]
              },
              'status': 'ok'
            },
            'ref': ref,
            'topic': 'realtime:public:todos'
          });
          webSocket!.add(replyString);

          // Send an insert event
          await Future.delayed(Duration(milliseconds: 300));
          final topic = (jsonDecode(request as String) as Map)['topic'];
          final insertString = jsonEncode({
            'topic': topic,
            'event': 'postgres_changes',
            'ref': null,
            'payload': {
              'ids': [77086988],
              'data': {
                'commit_timestamp': '2021-08-01T08:00:20Z',
                'record': {'id': 3, 'task': 'task 3', 'status': 't'},
                'schema': 'public',
                'table': 'todos',
                'type': 'INSERT',
                if (postgresFilter != null) 'filter': postgresFilter,
                'columns': [
                  {
                    'name': 'id',
                    'type': 'int4',
                    'type_modifier': 4294967295,
                  },
                  {
                    'name': 'task',
                    'type': 'text',
                    'type_modifier': 4294967295,
                  },
                  {
                    'name': 'status',
                    'type': 'bool',
                    'type_modifier': 4294967295,
                  },
                ],
              },
            },
          });
          webSocket!.add(insertString);

          // Send an update event for id = 2
          await Future.delayed(Duration(milliseconds: 10));
          final updateString = jsonEncode({
            'topic': topic,
            'ref': null,
            'event': 'postgres_changes',
            'payload': {
              'ids': [25993878],
              'data': {
                'columns': [
                  {'name': 'id', 'type': 'int4', 'type_modifier': 4294967295},
                  {'name': 'task', 'type': 'text', 'type_modifier': 4294967295},
                  {
                    'name': 'status',
                    'type': 'bool',
                    'type_modifier': 4294967295
                  },
                ],
                'commit_timestamp': '2021-08-01T08:00:30Z',
                'errors': null,
                'old_record': {'id': 2},
                'record': {'id': 2, 'task': 'task 2 updated', 'status': 'f'},
                'schema': 'public',
                'table': 'todos',
                'type': 'UPDATE',
                if (postgresFilter != null) 'filter': postgresFilter,
              },
            },
          });
          webSocket!.add(updateString);

          // Send delete event for id=2
          await Future.delayed(Duration(milliseconds: 10));
          final deleteString = jsonEncode({
            'ref': null,
            'topic': topic,
            'event': 'postgres_changes',
            'payload': {
              'data': {
                'columns': [
                  {'name': 'id', 'type': 'int4', 'type_modifier': 4294967295},
                  {'name': 'task', 'type': 'text', 'type_modifier': 4294967295},
                  {
                    'name': 'status',
                    'type': 'bool',
                    'type_modifier': 4294967295
                  },
                ],
                'commit_timestamp': '2022-09-14T02:12:52Z',
                'errors': null,
                'old_record': {'id': 2},
                'schema': 'public',
                'table': 'todos',
                'type': 'DELETE',
                if (postgresFilter != null) 'filter': postgresFilter,
              },
              'ids': [48673474]
            },
          });
          webSocket!.add(deleteString);
        });
      } else {
        request.response
          ..statusCode = HttpStatus.ok
          ..close();
      }
    }
  }

  setUp(() async {
    apiKey = 'supabaseKey';
    mockServer = await HttpServer.bind('localhost', 0);
    client = SupabaseClient(
      'http://${mockServer.address.host}:${mockServer.port}',
      apiKey,
      headers: {
        'X-Client-Info': 'supabase-flutter/0.0.0',
      },
    );
    customHeadersClient = SupabaseClient(
      'http://${mockServer.address.host}:${mockServer.port}',
      apiKey,
      headers: {'X-Client-Info': 'supabase-flutter/0.0.0', ...customHeaders},
    );
    hasListener = false;
    hasSentData = false;
    handleRequests(mockServer);
  });

  tearDown(() async {
    listener?.cancel();

    // Wait for the realtime updates to come through
    await Future.delayed(Duration(milliseconds: 100));

    await webSocket?.close();
    await mockServer.close();
  });

  test('test mock server', () async {
    final data = await client.from('todos').select('task, status');
    expect((data as List).length, 2);
  });

  group('Basic client test', () {
    test('Postgrest calls the correct endpoint', () async {
      final data = await client.from('todos').select();
      expect(data, [
        {'id': 1, 'task': 'task 1', 'status': true},
        {'id': 2, 'task': 'task 2', 'status': false}
      ]);
    });

    test('Postgrest calls the correct endpoint with custom headers', () async {
      apiKey = customApiKey;
      final data = await customHeadersClient.from('todos').select();
      expect(data, [
        {'id': 1, 'task': 'task 1', 'status': true},
        {'id': 2, 'task': 'task 2', 'status': false}
      ]);
    });
  });

  group('stream()', () {
    test("ddd", () async {
      final stream =
          Stream.periodic(Duration(milliseconds: 100)).asBroadcastStream();
      final sub = stream.listen((event) {
        print("1" + event);
      });

      await Future.delayed(Duration(milliseconds: 100));

      final sub2 = stream.listen((event) {
        print("2" + event);
      });
    });

    test("listen, cancel and listen again", () async {
      final stream = client.from('todos').stream(['id']);
      final sub = stream.listen(expectAsync1((event) {}, count: 4));
      await Future.delayed(Duration(milliseconds: 5000));

      await sub.cancel();
      await Future.delayed(Duration(milliseconds: 5000));
      hasSentData = false;
      hasListener = false;
      ref = "3";

      final sub2 = stream.listen(expectAsync1((event) {}, count: 4));

      // await Future.delayed(Duration(milliseconds: 5000));
    });
    test('emits data', () {
      final stream = client.from('todos').stream(['id']);
      expect(
        stream,
        emitsInOrder([
          containsAllInOrder([
            {'id': 1, 'task': 'task 1', 'status': true},
            {'id': 2, 'task': 'task 2', 'status': false}
          ]),
          containsAllInOrder([
            {'id': 1, 'task': 'task 1', 'status': true},
            {'id': 2, 'task': 'task 2', 'status': false},
            {'id': 3, 'task': 'task 3', 'status': true},
          ]),
          containsAllInOrder([
            {'id': 1, 'task': 'task 1', 'status': true},
            {'id': 2, 'task': 'task 2 updated', 'status': false},
            {'id': 3, 'task': 'task 3', 'status': true},
          ]),
          containsAllInOrder([
            {'id': 1, 'task': 'task 1', 'status': true},
            {'id': 3, 'task': 'task 3', 'status': true},
          ]),
        ]),
      );
    });
    test('emits data with custom headers', () {
      apiKey = customApiKey;
      final stream = customHeadersClient.from('todos').stream(['id']);
      expect(
        stream,
        emitsInOrder([
          containsAllInOrder([
            {'id': 1, 'task': 'task 1', 'status': true},
            {'id': 2, 'task': 'task 2', 'status': false}
          ]),
          containsAllInOrder([
            {'id': 1, 'task': 'task 1', 'status': true},
            {'id': 2, 'task': 'task 2', 'status': false},
            {'id': 3, 'task': 'task 3', 'status': true},
          ]),
        ]),
      );
    });

    test('can filter stream results with eq', () {
      final stream = client.from('todos').stream(['id']).eq('status', true);
      expect(
        stream,
        emitsInOrder([
          containsAllInOrder([
            {'id': 1, 'task': 'task 1', 'status': true},
          ]),
          containsAllInOrder([
            {'id': 1, 'task': 'task 1', 'status': true},
            {'id': 3, 'task': 'task 3', 'status': true},
          ]),
        ]),
      );
    });

    test('with order', () {
      final stream = client.from('todos').stream(['id']).order('id');
      expect(
        stream,
        emitsInOrder([
          containsAllInOrder([
            {'id': 2, 'task': 'task 2', 'status': false},
            {'id': 1, 'task': 'task 1', 'status': true},
          ]),
          containsAllInOrder([
            {'id': 3, 'task': 'task 3', 'status': true},
            {'id': 2, 'task': 'task 2', 'status': false},
            {'id': 1, 'task': 'task 1', 'status': true},
          ]),
          containsAllInOrder([
            {'id': 3, 'task': 'task 3', 'status': true},
            {'id': 2, 'task': 'task 2 updated', 'status': false},
            {'id': 1, 'task': 'task 1', 'status': true},
          ]),
          containsAllInOrder([
            {'id': 3, 'task': 'task 3', 'status': true},
            {'id': 1, 'task': 'task 1', 'status': true},
          ]),
        ]),
      );
    });

    test('with limit', () {
      final stream = client.from('todos').stream(['id']).order('id').limit(2);
      expect(
        stream,
        emitsInOrder([
          containsAllInOrder([
            {'id': 2, 'task': 'task 2', 'status': false},
            {'id': 1, 'task': 'task 1', 'status': true},
          ]),
          containsAllInOrder([
            {'id': 3, 'task': 'task 3', 'status': true},
            {'id': 2, 'task': 'task 2', 'status': false},
          ]),
          containsAllInOrder([
            {'id': 3, 'task': 'task 3', 'status': true},
            {'id': 2, 'task': 'task 2 updated', 'status': false},
          ]),
          containsAllInOrder([
            {'id': 3, 'task': 'task 3', 'status': true},
            {'id': 1, 'task': 'task 1', 'status': true},
          ]),
        ]),
      );
    });
  });

  group("rpc", () {
    test("rpc", () async {
      final data = await client.rpc("todos").select();
      expect(data, [
        {'id': 1, 'task': 'task 1', 'status': true},
        {'id': 2, 'task': 'task 2', 'status': false}
      ]);
    });

    test("rpc with custom headers", () async {
      apiKey = customApiKey;
      final data = await customHeadersClient.rpc("todos").select();
      expect(data, [
        {'id': 1, 'task': 'task 1', 'status': true},
        {'id': 2, 'task': 'task 2', 'status': false}
      ]);
    });
  });

  group('realtime', () {
    /// Constructing Supabase query within a realtime callback caused exception
    /// https://github.com/supabase-community/supabase-flutter/issues/81
    test('Calling Postgrest within realtime callback', () async {
      client.channel('todos').on(RealtimeListenTypes.postgresChanges,
          ChannelFilter(event: '*', schema: 'public', table: 'todos'), (event,
              [_]) async {
        client.from('todos');
      }).subscribe();

      await Future.delayed(const Duration(milliseconds: 700));

      await client.removeAllChannels();
    });
  });
}
