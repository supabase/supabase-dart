import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:supabase/src/storage/types.dart';

final fetch = Fetch();

class StorageError {
  final String message;

  StorageError(this.message);

  @override
  String toString() => message;
}

class StorageResponse<T> {
  final StorageError? error;
  final T? data;

  bool get hasError => error != null;

  StorageResponse({this.data, this.error});
}

class FetchOptions {
  FetchOptions({this.headers, this.noResolveJson});

  final Map<String, String>? headers;
  final bool? noResolveJson;
}

class Fetch {
  // Map<String, dynamic> _getRequestParams(String method, {FetchOptions? options, dynamic body}) {
  //   final Map<String, dynamic> params = {'method': method, 'headers': options?.headers ?? {}};

  //   if (method == 'GET') {
  //     return params;
  //   }

  //   params['headers'] = {'Content-Type': 'application/json', ...options?.headers ?? {}};
  //   params['body'] = body.toString();

  //   return params;
  // }

  bool isSuccessStatusCode(int code) {
    return code >= 200 && code <= 299;
  }

  StorageError handleError(dynamic error) {
    if (error is http.Response) {
      try {
        final parsedJson = json.decode(error.body) as Map<String, dynamic>;
        final message = parsedJson['msg'] ??
            parsedJson['message'] ??
            parsedJson['error_description'] ??
            parsedJson['error'] ??
            json.encode(parsedJson);
        return StorageError(message as String);
      } on FormatException catch (_) {
        return StorageError(error.body);
      }
    } else {
      return StorageError(error.toString());
    }
  }

  Future<StorageResponse> get(String url, {FetchOptions? options}) async {
    try {
      final client = http.Client();
      final headers = options?.headers ?? {};
      final http.Response response = await client.get(Uri.parse(url), headers: headers);
      if (isSuccessStatusCode(response.statusCode)) {
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
      return StorageResponse(error: handleError(e));
    }
  }

  Future<StorageResponse> post(String url, dynamic body, {FetchOptions? options}) async {
    try {
      final client = http.Client();
      final bodyStr = json.encode(body ?? {});
      final headers = options?.headers ?? {};
      headers['Content-Type'] = 'application/json';
      final http.Response response = await client.post(Uri.parse(url), headers: headers, body: bodyStr);

      if (isSuccessStatusCode(response.statusCode)) {
        if (options?.noResolveJson == true) {
          return StorageResponse(data: response.body);
        } else {
          final jsonBody = json.decode(response.body);
          return StorageResponse(data: jsonBody);
        }
      } else {
        throw response.body;
      }
    } catch (e) {
      return StorageResponse(error: handleError(e));
    }
  }

  Future<StorageResponse> postFile(String url, File file, FileOptions fileOptions, {FetchOptions? options}) async {
    try {
      final headers = options?.headers ?? {};
      final body = http.MultipartFile.fromBytes('', file.readAsBytesSync(), filename: file.path);
      final request = http.MultipartRequest('POST', Uri.parse(url))
        ..headers.addAll(headers)
        ..files.add(body);
      final response = await request.send();

      if (isSuccessStatusCode(response.statusCode)) {
        if (options?.noResolveJson == true) {
          return StorageResponse(data: await response.stream.bytesToString());
        } else {
          final jsonBody = json.decode(await response.stream.bytesToString());
          return StorageResponse(data: jsonBody);
        }
      } else {
        throw await response.stream.bytesToString();
      }
    } catch (e) {
      return StorageResponse(error: handleError(e));
    }
  }


  Future<StorageResponse> putFile(String url, File file, FileOptions fileOptions, {FetchOptions? options}) async {
    try {
      final headers = options?.headers ?? {};
      final body = http.MultipartFile.fromBytes('', file.readAsBytesSync(), filename: file.path);
      final request = http.MultipartRequest('PUT', Uri.parse(url))
        ..headers.addAll(headers)
        ..files.add(body);
      final response = await request.send();

      if (isSuccessStatusCode(response.statusCode)) {
        if (options?.noResolveJson == true) {
          return StorageResponse(data: await response.stream.bytesToString());
        } else {
          final jsonBody = json.decode(await response.stream.bytesToString());
          return StorageResponse(data: jsonBody);
        }
      } else {
        throw await response.stream.bytesToString();
      }
    } catch (e) {
      return StorageResponse(error: handleError(e));
    }
  }

  Future<StorageResponse> put(String url, dynamic body, {FetchOptions? options}) async {
    try {
      final client = http.Client();
      final bodyStr = json.encode(body ?? {});
      final headers = options?.headers ?? {};
      headers['Content-Type'] = 'application/json';
      final http.Response response = await client.put(Uri.parse(url), headers: headers, body: bodyStr);
      if (isSuccessStatusCode(response.statusCode)) {
        if (options?.noResolveJson == true) {
          return StorageResponse(data: response.body);
        } else {
          final jsonBody = json.decode(response.body);
          return StorageResponse(data: jsonBody);
        }
      } else {
        throw response;
      }
    } catch (e) {
      return StorageResponse(error: handleError(e));
    }
  }

  Future<StorageResponse> delete(String url, dynamic body, {FetchOptions? options}) async {
    try {
      final client = http.Client();
      final headers = options?.headers ?? {};
      final bodyStr = json.encode(body ?? {});
      headers['Content-Type'] = 'application/json';
      final http.Response response = await client.delete(Uri.parse(url), headers: headers, body: bodyStr);
      if (isSuccessStatusCode(response.statusCode)) {
        if (options?.noResolveJson == true) {
          return StorageResponse(data: response.body);
        } else {
          final jsonBody = json.decode(response.body);
          return StorageResponse(data: jsonBody);
        }
      } else {
        throw response.toString();
      }
    } catch (e) {
      return StorageResponse(error: handleError(e));
    }
  }
}
