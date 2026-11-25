import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter_sd_consultant/src/routing/app_routes.dart';
import 'package:flutter_sd_consultant/src/shared/app_assets.dart';
import 'package:flutter_sd_consultant/src/shared/helpers/show_toast.dart';

/// Professional OAuth callback handler screen.
///
/// Catches the deep-link return from Google OAuth, handles any errors (user
/// cancelled, access denied, server issues), exchanges tokens, syncs user
/// profile data, and transitions cleanly to Home or back to Login.
class OAuthCallbackScreen extends ConsumerStatefulWidget {
  const OAuthCallbackScreen({super.key});

  @override
  ConsumerState<OAuthCallbackScreen> createState() => _OAuthCallbackScreenState();
}

class _OAuthCallbackScreenState extends ConsumerState<OAuthCallbackScreen> {
  StreamSubscription<AuthState>? _authSubscription;
  Timer? _timeoutTimer;
  bool _hasProcessed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _processOAuthResult();
    });
  }

  void _processOAuthResult() async {
    if (_hasProcessed) return;

    final routerState = GoRouterState.of(context);
    final uri = routerState.uri;

    // 1. Inspect URI query parameters and fragment for OAuth errors
    final queryParams = uri.queryParameters;
    final fragment = uri.fragment;

    String? error = queryParams['error'];
    String? errorDescription = queryParams['error_description'];

    // Also check fragment (Supabase sometimes redirects with hash fragment)
    if (error == null && fragment.isNotEmpty) {
      final fragmentParams = Uri.splitQueryString(fragment);
      error = fragmentParams['error'];
      errorDescription = fragmentParams['error_description'];
    }

    if (error != null) {
      _hasProcessed = true;
      final isCancelled = error == 'access_denied' ||
          (errorDescription?.toLowerCase().contains('cancel') ?? false);

      if (isCancelled) {
        showToast(
          context,
          message: 'Google Sign-In was cancelled.',
          status: 'info',
        );
      } else {
        final cleanMsg = errorDescription != null && errorDescription.isNotEmpty
            ? Uri.decodeComponent(errorDescription.replaceAll('+', ' '))
            : 'Authentication failed. Please try again.';
        showToast(
          context,
          message: cleanMsg,
          status: 'error',
        );
      }

      context.go(AppRoutes.login);
      return;
    }

    // Check if this callback is for password recovery
    final type = queryParams['type'] ??
        (fragment.isNotEmpty ? Uri.splitQueryString(fragment)['type'] : null);
    final isRecovery = type == 'recovery';

    // 2. Check if a valid session is already established
    final currentSession = Supabase.instance.client.auth.currentSession;
    if (currentSession != null) {
      _hasProcessed = true;
      _cleanup();
      // Sync profile in background without blocking screen transition
      unawaited(_syncProfile(currentSession.user).catchError((_) {}));
      if (mounted) {
        if (isRecovery) {
          context.go(AppRoutes.resetPassword);
        } else {
          final name = currentSession.user.userMetadata?['name'] ??
              currentSession.user.userMetadata?['full_name'] ??
              currentSession.user.email?.split('@').first ??
              'User';
          showToast(
            context,
            message: 'Welcome back, $name!',
            status: 'success',
          );
          context.go(AppRoutes.home);
        }
      }
      return;
    }

    // 3. Otherwise, listen for Supabase to finish parsing deep link tokens
    _authSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      if (_hasProcessed) return;

      final session = data.session;
      if (session != null) {
        _hasProcessed = true;
        _cleanup();
        unawaited(_syncProfile(session.user).catchError((_) {}));
        if (mounted) {
          if (data.event == AuthChangeEvent.passwordRecovery || isRecovery) {
            context.go(AppRoutes.resetPassword);
          } else {
            final name = session.user.userMetadata?['name'] ??
                session.user.userMetadata?['full_name'] ??
                session.user.email?.split('@').first ??
                'User';
            showToast(
              context,
              message: 'Signed in successfully as $name!',
              status: 'success',
            );
            context.go(AppRoutes.home);
          }
        }
      }
    });

    // 4. Timeout safety net (6 seconds)
    _timeoutTimer = Timer(const Duration(seconds: 6), () {
      if (_hasProcessed) return;
      _hasProcessed = true;
      _cleanup();

      if (mounted) {
        final session = Supabase.instance.client.auth.currentSession;
        if (session != null) {
          if (isRecovery) {
            context.go(AppRoutes.resetPassword);
          } else {
            context.go(AppRoutes.home);
          }
        } else {
          showToast(
            context,
            message: 'Sign-in session could not be verified. Please try again.',
            status: 'warning',
          );
          context.go(AppRoutes.login);
        }
      }
    });
  }

  Future<void> _syncProfile(User user) async {
    try {
      final email = user.email ?? '';
      final name = user.userMetadata?['name'] ??
          user.userMetadata?['full_name'] ??
          (email.contains('@') ? email.split('@').first : 'User');
      final avatarUrl = user.userMetadata?['avatar_url'] ??
          user.userMetadata?['picture'];

      await Supabase.instance.client.from('profiles').upsert({
        'id': user.id,
        'email': email,
        'full_name': name,
        'avatar_url': avatarUrl,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }

  void _cleanup() {
    _authSubscription?.cancel();
    _timeoutTimer?.cancel();
  }

  @override
  void dispose() {
    _cleanup();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Circular Brand Logo
              Container(
                width: 76.w,
                height: 76.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1B3A5C).withValues(alpha: 0.15),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                  border: Border.all(
                    color: const Color(0xFF1B3A5C).withValues(alpha: 0.18),
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: Image.asset(
                    AppAssets.logo,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(height: 28.h),

              // Elegant Spinner
              SizedBox(
                width: 26.w,
                height: 26.w,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDark ? Colors.white : const Color(0xFF1B3A5C),
                  ),
                ),
              ),
              SizedBox(height: 18.h),

              // Status Text
              Text(
                'Securing your Google session...',
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                  letterSpacing: -0.2,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                'Connecting with SB Consultants',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: isDark ? Colors.white54 : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
