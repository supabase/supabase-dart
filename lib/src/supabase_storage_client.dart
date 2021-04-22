import 'package:supabase/src/storage/storage_bucket_api.dart';
import 'package:supabase/src/storage/storage_file_api.dart';

class SupabaseStorageClient extends StorageBucketApi {
  SupabaseStorageClient(String url, Map<String, String> headers)
      : super(url, headers);

  /// Perform file operation in a bucket.
  ///
  /// @param id The bucket id to operate on.
  StorageFileApi from(String id) {
    return StorageFileApi(url, headers, id);
  }
}
