import 'package:flutter_sd_consultant/src/imports/core_imports.dart';
import 'package:flutter_sd_consultant/src/imports/packages_imports.dart';

import 'package:flutter_sd_consultant/src/ui/auth/providers/session_provider.dart';

class SessionListenerWrapper extends ConsumerWidget {
  final Widget child;
  const SessionListenerWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<SessionState>(sessionProvider, (prev, next) {
      AppLogger.provider(
        'Session state changed',
        context: {
          'state': switch (next) {
            SessionUnknown() => 'unknown',
            SessionAuthenticated() => 'authenticated',
            SessionUnauthenticated() => 'unauthenticated',
          },
        },
      );
      // Navigation removed — redirect in app_router.dart now handles this.
      // We keep this listener only to remove the native splash screen.
      switch (next) {
        case SessionUnknown():
          break;
        case SessionAuthenticated():
        case SessionUnauthenticated():
          FlutterNativeSplash.remove();
      }
    });

    return child;
  }
}
