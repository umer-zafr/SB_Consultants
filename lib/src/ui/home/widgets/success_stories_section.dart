import 'package:flutter_sd_consultant/src/data/models/success_story_model.dart';
import 'package:flutter_sd_consultant/src/imports/core_imports.dart';
import 'package:flutter_sd_consultant/src/imports/packages_imports.dart';

/// Horizontal carousel displaying verified client visa success stories and approvals.
class SuccessStoriesSection extends StatelessWidget {
  const SuccessStoriesSection({
    super.key,
    required this.stories,
    this.onViewAll,
  });

  final List<SuccessStoryModel> stories;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final tt = context.textTheme;

    if (stories.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Success Stories',
                            style: tt.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: cs.onSurface,
                            ),
                          ),
                        ),
                        SizedBox(width: AppSpacing.xs),
                        FittedBox(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 7.w,
                              vertical: 2.h,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2E7D32).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color: const Color(0xFF2E7D32).withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.verified_rounded,
                                  size: 12.sp,
                                  color: const Color(0xFF2E7D32),
                                ),
                                SizedBox(width: 3.w),
                                Text(
                                  '99.4% Approved',
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF2E7D32),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'Real clients who achieved their visa dreams with us',
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontSize: 11.5.sp,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: onViewAll ?? () => _showAllStoriesSheet(context),
                borderRadius: BorderRadius.circular(8.r),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
                  child: Row(
                    children: [
                      Text(
                        'View All',
                        style: tt.labelMedium?.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: cs.primary,
                        size: 18.sp,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.sm),

        // Horizontal Story Cards
        SizedBox(
          height: 170.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
            itemCount: stories.length,
            separatorBuilder: (context, _) => SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              final story = stories[index];
              return _SuccessStoryCard(
                story: story,
                onTap: () => _showStoryDetailSheet(context, story),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showAllStoriesSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AllStoriesBottomSheet(stories: stories),
    );
  }

  void _showStoryDetailSheet(BuildContext context, SuccessStoryModel story) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _StoryDetailBottomSheet(story: story),
    );
  }
}

class _SuccessStoryCard extends StatelessWidget {
  const _SuccessStoryCard({
    required this.story,
    required this.onTap,
    this.isFullWidth = false,
  });

  final SuccessStoryModel story;
  final VoidCallback onTap;
  final bool isFullWidth;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        width: isFullWidth ? double.infinity : 308.w,
        padding: EdgeInsets.symmetric(horizontal: 13.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF121212) : Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.25)
                  : const Color(0xFF1B3A5C).withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top row: Avatar + Client Name + Flag/Visa + Approval Badge
            Row(
              children: [
                CircleAvatar(
                  radius: 17.r,
                  backgroundColor: cs.primaryContainer,
                  backgroundImage: NetworkImage(story.avatarUrl),
                  onBackgroundImageError: (_, __) {},
                  child: Text(
                    story.clientName.isNotEmpty
                        ? story.clientName[0].toUpperCase()
                        : 'C',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.sp,
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                ),
                SizedBox(width: 9.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                story.clientName,
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.bold,
                                  color: cs.onSurface,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Icon(
                            Icons.verified_rounded,
                            size: 13.sp,
                            color: const Color(0xFF2E7D32),
                          ),
                        ],
                      ),
                      Text(
                        '${story.countryFlag}  ${story.visaType}',
                        softWrap: true,
                        style: TextStyle(
                          fontSize: 10.5.sp,
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.5.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    story.badgeText,
                    style: TextStyle(
                      fontSize: 9.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2E7D32),
                    ),
                  ),
                ),
              ],
            ),

            // Middle: Encapsulated Testimonial Quote Bubble
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1B283A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: isDark ? const Color(0xFF26354A) : const Color(0xFFE2E8F0),
                  width: 0.8,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.format_quote_rounded,
                    size: 15.sp,
                    color: cs.primary.withValues(alpha: 0.7),
                  ),
                  SizedBox(width: 5.w),
                  Expanded(
                    child: Text(
                      story.quote,
                      maxLines: 2,
                      softWrap: true,
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontStyle: FontStyle.italic,
                        color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                        height: 1.28,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Footer: University / Employer on left + Speed & Rating on right
            Row(
              children: [
                Icon(
                  Icons.school_outlined,
                  size: 13.sp,
                  color: cs.primary,
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      story.universityOrEmployer,
                      style: TextStyle(
                        fontSize: 10.5.sp,
                        fontWeight: FontWeight.w600,
                        color: cs.primary,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.bolt_rounded,
                      size: 13.sp,
                      color: const Color(0xFFED6C02),
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      story.processingTime,
                      style: TextStyle(
                        fontSize: 10.5.sp,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Icon(
                      Icons.star_rounded,
                      size: 13.sp,
                      color: const Color(0xFFF59E0B),
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      story.rating.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 10.5.sp,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryDetailBottomSheet extends StatelessWidget {
  const _StoryDetailBottomSheet({required this.story});

  final SuccessStoryModel story;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 28.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121212) : Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          SizedBox(height: 16.h),

          // Client Header
          Row(
            children: [
              CircleAvatar(
                radius: 26.r,
                backgroundColor: cs.primaryContainer,
                backgroundImage: NetworkImage(story.avatarUrl),
                onBackgroundImageError: (_, __) {},
                child: Text(
                  story.clientName.isNotEmpty
                      ? story.clientName[0].toUpperCase()
                      : 'C',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18.sp,
                    color: cs.onPrimaryContainer,
                  ),
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            story.clientName,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: cs.onSurface,
                            ),
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Icon(
                          Icons.verified_rounded,
                          size: 16.sp,
                          color: const Color(0xFF2E7D32),
                        ),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      '${story.countryFlag} ${story.visaType}',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: cs.primary,
                      ),
                    ),
                    Text(
                      story.approvedDate,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 18.h),

          // Achievement Pill
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF18181B) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.business_center_rounded,
                  size: 18.sp,
                  color: cs.primary,
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    story.universityOrEmployer,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 14.h),

          // Full Testimonial
          Text(
            'Client Testimonial',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
          SizedBox(height: 6.h),
          Container(
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: cs.primary.withValues(alpha: 0.15),
              ),
            ),
            child: Text(
              '"${story.quote}"',
              style: TextStyle(
                fontSize: 13.sp,
                fontStyle: FontStyle.italic,
                height: 1.45,
                color: cs.onSurface,
              ),
            ),
          ),
          SizedBox(height: 16.h),

          // Speed & Rating Row
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 10.h),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF18181B) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Processing Time',
                        style: TextStyle(
                          fontSize: 10.5.sp,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        story.processingTime,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFED6C02),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 10.h),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF18181B) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Client Rating',
                        style: TextStyle(
                          fontSize: 10.5.sp,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 16,
                            color: Color(0xFFF59E0B),
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            '${story.rating} / 5.0',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              color: cs.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 18.h),

          // Close button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
                padding: EdgeInsets.symmetric(vertical: 12.h),
              ),
              child: const Text(
                'Close Story',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AllStoriesBottomSheet extends StatelessWidget {
  const _AllStoriesBottomSheet({required this.stories});

  final List<SuccessStoryModel> stories;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF121212) : Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          child: Column(
            children: [
              SizedBox(height: 12.h),
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(16.w),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Client Success Stories',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              color: cs.onSurface,
                            ),
                          ),
                          Text(
                            'Over 2,400+ visas processed with SB Consultants',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: EdgeInsets.all(16.w),
                  itemCount: stories.length,
                  separatorBuilder: (context, _) => SizedBox(height: 12.h),
                  itemBuilder: (context, index) {
                    final story = stories[index];
                    return _SuccessStoryCard(
                      story: story,
                      isFullWidth: true,
                      onTap: () {
                        Navigator.pop(context);
                        showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (ctx) => _StoryDetailBottomSheet(story: story),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
