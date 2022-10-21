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
  final supabase = SupabaseClient('supabaseUrl', 'supabaseKey');

  // Select from table `countries` ordering by `name`
  final data = await supabase
      .from('countries')
      .select()
      .order('name', ascending: true);
}
```

### [Realtime](https://supabase.io/docs/guides/database#realtime)

```dart
import 'package:supabase/supabase.dart';

main() {
  final supabase = SupabaseClient('supabaseUrl', 'supabaseKey');

  // Set up a listener to listen to changes in `countries` table
  supabase.channel('my_channel').on(RealtimeListenTypes.postgresChanges, ChannelFilter(
      event: '*',
      schema: 'public',
      table: 'countries'
    ), (payload, [ref]) {
      // Do something when there is an update
    }).subscribe();

  // remember to remove the channels when you're done
  supabase.removeAllChannels();
}
```

### Realtime data as `Stream`

To receive realtime updates, you have to first enable Realtime on from your Supabase console. You can read more [here](https://supabase.io/docs/guides/api#managing-realtime) on how to enable it.

```dart
import 'package:supabase/supabase.dart';

main() {
  final supabase = SupabaseClient('supabaseUrl', 'supabaseKey');

  // Set up a listener to listen to changes in `countries` table
  final subscription = supabase
      .from('countries')
      .stream(primaryKey: ['id']) // Pass list of primary key column names
      .order('name')
      .limit(30)
      .listen(_handleCountriesStream);

  // remember to remove subscription when you're done
  subscription.cancel();
}
```

### [Authentication](https://supabase.io/docs/guides/auth)

```dart
import 'package:supabase/supabase.dart';

main() {
  final supabase = SupabaseClient('supabaseUrl', 'supabaseKey');

  // Sign up user with email and password
  final response = await supabase
    .auth
    .signUp(email: 'sample@email.com', password: 'password');
}
```

### [Storage](https://supabase.io/docs/guides/storage)

```dart
import 'package:supabase/supabase.dart';

main() {
  final supabase = SupabaseClient('supabaseUrl', 'supabaseKey');

  // Create file `example.txt` and upload it in `public` bucket
  final file = File('example.txt');
  file.writeAsStringSync('File content');
  final storageResponse = await supabase
      .storage
      .from('public')
      .upload('example.txt', file);
}
```

## Authentication

Initialize a [`SupabaseClient`](https://supabase.com/docs/reference/dart/initializing#access-supabaseclient-instance) by passing your **Supabase URL** and **Supabase KEY**. The keys can be found in your supabase project in `/setting/API`.

```dart
final client = SupabaseClient('supabaseUrl', 'supabaseKey');
```

The `client` has a [`auth`](https://pub.dev/documentation/supabase/latest/supabase/SupabaseClient/auth.html) attribute (of type [`GoTrueClient`](https://pub.dev/documentation/gotrue/latest/gotrue/GoTrueClient-class.html)) that you can use to authenticate your users using supabase.

### Sign up

Use the [`signUp`](https://supabase.com/docs/reference/dart/auth-signup) method to create a new user account.

```dart
// Sign up user with email and password
final response = await supabase.auth.signUp(email: email, password: password);
final Session? session = response.session;
final User? user = response.user;
```

### Sign in

There are a few ways to sign in a user into your app. 

Use the [`signInWithPassword`](https://supabase.com/docs/reference/dart/auth-signinwithpassword) method to sign in a user with their email or phone with password.

```dart
// Sign in user with email and password
final response = await client.auth.signInWithPassword(email: email, password: password);
final Session? session = response.session;
final User? user = response.user;
```

Use the [`signInWithOtp`](https://supabase.com/docs/reference/dart/auth-signinwithotp) method to sign in a user using magic link with email or one time password using phone number.

```dart
// Sign in user with email and password
await client.auth.signInWithOtp(email: email);
```


### Sign out

Use the [`signOut`](https://supabase.com/docs/reference/dart/auth-signout) method to sign out a user.

```dart
// Sign out user
await client.auth.signOut();
```

Check out the [**Official Documentation**](https://supabase.com/docs/reference/dart/) to learn all the other available methods.

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
