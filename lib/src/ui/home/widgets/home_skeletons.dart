import 'package:flutter_sd_consultant/src/imports/core_imports.dart';
import 'package:flutter_sd_consultant/src/imports/packages_imports.dart';

/// Reusable shimmering placeholders for the Home screen's loading states.
///
/// Each skeleton mirrors the shape of the real widget it stands in for
/// (category grid, banner, country tabs, visa cards) so content doesn't
/// visually "jump" once real data arrives.

class HomeCategoriesSkeleton extends StatelessWidget {
  const HomeCategoriesSkeleton({super.key, this.itemCount = 7});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;

    return AppSkeleton(
      height: 100,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: itemCount,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 16.h,
            crossAxisSpacing: 12.w,
            childAspectRatio: 0.82,
          ),
          itemBuilder: (context, index) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 54.w,
                  height: 54.w,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16.r),
                    color: cs.surfaceContainerHighest,
                  ),
                ),
                SizedBox(height: 8.h),
                Container(
                  width: 40.w,
                  height: 8.h,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: AppBorders.xs,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class HomeBannerSkeleton extends StatelessWidget {
  const HomeBannerSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;

    return AppSkeleton(
      height: 160,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Container(
          height: 160.h,
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: AppBorders.xl,
          ),
        ),
      ),
    );
  }
}

class HomeCountriesSkeleton extends StatelessWidget {
  const HomeCountriesSkeleton({super.key, this.itemCount = 6});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;

    return AppSkeleton(
      height: 38,
      child: SizedBox(
        height: 38.h,
        child: ListView.separated(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
          scrollDirection: Axis.horizontal,
          itemCount: itemCount,
          separatorBuilder: (_, __) => SizedBox(width: 8.w),
          itemBuilder: (context, index) {
            return Container(
              width: 78.w,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: AppBorders.full,
              ),
            );
          },
        ),
      ),
    );
  }
}

class HomeVisaListSkeleton extends StatelessWidget {
  const HomeVisaListSkeleton({super.key, this.itemCount = 3});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;

    return AppSkeleton(
      height: 104,
      child: Column(
        children: List.generate(itemCount, (index) {
          return Container(
            margin: EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 6.h,
            ),
            padding: EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: AppBorders.lg,
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 76.w,
                  height: 76.w,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: AppBorders.md,
                  ),
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        height: 14.h,
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest,
                          borderRadius: AppBorders.xs,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Container(
                        width: 140.w,
                        height: 10.h,
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest,
                          borderRadius: AppBorders.xs,
                        ),
                      ),
                      SizedBox(height: 14.h),
                      Container(
                        width: 90.w,
                        height: 10.h,
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest,
                          borderRadius: AppBorders.xs,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
