import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/utils.dart';
import '../config/app_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  SupabaseClient get _supabaseClient => AppConfig.supabase;

  /// Stream of auth state changes. Emits the current user map or null.
  Stream<Map<String, dynamic>?> get authStateChanges {
    return logAuthStateChanges(
      _supabaseClient.auth.onAuthStateChange.map((data) {
        final session = data.session;
        if (session == null) return null;
        final user = session.user;
        final meta = user.userMetadata ?? {};
        return {
          'id': user.id,
          'created_at': user.createdAt,
          'email': user.email,
          'name': meta['name'] ?? meta['full_name'] ?? '',
          'phone': meta['phone'] ?? meta['phone_number'] ?? '',
          'city': meta['city'] ?? '',
          'photoUrl': meta['avatar_url'] ?? meta['picture'],
        };
      }),
      userIdOf: (user) => user['id'] as String? ?? '',
    );
  }

  Future<String> _fetchRole(String uid) async {
    try {
      final row = await _supabaseClient
          .from('profiles')
          .select('role')
          .eq('id', uid)
          .maybeSingle();
      return row?['role']?.toString() ?? 'user';
    } catch (_) {
      return 'user';
    }
  }

  FutureEither<Map<String, dynamic>?> login({
    required String email,
    required String password,
  }) async {
    return runTask(() async {
      final response = await _supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final user = response.user;
      if (user == null) return null;
      final role = await _fetchRole(user.id);
      final meta = user.userMetadata ?? {};
      return {
        'id': user.id,
        'created_at': user.createdAt,
        'email': user.email,
        'name': meta['name'] ?? meta['full_name'] ?? '',
        'phone': meta['phone'] ?? meta['phone_number'] ?? '',
        'city': meta['city'] ?? '',
        'photoUrl': meta['avatar_url'] ?? meta['picture'],
        'role': role,
      };
    },
      operation: 'auth.login',
      category: LogCategory.auth,
      context: {'method': 'email'},
      requiresNetwork: true,
    );
  }

  FutureEither<Map<String, dynamic>?> signUp({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) async {
    return runTask(() async {
      final response = await _supabaseClient.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: kIsWeb
            ? '${Uri.base.origin}/login-callback'
            : 'sbconsultants://login-callback',
        data: {
          'name': name,
          'full_name': name,
          'phone': phone,
          'phone_number': phone,
        },
      );
      final user = response.user;
      if (user == null) return null;

      // In Supabase, if an email already exists, signUp returns an obfuscated user with empty identities list
      if (user.identities != null && user.identities!.isEmpty) {
        throw const AuthException(
          'An account with this email address already exists. Please sign in or use "Forgot Password".',
        );
      }

      final role = await _fetchRole(user.id);

      // Explicitly upsert to profiles table to guarantee immediate persistence
      try {
        await _supabaseClient.from('profiles').upsert({
          'id': user.id,
          'email': email,
          'full_name': name,
          'phone': phone,
          'role': 'user',
          'is_verified': false,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      } catch (_) {}

      return {
        'id': user.id,
        'created_at': user.createdAt,
        'email': user.email,
        'name': name,
        'phone': phone,
        'photoUrl': user.userMetadata?['avatar_url'],
        'role': role,
      };
    },
      operation: 'auth.signUp',
      category: LogCategory.auth,
      context: {'method': 'email'},
      requiresNetwork: true,
    );
  }

  FutureEither<void> forgotPassword({required String email}) async {
    return runTask(() async {
      final redirectUrl = kIsWeb
          ? '${Uri.base.origin}/reset-password'
          : 'sbconsultants://login-callback';
      await _supabaseClient.auth.resetPasswordForEmail(
        email,
        redirectTo: redirectUrl,
      );
    },
      operation: 'auth.forgotPassword',
      category: LogCategory.auth,
      context: {'method': 'email'},
      requiresNetwork: true,
    );
  }

  FutureEither<void> resetPasswordWithOtp({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    return runTask(() async {
      // 1. Verify recovery OTP to establish authenticated recovery session
      await _supabaseClient.auth.verifyOTP(
        email: email,
        token: otp,
        type: OtpType.recovery,
      );

      // 2. Update user password
      await _supabaseClient.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    },
      operation: 'auth.resetPasswordWithOtp',
      category: LogCategory.auth,
      context: {'method': 'otp'},
      requiresNetwork: true,
    );
  }

  FutureEither<void> updatePassword({required String newPassword}) async {
    return runTask(() async {
      await _supabaseClient.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    },
      operation: 'auth.updatePassword',
      category: LogCategory.auth,
      requiresNetwork: true,
    );
  }

  FutureEither<void> logout() async {
    return runTask(() async {
      try {
        await _supabaseClient.auth.signOut(scope: SignOutScope.global).timeout(const Duration(seconds: 3));
      } catch (_) {
        try {
          await _supabaseClient.auth.signOut(scope: SignOutScope.local);
        } catch (_) {}
      }

      // Industry-standard complete wipe of all locally cached session tokens & credentials
      try {
        final prefs = await SharedPreferences.getInstance();
        final keys = prefs.getKeys().toList();
        for (final key in keys) {
          final k = key.toLowerCase();
          if (k.contains('auth') ||
              k.contains('supabase') ||
              k.contains('session') ||
              k.contains('token') ||
              k.contains('user') ||
              k.contains('profile') ||
              k.contains('unlock') ||
              k.contains('pass') ||
              k.contains('scholarship') ||
              k.contains('sponsored_job')) {
            await prefs.remove(key);
          }
        }
      } catch (_) {}
    },
      operation: 'auth.logout',
      category: LogCategory.auth,
      requiresNetwork: false,
    );
  }

  FutureEither<void> deleteAccount() async {
    return runTask(() async {
      final user = _supabaseClient.auth.currentUser;
      final userId = user?.id;

      // 1. Wipe remote user applications, documents, payments, and bookings
      if (userId != null && userId.isNotEmpty) {
        try {
          final apps = await _supabaseClient
              .from('applications')
              .select('id')
              .eq('user_id', userId);
          for (final a in apps) {
            final appId = a['id'];
            try {
              await _supabaseClient
                  .from('application_procedures')
                  .delete()
                  .eq('application_id', appId);
            } catch (_) {}
            try {
              await _supabaseClient
                  .from('application_status_history')
                  .delete()
                  .eq('application_id', appId);
            } catch (_) {}
            try {
              await _supabaseClient
                  .from('application_feedback')
                  .delete()
                  .eq('application_id', appId);
            } catch (_) {}
            try {
              await _supabaseClient
                  .from('consultancy_bookings')
                  .delete()
                  .eq('application_id', appId);
            } catch (_) {}
            try {
              await _supabaseClient
                  .from('user_documents')
                  .delete()
                  .eq('application_id', appId);
            } catch (_) {}
            try {
              await _supabaseClient
                  .from('payments')
                  .delete()
                  .eq('application_id', appId);
            } catch (_) {}
          }
          await _supabaseClient.from('applications').delete().eq('user_id', userId);
        } catch (_) {}

        try {
          await _supabaseClient.from('payments').delete().eq('user_id', userId);
        } catch (_) {}

        try {
          await _supabaseClient.from('consultancy_bookings').delete().eq('user_id', userId);
        } catch (_) {}

        try {
          await _supabaseClient.from('user_documents').delete().eq('user_id', userId);
        } catch (_) {}

        try {
          await _supabaseClient.from('user_directory_unlocks').delete().eq('user_id', userId);
        } catch (_) {}

        try {
          await _supabaseClient.from('notifications').delete().eq('user_id', userId);
        } catch (_) {}
      }

      // 2. Wipe local cached applications and directory unlock state
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('cached_user_applications');
        await prefs.remove('local_applications');
        if (userId != null) {
          await prefs.remove('sb_unlocked_sponsored_jobs_$userId');
          await prefs.remove('sb_unlocked_scholarships_$userId');
        }
        await prefs.remove('sb_unlocked_sponsored_jobs');
        await prefs.remove('sb_unlocked_scholarships');
      } catch (_) {}

      // Keep user authenticated in auth.users - credentials remain intact!
    },
      operation: 'auth.deleteAccount',
      category: LogCategory.auth,
      requiresNetwork: false,
    );
  }

  FutureEither<Map<String, dynamic>?> getCurrentUser() async {
    return runTask(() async {
      final session = _supabaseClient.auth.currentSession;
      if (session == null) return null;
      final user = session.user;
      final role = await _fetchRole(user.id);
      final meta = user.userMetadata ?? {};

      // Also try fetching from profiles table for fresh details
      Map<String, dynamic>? profile;
      try {
        profile = await _supabaseClient
            .from('profiles')
            .select()
            .eq('id', user.id)
            .maybeSingle();
      } catch (_) {}

      final name = ((profile?['full_name'] as String?)?.trim().isNotEmpty ?? false)
          ? profile!['full_name']
          : (meta['name'] ?? meta['full_name'] ?? '');
      final phone = ((profile?['phone'] as String?)?.trim().isNotEmpty ?? false)
          ? profile!['phone']
          : (meta['phone'] ?? meta['phone_number'] ?? '');
      final city = ((profile?['city'] as String?)?.trim().isNotEmpty ?? false)
          ? profile!['city']
          : (meta['city'] ?? '');
      final photoUrl = profile?['avatar_url'] ??
          meta['avatar_url'] ??
          meta['picture'];

      return {
        'id': user.id,
        'created_at': user.createdAt,
        'email': user.email,
        'name': name,
        'phone': phone,
        'city': city,
        'photoUrl': photoUrl,
        'role': role,
      };
    },
      operation: 'auth.getCurrentUser',
      category: LogCategory.auth,
    );
  }

  FutureEither<void> verifyOtp({
    required String email,
    required String otp,
  }) async {
    return runTask(() async {
      try {
        await _supabaseClient.auth.verifyOTP(
          email: email,
          token: otp,
          type: OtpType.signup,
        );
      } catch (e) {
        final errStr = e.toString().toLowerCase();
        // If the code is invalid or expired, rethrow directly so user sees the accurate message
        if (errStr.contains('invalid') ||
            errStr.contains('expired') ||
            errStr.contains('403') ||
            errStr.contains('400')) {
          rethrow;
        }
        // Fallback in case magiclink / email OTP was sent instead
        await _supabaseClient.auth.verifyOTP(
          email: email,
          token: otp,
          type: OtpType.email,
        );
      }
      final currentUser = _supabaseClient.auth.currentUser;
      if (currentUser != null) {
        try {
          final meta = currentUser.userMetadata ?? {};
          final name = meta['name'] ?? meta['full_name'];
          final phone = meta['phone'] ?? meta['phone_number'];
          await _supabaseClient.from('profiles').upsert({
            'id': currentUser.id,
            'email': currentUser.email ?? email,
            if (name != null && (name as String).isNotEmpty) 'full_name': name,
            if (phone != null && (phone as String).isNotEmpty) 'phone': phone,
            'is_verified': true,
            'updated_at': DateTime.now().toIso8601String(),
          });
        } catch (_) {}
      }
    },
      operation: 'auth.verifyOtp',
      category: LogCategory.auth,
      context: {'method': 'email'},
      requiresNetwork: true,
    );
  }

  FutureEither<void> resendOtp({required String email}) async {
    return runTask(() async {
      try {
        await _supabaseClient.auth.resend(
          type: OtpType.signup,
          email: email,
        );
      } catch (e) {
        final errStr = e.toString().toLowerCase();
        // If rate limit was triggered, rethrow immediately to avoid wasting another request
        if (errStr.contains('rate') ||
            errStr.contains('limit') ||
            errStr.contains('seconds') ||
            errStr.contains('429')) {
          rethrow;
        }
        await _supabaseClient.auth.resend(
          type: OtpType.email,
          email: email,
        );
      }
    },
      operation: 'auth.resendOtp',
      category: LogCategory.auth,
      context: {'method': 'email'},
      requiresNetwork: true,
    );
  }

  FutureEither<void> signInWithOAuth(OAuthProvider provider) async {
    return runTask(() async {
      final redirectUrl = kIsWeb
          ? Uri.base.origin
          : 'sbconsultants://login-callback';
      await _supabaseClient.auth.signInWithOAuth(
        provider,
        redirectTo: redirectUrl,
        authScreenLaunchMode:
            kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication,
      );
    },
      operation: 'auth.signInWithOAuth',
      category: LogCategory.auth,
      context: {'provider': provider.name},
      requiresNetwork: true,
    );
  }

  void dispose() {
    // Supabase manages its own streams
  }
}
