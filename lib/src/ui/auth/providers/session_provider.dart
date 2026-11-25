import 'dart:async';
import 'package:flutter_sd_consultant/src/imports/imports.dart';
import 'package:flutter_sd_consultant/src/data/models/user_model.dart';
import 'package:flutter_sd_consultant/src/data/repositories/auth_repository.dart';
import 'package:flutter_sd_consultant/src/data/repositories/auth_repository_impl.dart';
import 'package:flutter_sd_consultant/src/ui/dashboard/my_applications_screen.dart';
import 'package:flutter_sd_consultant/src/ui/home/providers/home_provider.dart';

/// Exhaustive session variants — prefer `switch (state)` over status enums.
sealed class SessionState {
  const SessionState();

  AppUser? get userOrNull => switch (this) {
        SessionAuthenticated(:final user) => user,
        _ => null,
      };

  bool get isUnknown => this is SessionUnknown;
  bool get isAuthenticated => this is SessionAuthenticated;
  bool get isUnauthenticated => this is SessionUnauthenticated;
}

final class SessionUnknown extends SessionState {
  const SessionUnknown();
}

final class SessionAuthenticated extends SessionState {
  const SessionAuthenticated(this.user);
  final AppUser user;
}

final class SessionUnauthenticated extends SessionState {
  const SessionUnauthenticated();
}

SessionState sessionFromUser(AppUser? user) => switch (user) {
      final AppUser u => SessionAuthenticated(u),
      null => const SessionUnauthenticated(),
    };

/// Provides the AuthRepository instance
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl();
});

/// Provides a stream of auth state changes
final authStateStreamProvider = StreamProvider<AppUser?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.onAuthStateChanged;
});

/// Provides the current session state
final sessionProvider = StateNotifierProvider<SessionNotifier, SessionState>((ref) {
  final repo = ref.read(authRepositoryProvider);
  return SessionNotifier(repository: repo, ref: ref);
});

/// Indicates whether current authenticated user has administrative privileges
final isAdminProvider = Provider<bool>((ref) {
  final session = ref.watch(sessionProvider);
  return session.userOrNull?.isAdmin ?? false;
});

class SessionNotifier extends StateNotifier<SessionState>
    with StreamSubscriptionsMixin {
  SessionNotifier({required AuthRepository repository, required Ref ref})
      : _repository = repository,
        _ref = ref,
        super(const SessionUnknown()) {
    _init();
  }

  final AuthRepository _repository;
  final Ref _ref;

  Future<void> _init() async {
    final result = await _repository.checkAuthState();
    state = result.fold(
      (_) => const SessionUnauthenticated(),
      sessionFromUser,
    );

    addSubscription(
      _repository.onAuthStateChanged.listen((user) async {
        state = sessionFromUser(user);
        if (user == null) {
          _ref.read(isSponsoredJobsUnlockedProvider.notifier).state = false;
          _ref.read(isScholarshipsUnlockedProvider.notifier).state = false;
        } else {
          await syncDirectoryUnlocks(_ref);
        }
      }),
    );
  }

  Future<void> logout() async {
    state = const SessionUnauthenticated();
    _ref.read(isSponsoredJobsUnlockedProvider.notifier).state = false;
    _ref.read(isScholarshipsUnlockedProvider.notifier).state = false;
    _ref.read(userApplicationsListProvider.notifier).clearAll();
    try {
      await _repository.logout();
    } catch (_) {}
  }

  Future<bool> deleteAccount() async {
    try {
      final res = await _repository.deleteAccount();
      final isSuccess = res.fold(
        (failure) => false,
        (_) {
          // Keep user authenticated! Just clear all application records & unlocked items
          _ref.read(userApplicationsListProvider.notifier).clearAll();
          _ref.read(isSponsoredJobsUnlockedProvider.notifier).state = false;
          _ref.read(isScholarshipsUnlockedProvider.notifier).state = false;
          return true;
        },
      );
      return isSuccess;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    cancelSubscriptions();
    super.dispose();
  }
}
