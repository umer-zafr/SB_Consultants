import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_sd_consultant/src/middleware/app_route_observer.dart';
import 'package:flutter_sd_consultant/src/routing/global_navigator.dart';
import 'package:flutter_sd_consultant/src/routing/app_routes.dart';
import 'package:flutter_sd_consultant/src/ui/auth/providers/session_provider.dart'; // <-- fix this path if wrong

import 'package:flutter_sd_consultant/src/ui/auth/login_screen.dart';
import 'package:flutter_sd_consultant/src/ui/auth/signup_screen.dart';
import 'package:flutter_sd_consultant/src/ui/auth/forgot_password_screen.dart';
import 'package:flutter_sd_consultant/src/ui/auth/reset_password_screen.dart';
import 'package:flutter_sd_consultant/src/ui/auth/otp_verification_screen.dart';
import 'package:flutter_sd_consultant/src/ui/auth/oauth_callback_screen.dart';

import 'package:flutter_sd_consultant/src/ui/home/home_page.dart';
import 'package:flutter_sd_consultant/src/ui/onboarding/onboarding_page.dart';
import 'package:flutter_sd_consultant/src/ui/splash/splash_screen.dart';
import 'package:flutter_sd_consultant/src/ui/visa/visit_visa_screen.dart';
import 'package:flutter_sd_consultant/src/ui/visa/business_visa_screen.dart';
import 'package:flutter_sd_consultant/src/ui/visa/golden_visa_screen.dart';
import 'package:flutter_sd_consultant/src/ui/visa/study_visa_screen.dart';
import 'package:flutter_sd_consultant/src/ui/visa/work_visa_screen.dart';
import 'package:flutter_sd_consultant/src/data/models/detail_item_model.dart';
import 'package:flutter_sd_consultant/src/data/models/visa_listing_model.dart';
import 'package:flutter_sd_consultant/src/data/repositories/detail_repository.dart';
import 'package:flutter_sd_consultant/src/ui/detail/detail_screen.dart';
import 'package:flutter_sd_consultant/src/ui/apply/applicant_details_screen.dart';
import 'package:flutter_sd_consultant/src/ui/payment/payment_status_screen.dart';
import 'package:flutter_sd_consultant/src/ui/payment/payment_checkout_screen.dart';
import 'package:flutter_sd_consultant/src/ui/payment/payfast_in_app_payment_screen.dart';
import 'package:flutter_sd_consultant/src/ui/dashboard/my_applications_screen.dart';
import 'package:flutter_sd_consultant/src/ui/dashboard/application_procedure_screen.dart';
import 'package:flutter_sd_consultant/src/ui/profile/profile_screen.dart';
import 'package:flutter_sd_consultant/src/ui/saved/saved_visas_screen.dart';
import 'package:flutter_sd_consultant/src/ui/jobs/sponsored_jobs_paywall_screen.dart';
import 'package:flutter_sd_consultant/src/ui/notifications/notifications_screen.dart';
import 'package:flutter_sd_consultant/src/ui/admin/admin_dashboard_screen.dart';


import 'package:flutter_sd_consultant/src/shared/widgets/ui/ui_showcase_screen.dart';
import 'package:flutter/foundation.dart';

/// Helper: turns any Stream into a Listenable so GoRouter can watch it.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _sub = stream.asBroadcastStream().listen((_) => notifyListeners());
  }
  late final StreamSubscription<dynamic> _sub;
  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

/// Comprehensive builder for DetailScreen supporting:
/// 1. DetailItemModel extra
/// 2. VisaListingModel extra
/// 3. Map extra
/// 4. Path parameter :id (e.g. /detail/:id)
/// 5. URI query parameters (?id=...&title=...)
/// 6. High-fidelity UK Student Visa default
Widget _buildDetailScreen(BuildContext context, GoRouterState state) {
  final extra = state.extra;
  if (extra is DetailItemModel) {
    return DetailScreen(item: extra);
  } else if (extra is VisaListingModel) {
    return DetailScreen(item: DetailRepository.getDetailForVisa(extra));
  } else if (extra is Map<String, dynamic>) {
    if (extra['item'] is DetailItemModel) {
      return DetailScreen(item: extra['item'] as DetailItemModel);
    }
    final title = (extra['title'] as String?) ??
        state.uri.queryParameters['title'] ??
        'UK Student Visa';
    return DetailScreen(
      item: DetailRepository.getDetailFromGeneric(
        id: (extra['id'] as String?) ??
            state.pathParameters['id'] ??
            state.uri.queryParameters['id'],
        title: title,
        subtitle: (extra['subtitle'] as String?) ??
            state.uri.queryParameters['subtitle'],
        countryName: (extra['countryName'] as String?) ??
            state.uri.queryParameters['country'],
        categoryTag: (extra['categoryTag'] as String?) ??
            state.uri.queryParameters['category'],
        fee: (extra['fee'] as String?) ?? state.uri.queryParameters['fee'],
      ),
    );
  }

  // Deep-link / direct URL query parameter fallback
  final paramId = state.pathParameters['id'] ?? state.uri.queryParameters['id'];
  final paramTitle = state.uri.queryParameters['title'];
  if (paramTitle != null && paramTitle.isNotEmpty) {
    return DetailScreen(
      item: DetailRepository.getDetailFromGeneric(
        id: paramId,
        title: paramTitle,
        subtitle: state.uri.queryParameters['subtitle'],
        countryName: state.uri.queryParameters['country'],
        categoryTag: state.uri.queryParameters['category'],
        fee: state.uri.queryParameters['fee'],
      ),
    );
  }

  if (paramId != null && paramId.isNotEmpty) {
    return DetailScreen(
      item: DetailRepository.getDetailByIdOrSlug(paramId),
    );
  }

  return DetailScreen(item: DetailRepository.getUkStudentVisaDetail());
}

/// The router is now a Provider instead of a bare top-level constant.
final goRouterProvider = Provider<GoRouter>((ref) {
  final sessionNotifier = ref.watch(sessionProvider.notifier);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    observers: <NavigatorObserver>[AppRouteObserver()],
    refreshListenable: GoRouterRefreshStream(sessionNotifier.stream),
    redirect: (context, state) => _sessionRedirect(ref, state),
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.signup,
        name: 'signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        name: 'forgotPassword',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        name: 'resetPassword',
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return ResetPasswordScreen(email: email);
        },
      ),
      GoRoute(
        path: AppRoutes.otpVerification,
        name: 'otpVerification',
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return OtpVerificationScreen(email: email);
        },
      ),
      GoRoute(
        path: AppRoutes.loginCallback,
        name: 'loginCallback',
        builder: (context, state) => const OAuthCallbackScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: AppRoutes.visitVisa,
        name: 'visitVisa',
        builder: (context, state) => const VisitVisaScreen(),
      ),
      GoRoute(
        path: AppRoutes.businessVisa,
        name: 'businessVisa',
        builder: (context, state) => const BusinessVisaScreen(),
      ),
      GoRoute(
        path: AppRoutes.goldenVisa,
        name: 'goldenVisa',
        builder: (context, state) => const GoldenVisaScreen(),
      ),
      GoRoute(
        path: AppRoutes.studyVisa,
        name: 'studyVisa',
        builder: (context, state) => const StudyVisaScreen(),
      ),
      GoRoute(
        path: AppRoutes.workVisa,
        name: 'workVisa',
        builder: (context, state) => const WorkVisaScreen(),
      ),
      GoRoute(
        path: AppRoutes.sponsoredJobs,
        name: 'sponsoredJobs',
        builder: (context, state) =>
            const SponsoredJobsPaywallScreen(isScholarship: false),
      ),
      GoRoute(
        path: AppRoutes.scholarships,
        name: 'scholarships',
        builder: (context, state) =>
            const SponsoredJobsPaywallScreen(isScholarship: true),
      ),

      // =======================================================================
      // DETAIL SCREEN (With comprehensive alias & deep-link support)
      // =======================================================================
      GoRoute(
        path: AppRoutes.visaDetail,
        name: 'visaDetail',
        builder: _buildDetailScreen,
      ),
      GoRoute(
        path: AppRoutes.viewDetail,
        name: 'viewDetail',
        builder: _buildDetailScreen,
      ),
      GoRoute(
        path: AppRoutes.detail,
        name: 'detail',
        builder: _buildDetailScreen,
      ),
      GoRoute(
        path: AppRoutes.details,
        name: 'details',
        builder: _buildDetailScreen,
      ),
      GoRoute(
        path: AppRoutes.viewDetails,
        name: 'viewDetails',
        builder: _buildDetailScreen,
      ),
      GoRoute(
        path: '/visa_detail',
        name: 'visa_detail',
        builder: _buildDetailScreen,
      ),
      GoRoute(
        path: '/visa-detail/:id',
        builder: _buildDetailScreen,
      ),
      GoRoute(
        path: '/view-detail/:id',
        builder: _buildDetailScreen,
      ),
      GoRoute(
        path: '/detail/:id',
        builder: _buildDetailScreen,
      ),

      GoRoute(
        path: AppRoutes.applicantDetails,
        name: 'applicantDetails',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is DetailItemModel) {
            return ApplicantDetailsScreen(item: extra);
          }
          return ApplicantDetailsScreen(
            item: DetailRepository.getUkStudentVisaDetail(),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.paymentCheckout,
        name: 'paymentCheckout',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is DetailItemModel) {
            return PaymentCheckoutScreen(item: extra);
          } else if (extra is Map<String, dynamic>) {
            return PaymentCheckoutScreen(
              item: extra['item'] as DetailItemModel?,
              customReference: extra['customReference'] as String?,
              formData: extra['formData'] as Map<String, dynamic>?,
              applicantName: extra['applicantName'] as String?,
              applicantEmail: extra['applicantEmail'] as String?,
              applicantPhone: extra['applicantPhone'] as String?,
              applicantPassport: extra['applicantPassport'] as String?,
            );
          }
          return const PaymentCheckoutScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.payment,
        name: 'payment',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is DetailItemModel) {
            return PaymentCheckoutScreen(item: extra);
          } else if (extra is Map<String, dynamic>) {
            return PaymentCheckoutScreen(
              item: extra['item'] as DetailItemModel?,
              customReference: extra['customReference'] as String?,
              formData: extra['formData'] as Map<String, dynamic>?,
              applicantName: extra['applicantName'] as String?,
              applicantEmail: extra['applicantEmail'] as String?,
              applicantPhone: extra['applicantPhone'] as String?,
              applicantPassport: extra['applicantPassport'] as String?,
            );
          }
          return const PaymentCheckoutScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.payfastPayment,
        name: 'payfastPayment',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is Map<String, dynamic>) {
            return PayFastInAppPaymentScreen(
              checkoutUrl: extra['checkoutUrl'] as String? ?? 'https://ipg1.apps.net.pk/Ecommerce/api/Transaction/PostTransaction',
              checkoutHtml: extra['checkoutHtml'] as String?,
              transactionId: extra['transactionId'] as String? ?? 'TXN-${DateTime.now().millisecondsSinceEpoch}',
              referenceId: extra['referenceId'] as String? ?? 'REF-${DateTime.now().millisecondsSinceEpoch}',
              amount: (extra['amount'] as num?)?.toDouble() ?? 500.0,
              merchantId: extra['merchantId'] as String? ?? '102',
              isSandbox: extra['isSandbox'] as bool? ?? true,
              item: extra['item'] as DetailItemModel?,
              finalPaidItem: extra['finalPaidItem'] as DetailItemModel?,
            );
          }
          return const PaymentCheckoutScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.paymentSuccess,
        name: 'paymentSuccess',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is Map<String, dynamic>) {
            return PaymentStatusScreen(
              initialStatus: PaymentStatus.success,
              item: extra['item'] as DetailItemModel?,
              amount: extra['amount'] as String?,
              transactionId: extra['transactionId'] as String?,
              referenceId: extra['referenceId'] as String?,
              paymentMethod: extra['paymentMethod'] as String?,
              applicationRef: extra['applicationRef'] as String?,
            );
          }
          return PaymentStatusScreen(
            initialStatus: PaymentStatus.success,
            item: extra is DetailItemModel ? extra : null,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.paymentPending,
        name: 'paymentPending',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is Map<String, dynamic>) {
            return PaymentStatusScreen(
              initialStatus: PaymentStatus.pending,
              item: extra['item'] as DetailItemModel?,
              amount: extra['amount'] as String?,
              transactionId: extra['transactionId'] as String?,
              referenceId: extra['referenceId'] as String?,
              paymentMethod: extra['paymentMethod'] as String?,
              applicationRef: extra['applicationRef'] as String?,
            );
          }
          return PaymentStatusScreen(
            initialStatus: PaymentStatus.pending,
            item: extra is DetailItemModel ? extra : null,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.paymentFailed,
        name: 'paymentFailed',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is Map<String, dynamic>) {
            return PaymentStatusScreen(
              initialStatus: PaymentStatus.failed,
              item: extra['item'] as DetailItemModel?,
              amount: extra['amount'] as String?,
              transactionId: extra['transactionId'] as String?,
              referenceId: extra['referenceId'] as String?,
              paymentMethod: extra['paymentMethod'] as String?,
              applicationRef: extra['applicationRef'] as String?,
            );
          }
          return PaymentStatusScreen(
            initialStatus: PaymentStatus.failed,
            item: extra is DetailItemModel ? extra : null,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.paymentStatus,
        name: 'paymentStatus',
        builder: (context, state) {
          final extra = state.extra;
          final statusParam = state.uri.queryParameters['status'];
          final status = statusParam == 'pending'
              ? PaymentStatus.pending
              : statusParam == 'failed'
                  ? PaymentStatus.failed
                  : PaymentStatus.success;
          if (extra is Map<String, dynamic>) {
            return PaymentStatusScreen(
              initialStatus: status,
              item: extra['item'] as DetailItemModel?,
              amount: extra['amount'] as String?,
              transactionId: extra['transactionId'] as String?,
              referenceId: extra['referenceId'] as String?,
              paymentMethod: extra['paymentMethod'] as String?,
              applicationRef: extra['applicationRef'] as String?,
            );
          }
          return PaymentStatusScreen(
            initialStatus: status,
            item: extra is DetailItemModel ? extra : null,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.myApplications,
        name: 'myApplications',
        builder: (context, state) {
          final extra = state.extra;
          return MyApplicationsScreen(
            newlyAddedItem: extra is DetailItemModel ? extra : null,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        name: 'dashboard',
        builder: (context, state) {
          final extra = state.extra;
          return MyApplicationsScreen(
            newlyAddedItem: extra is DetailItemModel ? extra : null,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.applicationProcedure,
        name: 'applicationProcedure',
        builder: (context, state) {
          final extra = state.extra;
          return ApplicationProcedureScreen(
            application: extra is ApplicationRecordItem ? extra : null,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.profile,
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.savedVisas,
        name: 'savedVisas',
        builder: (context, state) => const SavedVisasScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminDashboard,
        name: 'adminDashboard',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        name: 'notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      if (kDebugMode)
        GoRoute(
          path: AppRoutes.uiShowcase,
          name: 'uiShowcase',
          builder: (context, state) => const UiShowcaseScreen(),
        ),
    ],
  );
});

String? _sessionRedirect(Ref ref, GoRouterState state) {
  final session = ref.read(sessionProvider);
  final loc = state.matchedLocation;

  // Never redirect away while on the splash screen — let SplashScreen handle its timing.
  if (loc == AppRoutes.splash) {
    return null;
  }

  const publicRoutes = <String>{
    AppRoutes.splash,
    AppRoutes.onboarding,
    AppRoutes.login,
    AppRoutes.signup,
    AppRoutes.forgotPassword,
    AppRoutes.resetPassword,
    AppRoutes.otpVerification,
    AppRoutes.loginCallback,
    AppRoutes.uiShowcase,
    AppRoutes.visaDetail,
    AppRoutes.viewDetail,
    AppRoutes.detail,
    AppRoutes.details,
    AppRoutes.viewDetails,
    '/visa_detail',
    AppRoutes.visitVisa,
    AppRoutes.studyVisa,
    AppRoutes.workVisa,
    AppRoutes.businessVisa,
    AppRoutes.goldenVisa,
  };

  // If session state is still unknown, stay on splash or current screen
  if (session.isUnknown) {
    return null;
  }

  // If unauthenticated: prevent access to protected routes (like home)
  if (session.isUnauthenticated) {
    if (!publicRoutes.contains(loc)) {
      return AppRoutes.onboarding;
    }
    return null;
  }

  // If authenticated: prevent user from visiting auth/onboarding screens
  if (session.isAuthenticated) {
    if (loc == AppRoutes.onboarding ||
        loc == AppRoutes.login ||
        loc == AppRoutes.signup ||
        loc == AppRoutes.forgotPassword ||
        loc == AppRoutes.loginCallback) {
      return AppRoutes.home;
    }

    // Role-based route guard for Admin Dashboard
    if (loc == AppRoutes.adminDashboard) {
      final isAdmin = session.userOrNull?.isAdmin ?? false;
      if (!isAdmin) {
        return AppRoutes.home;
      }
    }

    return null;
  }

  return null;
}
