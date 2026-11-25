import '../imports/imports.dart';

/// A service to handle URL launching operations.
class UrlLauncherService {
  UrlLauncherService._();
  static final UrlLauncherService instance = UrlLauncherService._();

  /// Launch a URL string.
  FutureEither<void> launch(String url, {LaunchMode? mode}) async {
    final formattedUrl = _formatUrl(url);
    final uri = Uri.tryParse(formattedUrl);
    if (uri == null) {
      return Left(ValidationFailure('Invalid URL: $url'));
    }
    return runTask(
      () async {
        bool launched = false;
        try {
          launched = await launchUrl(
            uri,
            mode: mode ?? LaunchMode.externalApplication,
          );
        } catch (_) {}

        if (!launched) {
          try {
            launched = await launchUrl(
              uri,
              mode: LaunchMode.platformDefault,
            );
          } catch (_) {}
        }

        if (!launched) {
          // Last attempt with canLaunchUrl check
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri);
          } else {
            throw Exception('Could not launch url: $formattedUrl');
          }
        }
      },
      operation: 'urlLauncher.launch',
      category: LogCategory.app,
      context: {'host': uri.host, 'url': formattedUrl},
    );
  }

  String _formatUrl(String url) {
    var trimmed = url.trim();
    if (trimmed.isEmpty) return trimmed;
    if (trimmed.isValidPhoneNumber) {
      return !kIsWeb && defaultTargetPlatform == TargetPlatform.android
          ? 'whatsapp://send?phone=$trimmed'
          : 'https://wa.me/$trimmed';
    }
    if (!trimmed.contains('://') &&
        !trimmed.startsWith('mailto:') &&
        !trimmed.startsWith('tel:')) {
      trimmed = 'https://$trimmed';
    }
    return trimmed;
  }
}
