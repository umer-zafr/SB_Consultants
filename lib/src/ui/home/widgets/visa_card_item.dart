import 'package:flutter_sd_consultant/src/data/models/visa_listing_model.dart';
import 'package:flutter_sd_consultant/src/imports/core_imports.dart';
import 'package:flutter_sd_consultant/src/imports/packages_imports.dart';
import 'package:flutter_sd_consultant/src/ui/saved/models/saved_visa_model.dart';
import 'package:flutter_sd_consultant/src/ui/saved/providers/saved_visas_provider.dart';

class VisaCardItem extends ConsumerStatefulWidget {
  const VisaCardItem({
    super.key,
    required this.visa,
    required this.onTap,
    this.onApplyTap,
  });

  final VisaListingModel visa;
  final VoidCallback onTap;
  final VoidCallback? onApplyTap;

  @override
  ConsumerState<VisaCardItem> createState() => _VisaCardItemState();
}

class _VisaCardItemState extends ConsumerState<VisaCardItem> {
  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final tt = context.textTheme;
    final appColors = context.appColors;
    final visa = widget.visa;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: AppBorders.lg,
        border: Border.all(
          color: visa.isFeatured
              ? cs.primary.withValues(alpha: 0.4)
              : cs.outlineVariant,
        ),
        boxShadow: AppShadows.card,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppBorders.lg,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: AppBorders.lg,
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail with category + featured badges (Fixed pixel overflow)
                ClipRRect(
                  borderRadius: AppBorders.md,
                  child: SizedBox(
                    width: 84.w,
                    height: 84.w,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CommonImage(
                          imageUrl: visa.imageUrl,
                          width: 84.w,
                          height: 84.w,
                          fit: BoxFit.cover,
                          borderRadius: AppBorders.md,
                          errorWidget: Container(
                            width: 84.w,
                            height: 84.w,
                            color: cs.surfaceContainerHighest,
                            child: Icon(
                              Icons.public_rounded,
                              color: cs.primary,
                              size: 32.sp,
                            ),
                          ),
                        ),
                        if (visa.categoryName.isNotEmpty)
                          Positioned(
                            top: 4.h,
                            left: 4.w,
                            right: 4.w,
                            child: Align(
                              alignment: Alignment.topLeft,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 4.w,
                                  vertical: 2.h,
                                ),
                                decoration: BoxDecoration(
                                  color: cs.primary.withValues(alpha: 0.88),
                                  borderRadius: AppBorders.xs,
                                ),
                                child: Text(
                                  visa.categoryName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: tt.labelSmall?.copyWith(
                                    color: cs.onPrimary,
                                    fontSize: 9.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        if (visa.isFeatured)
                          Positioned(
                            bottom: 4.h,
                            left: 4.w,
                            right: 4.w,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 3.w,
                                vertical: 2.h,
                              ),
                              decoration: BoxDecoration(
                                color: appColors.warning,
                                borderRadius: AppBorders.xs,
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.star_rounded,
                                      size: 10.sp,
                                      color: cs.onPrimary,
                                    ),
                                    SizedBox(width: 2.w),
                                    Text(
                                      'Featured',
                                      style: tt.labelSmall?.copyWith(
                                        color: cs.onPrimary,
                                        fontSize: 9.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
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
                SizedBox(width: AppSpacing.md),

                // Details (Center)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title & Bookmark row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              visa.title,
                              maxLines: 2,
                              softWrap: true,
                              style: tt.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: cs.onSurface,
                                fontSize: 15.sp,
                              ),
                            ),
                          ),
                          Builder(
                            builder: (context) {
                              ref.watch(savedVisasProvider);
                              final isBookmarked = ref
                                  .read(savedVisasProvider.notifier)
                                  .isSaved(visa.title);

                              return InkWell(
                                onTap: () {
                                  final savedItem = SavedVisaItem(
                                    id: visa.id,
                                    title: visa.title,
                                    subtitle: visa.subtitle,
                                    countryName: visa.countryName,
                                    countryCode: visa.countryId,
                                    categoryTag: visa.categoryName,
                                    duration: visa.processingTime,
                                    approvalRate: '${(visa.rating * 20).toInt()}% approval',
                                    fee: visa.fee,
                                    badgeText:
                                        visa.isFeatured ? 'Featured' : null,
                                  );
                                  final wasAdded = ref
                                      .read(savedVisasProvider.notifier)
                                      .toggle(savedItem);
                                  showToast(
                                    context,
                                    message: wasAdded
                                        ? 'Saved to Bookmarks'
                                        : 'Removed from Bookmarks',
                                    status: wasAdded ? 'success' : 'info',
                                  );
                                },
                                child: Padding(
                                  padding: EdgeInsets.only(left: AppSpacing.xxs),
                                  child: Icon(
                                    isBookmarked
                                        ? Icons.bookmark_rounded
                                        : Icons.bookmark_border_rounded,
                                    color: isBookmarked
                                        ? cs.primary
                                        : cs.onSurfaceVariant,
                                    size: 20.sp,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: 3.h),

                      // Subtitle
                      Text(
                        visa.subtitle,
                        softWrap: true,
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontSize: 12.5.sp,
                        ),
                      ),
                      SizedBox(height: AppSpacing.xs),

                      // Processing Time and Fee Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Icon(
                                  Icons.access_time_rounded,
                                  size: 14.sp,
                                  color: appColors.success,
                                ),
                                SizedBox(width: 3.w),
                                Flexible(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      visa.processingTime,
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w600,
                                        color: appColors.success,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 6.w),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: Text(
                                visa.fee,
                                textAlign: TextAlign.end,
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.bold,
                                  color: cs.primary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: AppSpacing.xxs),

                      // Rating & Apply button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star_rounded,
                                  size: 15.sp,
                                  color: appColors.warning,
                                ),
                                SizedBox(width: 3.w),
                                Text(
                                  '${visa.rating}',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.bold,
                                    color: cs.onSurface,
                                  ),
                                ),
                                SizedBox(width: 3.w),
                                Flexible(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      '(${visa.reviewsCount})',
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: cs.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Apply Button
                          InkWell(
                            onTap: widget.onApplyTap ?? widget.onTap,
                            borderRadius: BorderRadius.circular(8.r),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10.w,
                                vertical: 4.h,
                              ),
                              decoration: BoxDecoration(
                                color: cs.primary,
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Apply',
                                    style: TextStyle(
                                      color: cs.onPrimary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12.5.sp,
                                    ),
                                  ),
                                  SizedBox(width: 3.w),
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    color: cs.onPrimary,
                                    size: 12.sp,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
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
