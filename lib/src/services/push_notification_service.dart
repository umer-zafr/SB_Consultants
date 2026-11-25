import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../routing/global_navigator.dart';

/// Central Push Notification Service powered by OneSignal.
/// Automatically bridges Supabase Auth state with OneSignal user identity.
class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  StreamSubscription<AuthState>? _authSubscription;
  bool _initialized = false;

  /// Initialize OneSignal SDK, request OS permissions, and attach listeners.
  Future<void> initialize() async {
    if (_initialized) return;

    final appId = dotenv.env['ONESIGNAL_APP_ID'] ?? '9ca16da7-ffc6-4a56-82e8-0cc19746e8c3';
    if (appId.isEmpty) {
      debugPrint('[PushNotificationService] Missing ONESIGNAL_APP_ID in .env');
      return;
    }

    try {
      // 1. Debug logging in debug mode
      if (kDebugMode) {
        OneSignal.Debug.setLogLevel(OSLogLevel.warn);
      }

      // 2. Initialize OneSignal with App ID
      OneSignal.initialize(appId);

      // 3. Request user notification permission (Shows Android 13+ / iOS alert dialog)
      OneSignal.Notifications.requestPermission(true);

      // 4. Foreground notification display listener (Shows attractive heads-up banner even if app is open)
      OneSignal.Notifications.addForegroundWillDisplayListener((event) {
        event.notification.display();
      });

      // 5. Handle Notification Clicks (Deep linking)
      OneSignal.Notifications.addClickListener((event) {
        try {
          final data = event.notification.additionalData;
          if (data != null && data['route'] != null) {
            final route = data['route'].toString().trim();
            if (route.isNotEmpty) {
              final ctx = rootContext;
              if (ctx != null) {
                GoRouter.of(ctx).push(route);
              }
            }
          }
        } catch (e) {
          debugPrint('[PushNotificationService] Deep link handling error: $e');
        }
      });

      // 5. Automatically bridge Supabase Auth with OneSignal external user ID
      _attachSupabaseAuthSync();

      _initialized = true;
      debugPrint('[PushNotificationService] OneSignal successfully initialized.');
    } catch (e) {
      debugPrint('[PushNotificationService] Initialization error: $e');
    }
  }

  /// Automatically syncs OneSignal identity with Supabase Auth session
  void _attachSupabaseAuthSync() {
    try {
      final client = Supabase.instance.client;

      // Check current user at startup
      final currentUser = client.auth.currentUser;
      if (currentUser != null) {
        OneSignal.login(currentUser.id);
      }

      // Listen to future auth state changes
      _authSubscription = client.auth.onAuthStateChange.listen((data) {
        final session = data.session;
        if (session != null) {
          OneSignal.login(session.user.id);
        } else {
          OneSignal.logout();
        }
      });
    } catch (e) {
      debugPrint('[PushNotificationService] Supabase auth sync error: $e');
    }
  }

  /// Explicitly login user to OneSignal
  Future<void> loginUser(String userId) async {
    if (!_initialized) return;
    try {
      await OneSignal.login(userId);
    } catch (e) {
      debugPrint('[PushNotificationService] loginUser error: $e');
    }
  }

  /// Explicitly logout user from OneSignal
  Future<void> logoutUser() async {
    if (!_initialized) return;
    try {
      await OneSignal.logout();
    } catch (e) {
      debugPrint('[PushNotificationService] logoutUser error: $e');
    }
  }

  void dispose() {
    _authSubscription?.cancel();
  }
}

