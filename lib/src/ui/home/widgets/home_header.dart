import 'package:flutter_sd_consultant/src/imports/core_imports.dart';
import 'package:flutter_sd_consultant/src/imports/packages_imports.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    this.userName = '',
    this.avatarUrl,
    this.unreadCount = 2,
    this.onNotificationTap,
    this.onSearchChanged,
    this.onFilterTap,
  });

  final String userName;
  final String? avatarUrl;
  final int unreadCount;
  final VoidCallback? onNotificationTap;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onFilterTap;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final tt = context.textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headerBg = isDark ? const Color(0xFF121212) : const Color(0xFF1B3A5C);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: headerBg,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28.r),
          bottomRight: Radius.circular(28.r),
        ),
        border: isDark
            ? const Border(
                bottom: BorderSide(color: Color(0xFF27272A), width: 1),
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.4)
                : cs.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Branding & Notification Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 44.w,
                          height: 44.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Padding(
                              padding: EdgeInsets.all(2.5.w),
                              child: Image.asset(
                                AppAssets.logo,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: AppSpacing.sm.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'SB Consultants',
                                style: tt.titleLarge?.copyWith(
                                  color: cs.onPrimary,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.4,
                                ),
                              ),
                              SizedBox(height: AppSpacing.xxs),
                              Text(
                                'Your Trusted Visa Partner',
                                style: tt.bodySmall?.copyWith(
                                  color: cs.onPrimary.withValues(alpha: 0.85),
                                  fontSize: 12.sp,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Notification Bell with dynamic Badge
                  if (unreadCount > 0)
                    AppBadge(
                      label: '$unreadCount',
                      color: cs.error,
                      textColor: cs.onError,
                      child: Container(
                        width: 44.w,
                        height: 44.w,
                        decoration: BoxDecoration(
                          color: cs.onPrimary.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.notifications_none_rounded,
                            color: cs.onPrimary,
                            size: 22.sp,
                          ),
                          onPressed: onNotificationTap,
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 44.w,
                      height: 44.w,
                      decoration: BoxDecoration(
                        color: cs.onPrimary.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.notifications_none_rounded,
                          color: cs.onPrimary,
                          size: 22.sp,
                        ),
                        onPressed: onNotificationTap,
                      ),
                    ),
                ],
              ),
              SizedBox(height: AppSpacing.lg),

              // Search Bar with Filter Icon
              Container(
                height: 50.h,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : cs.surface,
                  borderRadius: AppBorders.lg,
                  border: isDark ? Border.all(color: const Color(0xFF333333)) : null,
                  boxShadow: AppShadows.card,
                ),
                child: Row(
                  children: [
                    SizedBox(width: AppSpacing.md),
                    Icon(
                      Icons.search_rounded,
                      color: cs.onSurfaceVariant,
                      size: 22.sp,
                    ),
                    SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: TextField(
                        onChanged: onSearchChanged,
                        style: tt.bodyMedium?.copyWith(
                          color: cs.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search for visas, countries...',
                          hintStyle: tt.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                      ),
                    ),
                    Container(
                      height: 24.h,
                      width: 1,
                      color: cs.outlineVariant,
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.tune_rounded,
                        color: cs.primary,
                        size: 20.sp,
                      ),
                      onPressed: onFilterTap ??
                          () {
                            showToast(
                              context,
                              message: 'Filters applied',
                              status: 'info',
                            );
                          },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
