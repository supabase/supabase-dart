import 'dart:convert';
import 'dart:io';

import 'package:supabase/supabase.dart';
import 'package:test/test.dart';

void main() {
  late SupabaseClient client;
  late HttpServer mockServer;

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
  });

  tearDown(() async {
    await mockServer.close();
  });

  test('test mock server', () async {
    final res = await client.from('todos').select('task, status').execute();
    expect(res.data.length, 2);
  });
}
