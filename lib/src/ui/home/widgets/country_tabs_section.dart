import 'package:flutter_sd_consultant/src/data/models/country_model.dart';
import 'package:flutter_sd_consultant/src/imports/core_imports.dart';
import 'package:flutter_sd_consultant/src/imports/packages_imports.dart';

/// Horizontally scrolling destination-country filter chips.
class CountryTabsSection extends StatelessWidget {
  const CountryTabsSection({
    super.key,
    required this.countries,
    required this.selectedCountryId,
    required this.onCountrySelected,
    this.onViewMore,
  });

  final List<CountryModel> countries;
  final String selectedCountryId;
  final ValueChanged<String> onCountrySelected;
  final VoidCallback? onViewMore;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final tt = context.textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Top Country Visas',
                style: tt.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
              if (onViewMore != null)
                InkWell(
                  onTap: onViewMore,
                  borderRadius: AppBorders.sm,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: AppSpacing.xs,
                      horizontal: AppSpacing.xs,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View More',
                          style: tt.bodySmall?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 16.sp,
                          color: cs.primary,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.ms),
        SizedBox(
          height: 40.h,
          child: ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
            scrollDirection: Axis.horizontal,
            itemCount: countries.length,
            separatorBuilder: (_, __) => SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              final country = countries[index];
              final isSelected = country.id == selectedCountryId;

              return Semantics(
                button: true,
                selected: isSelected,
                label: country.name,
                child: InkWell(
                  onTap: () => onCountrySelected(country.id),
                  borderRadius: AppBorders.full,
                  child: AnimatedContainer(
                    duration: AppDurations.fast,
                    curve: AppCurves.standard,
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDark ? const Color(0xFF3B82F6) : const Color(0xFF002444))
                          : (isDark ? const Color(0xFF18181B) : const Color(0xFFEDF2F8)),
                      borderRadius: AppBorders.full,
                      border: Border.all(
                        color: isSelected
                            ? (isDark ? const Color(0xFF3B82F6) : const Color(0xFF002444))
                            : (isDark ? const Color(0xFF27272A) : const Color(0xFFD2E0F0)),
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: (isDark ? const Color(0xFF3B82F6) : const Color(0xFF002444))
                                    .withValues(alpha: 0.25),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : AppShadows.none,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (country.flagEmoji != null) ...[
                          Text(country.flagEmoji!, style: TextStyle(fontSize: 14.sp)),
                          SizedBox(width: AppSpacing.xs),
                        ],
                        Text(
                          country.name,
                          style: tt.bodySmall?.copyWith(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? Colors.white : const Color(0xFF0F172A)),
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
      ],
    );
  }
}
