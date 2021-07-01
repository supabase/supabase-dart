import 'dart:io';

import 'package:supabase/supabase.dart';

Future<void> main() async {
  const supabaseUrl = '';
  const supabaseKey = '';
  final client = SupabaseClient(supabaseUrl, supabaseKey);

  // query data
  final response = await client
      .from('countries')
      .select()
      .order('name', ascending: true)
      .execute(count: CountOption.exact);
  if (response.error == null) {
    print('response.data: ${response.data}');
  }

  // realtime
  final subscription1 =
      client.from('countries').on(SupabaseEventTypes.delete, (x) {
    print('on countries.delete: ${x.table} ${x.eventType} ${x.oldRecord}');
  }).subscribe((String event, {String? errorMsg}) {
    print('event: $event error: $errorMsg');
  });

  final subscription2 = client.from('todos').on(SupabaseEventTypes.insert, (x) {
    print('on todos.insert: ${x.table} ${x.eventType} ${x.newRecord}');
  }).subscribe((String event, {String? errorMsg}) {
    print('event: $event error: $errorMsg');
  });

  // remember to remove subscription
  client.removeSubscription(subscription1);
  client.removeSubscription(subscription2);

  // Upload file to bucket "public"
  final file = File('example.txt');
  file.writeAsStringSync('File content');
  final storageResponse =
      await client.storage.from('public').upload('example.txt', file);
  print('upload response : ${storageResponse.data}');

  // Get download url
  final urlResponse =
      await client.storage.from('public').createSignedUrl('example.txt', 60);
  print('download url : ${urlResponse.data}');

  // Download text file
  final fileResponse =
      await client.storage.from('public').download('example.txt');
  if (fileResponse.hasError) {
    print('Error while downloading file : ${fileResponse.error}');
  } else {
    print('downloaded file : ${String.fromCharCodes(fileResponse.data!)}');
  }

  // Delete file
  final deleteResponse =
      await client.storage.from('public').remove(['example.txt']);
  print('deleted file id : ${deleteResponse.data?.first.id}');

  // Local file cleanup
  if (file.existsSync()) file.deleteSync();
}
