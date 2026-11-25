import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_sd_consultant/src/routing/app_routes.dart';
import 'package:flutter_sd_consultant/src/ui/home/providers/home_provider.dart';

/// App-wide standard bottom navigation bar matching the Dashboard screen styling.
/// Used consistently across:
/// 1. Home (index 0)
/// 2. Dashboard / My Applications (index 1)
/// 3. Saved Visas (index 2)
/// 4. Profile (index 3)
class AppDashboardBottomNav extends ConsumerWidget {
  const AppDashboardBottomNav({
    super.key,
    required this.currentIndex,
  });

  /// The active navigation index:
  /// - 0 = Home
  /// - 1 = Dashboard
  /// - 2 = Saved
  /// - 3 = Profile
  final int currentIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF000000) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF27272A) : const Color(0xFFE8EEF5),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.5)
                : const Color(0xFF1B3A5C).withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64.h,
          child: Row(
            children: [
              // 1. Home
              Expanded(
                child: _buildNavItem(
                  context: context,
                  ref: ref,
                  index: 0,
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  label: 'Home',
                  route: AppRoutes.home,
                  isSelected: currentIndex == 0,
                  isDark: isDark,
                ),
              ),

              // 2. Dashboard
              Expanded(
                child: _buildNavItem(
                  context: context,
                  ref: ref,
                  index: 1,
                  icon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard_rounded,
                  label: 'Dashboard',
                  route: AppRoutes.dashboard,
                  isSelected: currentIndex == 1,
                  isDark: isDark,
                ),
              ),

              // 3. Saved
              Expanded(
                child: _buildNavItem(
                  context: context,
                  ref: ref,
                  index: 2,
                  icon: Icons.bookmark_border_rounded,
                  activeIcon: Icons.bookmark_rounded,
                  label: 'Saved',
                  route: AppRoutes.savedVisas,
                  isSelected: currentIndex == 2,
                  isDark: isDark,
                ),
              ),

              // 4. Profile
              Expanded(
                child: _buildNavItem(
                  context: context,
                  ref: ref,
                  index: 3,
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  label: 'Profile',
                  route: AppRoutes.profile,
                  isSelected: currentIndex == 3,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required WidgetRef ref,
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required String route,
    required bool isSelected,
    required bool isDark,
  }) {
    return InkWell(
      onTap: () {
        if (currentIndex != index) {
          ref.read(homeBottomNavIndexProvider.notifier).state = index;
          context.go(route);
        }
      },
      borderRadius: BorderRadius.circular(16.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isSelected)
              Container(
                width: 58.w,
                height: 30.h,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2563EB)
                      : const Color(0xFF002444),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Icon(
                  activeIcon,
                  size: 19.sp,
                  color: Colors.white,
                ),
              )
            else
              Icon(
                icon,
                size: 22.sp,
                color: isDark
                    ? const Color(0xFFA1A1AA)
                    : const Color(0xFF5B7FA5),
              ),
            SizedBox(height: 3.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? (isDark ? Colors.white : const Color(0xFF002444))
                    : (isDark ? const Color(0xFFA1A1AA) : const Color(0xFF5B7FA5)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
