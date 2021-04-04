import 'package:supabase/src/storage/types.dart';
import 'package:supabase/supabase.dart';
import 'package:test/test.dart';

import 'test_env.dart';

void main() {
  late SupabaseClient client;

  setUp(() {
    client = SupabaseClient(supabaseUrl, supabaseKey);
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
    expect(response.data, []);
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
}
