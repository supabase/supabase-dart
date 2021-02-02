import 'package:supabase/supabase.dart';

void main() async {
  const supabaseUrl = '';
  const supabaseKey = '';
  final client = SupabaseClient(supabaseUrl, supabaseKey);
  final response = await client
      .from('countries')
      .select()
      .order('name', ascending: true)
      .execute();
  if (response.error == null) {
    print('response.data: ${response.data}');
  }
}
