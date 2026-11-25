import 'package:flutter_sd_consultant/src/imports/core_imports.dart';
import 'package:flutter_sd_consultant/src/imports/packages_imports.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  late final PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onSkip() {
    context.go(AppRoutes.login);
  }

  void _onNext() {
    if (_currentIndex < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      context.go(AppRoutes.signup);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;

    final slides = [
      _OnboardingSlideData(
        icon: Icons.flight_takeoff_rounded,
        title: 'onboarding.onboarding_title_1'.tr(),
        subtitle: 'onboarding.onboarding_subtitle_1'.tr(),
        accentColor: cs.primary,
      ),
      _OnboardingSlideData(
        icon: Icons.support_agent_rounded,
        title: 'onboarding.onboarding_title_2'.tr(),
        subtitle: 'onboarding.onboarding_subtitle_2'.tr(),
        accentColor: const Color(0xFF5B7FA5),
      ),
      _OnboardingSlideData(
        icon: Icons.timeline_rounded,
        title: 'onboarding.onboarding_title_3'.tr(),
        subtitle: 'onboarding.onboarding_subtitle_3'.tr(),
        accentColor: cs.primary,
      ),
    ];

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Top Header: Brand + Skip Button
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.lg.w,
                vertical: AppSpacing.sm.h,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8.r),
                          child: Image.asset(
                            AppAssets.logo,
                            height: 32.h,
                            width: 32.w,
                            fit: BoxFit.cover,
                          ),
                        ),
                        SizedBox(width: AppSpacing.sm.w),
                        Flexible(
                          child: Text(
                            'SB Consultants',
                            softWrap: true,
                            style: tt.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: cs.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _onSkip,
                    child: Text(
                      'Skip',
                      style: tt.labelLarge?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // PageView Slider
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: slides.length,
                onPageChanged: (index) => setState(() => _currentIndex = index),
                itemBuilder: (context, index) {
                  final slide = slides[index];
                  return Center(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl.w),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Illustration card
                            Container(
                              width: 200.w,
                              height: 200.w,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    slide.accentColor.withValues(alpha: 0.15),
                                    slide.accentColor.withValues(alpha: 0.05),
                                  ],
                                ),
                                border: Border.all(
                                  color: slide.accentColor.withValues(alpha: 0.25),
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Icon(
                                  slide.icon,
                                  size: 96.sp,
                                  color: slide.accentColor,
                                ),
                              ),
                            ),
                            SizedBox(height: AppSpacing.xxxl.h),

                            // Title
                            Text(
                              slide.title,
                              textAlign: TextAlign.center,
                              style: tt.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: cs.onSurface,
                                height: 1.25,
                              ),
                            ),
                            SizedBox(height: AppSpacing.md.h),

                            // Subtitle
                            Text(
                              slide.subtitle,
                              textAlign: TextAlign.center,
                              style: tt.bodyMedium?.copyWith(
                                color: cs.onSurfaceVariant,
                                height: 1.5,
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

            // Bottom Section: Dots indicator & Actions
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.xl.w,
                vertical: AppSpacing.lg.h,
              ),
              child: Column(
                children: [
                  // Smooth Dots Indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(slides.length, (index) {
                      final isActive = index == _currentIndex;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: EdgeInsets.symmetric(horizontal: 4.w),
                        width: isActive ? 24.w : 8.w,
                        height: 8.h,
                        decoration: BoxDecoration(
                          color: isActive
                              ? cs.primary
                              : cs.outlineVariant.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      );
                    }),
                  ),
                  SizedBox(height: AppSpacing.xl.h),

                  // Next / Get Started button
                  AppButton(
                    label: _currentIndex == slides.length - 1
                        ? 'shared.get_started'.tr()
                        : 'Next',
                    onPressed: _onNext,
                    isFullWidth: true,
                  ),
                  SizedBox(height: AppSpacing.sm.h),

                  // Sign In link
                  TextButton(
                    onPressed: () => context.go(AppRoutes.login),
                    child: RichText(
                      text: TextSpan(
                        text: 'auth.already_have_account'.tr(),
                        style: tt.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                        children: [
                          TextSpan(
                            text: 'auth.sign_in'.tr(),
                            style: TextStyle(
                              color: cs.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingSlideData {
  const _OnboardingSlideData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
}
