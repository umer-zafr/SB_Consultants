import 'package:flutter_sd_consultant/src/imports/core_imports.dart';
import 'package:flutter_sd_consultant/src/imports/packages_imports.dart';

/// Auto-swipeable promotional banner carousel with a page indicator.
class BannerCarousel extends StatefulWidget {
  const BannerCarousel({
    super.key,
    required this.banners,
    this.onBannerTap,
  });

  final List<Map<String, String>> banners;
  final ValueChanged<int>? onBannerTap;

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  late final PageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildBannerImage(String? url, Color fallbackColor) {
    final cleanUrl = url?.trim() ?? '';
    if (cleanUrl.startsWith('assets/')) {
      return Image.asset(
        cleanUrl,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) => Image.asset(
          'assets/images/feature_banner_1.jpg',
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    } else if (cleanUrl.startsWith('http://') || cleanUrl.startsWith('https://')) {
      return Image.network(
        cleanUrl,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) => Image.asset(
          'assets/images/feature_banner_1.jpg',
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    } else {
      return Image.asset(
        'assets/images/feature_banner_1.jpg',
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (widget.banners.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          height: 222.h,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.banners.length,
            onPageChanged: (_) {},
            itemBuilder: (context, index) {
              final banner = widget.banners[index];
              final isAdvertise = banner['id'] == 'advertise-with-us' ||
                  banner['placement'] == 'advertise' ||
                  banner['actionUrl'] == '/support';

              if (isAdvertise) {
                return _buildAdvertiseCard(
                  context,
                  banner,
                  isDark,
                  () => widget.onBannerTap?.call(index),
                );
              }

              final actionText = banner['actionText'] ?? 'Explore Visas';
              final imageUrl = banner['imageUrl'] ?? '';
              final startColorInt =
                  int.tryParse(banner['gradientStart'] ?? '') ?? 0xFF1B3A5C;
              final startColor = Color(startColorInt);

              return Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: AppBorders.xl,
                  clipBehavior: Clip.antiAlias,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF18181B) : Colors.white,
                      borderRadius: AppBorders.xl,
                      border: Border.all(
                        color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 1. Crystal Clear Banner Image - Pure image with NO text on top
                        Expanded(
                          child: InkWell(
                            onTap: () => widget.onBannerTap?.call(index),
                            child: ClipRRect(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
                              child: _buildBannerImage(imageUrl, startColor),
                            ),
                          ),
                        ),

                        // 2. Navigation Button Below Image - Directly navigates user to visas
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E1E24) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.vertical(bottom: Radius.circular(16.r)),
                          ),
                          child: SizedBox(
                            height: 38.h,
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => widget.onBannerTap?.call(index),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDark ? const Color(0xFF2563EB) : const Color(0xFF002444),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: EdgeInsets.symmetric(horizontal: 16.w),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.flight_takeoff_rounded,
                                    size: 16.sp,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 8.w),
                                  Text(
                                    actionText.isNotEmpty ? actionText : 'Explore Visas',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13.sp,
                                    ),
                                  ),
                                  SizedBox(width: 6.w),
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 14.sp,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                            ),
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
        SizedBox(height: AppSpacing.sm),
        if (widget.banners.length > 1)
          SmoothPageIndicator(
            controller: _controller,
            count: widget.banners.length,
            effect: ExpandingDotsEffect(
              activeDotColor: cs.primary,
              dotColor: cs.outlineVariant,
              dotHeight: 6.h,
              dotWidth: 6.w,
              expansionFactor: 3,
              spacing: 6.w,
            ),
            onDotClicked: (index) {
              _controller.animateToPage(
                index,
                duration: AppDurations.normal,
                curve: AppCurves.standard,
              );
            },
          ),
      ],
    );
  }

  Widget _buildAdvertiseCard(
    BuildContext context,
    Map<String, String> banner,
    bool isDark,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppBorders.xl,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF001F3F), Color(0xFF1B3A5C), Color(0xFF2A5A8C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: AppBorders.xl,
              border: Border.all(
                color: const Color(0xFFD4AF37).withValues(alpha: 0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Top Bar: Gold Pill Badge + SB Consultants App Logo
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(color: const Color(0xFFD4AF37), width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.campaign_rounded, color: const Color(0xFFD4AF37), size: 14.sp),
                          SizedBox(width: 5.w),
                          Text(
                            'PARTNER SPOTLIGHT',
                            style: TextStyle(
                              color: const Color(0xFFD4AF37),
                              fontWeight: FontWeight.w800,
                              fontSize: 10.sp,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // App Logo
                    Container(
                      width: 36.w,
                      height: 36.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFD4AF37), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.asset(
                        'assets/images/logo.jpg',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                ),
                const Spacer(),

                // 2. Clear, Decent Headline & Subtitle
                Text(
                  'Advertise Your Business Here',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.5.sp,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Promote your university programs, overseas jobs, or commercial services to verified international clients across our global network.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 11.5.sp,
                    height: 1.35,
                  ),
                ),
                const Spacer(),

                // 3. Gold Action Button
                Container(
                  height: 36.h,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFD4AF37), Color(0xFFF3E5AB)],
                    ),
                    borderRadius: BorderRadius.circular(10.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded, color: const Color(0xFF001F3F), size: 15.sp),
                        SizedBox(width: 7.w),
                        Text(
                          'Contact Us to Advertise',
                          style: TextStyle(
                            color: const Color(0xFF001F3F),
                            fontWeight: FontWeight.w800,
                            fontSize: 12.5.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
