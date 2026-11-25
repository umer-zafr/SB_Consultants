/// Centralized route path constants for GoRouter.
///
/// Use these variables instead of raw strings throughout the app.
/// Example: `context.go(AppRoutes.onboarding)` instead of `context.go('/')`.
abstract final class AppRoutes {
  AppRoutes._();

  static const String splash = '/splash';
  static const String home = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String otpVerification = '/otp-verification';
  static const String visaDetail = '/visa-detail';
  static const String viewDetail = '/view-detail';
  static const String detail = '/detail';
  static const String details = '/details';
  static const String viewDetails = '/view-details';
  static const String visitVisa = '/visit-visa';
  static const String studyVisa = '/study-visa';
  static const String workVisa = '/work-visa';
  static const String businessVisa = '/business-visa';
  static const String goldenVisa = '/golden-visa';
  static const String sponsoredJobs = '/sponsored-jobs';
  static const String scholarships = '/scholarships';
  static const String applicantDetails = '/applicant-details';
  static const String paymentCheckout = '/payment-checkout';
  static const String payfastPayment = '/payfast-payment';
  static const String payment = '/payment';
  static const String paymentSuccess = '/payment-success';
  static const String paymentPending = '/payment-pending';
  static const String paymentFailed = '/payment-failed';
  static const String paymentStatus = '/payment-status';
  static const String myApplications = '/my-applications';
  static const String dashboard = '/dashboard';
  static const String applicationProcedure = '/application-procedure';
  static const String profile = '/profile';
  static const String savedVisas = '/saved-visas';
  static const String adminDashboard = '/admin';
  static const String notifications = '/notifications';

  /// Deep link OAuth callback route
  static const String loginCallback = '/login-callback';

  /// Debug-only component gallery.
  static const String uiShowcase = '/debug/ui-showcase';
}
