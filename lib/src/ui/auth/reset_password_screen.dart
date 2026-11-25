import 'dart:async';
import 'package:flutter_sd_consultant/src/imports/core_imports.dart';
import 'package:flutter_sd_consultant/src/imports/packages_imports.dart';
import 'package:flutter_sd_consultant/src/ui/auth/providers/auth_provider.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, this.email = ''});

  final String email;

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  int _resendTimer = 60;
  Timer? _timer;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.email);
    _startTimer();
  }

  void _startTimer() {
    _resendTimer = 60;
    _canResend = false;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimer > 0) {
        if (mounted) setState(() => _resendTimer--);
      } else {
        if (mounted) setState(() => _canResend = true);
        timer.cancel();
      }
    });
  }

  String get _otp => _otpControllers.map((c) => c.text).join();

  @override
  void dispose() {
    _timer?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _handleReset() {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      showToast(context, message: 'Please enter your email', status: 'error');
      return;
    }

    if (_otp.length < 6) {
      showToast(
        context,
        message: 'Please enter the complete 6-digit verification code',
        status: 'error',
      );
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) return;

    ref.read(authControllerProvider.notifier).resetPasswordWithOtp(
          context: context,
          email: email,
          otp: _otp,
          newPassword: _passwordController.text,
        );
  }

  void _handleResend() {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      showToast(context, message: 'Please enter your email', status: 'error');
      return;
    }
    if (_canResend) {
      ref.read(authControllerProvider.notifier).forgotPassword(
            context: context,
            email: email,
          );
      _startTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<RequestState<void>>(authControllerProvider, (prev, next) {
      if (next is RequestFailure) {
        for (final c in _otpControllers) {
          c.clear();
        }
        if (_otpFocusNodes.isNotEmpty) {
          _otpFocusNodes[0].requestFocus();
        }
      }
    });

    final isLoading = ref.watch(authControllerProvider).isLoading;
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;
    final displayEmail = _emailController.text.trim();

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppTopBar(
        title: '',
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(AppRoutes.login);
          }
        },
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 460.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Brand Logo
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

                  SizedBox(height: 20.h),

                  // Title
                  Center(
                    child: Text(
                      'Reset Your Password',
                      style: tt.headlineSmall?.copyWith(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Center(
                    child: Text(
                      displayEmail.isNotEmpty
                          ? 'Enter the 6-digit code sent to\n$displayEmail'
                          : 'Enter the 6-digit recovery code and your new password.',
                      textAlign: TextAlign.center,
                      style: tt.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ),

                  SizedBox(height: 28.h),

                  // Email input if not provided
                  if (widget.email.isEmpty) ...[
                    AppTextField(
                      controller: _emailController,
                      enabled: !isLoading,
                      label: 'Account Email',
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: const Icon(Icons.email_outlined),
                      validator: (v) {
                        if (AppUtils.isBlank(v)) {
                          return 'Please enter your email';
                        }
                        if (!AppUtils.isValidEmail(v!)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20.h),
                  ],

                  // 6-digit OTP code prompt
                  Text(
                    'Verification Code',
                    style: tt.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                  SizedBox(height: 10.h),

                  // OTP Boxes
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(6, (index) {
                        return Container(
                          width: 45.w,
                          height: 55.h,
                          margin: EdgeInsets.symmetric(horizontal: 4.w),
                          child: TextField(
                            controller: _otpControllers[index],
                            focusNode: _otpFocusNodes[index],
                            enabled: !isLoading,
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            style: tt.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: InputDecoration(
                              counterText: '',
                              filled: true,
                              fillColor: cs.surfaceContainerHighest
                                  .withValues(alpha: 0.3),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: cs.outline),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: cs.primary,
                                  width: 2,
                                ),
                              ),
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            onChanged: (value) {
                              if (value.length > 1) {
                                final digits =
                                    value.replaceAll(RegExp(r'\D'), '');
                                for (int i = 0;
                                    i < digits.length && (index + i) < 6;
                                    i++) {
                                  _otpControllers[index + i].text = digits[i];
                                }
                                final nextIndex =
                                    (index + digits.length).clamp(0, 5);
                                _otpFocusNodes[nextIndex].requestFocus();
                                if (_otp.length == 6) {
                                  FocusScope.of(context).unfocus();
                                }
                                return;
                              }
                              if (value.isNotEmpty && index < 5) {
                                _otpFocusNodes[index + 1].requestFocus();
                              } else if (value.isEmpty && index > 0) {
                                _otpFocusNodes[index - 1].requestFocus();
                              }
                              if (_otp.length == 6) {
                                FocusScope.of(context).unfocus();
                              }
                            },
                          ),
                        );
                      }),
                    ),
                  ),

                  SizedBox(height: 22.h),

                  // Form for New Password
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // New Password Field
                        AppTextField(
                          controller: _passwordController,
                          enabled: !isLoading,
                          label: 'New Password',
                          hint: 'At least 6 characters',
                          obscureText: _obscurePassword,
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 20.sp,
                            ),
                            onPressed: () {
                              setState(
                                  () => _obscurePassword = !_obscurePassword);
                            },
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a new password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),

                        SizedBox(height: 16.h),

                        // Confirm New Password Field
                        AppTextField(
                          controller: _confirmPasswordController,
                          enabled: !isLoading,
                          label: 'Confirm New Password',
                          hint: 'Re-enter your new password',
                          obscureText: _obscureConfirmPassword,
                          prefixIcon: const Icon(Icons.lock_reset_rounded),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 20.sp,
                            ),
                            onPressed: () {
                              setState(() => _obscureConfirmPassword =
                                  !_obscureConfirmPassword);
                            },
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please confirm your password';
                            }
                            if (value != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),

                        SizedBox(height: 28.h),

                        // Submit Button
                        AppButton(
                          label: 'Reset & Sign In',
                          isLoading: isLoading,
                          onPressed: isLoading ? null : _handleReset,
                          isFullWidth: true,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 18.h),

                  // Resend Code row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Didn't receive code? ",
                        style: tt.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      TextButton(
                        onPressed: _canResend && !isLoading ? _handleResend : null,
                        child: Text(
                          _canResend
                              ? 'Resend Code'
                              : 'Resend in ${_resendTimer}s',
                          style: tt.labelLarge?.copyWith(
                            color: _canResend ? cs.primary : cs.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 12.h),

                  // Back to Login
                  Center(
                    child: TextButton(
                      onPressed: isLoading
                          ? null
                          : () {
                              context.go(AppRoutes.login);
                            },
                      child: Text(
                        'Back to Login',
                        style: tt.bodyMedium?.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
