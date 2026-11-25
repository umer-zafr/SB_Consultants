import 'package:flutter_sd_consultant/src/imports/core_imports.dart';
import 'package:flutter_sd_consultant/src/imports/packages_imports.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter_sd_consultant/src/ui/auth/providers/auth_provider.dart';
import 'package:flutter_sd_consultant/src/ui/auth/widgets/social_login_button.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen>
    with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
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
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null && mounted) {
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
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider).isLoading;
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;

    void navigateToLogin() {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(AppRoutes.login);
      }
    }

    Future<void> handleSignup() async {
      if (!(_formKey.currentState?.validate() ?? false)) return;
      ref.read(authControllerProvider.notifier).signUp(
            context: context,
            name: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
            email: _emailController.text.trim().toLowerCase(),
            password: _passwordController.text,
          );
    }

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Back to Login',
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: cs.onSurface,
            size: 20.w,
          ),
          onPressed: isLoading ? null : navigateToLogin,
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: 24.w,
              vertical: 8.h,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 460.w,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo
                  Center(
                    child: Container(
                      width: 76.w,
                      height: 76.w,
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

                  SizedBox(height: 12.h),

                  // Brand
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

                  SizedBox(height: 18.h),

                  // Title
                  Text(
                    'auth.create_account'.tr(),
                    textAlign: TextAlign.center,
                    style: tt.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),

                  SizedBox(height: 6.h),

                  Text(
                    'auth.sign_up_subtitle'.tr(),
                    textAlign: TextAlign.center,
                    style: tt.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),

                  SizedBox(height: 22.h),

                  // Form
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Name
                        AppTextField(
                          controller: _nameController,
                          enabled: !isLoading,
                          label: 'auth.name'.tr(),
                          prefixIcon: Icon(
                            Icons.person_outline,
                            color: cs.onSurfaceVariant,
                          ),
                          validator: (v) {
                            if (AppUtils.isBlank(v)) {
                              return 'auth.name_required'.tr();
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 14.h),

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
                        SizedBox(height: 14.h),

                        // Phone Number
                        AppTextField(
                          controller: _phoneController,
                          enabled: !isLoading,
                          label: 'auth.phone'.tr(),
                          keyboardType: TextInputType.phone,
                          prefixIcon: Icon(
                            Icons.phone_outlined,
                            color: cs.onSurfaceVariant,
                          ),
                          validator: (v) {
                            if (AppUtils.isBlank(v)) {
                              return 'auth.phone_required'.tr();
                            }
                            if (!AppUtils.isPhoneNumber(v!.trim())) {
                              return 'auth.phone_invalid'.tr();
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 14.h),

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
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
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
                        SizedBox(height: 14.h),

                        // Confirm Password
                        AppTextField(
                          controller: _confirmPasswordController,
                          enabled: !isLoading,
                          label: 'auth.confirm_password'.tr(),
                          obscureText: _obscureConfirmPassword,
                          prefixIcon: Icon(
                            Icons.lock_outline,
                            color: cs.onSurfaceVariant,
                          ),
                          suffixIcon: IconButton(
                            tooltip: _obscureConfirmPassword
                                ? 'Show password'
                                : 'Hide password',
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: cs.onSurfaceVariant,
                            ),
                            onPressed: () => setState(
                              () => _obscureConfirmPassword =
                                  !_obscureConfirmPassword,
                            ),
                          ),
                          validator: (v) {
                            if (AppUtils.isBlank(v)) {
                              return 'auth.confirm_password_required'.tr();
                            }
                            if (v != _passwordController.text) {
                              return 'auth.passwords_do_not_match'.tr();
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 22.h),

                        // Sign Up button
                        SizedBox(
                          height: 54.h,
                          child: AppButton(
                            label: 'auth.create_account_button'.tr(),
                            isLoading: isLoading,
                            onPressed: isLoading ? null : handleSignup,
                            isFullWidth: true,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 22.h),

                  // Divider with "Or Continue With"
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

                  SizedBox(height: 18.h),

                  SocialLoginButton(
                    asset: AppAssets.google,
                    label: 'Continue with Google',
                    isLoading: _isGoogleAuthPending && isLoading,
                    onPressed: isLoading
                        ? null
                        : () {
                            setState(() => _isGoogleAuthPending = true);
                            ref
                                .read(authControllerProvider.notifier)
                                .signInWithOAuth(
                                  context: context,
                                  provider: OAuthProvider.google,
                                );
                          },
                  ),

                  SizedBox(height: 16.h),
                ],
              ),
            ),
          ),
        ),
      ),
      // Pinned bottom bar: NEVER hidden, no scrolling required to see Login button!
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 24.w),
          decoration: BoxDecoration(
            color: cs.surface,
            border: Border(
              top: BorderSide(
                color: cs.outlineVariant.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'auth.already_have_account'.tr(),
                style: tt.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              TextButton(
                onPressed: isLoading ? null : navigateToLogin,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.only(left: 4.w),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'auth.log_in'.tr(),
                  style: tt.bodyMedium?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
