import 'dart:io';

final String supabaseUrl = Platform.environment['SUPABASE_TEST_URL'] ?? '';
final String supabaseKey = Platform.environment['SUPABASE_TEST_KEY'] ?? '';