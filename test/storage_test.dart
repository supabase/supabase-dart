import 'dart:io';
import 'dart:typed_data';

import 'package:supabase/src/storage/types.dart';
import 'package:supabase/supabase.dart';
import 'package:test/test.dart';

// Note: Theses tests require a working Supabase project with Storage Policies configured as follows:
// DELETE, SELECT, UPDATE & INSERT policies are set to `true` for both Objects & Buckets

final String supabaseUrl = Platform.environment['SUPABASE_TEST_URL'] ?? '';
final String supabaseKey = Platform.environment['SUPABASE_TEST_KEY'] ?? '';

void main() {
  late SupabaseClient client;

  setUp(() {
    client = SupabaseClient(supabaseUrl, supabaseKey);
  });

  tearDown(() {
    final file = File('a.txt');
    if (file.existsSync()) file.deleteSync();
  });

  test('env variables are set', () {
    expect(supabaseUrl, isNotEmpty, reason: 'SUPABASE_TEST_URL env variable is required');
    expect(supabaseKey, isNotEmpty, reason: 'SUPABASE_TEST_KEY env variable is required');
  });

  test('should have correct storage url', () {
    expect(client.storage.url, '$supabaseUrl/storage/v1');
  });

  test('should have correct headers', () {
    expect(client.storage.headers, {
      'apikey': supabaseKey,
      'Authorization': 'Bearer $supabaseKey',
    });
  });

  test('should list buckets', () async {
    final response = await client.storage.listBuckets();
    expect(response.error, isNull);
    expect(response.data, isA<List<Bucket>>());
  });

  test('should create bucket', () async {
    final response = await client.storage.createBucket('test_bucket');
    expect(response.error, isNull);
    expect(response.data, isA<Bucket>());
    expect(response.data?.name, 'test_bucket');
    expect(response.data?.id, 'test_bucket');
  });

  test('should get bucket', () async {
    final response = await client.storage.getBucket('test_bucket');
    expect(response.error, isNull);
    expect(response.data, isA<Bucket>());
    expect(response.data?.id, 'test_bucket');
    expect(response.data?.name, 'test_bucket');
  });

  test('should empty bucket', () async {
    final response = await client.storage.emptyBucket('test_bucket');
    expect(response.error, isNull);
    expect(response.data, 'Emptied');
  });

  test('should delete bucket', () async {
    final response = await client.storage.deleteBucket('test_bucket');
    expect(response.error, isNull);
    expect(response.data, 'Deleted');
  });

  test('should upload file', () async {
    final file = File('a.txt');
    file.writeAsStringSync('File content');
    final response = await client.storage.from('public').upload('a.txt', file);
    expect(response.error, isNull);
    expect(response.data, isA<String>());
    expect(response.data?.endsWith('/a.txt'), isTrue);
  });
  
  test('should update file', () async {
    final file = File('a.txt');
    file.writeAsStringSync('Updated content');
    final response = await client.storage.from('public').update('a.txt', file);
    expect(response.error, isNull);
    expect(response.data, isA<String>());
    expect(response.data?.endsWith('/a.txt'), isTrue);
  });

  test('should move file', () async {
    final response = await client.storage.from('public').move('a.txt', 'b.txt');
    expect(response.error, isNull);
    expect(response.data, 'Move');
  });

  test('should createSignedUrl file', () async {
    final response = await client.storage.from('public').createSignedUrl('b.txt', 60);
    expect(response.error, isNull);
    expect(response.data, isA<String>());
  });

  test('should list files', () async {
    final response = await client.storage.from('public').list();
    expect(response.error, isNull);
    expect(response.data, isA<List<FileObject>>());
  });

  test('should download file', () async {
    final response = await client.storage.from('public').download('b.txt');
    expect(response.error, isNull);
    expect(response.data, isA<Uint8List>());
    expect(String.fromCharCodes(response.data!), 'Updated content');
  });

  test('should remove file', () async {
    final response = await client.storage.from('public').remove(['b.txt']);
    expect(response.error, isNull);
    expect(response.data, isA<List>());
    expect(response.data?.length, 1);
  });
}
