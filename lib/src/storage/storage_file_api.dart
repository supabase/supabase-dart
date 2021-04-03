import 'dart:html';

import 'package:supabase/src/storage/fetch.dart';
import 'package:supabase/src/storage/types.dart';

const defaultSearchOptions = {
  'limit': 100,
  'offset': 0,
  'sortBy': {
    'column': 'name',
    'order': 'asc',
  },
};

const defaultFileOptions = FileOptions(cacheControl: '3600');

class StorageFileApi {
  StorageFileApi(this.url, this.headers, this.bucketId);

  final String url;
  final Map<String, String> headers;
  final String? bucketId;

  /// Uploads a file to an existing bucket.
  ///
  /// @param path The relative file path including the bucket ID. Should be of the format `bucket/folder/subfolder/filename.png`. The bucket must already exist before attempting to upload.
  /// @param file The File object to be stored in the bucket.
  /// @param fileOptions HTTP headers. For example `cacheControl`
  Future<String> upload(
    String path,
    File file,
    {FileOptions? fileOptions} 
  ) async {
      final formData = FormData();
      formData.appendBlob('', file, file.name);

      final FileOptions options = { ...defaultFileOptions, ...fileOptions };
      formData.append('cacheControl', options.cacheControl);

      final _path = _getFinalPath(path);
      final res = await fetch('$url/object/$_path', {
        'method': 'POST',
        'body': formData,
        'headers': { ...headers },
      });

      if (res.ok) {
        const data = res.toJson()
        return data;
      } else {
        const error = res.toJson()
        throw error;
      }
  }

  /// Replaces an existing file at the specified path with a new one.
  ///
  /// @param path The relative file path including the bucket ID. Should be of the format `bucket/folder/subfolder`. The bucket already exist before attempting to upload.
  /// @param file The file object to be stored in the bucket.
  /// @param fileOptions HTTP headers. For example `cacheControl`
  Future<String> update(
    String path,
    File file,
    {FileOptions? fileOptions}
  ) async {
      final formData = FormData();
      formData.appendBlob('', file, file.name);

      final FileOptions options = { ...defaultFileOptions, ...fileOptions };
      formData.append('cacheControl', options.cacheControl);

      final _path = _getFinalPath(path);
      final res = await fetch('$url/object/$_path', {
        'method': 'PUT',
        'body': formData,
        'headers': { ...headers },
      });

      if (res.ok) {
        const data = res.toJson()
        return data;
      } else {
        const error = res.toJson()
        throw error;
      }
  }

  /// Moves an existing file, optionally renaming it at the same time.
  ///
  /// @param fromPath The original file path, including the current file name. For example `folder/image.png`.
  /// @param toPath The new file path, including the new file name. For example `folder/image-copy.png`.
  Future<String> move(
    String fromPath,
    String toPath
  ) async {
      final options = FetchOptions(headers: headers);
      final data = await callPost(
        '$url/object/move',
        { 'bucketId': bucketId, 'sourceKey': fromPath, 'destinationKey': toPath },
        options
      );
      return data;
  }

  /// Create signed url to download file without requiring permissions. This URL can be valid for a set number of seconds.
  ///
  /// @param path The file path to be downloaded, including the current file name. For example `folder/image.png`.
  /// @param expiresIn The number of seconds until the signed URL expires. For example, `60` for a URL which is valid for one minute.
  Future<String> createSignedUrl(
    String path,
    int expiresIn
  ) async {
      final _path = _getFinalPath(path);
      final options = FetchOptions(headers: headers);
      var data = await callPost(
        '$url}/object/sign/$_path',
        { expiresIn },
        options
      );
      final signedUrl = '$url${data['signedUrl']}';
      data = { ...data, signedUrl };
      return data;
  }

  /// Downloads a file.
  ///
  /// @param path The file path to be downloaded, including the path and file name. For example `folder/image.png`.
  Future<Blob> download(String path) async {
      final _path = _getFinalPath(path);
      final options = FetchOptions(headers: headers, noResolveJson: true);
      final res = await callGet('$url/object/$_path', options);
      final data = await res.blob();
      return data;

  }

  /// Deletes files within the same bucket
  ///
  /// @param paths An array of files to be deletes, including the path and file name. For example [`folder/image.png`].
  Future<List<FileObject>> remove(List<String> paths) async {
      final options = FetchOptions(headers: headers);
      final data = await callRemove(
        '$url/object/$bucketId',
        { 'prefixes': paths },
        options
      );
      return data;
  }

  /// Lists all the files within a bucket.
  /// @param path The folder path.
  /// @param options Search options, including `limit`, `offset`, and `sortBy`.
  Future<List<FileObject>> list(
    String? path,
    SearchOptions? searchOptions, 
  ) async {
      final Map body = { ...defaultSearchOptions, ...searchOptions, prefix: path ?? '' };
      final options = FetchOptions(headers: headers);
      final data = await callPost('$url/object/list/$bucketId', body ,options);
      return data;
  }

  String _getFinalPath(String path) {
    return '$bucketId/$path';
  }
}