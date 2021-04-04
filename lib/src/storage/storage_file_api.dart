import 'dart:io';
import 'dart:typed_data';

import 'fetch.dart';
import 'types.dart';

const defaultSearchOptions = SearchOptions(
  limit: 100,
  offset: 0,
  sortBy: SortBy(
    column: 'name',
    order: 'asc',
  ),
);

const defaultFileOptions = FileOptions(
  cacheControl: '3600',
);

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
  Future<StorageResponse<String>> upload(String path, File file, {FileOptions? fileOptions}) async {
    try {
      final FileOptions options = fileOptions ?? defaultFileOptions;
      final formData = {
        '': file,
        'name': file.uri, // TODO This is not the correct API
        'cacheControl': options.cacheControl,
      };

      final _path = _getFinalPath(path);
      final response = await fetch.post(
        '$url/object/$_path',
        formData,
        options: FetchOptions(headers: headers),
      );

      if (response.hasError) {
        return StorageResponse(error: response.error);
      } else {
        return StorageResponse<String>(data: response.data.toString()); // TODO Correct format ?
      }
    } catch (e) {
      return StorageResponse(error: StorageError(e.toString()));
    }
  }

  /// Replaces an existing file at the specified path with a new one.
  ///
  /// @param path The relative file path including the bucket ID. Should be of the format `bucket/folder/subfolder`. The bucket already exist before attempting to upload.
  /// @param file The file object to be stored in the bucket.
  /// @param fileOptions HTTP headers. For example `cacheControl`
  Future<StorageResponse<String>> update(String path, File file, {FileOptions? fileOptions}) async {
    try {
      final FileOptions options = fileOptions ?? defaultFileOptions;
      final formData = {
        '': file,
        'name': file.uri, // TODO This is not the correct API
        'cacheControl': options.cacheControl,
      };

      final _path = _getFinalPath(path);
      final response = await fetch.put(
        '$url/object/$_path',
        formData,
        options: FetchOptions(headers: headers),
      );

      if (response.hasError) {
        return StorageResponse(error: response.error);
      } else {
        return StorageResponse<String>(data: response.data.toString()); // TODO Correct format ?
      }
    } catch (e) {
      return StorageResponse(error: StorageError(e.toString()));
    }
  }

  /// Moves an existing file, optionally renaming it at the same time.
  ///
  /// @param fromPath The original file path, including the current file name. For example `folder/image.png`.
  /// @param toPath The new file path, including the new file name. For example `folder/image-copy.png`.
  Future<StorageResponse<String>> move(String fromPath, String toPath) async {
    try {
      final options = FetchOptions(headers: headers);
      final response = await fetch.post(
        '$url/object/move',
        {
          'bucketId': bucketId,
          'sourceKey': fromPath,
          'destinationKey': toPath,
        },
        options: options,
      );
      if (response.hasError) {
        return StorageResponse(error: response.error);
      } else {
        return StorageResponse<String>(data: response.data.toString()); // TODO Correct format ?
      }
    } catch (e) {
      return StorageResponse(error: StorageError(e.toString()));
    }
  }

  /// Create signed url to download file without requiring permissions. This URL can be valid for a set number of seconds.
  ///
  /// @param path The file path to be downloaded, including the current file name. For example `folder/image.png`.
  /// @param expiresIn The number of seconds until the signed URL expires. For example, `60` for a URL which is valid for one minute.
  Future<StorageResponse<String>> createSignedUrl(String path, int expiresIn) async {
    try {
      final _path = _getFinalPath(path);
      final options = FetchOptions(headers: headers);
      final response = await fetch.post('$url}/object/sign/$_path', {expiresIn}, options: options);
      if (response.hasError) {
        return StorageResponse(error: response.error);
      } else {
        final signedUrl = '$url${response.data['signedUrl']}';
        return StorageResponse<String>(data: signedUrl);
      }
    } catch (e) {
      return StorageResponse(error: StorageError(e.toString()));
    }
  }

  /// Downloads a file.
  ///
  /// @param path The file path to be downloaded, including the path and file name. For example `folder/image.png`.
  Future<StorageResponse<Uint8List>> download(String path) async {
    try {
      final _path = _getFinalPath(path);
      final options = FetchOptions(headers: headers, noResolveJson: true);
      final response = await fetch.get('$url/object/$_path', options: options);
      if (response.hasError) {
        return StorageResponse(error: response.error);
      } else {
        return StorageResponse<Uint8List>(data: response.data as Uint8List);
      }
    } catch (e) {
      return StorageResponse(error: StorageError(e.toString()));
    }
  }

  /// Deletes files within the same bucket
  ///
  /// @param paths An array of files to be deletes, including the path and file name. For example [`folder/image.png`].
  Future<StorageResponse<List<FileObject>>> remove(List<String> paths) async {
    try {
      final options = FetchOptions(headers: headers);
      final response = await fetch.delete('$url/object/$bucketId', {'prefixes': paths}, options: options);
      if (response.hasError) {
        return StorageResponse(error: response.error);
      } else {
        final fileObjects = List<FileObject>.from((response.data as List).map((item) => FileObject.fromJson(item)));
        return StorageResponse<List<FileObject>>(data: fileObjects);
      }
    } catch (e) {
      return StorageResponse(error: StorageError(e.toString()));
    }
  }

  /// Lists all the files within a bucket.
  /// @param path The folder path.
  /// @param options Search options, including `limit`, `offset`, and `sortBy`.
  Future<StorageResponse<List<FileObject>>> list(
    String? path,
    SearchOptions? searchOptions,
  ) async {
    try {
      final Map<String, dynamic> body = {
        'prefix': path ?? '',
        'limit': searchOptions?.limit ?? defaultSearchOptions.limit,
        'offset': searchOptions?.offset ?? defaultSearchOptions.offset,
        'sort_by': searchOptions?.sortBy ?? defaultSearchOptions.sortBy,
      };
      final options = FetchOptions(headers: headers);
      final response = await fetch.post('$url/object/list/$bucketId', body, options: options);
      if (response.hasError) {
        return StorageResponse(error: response.error);
      } else {
        final fileObjects = List<FileObject>.from((response.data as List).map((item) => FileObject.fromJson(item)));
        return StorageResponse<List<FileObject>>(data: fileObjects);
      }
    } catch (e) {
      return StorageResponse(error: StorageError(e.toString()));
    }
  }

  String _getFinalPath(String path) {
    return '$bucketId/$path';
  }
}
