import 'package:supabase/supabase.dart';
import 'package:test/test.dart';

void main() {
  const supabaseUrl = '';
  const supabaseKey = '';
  late SupabaseClient client;

  setUp(() {
    client = SupabaseClient(supabaseUrl, supabaseKey);
  });

  test('postgrest builder url', () async {
    final builder = client.from('users').select();
    expect(builder.url.toString(), '/rest/v1/users?select=%2A');
  });

  test('X-Client-Info header is set properly on auth', () {
    final xClientHeaderBeforeSlash =
        client.auth.api.headers['X-Client-Info']!.split('/').first;
    expect(xClientHeaderBeforeSlash, 'supabase-dart');
  });

  test('X-Client-Info header is set properly on postgrest', () {
    final xClientHeaderBeforeSlash =
        client.from('cats').headers['X-Client-Info']!.split('/').first;
    expect(xClientHeaderBeforeSlash, 'supabase-dart');
  });

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
}
