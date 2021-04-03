class FetchOptions {
  FetchOptions({this.headers, this.noResolveJson});

  final Map<String, String>? headers;
  final bool? noResolveJson;
}

// TODO: Handle error like js: err.msg || err.message || err.error_description || err.error || err.toString();
String _getErrorMessage(dynamic error) => error.toString();

// TODO: This does not work
void handleError(dynamic error, Function reject) {
  if (error! is Map) {
    reject(error);
  } else {
    reject({
      'message': _getErrorMessage(error),
      'status': error?.status ?? 500,
    });
  }
}

Map<String, dynamic> _getRequestParams(String method, {FetchOptions? options, dynamic body}) {
  final Map<String, dynamic> params = {'method': method, 'headers': options?.headers ?? {}};

  if (method == 'GET') {
    return params;
  }

  params['headers'] = {'Content-Type': 'application/json', ...options?.headers ?? {}};
  params['body'] = body.toString();

  return params;
}

Future<dynamic> _handleRequest(String method, String url, FetchOptions? options, {dynamic body}) {
  throw UnimplementedError();
  // TODO: Perform request
  //  return fetch(url, _getRequestParams(method, options, body))
  //       .then((result) => {
  //         if (!result.ok) throw result
  //         if (options?.noResolveJson) return resolve(result)
  //         return result.json()
  //       })
  //       .then((data) => resolve(data))
  //       .catch((error) => handleError(error, reject));
}

Future<dynamic> callGet(String url, FetchOptions? options) {
  return _handleRequest('GET', url, options);
}

Future<dynamic> callPost(String url, dynamic body, FetchOptions? options) {
  return _handleRequest('POST', url, options, body: body);
}

Future<dynamic> callPut(String url, dynamic body, FetchOptions? options) {
  return _handleRequest('PUT', url, options, body: body);
}

Future<dynamic> callRemove(String url, dynamic body, FetchOptions? options) {
  return _handleRequest('DELETE', url, options, body: body);
}
