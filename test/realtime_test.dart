import 'package:supabase/supabase.dart';
import 'package:test/test.dart';

void main() {
  group('subscription: ', () {
    late SupabaseClient client;
    setUp(() {
      client = SupabaseClient(
        'https://xyz.supabase.co',
        'key',
      );
    });
    test('subscribe on existing subscription fail', () {
      final subscription =
          client.from('table').on(SupabaseEventTypes.insert, (_) {}).subscribe(
                (event, {errorMsg}) => print('event: $event error: $errorMsg'),
              );
      expect(
        () => subscription.subscribe(),
        throwsA(const TypeMatcher<String>()),
      );
    });
    test('two realtime connections', () {
      client.from('table').on(SupabaseEventTypes.insert, (_) {}).subscribe();
      client.from('table').on(SupabaseEventTypes.insert, (_) {}).subscribe();

      expect(
        client.getSubscriptions().length,
        2,
      );
    });
    test('remove realtime connection', () async {
      final first = client
          .from('table')
          .on(SupabaseEventTypes.insert, (event, {error}) {})
          .subscribe();

      client
          .from('table')
          .on(SupabaseEventTypes.update, (event, {error}) {})
          .subscribe();
      final result = await client.removeSubscription(first);
      expect(
        result.error,
        isNull,
      );

      expect(
        client.getSubscriptions().length,
        1,
      );
    });
    test('remove multiple realtime connection', () async {
      final first = client
          .from('table')
          .on(SupabaseEventTypes.insert, (event, {error}) {})
          .subscribe();
      final second = client
          .from('table')
          .on(SupabaseEventTypes.update, (event, {error}) {})
          .subscribe();

      final result1 = await client.removeSubscription(first);
      final result2 = await client.removeSubscription(second);

      expect(
        result1.error,
        isNull,
      );
      expect(
        result2.error,
        isNull,
      );

      expect(
        client.getSubscriptions().length,
        0,
      );
    });

    test('remove all realtime connection', () async {
      client
          .from('table')
          .on(SupabaseEventTypes.insert, (event, {error}) {})
          .subscribe();

      client
          .from('table')
          .on(SupabaseEventTypes.update, (event, {error}) {})
          .subscribe();

      final result1 = await client.removeAllSubscriptions();
      expect(
        result1,
        isNotEmpty,
      );
      expect(
        result1.length,
        2,
      );

      expect(
        client.getSubscriptions().length,
        0,
      );
    });
  });
}
