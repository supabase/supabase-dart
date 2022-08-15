## [1.0.0-dev.4]

- fix: update storage to [v1.0.0-dev.3](https://github.com/supabase-community/storage-dart/blob/main/CHANGELOG.md#100-dev3)
- fix: add `web_socket_channel` to dev dependencies since it is used in tests
- fix: add basic `postgrest` test
- BREAKING: update gotrue to [v1.0.0-dev.3](https://github.com/supabase-community/gotrue-dart/blob/main/CHANGELOG.md#100-dev3)

## [1.0.0-dev.3]

- fix: export storage types
- BREAKING: update postgrest to [v1.0.0-dev.2](https://github.com/supabase-community/postgrest-dart/blob/master/CHANGELOG.md#100-dev2)
- BREAKING: update gotrue to [v1.0.0-dev.2](https://github.com/supabase-community/gotrue-dart/blob/main/CHANGELOG.md#100-dev2)
- feat: update storage to [v1.0.0-dev.2](https://github.com/supabase-community/storage-dart/blob/main/CHANGELOG.md#100-dev2)

## [1.0.0-dev.2]

- feat: custom http client

## [1.0.0-dev.1]

- BREAKING: update postgrest to [v1.0.0-dev.1](https://github.com/supabase-community/postgrest-dart/blob/master/CHANGELOG.md#100-dev1)
- BREAKING: update gotrue to [v1.0.0-dev.1](https://github.com/supabase-community/gotrue-dart/blob/main/CHANGELOG.md#100-dev1)
- BREAKING: update storage to [v1.0.0-dev.1](https://github.com/supabase-community/storage-dart/blob/main/CHANGELOG.md#100-dev1)
- BREAKING: update functions to [v1.0.0-dev.1](https://github.com/supabase-community/functions-dart/blob/main/CHANGELOG.md#100-dev1)

## [0.3.6]

- fix: Calling postgrest endpoints within realtime callback throws exception
- feat: update gotrue to [v0.2.3](https://github.com/supabase-community/gotrue-dart/blob/main/CHANGELOG.md#023)

## [0.3.5]

- fix: update gotrue to [v0.2.2+1](https://github.com/supabase-community/gotrue-dart/blob/main/CHANGELOG.md#0221)
- feat: update postgrest to [v0.1.11](https://github.com/supabase-community/postgrest-dart/blob/master/CHANGELOG.md#0111)
- fix: flaky test on stream()

## [0.3.4+1]

- fix: export type, `SupabaseRealtimePayload`

## [0.3.4]

- fix: update gotrue to [v0.2.2](https://github.com/supabase-community/gotrue-dart/blob/main/CHANGELOG.md#022)

## [0.3.3]

- feat: update gotrue to[v0.2.1](https://github.com/supabase-community/gotrue-dart/blob/main/CHANGELOG.md#021)
- fix: update postgrest to[0.1.10+1](https://github.com/supabase-community/postgrest-dart/blob/master/CHANGELOG.md#01101)

## [0.3.2]

- feat: update postgrest to [v0.1.10](https://github.com/supabase-community/postgrest-dart/blob/master/CHANGELOG.md#0110)
- fix: update functions_client to [v0.0.1-dev.4](https://github.com/supabase-community/functions-dart/blob/main/CHANGELOG.md#001-dev4)

## [0.3.1+1]

- feat: exporting classes of functions_client

## [0.3.1]

- feat: add functions support

## [0.3.0]

- BREAKING: update gotrue_client to [v0.2.0](https://github.com/supabase-community/gotrue-dart/blob/main/CHANGELOG.md#020)

## [0.2.15]

- chore: update gotrue_client to v0.1.6

## [0.2.14]

- chore: update gotrue_client to v0.1.5
- chore: update postgrest to v0.1.9
- chore: update realtime_client to v0.1.15
- chore: update storage_client to v0.0.6+2

## [0.2.13]

- chore: update realtime_client to v0.1.14

## [0.2.12]

- fix: changedAccessToken never initialized error when changing account
- fix: stream replaces the correct row

## [0.2.11]

- feat: listen for auth event and handle token changed
- chore: update gotrue to v0.1.3
- chore: update realtime_client to v0.1.13
- fix: use PostgrestFilterBuilder type for rpc
- docs: correct stream method documentation

## [0.2.10]

- fix: type 'Null' is not a subtype of type 'List<dynamic>' in type cast

## [0.2.9]

- feat: add user_token when creating realtime channel subscription
- fix: typo on Realtime data as Stream on readme.md

## [0.2.8]

- chore: update gotrue to v0.1.2
- chore: update storage_client to v0.0.6
- fix: cleanup imports in `supabase_stream_builder` to remove analysis error

## [0.2.7]

- chore: update postgrest to v0.1.8

## [0.2.6]

- chore: add `X-Client-Info` header
- chore: update gotrue to v0.1.1
- chore: update postgrest to v0.1.7
- chore: update realtime_client to v0.1.11
- chore: update storage_client to v0.0.5

## [0.2.5]

- chore: update realtime_client to v0.1.10

## [0.2.4]

- chore: update postgrest to v0.1.6

## [0.2.3]

- chore: update realtime_client to v0.1.9

## [0.2.2]

- fix: bug where `stream()` tries to emit data when `StreamController` is closed

## [0.2.1]

- chore: update realtime_client to v0.1.8

## [0.2.0]

- feat: added `stream()` method to listen to realtime updates as stream

## [0.1.0]

- chore: update gotrue to v0.1.0
- feat: add phone auth

## [0.0.8]

- chore: update postgrest to v0.1.5
- chore: update storage_client to v0.0.4

## [0.0.7]

- chore: update realtime_client to v0.1.7

## [0.0.6]

- chore: update realtime_client to v0.1.6

## [0.0.5]

- chore: update realtime_client to v0.1.5

## [0.0.4]

- chore: update realtime_client to v0.1.4

## [0.0.3]

- chore: update storage_client to v0.0.3

## [0.0.2]

- chore: update gotrue to v0.0.7
- chore: update postgrest to v0.1.4
- chore: update storage_client to v0.0.2

## [0.0.1]

- chore: update storage_client to v0.0.1
- Initial Release

## [0.0.1-dev.27]

- chore: update realtime to v0.1.3

## [0.0.1-dev.26]

- chore: update gotrue to v0.0.6

## [0.0.1-dev.25]

- chore: update realtime to v0.1.2

## [0.0.1-dev.24]

- fix: export postgrest classes

## [0.0.1-dev.23]

- chore: update realtime to v0.1.1

## [0.0.1-dev.22]

- chore: update gotrue to v0.0.5

## [0.0.1-dev.21]

- chore: update realtime to v0.1.0

## [0.0.1-dev.20]

- chore: update gotrue to v0.0.4

## [0.0.1-dev.19]

- chore: update gotrue to v0.0.3

## [0.0.1-dev.18]

- chore: update gotrue to v0.0.2
- chore: update postgrest to v0.1.3
- chore: update storage_client to v0.0.1-dev.3

## [0.0.1-dev.17]

- chore: update realtime to v0.0.9
- chore: update postgrest to v0.1.2

## [0.0.1-dev.16]

- chore: update storage_client to v0.0.1-dev.2
- chore: update gotrue to v0.0.1

## [0.0.1-dev.15]

- chore: update postgrest to v0.1.1
- chore: update gotrue to v0.0.1-dev.11

## [0.0.1-dev.14]

- refactor: use storage_client package v0.0.1-dev.1

## [0.0.1-dev.13]

- fix: package dependencies

## [0.0.1-dev.12]

- feat: implement Storage API
- chore: update postgrest to v0.1.0
- chore: update gotrue to v0.0.1-dev.10

## [0.0.1-dev.11]

- fix: aligned exports with supabase-js

## [0.0.1-dev.10]

- chore: migrate to null-safety

## [0.0.1-dev.9]

- fix: rpc to return PostgrestTransformBuilder
- chore: update postgrest to v0.0.7
- chore: expose gotrue User as AuthUser
- chore: expose 'RealtimeSubscription'
- chore: update lib description

## [0.0.1-dev.8]

- fix: rpc method missing param name

## [0.0.1-dev.8]

- chore: update postgrest ^0.0.6

## [0.0.1-dev.6]

- chore: update gotrue v0.0.1-dev.7
- chore: update realtime_client v0.0.7

## [0.0.1-dev.5]

- refactor: SupabaseRealtimePayload variable names

## [0.0.1-dev.4]

- fix: export SupabaseEventTypes
- chore: include realtime supscription code in example

## [0.0.1-dev.3]

- fix: SupabaseRealtimeClient client and payload parsing bug
- update: realtime_client to v0.0.5

## [0.0.1-dev.2]

- fix: builder method not injecting table in the url

## [0.0.1-dev.1]

- Initial pre-release.
