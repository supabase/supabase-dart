import 'dart:io';
import 'dart:typed_data';

import 'package:mocktail/mocktail.dart';
import 'package:supabase/src/storage/fetch.dart';
import 'package:supabase/src/storage/types.dart';
import 'package:supabase/supabase.dart';
import 'package:test/test.dart';

const String supabaseUrl = 'SUPABASE_TEST_URL';
const String supabaseKey = 'SUPABASE_TEST_KEY';

class MockFetch extends Mock implements Fetch {}

void main() {
  late SupabaseClient client;

  setUp(() {
    client = SupabaseClient(supabaseUrl, supabaseKey);
    fetch = MockFetch();
    registerFallbackValue<FileOptions>(const FileOptions(cacheControl: '3600'));
  });

  tearDown(() {
    final file = File('a.txt');
    if (file.existsSync()) file.deleteSync();
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
    when(() => fetch.get('$supabaseUrl/storage/v1/bucket', options: any(named: "options")))
        .thenAnswer((_) => Future.value(StorageResponse(data: <Bucket>[])));

    final response = await client.storage.listBuckets();
    expect(response.error, isNull);
    expect(response.data, isA<List<Bucket>>());
  });

  test('should create bucket', () async {
    const testBucket = {
      'id': 'test_bucket',
      'name': 'test_bucket',
      'owner': '',
      'created_at': '',
      'updated_at': '',
    };
    when(() => fetch.post('$supabaseUrl/storage/v1/bucket', any(), options: any(named: "options")))
        .thenAnswer((_) => Future.value(StorageResponse(data: testBucket)));

    final response = await client.storage.createBucket('test_bucket');
    expect(response.error, isNull);
    expect(response.data, isA<Bucket>());
    expect(response.data?.name, 'test_bucket');
    expect(response.data?.id, 'test_bucket');
  });

  test('should get bucket', () async {
    const testBucket = {
      'id': 'test_bucket',
      'name': 'test_bucket',
      'owner': '',
      'created_at': '',
      'updated_at': '',
    };
    when(() => fetch.get('$supabaseUrl/storage/v1/bucket/test_bucket', options: any(named: "options")))
        .thenAnswer((_) => Future.value(StorageResponse(data: testBucket)));

    final response = await client.storage.getBucket('test_bucket');
    expect(response.error, isNull);
    expect(response.data, isA<Bucket>());
    expect(response.data?.id, 'test_bucket');
    expect(response.data?.name, 'test_bucket');
  });

  test('should empty bucket', () async {
    when(() => fetch.post('$supabaseUrl/storage/v1/bucket/test_bucket/empty', {}, options: any(named: "options")))
        .thenAnswer((_) => Future.value(StorageResponse(data: {'message': 'Emptied'})));

    final response = await client.storage.emptyBucket('test_bucket');
    expect(response.error, isNull);
    expect(response.data, 'Emptied');
  });

  test('should delete bucket', () async {
    when(() => fetch.delete('$supabaseUrl/storage/v1/bucket/test_bucket', {}, options: any(named: "options")))
        .thenAnswer((_) => Future.value(StorageResponse(data: {'message': 'Deleted'})));

    final response = await client.storage.deleteBucket('test_bucket');
    expect(response.error, isNull);
    expect(response.data, 'Deleted');
  });

  test('should upload file', () async {
    final file = File('a.txt');
    file.writeAsStringSync('File content');

    when(() =>
            fetch.postFile('$supabaseUrl/storage/v1/object/public/a.txt', file, any(), options: any(named: "options")))
        .thenAnswer((_) => Future.value(StorageResponse(data: {'Key': 'public/a.txt'})));

    final response = await client.storage.from('public').upload('a.txt', file);
    expect(response.error, isNull);
    expect(response.data, isA<String>());
    expect(response.data?.endsWith('/a.txt'), isTrue);
  });

  test('should update file', () async {
    final file = File('a.txt');
    file.writeAsStringSync('Updated content');

    when(() =>
            fetch.putFile('$supabaseUrl/storage/v1/object/public/a.txt', file, any(), options: any(named: "options")))
        .thenAnswer((_) => Future.value(StorageResponse(data: {'Key': 'public/a.txt'})));

    final response = await client.storage.from('public').update('a.txt', file);
    expect(response.error, isNull);
    expect(response.data, isA<String>());
    expect(response.data?.endsWith('/a.txt'), isTrue);
  });

  test('should move file', () async {
    when(() => fetch.post('$supabaseUrl/storage/v1/object/move', any(), options: any(named: "options")))
        .thenAnswer((_) => Future.value(StorageResponse(data: {'message': 'Move'})));

    final response = await client.storage.from('public').move('a.txt', 'b.txt');
    expect(response.error, isNull);
    expect(response.data, 'Move');
  });

  test('should createSignedUrl file', () async {
    when(() => fetch.post('$supabaseUrl/storage/v1/object/sign/public/b.txt', any(), options: any(named: "options")))
        .thenAnswer((_) => Future.value(StorageResponse(data: {'signedURL': 'url'})));

    final response = await client.storage.from('public').createSignedUrl('b.txt', 60);
    expect(response.error, isNull);
    expect(response.data, isA<String>());
  });

  test('should list files', () async {
    final fileObjects = [
      {
        'name': 'hello',
        'id': '',
        'bucket_id': '',
        'owner': '',
        'updated_at': '',
        'created_at': '',
        'last_accessed_at': '',
        'buckets': {
          'id': '',
          'name': '',
          'owner': '',
          'created_at': '',
          'updated_at': '',
        }
      }
    ];
    when(() => fetch.post('$supabaseUrl/storage/v1/object/list/public', any(), options: any(named: "options")))
        .thenAnswer((_) => Future.value(StorageResponse(data: fileObjects)));

    final response = await client.storage.from('public').list();
    expect(response.error, isNull);
    expect(response.data, isA<List<FileObject>>());
  });

  test('should download file', () async {
    final file = File('a.txt');
    file.writeAsStringSync('Updated content');

    when(() => fetch.get('$supabaseUrl/storage/v1/object/public/b.txt', options: any(named: "options")))
        .thenAnswer((_) => Future.value(StorageResponse(data: file.readAsBytesSync())));

    final response = await client.storage.from('public').download('b.txt');
    expect(response.error, isNull);
    expect(response.data, isA<Uint8List>());
    expect(String.fromCharCodes(response.data!), 'Updated content');
  });

  test('should remove file', () async {
    final requestBody = {
      'prefixes': ['a.txt', 'b.txt']
    };
    final fileObjects = [
      {
        'name': 'hello',
        'id': '',
        'bucket_id': '',
        'owner': '',
        'updated_at': '',
        'created_at': '',
        'last_accessed_at': '',
        'buckets': {
          'id': '',
          'name': '',
          'owner': '',
          'created_at': '',
          'updated_at': '',
        }
      }
    ];

    when(() => fetch.delete('$supabaseUrl/storage/v1/object/public', requestBody, options: any(named: "options")))
        .thenAnswer((_) => Future.value(StorageResponse(data: fileObjects)));

    final response = await client.storage.from('public').remove(['a.txt', 'b.txt']);
    expect(response.error, isNull);
    expect(response.data, isA<List>());
    expect(response.data?.length, 1);
  });
}
