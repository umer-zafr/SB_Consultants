import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'error_handler.dart';

/// Domain-level failure hierarchy. Prefer exhaustive `switch` over `is` checks.
sealed class Failure extends Equatable {
  const Failure(this.message, {this.error});

  final String message;
  final Object? error;

  /// Maps thrown objects into a typed, user-friendly [Failure] for railway-style APIs.
  factory Failure.fromException(Object error, [StackTrace? stackTrace]) {
    if (error is Failure) return error;

    final message = AppErrorHandler.format(error);

    if (error is DioException) {
      return switch (error.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout =>
          TimeoutFailure(message, error: error),
        DioExceptionType.badResponse => ServerFailure(message, error: error),
        DioExceptionType.connectionError ||
        DioExceptionType.badCertificate =>
          NetworkFailure(message, error: error),
        _ => NetworkFailure(message, error: error),
      };
    }

    if (error is AuthException) {
      return AuthFailure(message, error: error);
    }

    if (error is PostgrestException) {
      return ServerFailure(message, error: error);
    }

    if (error is SocketException || error is HttpException) {
      return NetworkFailure(message, error: error);
    }

    if (error is TimeoutException) {
      return TimeoutFailure(message, error: error);
    }

    if (error is PlatformException) {
      final code = error.code.toLowerCase();
      if (code.contains('permission') || code.contains('denied')) {
        return PermissionFailure(message, error: error);
      }
      return UnknownFailure(message, error: error);
    }

    if (error is FormatException) {
      return ValidationFailure(message, error: error);
    }

    if (error is FileSystemException) {
      return StorageFailure(message, error: error);
    }

    final errStr = error.toString();
    if (errStr.contains('SocketException') || errStr.contains('Network')) {
      return NetworkFailure(message, error: error);
    }

    return UnknownFailure(message, error: error);
  }

  @override
  List<Object?> get props => [message, error];

  @override
  String toString() => message;
}

final class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.error});
}

final class CacheFailure extends Failure {
  const CacheFailure(super.message, {super.error});
}

final class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {super.error});
}

final class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.error});
}

final class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {super.error});
}

final class PermissionFailure extends Failure {
  const PermissionFailure(super.message, {super.error});
}

final class TimeoutFailure extends Failure {
  const TimeoutFailure(super.message, {super.error});
}

final class StorageFailure extends Failure {
  const StorageFailure(super.message, {super.error});
}

final class UnknownFailure extends Failure {
  const UnknownFailure(super.message, {super.error});
}
