import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Centralized, industry-standard error formatter and exception translator.
///
/// Converts any technical Dart, Platform, Network, or Backend exception
/// into clean, user-friendly, and actionable feedback messages.
class AppErrorHandler {
  AppErrorHandler._();

  /// Formats any error object into a clean, human-readable string suitable for UI display.
  static String format(Object? error) {
    if (error == null) return 'An unexpected error occurred. Please try again.';
    if (error is String) return _cleanString(error);

    // 1. Dio Network & API Exceptions
    if (error is DioException) {
      return _formatDioException(error);
    }

    // 2. Supabase Auth Exceptions
    if (error is AuthException) {
      return _formatAuthException(error);
    }

    // 3. Supabase Postgrest Database Exceptions
    if (error is PostgrestException) {
      return _formatPostgrestException(error);
    }

    // 4. Low-level Network & Socket Exceptions
    if (error is SocketException) {
      return 'No internet connection. Please verify your Wi-Fi or cellular network.';
    }

    if (error is HttpException) {
      return 'Network communication error. Please try again in a few moments.';
    }

    // 5. Timeout Exceptions
    if (error is TimeoutException) {
      return 'The connection timed out. Please check your network and try again.';
    }

    // 6. Platform & Native Device Exceptions (Permissions, Camera, FilePicker)
    if (error is PlatformException) {
      return _formatPlatformException(error);
    }

    // 7. Data format & decoding exceptions
    if (error is FormatException) {
      return 'Received invalid response format. Please try again later.';
    }

    // 8. File system exceptions
    if (error is FileSystemException) {
      return 'Unable to access device storage. Please check device permissions.';
    }

    // 9. Generic Exception string inspection
    final errStr = error.toString();
    if (errStr.contains('SocketException') ||
        errStr.contains('NetworkImage') ||
        errStr.contains('Failed host lookup') ||
        errStr.contains('Network is unreachable')) {
      return 'Network connection lost. Please check your internet connection.';
    }

    if (errStr.contains('TimeoutException')) {
      return 'Operation timed out. Please try again.';
    }

    // Try extracting dynamic 'message' property if present
    try {
      final dynamic dynamicError = error;
      if (dynamicError.message != null && dynamicError.message is String) {
        final msg = (dynamicError.message as String).trim();
        if (msg.isNotEmpty && !msg.contains('Exception:')) {
          return msg;
        }
      }
    } catch (_) {}

    return _cleanString(errStr);
  }

  static String _formatDioException(DioException dioError) {
    switch (dioError.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timed out. Please check your internet connection and retry.';

      case DioExceptionType.badCertificate:
        return 'Security handshake failed. Please ensure your device clock is accurate.';

      case DioExceptionType.connectionError:
        return 'Cannot connect to server. Please verify your internet connection.';

      case DioExceptionType.cancel:
        return 'The request was cancelled.';

      case DioExceptionType.badResponse:
        final statusCode = dioError.response?.statusCode;
        final data = dioError.response?.data;

        // Try extracting backend server error message
        if (data is Map) {
          final serverMsg = data['message'] ?? data['error'] ?? data['detail'];
          if (serverMsg is String && serverMsg.trim().isNotEmpty) {
            return serverMsg.trim();
          }
        }

        if (statusCode == null) {
          return 'Server returned an unexpected response. Please try again.';
        }

        return switch (statusCode) {
          400 => 'Invalid request. Please check your inputs and try again.',
          401 => 'Session expired. Please sign in again to continue.',
          403 => 'Access denied. You do not have permission for this action.',
          404 => 'The requested resource could not be found.',
          408 => 'Request timed out on the server. Please try again.',
          409 => 'Conflict detected with existing record.',
          422 => 'Validation failed. Please review the submitted details.',
          429 => 'Too many requests. Please wait a moment before trying again.',
          final int code when code >= 500 && code < 600 =>
            'Server temporarily unavailable. Our team is resolving it.',
          _ => 'Server returned an error (code: $statusCode). Please try again.',
        };

      case DioExceptionType.unknown:
      default:
        if (dioError.error is SocketException) {
          return 'No internet connection. Please verify your Wi-Fi or cellular network.';
        }
        return 'Unable to complete request. Please check your connection and try again.';
    }
  }

  static String _formatAuthException(AuthException authError) {
    final msg = authError.message.toLowerCase();

    if (msg.contains('invalid login credentials') || msg.contains('invalid_grant')) {
      return 'Incorrect email or password. Please verify and try again.';
    }
    if (msg.contains('email not confirmed') || msg.contains('unconfirmed')) {
      return 'Please verify your email address before signing in.';
    }
    if (msg.contains('user already registered') || msg.contains('already exists')) {
      return 'An account with this email address already exists. Please log in.';
    }
    if (msg.contains('rate limit') || msg.contains('too many requests')) {
      return 'Too many login attempts. Please wait a few minutes before trying again.';
    }
    if (msg.contains('user not found')) {
      return 'No account found with this email address.';
    }
    if (msg.contains('token has expired') || msg.contains('expired')) {
      return 'Your verification token or session has expired. Please request a new one.';
    }
    if (msg.contains('weak password') || msg.contains('password should be at least')) {
      return 'Password must be at least 6 characters long.';
    }

    return authError.message.isNotEmpty
        ? authError.message
        : 'Authentication failed. Please verify your credentials.';
  }

  static String _formatPostgrestException(PostgrestException pgError) {
    // Check postgres standard error codes
    switch (pgError.code) {
      case '23505':
        return 'This record already exists in the system.';
      case '42501':
        return 'Permission denied: You do not have authorization for this operation.';
      case 'PGRST116':
        return 'Requested record was not found.';
      case 'PGRST301':
        return 'Your session has expired. Please sign in again.';
      default:
        if (pgError.message.isNotEmpty) {
          return pgError.message;
        }
        return 'Database operation failed. Please try again.';
    }
  }

  static String _formatPlatformException(PlatformException platformError) {
    final code = platformError.code.toLowerCase();
    final message = platformError.message?.toLowerCase() ?? '';

    if (code.contains('camera_access_denied') || message.contains('camera')) {
      return 'Camera permission was denied. Please grant access in device Settings.';
    }
    if (code.contains('photo_access_denied') || message.contains('photo') || message.contains('storage')) {
      return 'Storage permission was denied. Please grant access in device Settings.';
    }
    if (code.contains('canceled') || code.contains('cancelled') || message.contains('cancel')) {
      return 'Operation was cancelled.';
    }

    return (platformError.message?.isNotEmpty ?? false)
        ? platformError.message!
        : 'Device platform error occurred. Please try again.';
  }

  static String _cleanString(String raw) {
    var cleaned = raw.trim();
    if (cleaned.startsWith('Exception: ')) {
      cleaned = cleaned.substring('Exception: '.length).trim();
    }
    if (cleaned.isEmpty) {
      return 'An unexpected error occurred. Please try again.';
    }
    return cleaned;
  }
}
