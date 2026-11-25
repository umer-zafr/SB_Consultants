import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_sd_consultant/src/data/models/user_model.dart';
import 'package:flutter_sd_consultant/src/routing/app_routes.dart';

void main() {
  group('Security Hardening Audit Verification Tests', () {
    test('AppUser default role is strictly "user" (no privilege escalation)', () {
      const user = AppUser(
        id: 'usr-123',
        email: 'applicant@example.com',
        name: 'Test Applicant',
      );

      expect(user.role, equals('user'));
      expect(user.isAdmin, isFalse);
    });

    test('AppUser role parsing safely maps non-admin inputs', () {
      final json = {
        'id': 'usr-456',
        'email': 'user@example.com',
        'full_name': 'Regular User',
        'role': 'user',
      };

      final user = AppUser.fromJson(json);
      expect(user.isAdmin, isFalse);
      expect(user.role, equals('user'));
    });

    test('AppUser only grants isAdmin when role is explicitly "admin"', () {
      final adminUser = AppUser.fromJson(const {
        'id': 'adm-789',
        'email': 'admin@sbconsultant.site',
        'full_name': 'Admin User',
        'role': 'admin',
      });

      final staffUser = AppUser.fromJson(const {
        'id': 'stf-001',
        'email': 'staff@sbconsultant.site',
        'full_name': 'Consultant Staff',
        'role': 'consultant',
      });

      expect(adminUser.isAdmin, isTrue);
      expect(staffUser.isAdmin, isFalse);
    });

    test('Sensitive routes are distinct from public routes', () {
      final protectedRoutes = <String>{
        AppRoutes.myApplications,
        AppRoutes.applicationProcedure,
        AppRoutes.profile,
        AppRoutes.adminDashboard,
        AppRoutes.payfastPayment,
      };

      const publicRoutes = <String>{
        AppRoutes.splash,
        AppRoutes.onboarding,
        AppRoutes.login,
        AppRoutes.signup,
        AppRoutes.forgotPassword,
        AppRoutes.resetPassword,
        AppRoutes.otpVerification,
        AppRoutes.loginCallback,
      };

      for (final route in protectedRoutes) {
        expect(
          publicRoutes.contains(route),
          isFalse,
          reason: 'Route $route must not be in publicRoutes set',
        );
      }
    });
  });
}
