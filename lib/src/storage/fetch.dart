import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:supabase/src/storage/types.dart';

Fetch fetch = Fetch();

class StorageError {
  final String message;
  final String? error;
  final String? statusCode;

  StorageError(this.message, {this.error, this.statusCode});

  StorageError.fromJson(dynamic json)
      : assert(json is Map<String, dynamic>),
        message = json['message'] as String,
        error = json['error'] as String?,
        statusCode = json['statusCode'] as String?;

  @override
  String toString() => message;
}

class StorageResponse<T> {
  final StorageError? error;
  final T? data;

  StorageResponse({this.data, this.error});

  bool get hasError => error != null;
}

class FetchOptions {
  final Map<String, String>? headers;
  final bool? noResolveJson;

  FetchOptions({this.headers, this.noResolveJson});
}

class Fetch {
  bool _isSuccessStatusCode(int code) {
    return code >= 200 && code <= 299;
  }

  StorageError _handleError(dynamic error) {
    if (error is http.Response) {
      try {
        final data = json.decode(error.body) as Map<String, dynamic>;
        return StorageError.fromJson(data);
      } on FormatException catch (_) {
        return StorageError(error.body);
      }
    } else {
      return StorageError(error.toString());
    }
  }

  Future<StorageResponse> _handleRequest(
    String method,
    String url,
    dynamic body,
    FetchOptions? options,
  ) async {
    try {
      final headers = options?.headers ?? {};
      if (method != 'GET') {
        headers['Content-Type'] = 'application/json';
      }
      final bodyStr = json.encode(body ?? {});
      final request = http.Request(method, Uri.parse(url))
        ..headers.addAll(headers)
        ..body = bodyStr;

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (_isSuccessStatusCode(response.statusCode)) {
        if (options?.noResolveJson == true) {
          return StorageResponse(data: response.bodyBytes);
        } else {
          final jsonBody = json.decode(response.body);
          return StorageResponse(data: jsonBody);
        }
      } else {
        throw response;
      }
    } catch (e) {
      return StorageResponse(error: _handleError(e));
    }
  }

  Future<StorageResponse> _handleMultipartRequest(
    String method,
    String url,
    File file,
    FileOptions fileOptions,
    FetchOptions? options,
  ) async {
    try {
      final headers = options?.headers ?? {};
      if (method != 'GET') {
        headers['Content-Type'] = 'application/json';
      }
      final multipartFile = http.MultipartFile.fromBytes('', file.readAsBytesSync(), filename: file.path);
      final request = http.MultipartRequest(method, Uri.parse(url))
        ..headers.addAll(headers)
        ..files.add(multipartFile)
        ..fields['cacheControl'] = fileOptions.cacheControl;

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (_isSuccessStatusCode(response.statusCode)) {
        if (options?.noResolveJson == true) {
          return StorageResponse(data: response.bodyBytes);
        } else {
          final jsonBody = json.decode(response.body);
          return StorageResponse(data: jsonBody);
        }
      } else {
        throw response;
      }
    } catch (e) {
      return StorageResponse(error: _handleError(e));
    }
  }

  Future<StorageResponse> get(String url, {FetchOptions? options}) async {
    return _handleRequest('GET', url, {}, options);
  }

  Future<StorageResponse> post(String url, dynamic body, {FetchOptions? options}) async {
    return _handleRequest('POST', url, body, options);
  }

  Future<StorageResponse> put(String url, dynamic body, {FetchOptions? options}) async {
    return _handleRequest('PUT', url, body, options);
  }

  Future<StorageResponse> delete(String url, dynamic body, {FetchOptions? options}) async {
    return _handleRequest('DELETE', url, body, options);
  }

  Future<StorageResponse> postFile(String url, File file, FileOptions fileOptions, {FetchOptions? options}) async {
    return _handleMultipartRequest('POST', url, file, fileOptions, options);
  }

  Future<StorageResponse> putFile(String url, File file, FileOptions fileOptions, {FetchOptions? options}) async {
    return _handleMultipartRequest('PUT', url, file, fileOptions, options);
  }
}
