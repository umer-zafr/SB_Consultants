import 'package:supabase_flutter/supabase_flutter.dart';

/// Developer utility script to clean up test user records for umerzafar781@gmail.com
/// Run with: dart run tool/cleanup_user.dart
void main() async {
  final client = SupabaseClient(
    'https://tpmdqfmtunxbnhpckkbh.supabase.co',
    'sb_publishable_5n7vzIcQ-hXaBq0s3XliCw_J066pNPo',
  );

  final res = await client.auth.signInWithPassword(
    email: 'umerzafar781@gmail.com',
    password: 'umer123',
  );
  final user = res.user;
  if (user == null) {
    // ignore: avoid_print
    print('Failed to authenticate test user');
    return;
  }
  // ignore: avoid_print
  print('Logged in as ${user.email} (ID: ${user.id})');

  // 1. Get all applications
  final apps = await client.from('applications').select('id').eq('user_id', user.id);
  // ignore: avoid_print
  print('Found ${apps.length} applications to delete.');

  for (final app in apps) {
    final appId = app['id'] as String;
    // ignore: avoid_print
    print('Deleting dependencies for application $appId...');

    try {
      await client.from('application_procedures').delete().eq('application_id', appId);
    } catch (e) {
      // ignore: avoid_print
      print('  application_procedures err: $e');
    }

    try {
      await client.from('application_status_history').delete().eq('application_id', appId);
    } catch (e) {
      // ignore: avoid_print
      print('  application_status_history err: $e');
    }

    try {
      await client.from('application_feedback').delete().eq('application_id', appId);
    } catch (e) {
      // ignore: avoid_print
      print('  application_feedback err: $e');
    }

    try {
      await client.from('consultancy_bookings').delete().eq('application_id', appId);
    } catch (e) {
      // ignore: avoid_print
      print('  consultancy_bookings err: $e');
    }

    try {
      await client.from('user_documents').delete().eq('application_id', appId);
    } catch (e) {
      // ignore: avoid_print
      print('  user_documents err: $e');
    }

    try {
      await client.from('payments').delete().eq('application_id', appId);
    } catch (e) {
      // ignore: avoid_print
      print('  payments err: $e');
    }

    try {
      await client.from('applications').delete().eq('id', appId);
      // ignore: avoid_print
      print('  Deleted application $appId successfully');
    } catch (e) {
      // ignore: avoid_print
      print('  applications delete err: $e');
    }
  }

  // 2. Delete any standalone payments for this user
  try {
    final payments = await client.from('payments').select('id').eq('user_id', user.id);
    for (final p in payments) {
      final pid = p['id'] as String;
      await client.from('payments').delete().eq('id', pid);
      // ignore: avoid_print
      print('Deleted payment $pid');
    }
  } catch (e) {
    // ignore: avoid_print
    print('payments delete err: $e');
  }

  // 3. Delete user documents, unlocks, notifications
  try {
    await client.from('user_documents').delete().eq('user_id', user.id);
  } catch (e) {
    // ignore: avoid_print
    print('user_documents err: $e');
  }

  try {
    await client.from('user_directory_unlocks').delete().eq('user_id', user.id);
  } catch (e) {
    // ignore: avoid_print
    print('user_directory_unlocks err: $e');
  }

  try {
    await client.from('notifications').delete().eq('user_id', user.id);
  } catch (e) {
    // ignore: avoid_print
    print('notifications err: $e');
  }

  // 4. Verify cleanup
  final remainingApps = await client.from('applications').select('id').eq('user_id', user.id);
  final remainingPayments = await client.from('payments').select('id').eq('user_id', user.id);
  // ignore: avoid_print
  print('Remaining applications: ${remainingApps.length}');
  // ignore: avoid_print
  print('Remaining payments: ${remainingPayments.length}');
}

