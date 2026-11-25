import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:flutter_sd_consultant/src/data/repositories/detail_repository.dart';
import 'package:flutter_sd_consultant/src/routing/app_routes.dart';
import 'package:url_launcher/url_launcher.dart';

/// Swipeable category-targeted banner carousel with real-time sync from Supabase.
/// If 1 banner is enabled in admin, displays 1 static card.
/// If multiple (up to 5+) are enabled, displays a smooth PageView carousel with indicator dots.
class CategoryBannerCarousel extends StatefulWidget {
  const CategoryBannerCarousel({
    super.key,
    required this.banners,
    required this.defaultHeadline,
    required this.defaultSubtitle,
    required this.watermarkIcon,
    required this.screenTitle,
    this.defaultBadge = 'POPULAR',
    this.defaultActionText = 'Get Free Consultation',
    this.onTapDefault,
  });

  final List<Map<String, String>> banners;
  final String defaultHeadline;
  final String defaultSubtitle;
  final IconData watermarkIcon;
  final String screenTitle;
  final String defaultBadge;
  final String defaultActionText;
  final VoidCallback? onTapDefault;

  @override
  State<CategoryBannerCarousel> createState() => _CategoryBannerCarouselState();
}

class _CategoryBannerCarouselState extends State<CategoryBannerCarousel> {
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

  Color _parseColor(String? hexString, Color fallback) {
    if (hexString == null || hexString.isEmpty) return fallback;
    try {
      final clean = hexString.replaceAll('#', '').replaceAll('0x', '').replaceAll('0X', '');
      if (clean.length == 6) {
        return Color(int.parse('0xFF$clean'));
      } else if (clean.length == 8) {
        return Color(int.parse('0x$clean'));
      }
      final parsed = int.tryParse(hexString);
      if (parsed != null) return Color(parsed);
      return fallback;
    } catch (_) {
      return fallback;
    }
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
    final count = widget.banners.isEmpty ? 1 : widget.banners.length;

    return Column(
      children: [
        SizedBox(
          height: 222.h,
          child: PageView.builder(
            controller: _controller,
            itemCount: count,
            itemBuilder: (context, index) {
              final banner = widget.banners.isNotEmpty ? widget.banners[index] : null;
              final isAdvertiseFallback = banner == null;

              final bannerSubtitle = (banner != null && (banner['subtitle']?.trim().isNotEmpty ?? false))
                  ? banner['subtitle']!.trim().replaceAll('\n', ' • ')
                  : 'Advertise your educational or migration programs here • Contact SB Consultants';

              final bannerActionText = (banner != null && (banner['actionText']?.trim().isNotEmpty ?? false))
                  ? banner['actionText']!.trim()
                  : 'Contact Us to Feature';

              final bannerActionUrl = banner?['actionUrl']?.trim();
              final imageUrl = banner?['imageUrl']?.trim() ?? '';

              final startColor = _parseColor(banner?['gradientStart'], const Color(0xFF1B3A5C));
              final isDark = Theme.of(context).brightness == Brightness.dark;

              void onBannerClick() {
                if (isAdvertiseFallback || bannerActionUrl == '/support' || bannerActionUrl == 'support') {
                  final uri = Uri.parse('https://wa.me/923155440606?text=Hello%20SB%20Consultants,%20I%20would%20like%20to%20advertise%20on%20your%20app');
                  launchUrl(uri, mode: LaunchMode.externalApplication);
                  return;
                }
                if (bannerActionUrl != null && bannerActionUrl.isNotEmpty) {
                  if (bannerActionUrl.startsWith('http://') || bannerActionUrl.startsWith('https://')) {
                    final uri = Uri.tryParse(bannerActionUrl);
                    if (uri != null) {
                      launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                    return;
                  }
                  final target = switch (bannerActionUrl) {
                    '/study' || 'study' => AppRoutes.studyVisa,
                    '/work' || 'work' => AppRoutes.workVisa,
                    '/visit' || 'visit' => AppRoutes.visitVisa,
                    '/business' || 'business' => AppRoutes.businessVisa,
                    '/golden' || 'golden' => AppRoutes.goldenVisa,
                    '/jobs' || 'jobs' => AppRoutes.sponsoredJobs,
                    '/scholarships' || 'scholarships' => AppRoutes.scholarships,
                    '/visas' || 'visas' => AppRoutes.home,
                    _ => bannerActionUrl,
                  };
                  if (target.startsWith('/')) {
                    context.push(target);
                    return;
                  }
                  context.push('/visa-detail/$target');
                  return;
                }
                if (widget.onTapDefault != null) {
                  widget.onTapDefault!();
                } else {
                  final detail =
                      DetailRepository.getDetailFromGeneric(
                    title: '${widget.screenTitle} Consultation',
                    subtitle: bannerSubtitle,
                    categoryTag: widget.screenTitle,
                    fee: 'Consultation Free',
                  );
                  context.push(AppRoutes.visaDetail, extra: detail);
                }
              }

              if (isAdvertiseFallback || banner['id'] == 'advertise-with-us') {
                return _buildAdvertiseCard(context, isDark, onBannerClick);
              }

              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF18181B) : Colors.white,
                    borderRadius: BorderRadius.circular(20.r),
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
                      // 1. Crystal Clear Image (NO text on top of image)
                      Expanded(
                        child: InkWell(
                          onTap: onBannerClick,
                          child: ClipRRect(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
                            child: _buildBannerImage(imageUrl, startColor),
                          ),
                        ),
                      ),

                      // 2. Navigation Button Below Image - Directly navigates to visas
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E1E24) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20.r)),
                        ),
                        child: SizedBox(
                          height: 38.h,
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: onBannerClick,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark ? const Color(0xFF2563EB) : const Color(0xFF002444),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: EdgeInsets.symmetric(horizontal: 14.w),
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
                                  bannerActionText.isNotEmpty ? bannerActionText : 'Explore ${widget.screenTitle}',
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
              );
            },
          ),
        ),
        if (count > 1) ...[
          SizedBox(height: 10.h),
          SmoothPageIndicator(
            controller: _controller,
            count: count,
            effect: ExpandingDotsEffect(
              activeDotColor: const Color(0xFF1B3A5C),
              dotColor: const Color(0xFFCCD5E2),
              dotHeight: 5.h,
              dotWidth: 6.w,
              expansionFactor: 3,
              spacing: 5.w,
            ),
            onDotClicked: (index) {
              _controller.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildAdvertiseCard(
    BuildContext context,
    bool isDark,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20.r),
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
              borderRadius: BorderRadius.circular(20.r),
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
