import 'package:flutter_sd_consultant/src/utils/utils.dart';
import 'package:flutter_sd_consultant/src/data/models/user_model.dart';

abstract class AuthRepository {
  /// Stream of auth state changes. Emits AppUser when authenticated, null when not.
  Stream<AppUser?> get onAuthStateChanged;

  /// Sign in with email and password
  FutureEither<AppUser> login({
    required String email,
    required String password,
  });

  /// Sign up with email, password, name, and phone
  FutureEither<AppUser> signUp({
    required String name,
    required String phone,
    required String email,
    required String password,
  });

  /// Send a password reset email
  FutureEither<void> forgotPassword({
    required String email,
  });

  /// Update password for the currently authenticated user
  FutureEither<void> updatePassword({
    required String newPassword,
  });

  /// Reset password using 6-digit recovery OTP
  FutureEither<void> resetPasswordWithOtp({
    required String email,
    required String otp,
    required String newPassword,
  });

  /// Sign out the current user
  FutureEither<void> logout();

  /// Permanently delete the user account and all associated data
  FutureEither<void> deleteAccount();

  /// Check if the user is currently authenticated natively
  FutureEither<AppUser?> checkAuthState();

  /// Verify OTP sent to email
  FutureEither<void> verifyOtp({required String email, required String otp});

  /// Resend OTP to email
  FutureEither<void> resendOtp({required String email});

  /// Sign in with OAuth provider (Google, Facebook, Apple)
  FutureEither<void> signInWithOAuth(dynamic provider);
}

