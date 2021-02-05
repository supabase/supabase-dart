import 'package:supabase/supabase.dart';

void main() async {
  const supabaseUrl = '';
  const supabaseKey = '';
  final client = SupabaseClient(supabaseUrl, supabaseKey);

  // query data
  final response = await client
      .from('countries')
      .select()
      .order('name', ascending: true)
      .execute();
  if (response.error == null) {
    print('response.data: ${response.data}');
  }

  // realtime
  final supscription1 =
      client.from('countries').on(SupabaseEventTypes.delete, (x) {
    print('on countries.delete: ${x.table} ${x.eventType} ${x.oldRecord}');
  }).subscribe((String event, {String errorMsg}) {
    print('event: $event error: $errorMsg');
  });

  final supscription2 = client.from('todos').on(SupabaseEventTypes.insert, (x) {
    print('on todos.insert: ${x.table} ${x.eventType} ${x.newRecord}');
  }).subscribe((String event, {String errorMsg}) {
    print('event: $event error: $errorMsg');
  });

  // remember to remove subscription
  client.removeSubscription(supscription1);
  client.removeSubscription(supscription2);
}
