import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  final client = SupabaseClient(
    'https://tpmdqfmtunxbnhpckkbh.supabase.co',
    'sb_publishable_5n7vzIcQ-hXaBq0s3XliCw_J066pNPo',
  );

  try {
    final authRes = await client.auth.signInWithPassword(
      email: 'umerzafar780@gmail.com',
      password: 'umer123',
    );
    final user = authRes.user;
    print('Logged in user ID: ${user?.id}');

    // Test select user_directory_unlocks
    final rows = await client
        .from('user_directory_unlocks')
        .select('directory_type, is_active')
        .eq('user_id', user!.id)
        .eq('is_active', true);
    print('Unlocks from Supabase: $rows');

    // Test select payments
    final payments = await client
        .from('payments')
        .select('id, listing_id, reference_id, amount, status')
        .eq('user_id', user.id);
    print('Payments from Supabase: $payments');
  } catch (e) {
    print('Error: $e');
  }
}

