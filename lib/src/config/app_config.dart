import '../middleware/dio_logging_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/storage_service.dart';

class AppConfig {
  AppConfig._();
  static late final Dio dio;
  static late final SupabaseClient supabase;

  static String get baseUrl => _getBaseUrl();

  static Future<void> init() async {
    await StorageService.instance.init();
    await Supabase.initialize(
      url: dotenv.get('SUPABASE_URL',
          fallback: 'https://YOUR-PROJECT.supabase.co'),
      publishableKey:
          dotenv.get('SUPABASE_ANON_KEY', fallback: 'YOUR-ANON-KEY'),
      authOptions: FlutterAuthClientOptions(
        detectSessionInUri: true,
        detectSessionInUriPredicate: (uri) =>
            uri.host == 'login-callback' ||
            uri.scheme == 'sbconsultants' ||
            uri.scheme == 'com.sbconsultants.app' ||
            uri.scheme == 'com.example.flutter_sd_consultant' ||
            uri.host.contains('sbconsultant.site'),
      ),
    );
    supabase = Supabase.instance.client;
    dio = Dio(
      BaseOptions(
        baseUrl: _getBaseUrl(),
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(DioLoggingInterceptor());
  }

  static String _getBaseUrl() {
    return dotenv.get('API_BASE_URL', fallback: 'https://api.example.com');
  }
}
