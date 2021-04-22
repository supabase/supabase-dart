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

FileOptions get mockFileOptions => any<FileOptions>();

FetchOptions get mockFetchOptions => any<FetchOptions>(named: 'options');

Map<String, dynamic> get testBucketJson => {
      'id': 'test_bucket',
      'name': 'test_bucket',
      'owner': 'owner_id',
      'created_at': '',
      'updated_at': '',
    };

Map<String, dynamic> get testFileObjectJson => {
      'name': 'test_bucket',
      'id': 'test_bucket',
      'bucket_id': 'public',
      'owner': 'owner_id',
      'updated_at': null,
      'created_at': null,
      'last_accessed_at': null,
      'buckets': testBucketJson
    };

String get bucketUrl => '$supabaseUrl/storage/v1/bucket';

String get objectUrl => '$supabaseUrl/storage/v1/object';

void main() {
  late SupabaseClient client;

  setUp(() {
    // init SupabaseClient with test url & test key
    client = SupabaseClient(supabaseUrl, supabaseKey);

    // Use mocked version for `fetch`, to prevent actual http calls.
    fetch = MockFetch();

    // Register default mock values (used by mocktail)
    registerFallbackValue<FileOptions>(const FileOptions(cacheControl: '3600'));
    registerFallbackValue<FetchOptions>(FetchOptions());
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
    when(() => fetch.get(bucketUrl, options: mockFetchOptions)).thenAnswer(
        (_) => Future.value(
            StorageResponse(data: [testBucketJson, testBucketJson])));

    final response = await client.storage.listBuckets();
    expect(response.error, isNull);
    expect(response.data, isA<List<Bucket>>());
  });

  test('should create bucket', () async {
    const testBucketId = 'test_bucket';
    const requestBody = {'id': testBucketId, 'name': testBucketId};
    when(() => fetch.post(bucketUrl, requestBody, options: mockFetchOptions))
        .thenAnswer((_) => Future.value(StorageResponse(data: testBucketJson)));

    final response = await client.storage.createBucket(testBucketId);
    expect(response.error, isNull);
    expect(response.data, isA<Bucket>());
    expect(response.data?.name, testBucketId);
    expect(response.data?.id, testBucketId);
  });

  test('should get bucket', () async {
    const testBucketId = 'test_bucket';
    when(() => fetch.get('$bucketUrl/$testBucketId', options: mockFetchOptions))
        .thenAnswer((_) => Future.value(StorageResponse(data: testBucketJson)));

    final response = await client.storage.getBucket(testBucketId);
    expect(response.error, isNull);
    expect(response.data, isA<Bucket>());
    expect(response.data?.id, testBucketId);
    expect(response.data?.name, testBucketId);
  });

  test('should empty bucket', () async {
    const testBucketId = 'test_bucket';
    when(() => fetch.post('$bucketUrl/$testBucketId/empty', {},
            options: mockFetchOptions))
        .thenAnswer(
            (_) => Future.value(StorageResponse(data: {'message': 'Emptied'})));

    final response = await client.storage.emptyBucket(testBucketId);
    expect(response.error, isNull);
    expect(response.data, 'Emptied');
  });

  test('should delete bucket', () async {
    const testBucketId = 'test_bucket';
    when(() => fetch.delete('$bucketUrl/$testBucketId', {},
            options: mockFetchOptions))
        .thenAnswer(
            (_) => Future.value(StorageResponse(data: {'message': 'Deleted'})));

    final response = await client.storage.deleteBucket(testBucketId);
    expect(response.error, isNull);
    expect(response.data, 'Deleted');
  });

  test('should upload file', () async {
    final file = File('a.txt');
    file.writeAsStringSync('File content');

    when(() =>
        fetch.postFile('$objectUrl/public/a.txt', file, mockFileOptions,
            options: mockFetchOptions)).thenAnswer(
        (_) => Future.value(StorageResponse(data: {'Key': 'public/a.txt'})));

    final response = await client.storage.from('public').upload('a.txt', file);
    expect(response.error, isNull);
    expect(response.data, isA<String>());
    expect(response.data?.endsWith('/a.txt'), isTrue);
  });

  test('should update file', () async {
    final file = File('a.txt');
    file.writeAsStringSync('Updated content');

    when(() =>
        fetch.putFile('$objectUrl/public/a.txt', file, mockFileOptions,
            options: mockFetchOptions)).thenAnswer(
        (_) => Future.value(StorageResponse(data: {'Key': 'public/a.txt'})));

    final response = await client.storage.from('public').update('a.txt', file);
    expect(response.error, isNull);
    expect(response.data, isA<String>());
    expect(response.data?.endsWith('/a.txt'), isTrue);
  });

  test('should move file', () async {
    const requestBody = {
      'bucketName': 'public',
      'sourceKey': 'a.txt',
      'destinationKey': 'b.txt',
    };
    when(() => fetch.post('$objectUrl/move', requestBody,
            options: mockFetchOptions))
        .thenAnswer(
            (_) => Future.value(StorageResponse(data: {'message': 'Move'})));

    final response = await client.storage.from('public').move('a.txt', 'b.txt');
    expect(response.error, isNull);
    expect(response.data, 'Move');
  });

  test('should createSignedUrl file', () async {
    when(() => fetch.post('$objectUrl/sign/public/b.txt', {'expiresIn': 60},
            options: mockFetchOptions))
        .thenAnswer(
            (_) => Future.value(StorageResponse(data: {'signedURL': 'url'})));

    final response =
        await client.storage.from('public').createSignedUrl('b.txt', 60);
    expect(response.error, isNull);
    expect(response.data, isA<String>());
  });

  test('should list files', () async {
    when(() => fetch.post('$objectUrl/list/public', any(),
            options: mockFetchOptions))
        .thenAnswer((_) => Future.value(
            StorageResponse(data: [testFileObjectJson, testFileObjectJson])));

    final response = await client.storage.from('public').list();
    expect(response.error, isNull);
    expect(response.data, isA<List<FileObject>>());
    expect(response.data?.length, 2);
  });

  test('should download file', () async {
    final file = File('a.txt');
    file.writeAsStringSync('Updated content');

    when(() => fetch.get('$objectUrl/public/b.txt', options: mockFetchOptions))
        .thenAnswer(
            (_) => Future.value(StorageResponse(data: file.readAsBytesSync())));

    final response = await client.storage.from('public').download('b.txt');
    expect(response.error, isNull);
    expect(response.data, isA<Uint8List>());
    expect(String.fromCharCodes(response.data!), 'Updated content');
  });

  test('should remove file', () async {
    final requestBody = {
      'prefixes': ['a.txt', 'b.txt']
    };
    when(() => fetch.delete('$objectUrl/public', requestBody,
            options: mockFetchOptions))
        .thenAnswer((_) => Future.value(
            StorageResponse(data: [testFileObjectJson, testFileObjectJson])));

    final response =
        await client.storage.from('public').remove(['a.txt', 'b.txt']);
    expect(response.error, isNull);
    expect(response.data, isA<List>());
    expect(response.data?.length, 2);
  });
}
