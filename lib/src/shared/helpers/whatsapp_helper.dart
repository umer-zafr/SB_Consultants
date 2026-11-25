import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Helper utility for opening WhatsApp chat and phone calls to SB Consultants (+92 315 5440606).
class WhatsAppHelper {
  WhatsAppHelper._();

  /// Official SB Consultants WhatsApp & Helpline number.
  static const String rawNumber = '923155440606';
  static const String displayNumber = '+92 315 5440606';
  static const String officialEmail = 'sbconsultantofficial@gmail.com';

  /// Launches WhatsApp chat directly to SB Consultants with an optional prefilled message.
  /// Tries the native app scheme first, then falls back to the official wa.me universal URL.
  static Future<bool> launchChat({
    String phone = rawNumber,
    String? message,
  }) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final encodedMsg = message != null && message.trim().isNotEmpty
        ? Uri.encodeComponent(message.trim())
        : '';

    final query = encodedMsg.isNotEmpty ? '?text=$encodedMsg' : '';
    final nativeQuery = encodedMsg.isNotEmpty ? '&text=$encodedMsg' : '';

    final nativeUri = Uri.parse('whatsapp://send?phone=$cleanPhone$nativeQuery');
    final webUri = Uri.parse('https://wa.me/$cleanPhone$query');

    try {
      if (await canLaunchUrl(nativeUri)) {
        return await launchUrl(nativeUri, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(webUri)) {
        return await launchUrl(webUri, mode: LaunchMode.externalApplication);
      } else {
        return await launchUrl(webUri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      debugPrint('WhatsApp launch error: $e');
      try {
        return await launchUrl(webUri, mode: LaunchMode.externalApplication);
      } catch (_) {
        return false;
      }
    }
  }

  /// Dials the SB Consultants official helpline number.
  static Future<bool> launchCall({String phone = '+923155440606'}) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri);
      }
    } catch (e) {
      debugPrint('Phone dial error: $e');
    }
    return false;
  }

  /// Launches email composer directed to SB Consultants official email.
  static Future<bool> launchEmail({
    String email = officialEmail,
    String subject = 'Inquiry - SB Consultants',
    String? body,
  }) async {
    final cleanEmail = email.trim();
    final encodedSubject = Uri.encodeComponent(subject);
    final encodedBody = body != null && body.trim().isNotEmpty
        ? '&body=${Uri.encodeComponent(body.trim())}'
        : '';
    final uri = Uri.parse('mailto:$cleanEmail?subject=$encodedSubject$encodedBody');
    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri);
      }
    } catch (e) {
      debugPrint('Email launch error: $e');
    }
    return false;
  }
}
