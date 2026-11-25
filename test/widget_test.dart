import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fpdart/fpdart.dart';

import 'package:flutter_sd_consultant/src/app.dart';
import 'package:flutter_sd_consultant/src/data/models/user_model.dart';
import 'package:flutter_sd_consultant/src/data/repositories/auth_repository.dart';
import 'package:flutter_sd_consultant/src/ui/auth/providers/session_provider.dart';
import 'package:flutter_sd_consultant/src/utils/utils.dart';

class MockAuthRepository implements AuthRepository {
  const MockAuthRepository();

  @override
  Stream<AppUser?> get onAuthStateChanged => const Stream.empty();

  @override
  FutureEither<AppUser> login({
    required String email,
    required String password,
  }) async =>
      left(const ServerFailure('test'));

  @override
  FutureEither<AppUser> signUp({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) async =>
      left(const ServerFailure('test'));

  @override
  FutureEither<void> forgotPassword({required String email}) async => right(null);

  @override
  FutureEither<void> updatePassword({required String newPassword}) async => right(null);

  @override
  FutureEither<void> resetPasswordWithOtp({
    required String email,
    required String otp,
    required String newPassword,
  }) async =>
      right(null);

  @override
  FutureEither<void> logout() async => right(null);

  @override
  FutureEither<void> deleteAccount() async => right(null);

  @override
  FutureEither<AppUser?> checkAuthState() async => right(null);

  @override
  FutureEither<void> verifyOtp({required String email, required String otp}) async => right(null);

  @override
  FutureEither<void> resendOtp({required String email}) async => right(null);

  @override
  FutureEither<void> signInWithOAuth(dynamic provider) async => right(null);
}

void main() {
  testWidgets('App should build', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en')],
        path: 'assets/translations',
        fallbackLocale: const Locale('en'),
        saveLocale: false,
        child: ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(const MockAuthRepository()),
          ],
          child: const App(),
        ),
      ),
    );

    expect(find.byType(App), findsOneWidget);
  });
}
