import 'dart:async';
import 'dart:ui' as ui;
import 'src/imports/core_imports.dart';
import 'src/imports/packages_imports.dart';
import 'src/services/push_notification_service.dart';
import 'src/app.dart';

Future<void> main() async {
  await runZonedGuarded(_bootstrap, (error, stackTrace) {
    AppLogger.error(
      'Unhandled asynchronous error caught by runZonedGuarded',
      error: error,
      stackTrace: stackTrace,
      category: LogCategory.app,
    );
  });
}

Future<void> _bootstrap() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // 1. Flutter Framework-level error handling
  FlutterError.onError = (details) {
    AppLogger.error(
      'Flutter framework error',
      error: details.exception,
      stackTrace: details.stack ?? StackTrace.current,
      category: LogCategory.app,
      context: {'library': details.library ?? 'unknown'},
    );
    // In debug mode, present the error to console; in release, suppress fatal abort
    FlutterError.presentError(details);
  };

  // 2. Global UI Error Fallback Widget (Replaces ugly Red/Gray Crash Screens)
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFECACA)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEE2E2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFDC2626),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Content Display Notice',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF991B1B),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Unable to render this section. Please swipe or refresh.',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFFB91C1C),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  };

  // 3. Platform & Engine-level error handling
  ui.PlatformDispatcher.instance.onError = (error, stackTrace) {
    AppLogger.error(
      'Unhandled platform error caught by PlatformDispatcher',
      error: error,
      stackTrace: stackTrace,
      category: LogCategory.app,
    );
    // Returning true informs the Flutter engine that the error has been handled
    // and prevents native host app process crashes.
    return true;
  };

  AppLogger.info('Application bootstrap started', category: LogCategory.app);

  try {
    await EasyLocalization.ensureInitialized();
  } catch (e, st) {
    AppLogger.error('Localization initialization warning', error: e, stackTrace: st, category: LogCategory.app);
  }

  try {
    await dotenv.load(fileName: '.env', isOptional: true);
  } catch (e, st) {
    AppLogger.warning('Dotenv optional load notice: $e', error: e, stackTrace: st, category: LogCategory.app);
  }

  try {
    await AppConfig.init();
    AppLogger.success(
      'Application configuration initialized',
      category: LogCategory.backend,
    );
  } catch (e, st) {
    AppLogger.error('AppConfig initialization error', error: e, stackTrace: st, category: LogCategory.backend);
  }

  try {
    await PushNotificationService.instance.initialize();
  } catch (e, st) {
    AppLogger.warning('OneSignal Push initialization notice: $e', error: e, stackTrace: st, category: LogCategory.app);
  }

  runApp(
    const LocalizationWrapper(
      child: StateWrapper(
        child: App(),
      ),
    ),
  );

  AppLogger.success('Application started successfully', category: LogCategory.app);
}
