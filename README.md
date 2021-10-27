# `supabase-dart`

A Dart client for [Supabase](https://supabase.io/).

[![pub package](https://img.shields.io/pub/v/supabase.svg)](https://pub.dev/packages/supabase)
[![pub test](https://github.com/supabase/supabase-dart/workflows/Test/badge.svg)](https://github.com/supabase/supabase-dart/actions?query=workflow%3ATest)

---

## What is Supabase

[Supabase](https://supabase.io/docs/) is an open source Firebase alternative. We are a service to:

- listen to database changes
- query your tables, including filtering, pagination, and deeply nested relationships (like GraphQL)
- create, update, and delete rows
- manage your users and their permissions
- interact with your database using a simple UI

## Status

- [x] Alpha: Under heavy development
- [x] Public Alpha: Ready for testing. But go easy on us, there will be bugs and missing functionality.
- [x] Public Beta: Stable. No breaking changes expected in this version but possible bugs.
- [ ] Public: Production-ready

## Docs

`supabase-dart` mirrors the design of `supabase-js`. Find the documentation [here](https://supabase.io/docs/reference/javascript/initializing).

## Usage example

### [Database](https://supabase.io/docs/guides/database)

```dart
import 'package:supabase/supabase.dart';

main() {
  final client = SupabaseClient('supabaseUrl', 'supabaseKey');

  // Select from table `countries` ordering by `name`
  final response = await client
      .from('countries')
      .select()
      .order('name', ascending: true)
      .execute();
}
```

### [Realtime](https://supabase.io/docs/guides/database#realtime)

```dart
import 'package:supabase/supabase.dart';

main() {
  final client = SupabaseClient('supabaseUrl', 'supabaseKey');

  // Set up a listener to listen to changes in `countries` table
  final subscription = await client
      .from('countries')
      .on(SupabaseEventTypes.all, (payload) {
        // Do something when there is an update
      })
      .subscribe();

  // remember to remove subscription when you're done
  client.removeSubscription(subscription);
}
```

### Realtime data as `Stream`

To receive realtime updates, you have to first enable Realtime on from your Supabase console. You can read more [here](https://supabase.io/docs/guides/api#managing-realtime) on how to enable it.

```dart
import 'package:supabase/supabase.dart';

main() {
  final client = SupabaseClient('supabaseUrl', 'supabaseKey');

  // Set up a listener to listen to changes in `countries` table
  final subscription = await client
      .from('countries')
      .stream()
      .order('name')
      .limit(30)
      .execute()
      .listen(_handleCountriesStream);

  // remember to remove subscription when you're done
  subscription.cancel();
}
```

### [Authentication](https://supabase.io/docs/guides/auth)

```dart
import 'package:supabase/supabase.dart';

main() {
  final client = SupabaseClient('supabaseUrl', 'supabaseKey');

  // Sign up user with email and password
  final response = await client
      .auth
      .signUp('email', 'password');
}
```

### [Storage](https://supabase.io/docs/guides/storage)

```dart
import 'package:supabase/supabase.dart';

main() {
  final client = SupabaseClient('supabaseUrl', 'supabaseKey');

  // Create file `example.txt` and upload it in `public` bucket
  final file = File('example.txt');
  file.writeAsStringSync('File content');
  final storageResponse = await client
      .storage
      .from('public')
      .upload('example.txt', file);
}
```

## Authentication

Initialize a [`SupabaseClient`](https://pub.dev/documentation/supabase/latest/supabase/SupabaseClient-class.html) by passing your **Supabase URL** and **Supabase KEY**. The keys can be found in your supabase project in `/setting/API`.

```dart
final client = SupabaseClient('supabaseUrl', 'supabaseKey');
```

The `client` has a [`auth`](https://pub.dev/documentation/supabase/latest/supabase/SupabaseClient/auth.html) attribute (of type [`GoTrueClient`](https://pub.dev/documentation/gotrue/latest/gotrue/GoTrueClient-class.html)) that you can use to authenticate your users using supabase.

### Sign up

Use the [`signUp`](https://pub.dev/documentation/gotrue/latest/gotrue/GoTrueClient/signUp.html) method, which returns a [`GotrueSessionResponse`](https://github.com/supabase/gotrue-dart/blob/7e58474b444e7d9ea303d11dd058d07f68b3d781/lib/src/gotrue_response.dart#L19).

If the `error` attribute is `null`, the request was successful and the method returns `data` of type [`Session`](https://pub.dev/documentation/gotrue/latest/gotrue/Session-class.html).

```dart
// Sign up user with email and password
final response = await client.auth.signUp('email', 'password');

if (response.error != null) {
  // Error
  print('Error: ${response.error?.message}');
} else {
  // Success
  final session = response.data;
}
```

### Sign in

Use the [`signIn`](https://pub.dev/documentation/gotrue/latest/gotrue/GoTrueClient/signIn.html) method. It works similar to the `signUp` method.

```dart
// Sign in user with email and password
final response = await client.auth.signIn(email: 'email', password: 'password');

if (response.error != null) {
  // Error
  print('Error: ${response.error?.message}');
} else {
  // Success
  final session = response.data;
}
```

### Sign out

Use the [`signOut`](https://pub.dev/documentation/gotrue/latest/gotrue/GoTrueClient/signOut.html) method, which returns a [`GotrueResponse`](https://github.com/supabase/gotrue-dart/blob/7e58474b444e7d9ea303d11dd058d07f68b3d781/lib/src/gotrue_response.dart#L6).

Also for the sign out check that `error` is `null` to know if the request was successful.

```dart
// Sign out user
final response = await client.auth.signOut();

if (response.error != null) {
  // Error
  print('Error: ${response.error?.message}');
} else {
  // Success
}
```

Check out the [**Official Documentation**](https://pub.dev/documentation/gotrue/latest/gotrue/gotrue-library.html) to learn all the other available methods.

## Guides

- Flutter Supabase Authentication - [Blog](https://www.sandromaglione.com/2021/04/24/flutter-supabase-authentication/)

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
