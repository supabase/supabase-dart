import '../supabase.dart';

typedef ResponseConverter<T> = T Function(dynamic data);

extension Converter on Future<PostgrestResponse> {
  Future<T> withConverter<T>(ResponseConverter<T> converter) async {
    final response = await this;
    return converter(response.data);
  }
}

extension StreamConverter on Stream<List<Map<String, dynamic>>> {
  Stream<T> withConverter<T>(ResponseConverter<T> converter) {
    return map<T>((data) => converter(data));
  }
}
