# `supabase-dart`

A dart client for Supabase.

[![pub package](https://img.shields.io/pub/v/supabase.svg)](https://pub.dev/packages/supabase)
[![pub test](https://github.com/supabase/supabase-dart/workflows/Test/badge.svg)](https://github.com/supabase/supabase-dart/actions?query=workflow%3ATest)

## Usage

```dart
import 'package:supabase/supabase.dart';

main() {
  final client = SupabaseClient('supabaseUrl', 'supabaseKey');
  final response = await client
      .from('countries')
      .select()
      .order('name', ascending: true)
      .execute();
}
```

## Contributing

- Fork the repo on [GitHub](https://github.com/supabase/supabase-dart)
- Clone the project to your own machine
- Commit changes to your own branch
- Push your work back up to your fork
- Submit a Pull request so that we can review your changes and merge

## License

This repo is licenced under MIT.

## Credits

- https://github.com/supabase/supabase-js
