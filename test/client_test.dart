import 'package:supabase/supabase.dart';
import 'package:test/test.dart';

void main() {
  const supabaseUrl = '';
  const supabaseKey = '';
  SupabaseClient client;

  setUp(() {
    client = SupabaseClient(supabaseUrl, supabaseKey);
  });
}
