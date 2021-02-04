enum SupabaseEventTypes { insert, update, delete, all }

extension SupabaseEventTypesName on SupabaseEventTypes {
  String name() {
    final name = toString().split('.').last;
    if (name == 'all') {
      return '*';
    } else {
      return name.toUpperCase();
    }
  }
}
