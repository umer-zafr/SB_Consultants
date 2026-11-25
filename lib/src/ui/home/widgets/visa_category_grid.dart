import 'package:flutter_sd_consultant/src/data/models/visa_category_model.dart';
import 'package:flutter_sd_consultant/src/imports/core_imports.dart';
import 'package:flutter_sd_consultant/src/imports/packages_imports.dart';

/// Visa category grid organized into:
/// - Row 1 (4 items): Scholarships, Sponsored Jobs, Visit Visa, Business Visa
/// - Row 2 (3 items): Golden Visa, Study Visa, Work Visa
class VisaCategoryGrid extends StatelessWidget {
  const VisaCategoryGrid({
    super.key,
    required this.categories,
    this.selectedCategoryId,
    required this.onCategoryTap,
  });

  final List<VisaCategoryModel> categories;
  final String? selectedCategoryId;
  final ValueChanged<VisaCategoryModel> onCategoryTap;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final tt = context.textTheme;

    if (categories.isEmpty) return const SizedBox.shrink();

    // Split into Row 1 (first 4) and Row 2 (remaining 3)
    final row1 = categories.take(4).toList();
    final row2 = categories.skip(4).take(3).toList();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        children: [
          // Row 1: Scholarships, Sponsored Jobs, Visit Visa, Business Visa
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: row1
                .map(
                  (item) => Expanded(
                    child: _CategoryItemWidget(
                      item: item,
                      isSelected: selectedCategoryId == item.id,
                      onTap: () => onCategoryTap(item),
                      cs: cs,
                      tt: tt,
                    ),
                  ),
                )
                .toList(),
          ),

          if (row2.isNotEmpty) ...[
            SizedBox(height: AppSpacing.sm),
            // Row 2: Golden, Study, Work (balanced & centered)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final item in row2)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      child: _CategoryItemWidget(
                        item: item,
                        isSelected: selectedCategoryId == item.id,
                        onTap: () => onCategoryTap(item),
                        cs: cs,
                        tt: tt,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryItemWidget extends StatelessWidget {
  const _CategoryItemWidget({
    required this.item,
    required this.isSelected,
    required this.onTap,
    required this.cs,
    required this.tt,
  });

  final VisaCategoryModel item;
  final bool isSelected;
  final VoidCallback onTap;
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = item.color ?? cs.primary;

    // High-contrast badge container: In dark mode, a matte soft-slate badge makes navy blue
    // and gold graphics stand out vividly without visual glare. In light mode, a crisp
    // clean container provides depth and contrast.
    final Color badgeBg = isDark
        ? (isSelected ? const Color(0xFFE2E8F0) : const Color(0xFFECEFF3))
        : (isSelected
            ? accentColor.withValues(alpha: 0.14)
            : const Color(0xFFF8FAFC));

    final Border badgeBorder = Border.all(
      color: isSelected
          ? accentColor
          : (isDark
              ? Colors.white.withValues(alpha: 0.22)
              : cs.outlineVariant.withValues(alpha: 0.6)),
      width: isSelected ? 2.2 : 1.0,
    );

    final List<BoxShadow> badgeShadow = isSelected
        ? [
            BoxShadow(
              color: accentColor.withValues(alpha: isDark ? 0.45 : 0.35),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ]
        : [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ];

    return Semantics(
      button: true,
      selected: isSelected,
      label: item.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 2.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: AppDurations.fast,
                curve: AppCurves.standard,
                width: 54.w,
                height: 54.w,
                padding: EdgeInsets.all(8.5.w),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.r),
                  color: badgeBg,
                  border: badgeBorder,
                  boxShadow: badgeShadow,
                ),
                child: item.imageAsset != null
                    ? Image.asset(
                        item.imageAsset!,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.medium,
                        errorBuilder: (_, __, ___) => Icon(
                          item.icon,
                          color: isSelected ? accentColor : cs.primary,
                          size: 22.sp,
                        ),
                      )
                    : Icon(
                        item.icon,
                        color: isSelected ? accentColor : cs.primary,
                        size: 22.sp,
                      ),
              ),
              SizedBox(height: 6.h),
              SizedBox(
                height: 28.h,
                child: Center(
                  child: Text(
                    item.label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                    style: tt.labelSmall?.copyWith(
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? accentColor
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.92)
                              : cs.onSurface),
                      fontSize: 11.sp,
                      height: 1.15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
