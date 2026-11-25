import 'dart:async';
import 'package:flutter_sd_consultant/src/imports/core_imports.dart';
import 'package:flutter_sd_consultant/src/imports/packages_imports.dart';
import 'package:flutter_sd_consultant/src/ui/auth/providers/auth_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  const OtpVerificationScreen({super.key, required this.email});

  final String email;

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState
    extends ConsumerState<OtpVerificationScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  int _resendTimer = 60;
  Timer? _timer;
  bool _canResend = false;
  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.session != null && mounted) {
        showToast(context, message: 'Account verified successfully!', status: 'success');
        context.go(AppRoutes.home);
      }
    });
  }

  void _startTimer() {
    _resendTimer = 60;
    _canResend = false;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimer > 0) {
        setState(() => _resendTimer--);
      } else {
        setState(() => _canResend = true);
        timer.cancel();
      }
    });
  }

  String get _otp => _controllers.map((c) => c.text).join();

  @override
  void dispose() {
    _timer?.cancel();
    _authSub?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _handleVerify() {
    if (_otp.length == 6) {
      ref.read(authControllerProvider.notifier).verifyOtp(
            context: context,
            email: widget.email,
            otp: _otp,
          );
    } else {
      showToast(context, message: 'auth.otp_invalid'.tr(), status: 'error');
    }
  }

  void _handleResend() {
    if (_canResend) {
      ref.read(authControllerProvider.notifier).resendOtp(
            context: context,
            email: widget.email,
          );
      _startTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<RequestState<void>>(authControllerProvider, (prev, next) {
      if (next is RequestFailure) {
        for (final c in _controllers) {
          c.clear();
        }
        if (_focusNodes.isNotEmpty) {
          _focusNodes[0].requestFocus();
        }
      }
    });

    final isLoading = ref.watch(authControllerProvider).isLoading;
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;

    return Scaffold(
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
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg.w),
          child: Column(
            children: [
              SizedBox(height: AppSpacing.xl.h),

              // Logo
              Container(
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
              SizedBox(height: AppSpacing.lg.h),

              // Mail icon
              Container(
                padding: EdgeInsets.all(AppSpacing.lg.w),
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.mark_email_read_outlined,
                  size: 48.sp,
                  color: cs.primary,
                ),
              ),
              SizedBox(height: AppSpacing.xl.h),

              // Title
              Text(
                'auth.verify_email'.tr(),
                style: tt.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: AppSpacing.sm.h),
              Text(
                'auth.verify_subtitle'.tr(),
                textAlign: TextAlign.center,
                style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
              SizedBox(height: AppSpacing.xs.h),
              Text(
                widget.email,
                style: tt.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: cs.primary,
                ),
              ),
              SizedBox(height: AppSpacing.md.h),
              Container(
                margin: EdgeInsets.symmetric(horizontal: 4.w),
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: cs.primary.withValues(alpha: 0.18),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 18.sp, color: cs.primary),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        'Didn\'t receive code in inbox? Please check your Spam or Junk folder. You can enter the 6-digit OTP or tap the confirmation link in your email.',
                        style: tt.bodySmall?.copyWith(
                          fontSize: 11.5.sp,
                          color: cs.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.xl.h),

              // OTP input boxes
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
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
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
                          borderSide:
                              BorderSide(color: cs.primary, width: 2),
                        ),
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      onChanged: (value) {
                        if (value.length > 1) {
                          // Handle pasted OTP (e.g. 6 digits pasted into one box)
                          final digits = value.replaceAll(RegExp(r'\D'), '');
                          for (int i = 0; i < digits.length && (index + i) < 6; i++) {
                            _controllers[index + i].text = digits[i];
                          }
                          final nextIndex = (index + digits.length).clamp(0, 5);
                          _focusNodes[nextIndex].requestFocus();
                          if (_otp.length == 6) {
                            FocusScope.of(context).unfocus();
                            _handleVerify();
                          }
                          return;
                        }
                        if (value.isNotEmpty && index < 5) {
                          _focusNodes[index + 1].requestFocus();
                        } else if (value.isEmpty && index > 0) {
                          _focusNodes[index - 1].requestFocus();
                        }
                        if (_otp.length == 6) {
                          FocusScope.of(context).unfocus();
                          _handleVerify();
                        }
                      },
                    ),
                  );
                }),
                ),
              ),
              SizedBox(height: AppSpacing.xxxl.h),

              // Verify button
              AppButton(
                label: 'auth.verify_button'.tr(),
                isLoading: isLoading,
                onPressed: isLoading ? null : _handleVerify,
                isFullWidth: true,
              ),
              SizedBox(height: AppSpacing.xl.h),

              // Resend
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'auth.didnt_receive'.tr(),
                    style: tt.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  TextButton(
                    onPressed: _canResend ? _handleResend : null,
                    child: Text(
                      _canResend
                          ? 'auth.resend'.tr()
                          : 'Resend in ${_resendTimer}s',
                      style: tt.labelLarge?.copyWith(
                        color: _canResend
                            ? cs.primary
                            : cs.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.sm.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.info_outline_rounded, size: 15.sp, color: cs.onSurfaceVariant),
                    SizedBox(width: 6.w),
                    Flexible(
                      child: Text(
                        'Can\'t find it? Check your Spam or Junk folder.',
                        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.xl.h),
            ],
          ),
        ),
      ),
    );
  }
}



