import 'package:supabase/src/storage/fetch.dart';
import 'package:supabase/src/storage/types.dart';

class StorageBucketApi {
  StorageBucketApi(this.url, this.headers);

  final String url;
  final Map<String, String> headers;

  /// Retrieves the details of all Storage buckets within an existing product.
  Future<List<Bucket>> listBuckets() async {
    final FetchOptions options = FetchOptions(headers: headers);
    final data = await callGet('$url/bucket', options);
    return List.from((data as List).map((value) => Bucket.fromJson(value)));
  }

  /// Retrieves the details of an existing Storage bucket.
  ///
  /// @param id The unique identifier of the bucket you would like to retrieve.
  Future<Bucket> getBucket(String id) async {
    final FetchOptions options = FetchOptions(headers: headers);
    final data = await callGet('$url/bucket/$id', options);
    return Bucket.fromJson(data);
  }

  /// Creates a new Storage bucket
  ///
  /// @param id A unique identifier for the bucket you are creating.
  Future<Bucket> createBucket(String id) async {
    final FetchOptions options = FetchOptions(headers: headers);
    final data = await callPost('$url/bucket', {'id': id, 'name': id}, options);
    return Bucket.fromJson(data);
  }

  /// Removes all objects inside a single bucket.
  ///
  /// @param id The unique identifier of the bucket you would like to empty.
  Future<String> emptyBucket(String id) async {
    final FetchOptions options = FetchOptions(headers: headers);
    final data = await callPost('$url/bucket/$id/empty', {}, options);
    return data['message'] as String;
  }

  /// Deletes an existing bucket. A bucket can't be deleted with existing objects inside it.
  /// You must first `emptyBucket()` the bucket.
  ///
  /// @param id The unique identifier of the bucket you would like to delete.
  Future<String> deleteBucket(String id) async {
    final FetchOptions options = FetchOptions(headers: headers);
    final data = await callRemove('$url/bucket/$id', {}, options);
    return data['message'] as String;
  }
}
