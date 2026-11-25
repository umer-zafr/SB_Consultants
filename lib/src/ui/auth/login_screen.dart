import 'package:flutter_sd_consultant/src/imports/core_imports.dart';
import 'package:flutter_sd_consultant/src/imports/packages_imports.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter_sd_consultant/src/ui/auth/providers/auth_provider.dart';
import 'package:flutter_sd_consultant/src/ui/auth/providers/session_provider.dart';
import 'package:flutter_sd_consultant/src/ui/auth/widgets/social_login_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _isGoogleAuthPending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAlreadyLoggedIn();
    });
  }

  void _checkAlreadyLoggedIn() {
    final session = ref.read(sessionProvider);
    final user = Supabase.instance.client.auth.currentUser;
    if (session.isAuthenticated && user != null && mounted) {
      final name = user.userMetadata?['name'] ??
          user.userMetadata?['full_name'] ??
          user.email?.split('@').first ??
          'User';
      showToast(context, message: 'Welcome back, $name!', status: 'success');
      context.go(AppRoutes.home);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isGoogleAuthPending) {
      Future.delayed(const Duration(milliseconds: 2500), () {
        if (!mounted) return;
        final user = Supabase.instance.client.auth.currentUser;
        if (user == null && _isGoogleAuthPending) {
          setState(() => _isGoogleAuthPending = false);
          ref.read(authControllerProvider.notifier).resetState();
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;

    Future<void> handleLogin() async {
      if (!(_formKey.currentState?.validate() ?? false)) return;

      ref.read(authControllerProvider.notifier).login(
            context: context,
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
    }

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: 24.w,
              vertical: 24.h,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 460.w,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 12.h),

                  // ---------------------------------------------------------
                  // LOGO
                  // ---------------------------------------------------------
                  Center(
                    child: Container(
                      width: 80.w,
                      height: 80.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: cs.primary.withValues(alpha: 0.12),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: cs.primary.withValues(alpha: 0.15),
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child: Padding(
                          padding: EdgeInsets.all(4.w),
                          child: Image.asset(
                            AppAssets.logo,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 18.h),

                  // ---------------------------------------------------------
                  // BRAND
                  // ---------------------------------------------------------
                  Center(
                    child: Text(
                      'SB Consultants',
                      style: tt.titleLarge?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),

                  SizedBox(height: 34.h),

                  // ---------------------------------------------------------
                  // TITLE
                  // ---------------------------------------------------------
                  Text(
                    'auth.welcome_back'.tr(),
                    textAlign: TextAlign.center,
                    style: tt.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),

                  SizedBox(height: 8.h),

                  Text(
                    'auth.log_in_subtitle'.tr(),
                    textAlign: TextAlign.center,
                    style: tt.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),

                  SizedBox(height: 30.h),

                  // ---------------------------------------------------------
                  // FORM
                  // ---------------------------------------------------------
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Email
                        AppTextField(
                          controller: _emailController,
                          enabled: !isLoading,
                          label: 'auth.email'.tr(),
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: Icon(
                            Icons.email_outlined,
                            color: cs.onSurfaceVariant,
                          ),
                          validator: (v) {
                            if (AppUtils.isBlank(v)) {
                              return 'auth.email_required'.tr();
                            }

                            if (!AppUtils.isValidEmail(v!)) {
                              return 'auth.email_invalid'.tr();
                            }

                            return null;
                          },
                        ),

                        SizedBox(height: 18.h),

                        // Password
                        AppTextField(
                          controller: _passwordController,
                          enabled: !isLoading,
                          label: 'auth.password'.tr(),
                          obscureText: _obscurePassword,
                          prefixIcon: Icon(
                            Icons.lock_outline,
                            color: cs.onSurfaceVariant,
                          ),
                          suffixIcon: IconButton(
                            tooltip: _obscurePassword
                                ? 'Show password'
                                : 'Hide password',
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: cs.onSurfaceVariant,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          validator: (v) {
                            if (AppUtils.isBlank(v)) {
                              return 'auth.password_required'.tr();
                            }

                            if (v!.length < 6) {
                              return 'auth.password_too_short'.tr();
                            }

                            return null;
                          },
                        ),

                        SizedBox(height: 10.h),

                        // -----------------------------------------------------
                        // REMEMBER + FORGOT PASSWORD
                        // -----------------------------------------------------
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                borderRadius: BorderRadius.circular(8.r),
                                onTap: isLoading
                                    ? null
                                    : () {
                                        setState(() {
                                          _rememberMe = !_rememberMe;
                                        });
                                      },
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 22.w,
                                      height: 22.w,
                                      child: Checkbox(
                                        value: _rememberMe,
                                        onChanged: isLoading
                                            ? null
                                            : (value) {
                                                setState(() {
                                                  _rememberMe = value ?? false;
                                                });
                                              },
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(5.r),
                                        ),
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    ),
                                    SizedBox(width: 7.w),
                                    Flexible(
                                      child: Text(
                                        'auth.remember_me'.tr(),
                                        style: tt.bodySmall?.copyWith(
                                          color: cs.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: isLoading
                                  ? null
                                  : () {
                                      context.push(
                                        AppRoutes.forgotPassword,
                                      );
                                    },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 4.w,
                                  vertical: 4.h,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'auth.forgot_password'.tr(),
                                style: tt.bodySmall?.copyWith(
                                  color: cs.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 22.h),

                        // -----------------------------------------------------
                        // SIGN IN
                        // -----------------------------------------------------
                        SizedBox(
                          height: 54.h,
                          child: AppButton(
                            label: 'auth.login_button'.tr(),
                            isLoading: isLoading,
                            onPressed: isLoading ? null : handleLogin,
                            isFullWidth: true,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 28.h),

                  // ---------------------------------------------------------
                  // DIVIDER
                  // ---------------------------------------------------------
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: cs.outlineVariant,
                          thickness: 1,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14.w),
                        child: Text(
                          'auth.or_continue_with'.tr(),
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: cs.outlineVariant,
                          thickness: 1,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 20.h),

                  // ---------------------------------------------------------
                  // SOCIAL LOGIN
                  // ---------------------------------------------------------
                  SocialLoginButton(
                    asset: AppAssets.google,
                    label: 'Continue with Google',
                    isLoading: _isGoogleAuthPending && isLoading,
                    onPressed: isLoading
                        ? null
                        : () {
                            setState(() => _isGoogleAuthPending = true);
                            ref
                                .read(
                                  authControllerProvider.notifier,
                                )
                                .signInWithOAuth(
                                  context: context,
                                  provider: OAuthProvider.google,
                                );
                          },
                  ),

                  SizedBox(height: 30.h),

                  // ---------------------------------------------------------
                  // SIGN UP
                  // ---------------------------------------------------------
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'auth.dont_have_account'.tr(),
                        style: tt.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      TextButton(
                        onPressed: isLoading
                            ? null
                            : () {
                                context.push(AppRoutes.signup);
                              },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.only(left: 5.w),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'auth.sign_up'.tr(),
                          style: tt.bodyMedium?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 12.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

