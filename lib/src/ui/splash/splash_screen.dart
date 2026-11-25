import 'dart:async';
import 'package:flutter_sd_consultant/src/imports/core_imports.dart';
import 'package:flutter_sd_consultant/src/imports/packages_imports.dart';
import 'package:flutter_sd_consultant/src/ui/auth/providers/session_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Dismiss the native splash screen as soon as Flutter renders
    FlutterNativeSplash.remove();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.6, curve: Curves.easeOut),
      ),
    );
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.6, curve: Curves.elasticOut),
      ),
    );
    _controller.forward();

    // Allow user to view the branded splash for 2.5s before proceeding
    _timer = Timer(const Duration(milliseconds: 2500), _navigateToNext);
  }

  void _navigateToNext() {
    if (!mounted) return;
    final session = ref.read(sessionProvider);
    if (session.isAuthenticated) {
      context.go(AppRoutes.home);
    } else {
      context.go(AppRoutes.onboarding);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Circular Company Logo
                      Container(
                        width: 130.w,
                        height: 130.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: cs.primary.withValues(alpha: 0.15),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                          border: Border.all(
                            color: cs.primary.withValues(alpha: 0.2),
                            width: 2.5,
                          ),
                        ),
                        child: ClipOval(
                          child: Padding(
                            padding: EdgeInsets.all(6.w),
                            child: Image.asset(
                              AppAssets.logo,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: AppSpacing.lg.h),

                      // Company Name
                      Text(
                        'SB',
                        style: tt.displayMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: cs.primary,
                          letterSpacing: 2,
                        ),
                      ),
                      Text(
                        'Consultants',
                        style: tt.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: cs.primary,
                          letterSpacing: 1,
                        ),
                      ),
                      SizedBox(height: AppSpacing.sm.h),

                      // Tagline
                      Text(
                        'Your Trusted Visa Partner',
                        style: tt.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: AppSpacing.xxl.h),

                      // Loading indicator
                      SizedBox(
                        width: 28.w,
                        height: 28.w,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
