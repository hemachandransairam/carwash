
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ccwink/config/supabase_config.dart';

// This is a scratch script to check workers in the database.
// Since it's for the agent to run and see output, I'll use print statements.

void main() async {
  // We need to initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  final client = Supabase.instance.client;

  try {
    final workers = await client.from('workers').select();
    print('Workers table: $workers');

    for (var w in workers) {
      final user = await client.from('users').select().eq('id', w['user_id']).maybeSingle();
      print('Worker: ${w['id']}, Status: ${w['status']}, User Role: ${user?['role']}');
    }
  } catch (e) {
    print('Error: $e');
  }
}
