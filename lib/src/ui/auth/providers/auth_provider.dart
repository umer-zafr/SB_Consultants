import 'dart:async';
import 'package:flutter_sd_consultant/src/data/repositories/auth_repository.dart';
import 'package:flutter_sd_consultant/src/imports/core_imports.dart';
import 'package:flutter_sd_consultant/src/imports/packages_imports.dart';
import 'package:flutter_sd_consultant/src/ui/auth/providers/session_provider.dart'
    show authRepositoryProvider;
import 'package:supabase_flutter/supabase_flutter.dart';

final authControllerProvider =
    StateNotifierProvider<AuthController, RequestState<void>>((ref) {
  return AuthController(
    repository: ref.read(authRepositoryProvider),
  );
});

class AuthController extends StateNotifier<RequestState<void>> {
  AuthController({
    required AuthRepository repository,
  })  : _repository = repository,
        super(const RequestInitial());

  final AuthRepository _repository;

  void login({
    required BuildContext context,
    required String email,
    required String password,
  }) async {
    state = const RequestLoading();

    final result = await _repository.login(email: email, password: password);

    result.fold(
      (failure) {
        state = RequestFailure(failure);

        // Check if user credentials are valid but email is not yet confirmed
        final isUnconfirmed = failure.message.toLowerCase().contains('verify your email') ||
            failure.message.toLowerCase().contains('email not confirmed') ||
            (failure.error is AuthException &&
                (failure.error as AuthException)
                    .message
                    .toLowerCase()
                    .contains('email not confirmed'));

        if (isUnconfirmed) {
          // Trigger OTP resend so the user gets a fresh code immediately
          _repository.resendOtp(email: email);
          if (context.mounted) {
            showToast(
              context,
              message: 'Please verify your email. A 6-digit code has been sent.',
              status: 'info',
            );
            context.go('${AppRoutes.otpVerification}?email=${Uri.encodeComponent(email)}');
          } else if (rootContext?.mounted ?? false) {
            rootContext!.go('${AppRoutes.otpVerification}?email=${Uri.encodeComponent(email)}');
          }
          return;
        }

        if (context.mounted) {
          showToast(context, message: failure.message, status: 'error');
        }
      },
      (_) {
        state = const RequestSuccess(null);
        if (context.mounted) {
          context.go(AppRoutes.home);
        } else if (rootContext?.mounted ?? false) {
          rootContext!.go(AppRoutes.home);
        }
      },
    );
  }

  void signUp({
    required BuildContext context,
    required String name,
    required String phone,
    required String email,
    required String password,
  }) async {
    state = const RequestLoading();

    final result = await _repository.signUp(
      name: name,
      phone: phone,
      email: email,
      password: password,
    );

    result.fold(
      (failure) {
        state = RequestFailure(failure);
        if (context.mounted) {
          showToast(context, message: failure.message, status: 'error');
        }
      },
      (user) async {
        state = const RequestSuccess(null);
        final currentSession = AppConfig.supabase.auth.currentSession;
        final currentUser = AppConfig.supabase.auth.currentUser;

        // If Supabase auto-confirmed the user (email confirmation disabled in Supabase)
        final isConfirmed = currentUser?.emailConfirmedAt != null;

        if (isConfirmed && currentSession != null) {
          if (context.mounted) {
            showToast(
              context,
              message: 'Welcome to SB Consultants!',
              status: 'success',
            );
            context.go(AppRoutes.home);
          } else if (rootContext?.mounted ?? false) {
            rootContext!.go(AppRoutes.home);
          }
          return;
        }

        // If email confirmation is required, sign out any temporary unconfirmed session
        // so user cannot bypass OTP verification
        if (currentSession != null) {
          try {
            await AppConfig.supabase.auth.signOut();
          } catch (_) {}
        }

        if (context.mounted) {
          showToast(
            context,
            message: 'Verification code sent to $email',
            status: 'info',
          );
          context.go('${AppRoutes.otpVerification}?email=${Uri.encodeComponent(email)}');
        } else if (rootContext?.mounted ?? false) {
          rootContext!.go('${AppRoutes.otpVerification}?email=${Uri.encodeComponent(email)}');
        }
      },
    );
  }

  void forgotPassword({
    required BuildContext context,
    required String email,
  }) async {
    state = const RequestLoading();

    final result = await _repository.forgotPassword(email: email);

    result.fold(
      (failure) {
        state = RequestFailure(failure);
        if (context.mounted) {
          showToast(context, message: failure.message, status: 'error');
        }
      },
      (_) {
        state = const RequestSuccess(null);
        if (context.mounted) {
          showToast(
            context,
            message: 'A 6-digit verification code has been sent to $email',
            status: 'info',
          );
          context.push('${AppRoutes.resetPassword}?email=${Uri.encodeComponent(email)}');
        } else if (rootContext?.mounted ?? false) {
          rootContext!.push('${AppRoutes.resetPassword}?email=${Uri.encodeComponent(email)}');
        }
      },
    );
  }

  void resetPasswordWithOtp({
    required BuildContext context,
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    state = const RequestLoading();

    final result = await _repository.resetPasswordWithOtp(
      email: email,
      otp: otp,
      newPassword: newPassword,
    );

    result.fold(
      (failure) {
        state = RequestFailure(failure);
        if (context.mounted) {
          showToast(context, message: failure.message, status: 'error');
        }
      },
      (_) {
        state = const RequestSuccess(null);
        if (context.mounted) {
          showToast(
            context,
            message: 'Password reset successfully! Welcome to SB Consultants.',
            status: 'success',
          );
          context.go(AppRoutes.home);
        } else if (rootContext?.mounted ?? false) {
          rootContext!.go(AppRoutes.home);
        }
      },
    );
  }

  void updatePassword({
    required BuildContext context,
    required String newPassword,
  }) async {
    state = const RequestLoading();

    final result = await _repository.updatePassword(newPassword: newPassword);

    result.fold(
      (failure) {
        state = RequestFailure(failure);
        if (context.mounted) {
          showToast(context, message: failure.message, status: 'error');
        }
      },
      (_) {
        state = const RequestSuccess(null);
        if (context.mounted) {
          showToast(
            context,
            message: 'Password updated successfully! Welcome back.',
            status: 'success',
          );
          context.go(AppRoutes.home);
        } else if (rootContext?.mounted ?? false) {
          rootContext!.go(AppRoutes.home);
        }
      },
    );
  }

  void verifyOtp({
    required BuildContext context,
    required String email,
    required String otp,
  }) async {
    state = const RequestLoading();

    final result = await _repository.verifyOtp(email: email, otp: otp);

    result.fold(
      (failure) {
        state = RequestFailure(failure);
        if (context.mounted) {
          showToast(context, message: failure.message, status: 'error');
        }
      },
      (_) {
        state = const RequestSuccess(null);
        if (context.mounted) {
          showToast(
            context,
            message: 'auth.otp_verified'.tr(),
            status: 'success',
          );
          context.go(AppRoutes.home);
        } else if (rootContext?.mounted ?? false) {
          rootContext!.go(AppRoutes.home);
        }
      },
    );
  }

  void resendOtp({
    required BuildContext context,
    required String email,
  }) async {
    state = const RequestLoading();

    final result = await _repository.resendOtp(email: email);

    result.fold(
      (failure) {
        state = RequestFailure(failure);
        if (context.mounted) {
          showToast(context, message: failure.message, status: 'error');
        }
      },
      (_) {
        state = const RequestSuccess(null);
        if (context.mounted) {
          showToast(
            context,
            message: 'OTP resent to $email',
            status: 'success',
          );
        }
      },
    );
  }

  void resetState() {
    state = const RequestInitial();
  }

  void signInWithOAuth({
    required BuildContext context,
    required dynamic provider,
  }) async {
    // 1. If user is already logged in, handle gracefully without launching browser
    final existingUser = Supabase.instance.client.auth.currentUser;
    final existingSession = Supabase.instance.client.auth.currentSession;
    if (existingUser != null || existingSession != null) {
      final user = existingUser ?? existingSession?.user;
      final name = user?.userMetadata?['name'] ??
          user?.userMetadata?['full_name'] ??
          user?.email?.split('@').first ??
          'User';
      if (context.mounted) {
        showToast(
          context,
          message: 'Welcome back, $name! You are already signed in.',
          status: 'success',
        );
        context.go(AppRoutes.home);
      } else if (rootContext?.mounted ?? false) {
        rootContext!.go(AppRoutes.home);
      }
      return;
    }

    // 2. Check network connectivity before starting
    final hasNet = await InternetConnectionService().hasConnection();
    if (!hasNet) {
      if (context.mounted) {
        showToast(
          context,
          message: 'No internet connection. Please verify your connection and try again.',
          status: 'warning',
        );
      }
      return;
    }

    state = const RequestLoading();

    // 3. Set up AuthState listener to catch the return from OAuth
    StreamSubscription<AuthState>? authSub;
    Timer? timeoutTimer;

    void cleanup() {
      authSub?.cancel();
      timeoutTimer?.cancel();
    }

    timeoutTimer = Timer(const Duration(seconds: 90), () {
      cleanup();
      if (state.isLoading) {
        state = const RequestInitial();
        if (context.mounted) {
          showToast(
            context,
            message: 'Google Sign-In timed out. Please try again.',
            status: 'warning',
          );
        }
      }
    });

    authSub = Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      final event = data.event;
      final session = data.session;

      if (event != AuthChangeEvent.signedOut && session != null) {
        cleanup();
        state = const RequestSuccess(null);

        // Sync or upsert public profile asynchronously so UI transitions without delay
        unawaited(_syncGoogleProfile(session.user).catchError((_) {}));

        if (context.mounted) {
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
        } else if (rootContext?.mounted ?? false) {
          rootContext!.go(AppRoutes.home);
        }
      }
    });

    // 4. Trigger OAuth
    final result = await _repository.signInWithOAuth(provider);

    result.fold(
      (failure) {
        cleanup();
        state = RequestFailure(failure);
        final cleanMsg = _formatOAuthFailure(failure);
        if (context.mounted) {
          showToast(context, message: cleanMsg, status: 'error');
        }
      },
      (_) {
        // External browser was launched successfully.
        // We remain in RequestLoading state until callback arrives or timeout occurs.
      },
    );
  }

  String _formatOAuthFailure(Failure failure) {
    final msg = failure.message.toLowerCase();
    if (msg.contains('already registered') ||
        msg.contains('already exists') ||
        msg.contains('different credential') ||
        msg.contains('identity_already_exists')) {
      return 'An account already exists with this email. Please sign in using your password.';
    }
    if (msg.contains('provider is not enabled') ||
        msg.contains('unauthorized_client') ||
        msg.contains('not enabled')) {
      return 'Google Sign-In is temporarily unavailable. Please sign in with email and password.';
    }
    if (msg.contains('access_denied') ||
        msg.contains('cancelled') ||
        msg.contains('user_cancelled')) {
      return 'Google Sign-In was cancelled.';
    }
    if (msg.contains('activity') || msg.contains('browser')) {
      return 'No web browser found. Please ensure Chrome or a standard browser is installed.';
    }
    return failure.message;
  }

  Future<void> _syncGoogleProfile(User user) async {
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
}

