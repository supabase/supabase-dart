import 'package:supabase/supabase.dart';
import 'package:test/test.dart';

void main() {
  group('Standard Header', () {
    const supabaseUrl = '';
    const supabaseKey = '';
    late SupabaseClient client;

    setUp(() {
      client = SupabaseClient(supabaseUrl, supabaseKey);
    });

    // test('postgrest builder url', () async {
    //   final builder = client.from('users').select();
    //   expect(builder.url.toString(), '/rest/v1/users?select=%2A');
    // });

    test('X-Client-Info header is set properly on auth', () {
      final xClientHeaderBeforeSlash =
          client.auth.api.headers['X-Client-Info']!.split('/').first;
      expect(xClientHeaderBeforeSlash, 'supabase-dart');
    });

    // test('X-Client-Info header is set properly on postgrest', () {
    //   final xClientHeaderBeforeSlash =
    //       client.from('cats').headers['X-Client-Info']!.split('/').first;
    //   expect(xClientHeaderBeforeSlash, 'supabase-dart');
    // });

    test('X-Client-Info header is set properly on realtime', () {
      final xClientHeaderBeforeSlash =
          client.realtime.headers['X-Client-Info']!.split('/').first;
      expect(xClientHeaderBeforeSlash, 'supabase-dart');
    });

    test('X-Client-Info header is set properly on storage', () {
      final xClientHeaderBeforeSlash =
          client.storage.headers['X-Client-Info']!.split('/').first;
      expect(xClientHeaderBeforeSlash, 'supabase-dart');
    });
  });

  group('Custom Header', () {
    const supabaseUrl = '';
    const supabaseKey = '';
    late SupabaseClient client;

    setUp(() {
      client = SupabaseClient(
        supabaseUrl,
        supabaseKey,
        headers: {
          'X-Client-Info': 'supabase-flutter/0.0.0',
        },
      );
    });

    test('X-Client-Info header is set properly on auth', () {
      final xClientInfoHeader = client.auth.api.headers['X-Client-Info'];
      expect(xClientInfoHeader, 'supabase-flutter/0.0.0');
    });

    // test('X-Client-Info header is set properly on postgrest', () {
    //   final xClientInfoHeader = client.from('cats').headers['X-Client-Info'];
    //   expect(xClientInfoHeader, 'supabase-flutter/0.0.0');
    // });

    test('X-Client-Info header is set properly on realtime', () {
      final xClientInfoHeader = client.realtime.headers['X-Client-Info'];
      expect(xClientInfoHeader, 'supabase-flutter/0.0.0');
    });

    test('X-Client-Info header is set properly on storage', () {
      final xClientInfoHeader = client.storage.headers['X-Client-Info'];
      expect(xClientInfoHeader, 'supabase-flutter/0.0.0');
    });
  });
}
