import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:supabase/supabase.dart';
import 'package:test/test.dart';

void main() {
  late SupabaseClient client;
  late HttpServer mockServer;
  WebSocket? webSocket;
  bool hasListener = false;
  bool hasSentData = false;
  StreamSubscription<dynamic>? listener;

  Future<void> handleRequests(HttpServer server) async {
    await for (final HttpRequest request in server) {
      final url = request.uri.toString();
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
      } else if (url == '/rest/v1/todos?select=%2A') {
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
          await Future.delayed(const Duration(milliseconds: 10));
          final topic = (jsonDecode(request as String) as Map)['topic'];
          final jsonString = jsonEncode({
            'topic': topic,
            'event': 'INSERT',
            'ref': null,
            'payload': {
              'commit_timestamp': '2021-08-01T08:00:20Z',
              'record': {'id': 3, 'task': 'task 3', 'status': 't'},
              'schema': 'public',
              'table': 'todos',
              'type': 'INSERT',
              'columns': [
                {
                  'name': 'id',
                  'type': 'int4',
                  'type_modifier': 4294967295,
                },
                {'name': 'task', 'type': 'text', 'type_modifier': 4294967295},
                {'name': 'status', 'type': 'bool', 'type_modifier': 4294967295},
              ],
            },
          });
          webSocket!.add(jsonString);
        });
      } else {
        request.response
          ..statusCode = HttpStatus.ok
          ..close();
      }
    }
  }

  setUp(() async {
    mockServer = await HttpServer.bind('localhost', 0);
    client = SupabaseClient(
      'http://${mockServer.address.host}:${mockServer.port}',
      'supabaseKey',
    );
    handleRequests(mockServer);
    hasListener = false;
    hasSentData = false;
  });

  tearDown(() async {
    listener?.cancel();
    await webSocket?.close();
    await mockServer.close();
  });

  test('test mock server', () async {
    final data = await client.from('todos').select('task, status');
    expect((data as List).length, 2);
  });

  group('stream()', () {
    test('stream() emits data', () {
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
        ]),
      );
    });

    test('Can filter stream results with eq', () {
      final stream = client.from('todos:status=eq.true').stream(['id']);
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

    test('stream() with order', () {
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
        ]),
      );
    });

    test('stream() with limit', () {
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
        ]),
      );
    });
  });

  group('realtime', () {
    /// Constructing Supabase query within a realtime callback caused exception
    /// https://github.com/supabase-community/supabase-flutter/issues/81
    test('Calling Postgrest within realtime callback', () async {
      client.channel('todos').on(RealtimeListenTypes.postgresChanges,
          ChannelFilter(event: '*', schema: 'public', table: 'todos'), (event,
              [_]) async {
        await client.from('todos').select('task, status');
      }).subscribe();

      await Future.delayed(const Duration(milliseconds: 700));

      await client.removeAllChannels();
    });
  });
}
