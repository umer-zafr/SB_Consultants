import 'package:flutter_sd_consultant/src/imports/core_imports.dart';
import 'package:flutter_sd_consultant/src/imports/packages_imports.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter_sd_consultant/src/data/models/user_model.dart';
import 'package:flutter_sd_consultant/src/data/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthService _authService = AuthService.instance;

  AppUser _toUser(Map<String, dynamic> userData, {String? fallbackEmail, String? fallbackName}) {
    final user = AppUser.fromJson(
      userData['user'] is Map<String, dynamic>
          ? userData['user'] as Map<String, dynamic>
          : userData,
    );
    if (fallbackEmail == null && fallbackName == null) return user;
    return AppUser(
      id: user.id,
      email: user.email.isEmpty ? (fallbackEmail ?? '') : user.email,
      name: user.name ?? fallbackName,
      phone: user.phone,
      city: user.city,
      photoUrl: user.photoUrl,
      role: user.role,
      createdAt: user.createdAt,
    );
  }

  @override
  Stream<AppUser?> get onAuthStateChanged {
    return _authService.authStateChanges.map((userData) {
      if (userData == null) return null;
      return _toUser(userData);
    });
  }

  @override
  FutureEither<AppUser> login({
    required String email,
    required String password,
  }) async {
    final result = await _authService.login(email: email, password: password);

    return result.flatMap((userData) {
      if (userData == null) {
        return left(const ServerFailure('Login failed: User record not found'));
      }
      return right(_toUser(userData, fallbackEmail: email));
    });
  }

  @override
  FutureEither<AppUser> signUp({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) async {
    final result = await _authService.signUp(
      name: name,
      phone: phone,
      email: email,
      password: password,
    );

    return result.flatMap((userData) {
      if (userData == null) {
        return left(
            const ServerFailure('Sign up failed: User record corrupted'));
      }
      return right(_toUser(userData, fallbackEmail: email, fallbackName: name));
    });
  }

  @override
  FutureEither<void> forgotPassword({required String email}) {
    return _authService.forgotPassword(email: email);
  }

  @override
  FutureEither<void> updatePassword({required String newPassword}) {
    return _authService.updatePassword(newPassword: newPassword);
  }

  @override
  FutureEither<void> resetPasswordWithOtp({
    required String email,
    required String otp,
    required String newPassword,
  }) {
    return _authService.resetPasswordWithOtp(
      email: email,
      otp: otp,
      newPassword: newPassword,
    );
  }

  @override
  FutureEither<void> logout() {
    return _authService.logout();
  }

  @override
  FutureEither<void> deleteAccount() {
    return _authService.deleteAccount();
  }

  @override
  FutureEither<AppUser?> checkAuthState() async {
    final result = await _authService.getCurrentUser();

    return result.map((userData) {
      if (userData == null) return null;
      return _toUser(userData);
    });
  }

  @override
  FutureEither<void> verifyOtp({required String email, required String otp}) {
    return _authService.verifyOtp(email: email, otp: otp);
  }

  @override
  FutureEither<void> resendOtp({required String email}) {
    return _authService.resendOtp(email: email);
  }

  @override
  FutureEither<void> signInWithOAuth(dynamic provider) async {
    if (provider is OAuthProvider) {
      return _authService.signInWithOAuth(provider);
    }
    return left<Failure, void>(const ServerFailure('Invalid OAuth provider'));
  }
}
