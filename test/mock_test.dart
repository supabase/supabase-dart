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
      } else if (url.contains('realtime')) {
        webSocket = await WebSocketTransformer.upgrade(request);
        if (!hasListener) {
          hasListener = true;
          webSocket!.listen((request) async {
            if (!hasSentData) {
              final topic = jsonDecode(request as String)['topic'];
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
                      'flags': ['key'],
                      'name': 'id',
                      'type': 'int4',
                      'type_modifier': 4294967295
                    },
                    {
                      'flags': [],
                      'name': 'task',
                      'type': 'text',
                      'type_modifier': 4294967295
                    },
                    {
                      'flags': [],
                      'name': 'status',
                      'type': 'bool',
                      'type_modifier': 4294967295
                    },
                  ],
                },
              });
              hasSentData = true;
              webSocket!.add(jsonString);
            }
          });
        }
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
        'http://${mockServer.address.host}:${mockServer.port}', 'supabaseKey');
    handleRequests(mockServer);
    hasListener = false;
    hasSentData = false;
  });

  tearDown(() async {
    await webSocket?.close();
    await mockServer.close();
  });

  test('test mock server', () async {
    final res = await client.from('todos').select('task, status').execute();
    expect(res.data.length, 2);
  });

  test('stream() emits data', () {
    final stream = client.from('todos').stream();
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
        ]));
  });

  test('Can filter stream results with eq', () {
    final stream = client.from('todos:status=eq.true').stream();
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
        ]));
  });
}
