import 'package:supabase/supabase.dart';
import 'package:test/test.dart';

void main() {
  const supabaseUrl = '';
  const supabaseKey = '';
  SupabaseClient client;

  setUp(() {
    client = SupabaseClient(supabaseUrl, supabaseKey);
  });

  test('postgrest builder url', () async {
    final builder = client.from('users').select();
    expect(builder.url.toString(), '/rest/v1/users?select=%2A');
  });
}
