import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_sd_consultant/src/data/repositories/detail_repository.dart';
import 'package:flutter_sd_consultant/src/routing/app_routes.dart';
import 'package:flutter_sd_consultant/src/shared/helpers/show_toast.dart';
import 'package:flutter_sd_consultant/src/shared/widgets/app_dashboard_bottom_nav.dart';
import 'package:flutter_sd_consultant/src/ui/saved/models/saved_visa_model.dart';
import 'package:flutter_sd_consultant/src/ui/saved/providers/saved_visas_provider.dart';

/// Screen displaying all bookmarked & saved visas in the application.
/// Provides category filtering, search, quick details inspection, direct application,
/// and live bookmark removal with both Light and Dark mode themes.
class SavedVisasScreen extends ConsumerStatefulWidget {
  const SavedVisasScreen({super.key});

  @override
  ConsumerState<SavedVisasScreen> createState() => _SavedVisasScreenState();
}

class _SavedVisasScreenState extends ConsumerState<SavedVisasScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedCategoryIndex = 0;
  String _searchQuery = '';

  final List<String> _categories = [
    'All',
    'Work Visa',
    'Study Visa',
    'Visit Visa',
    'Business Visa',
    'Golden Visa',
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<SavedVisaItem> _filterVisas(List<SavedVisaItem> allVisas) {
    return allVisas.where((item) {
      // Category filter
      if (_selectedCategoryIndex > 0) {
        final selectedCat = _categories[_selectedCategoryIndex].toLowerCase();
        if (!item.categoryTag.toLowerCase().contains(selectedCat)) {
          return false;
        }
      }

      // Search filter
      if (_searchQuery.isNotEmpty) {
        final matchesTitle = item.title.toLowerCase().contains(_searchQuery);
        final matchesSubtitle =
            item.subtitle.toLowerCase().contains(_searchQuery);
        final matchesCountry =
            item.countryName.toLowerCase().contains(_searchQuery);
        final matchesCat = item.categoryTag.toLowerCase().contains(_searchQuery);
        return matchesTitle || matchesSubtitle || matchesCountry || matchesCat;
      }

      return true;
    }).toList();
  }

  void _showClearAllConfirmDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Text(
            'Clear All Saved Visas?',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF171C21),
            ),
          ),
          content: Text(
            'Are you sure you want to remove all saved visas from your bookmarks? You can re-save any visa anytime.',
            style: TextStyle(
              fontSize: 12.5.sp,
              color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF5A626A),
              height: 1.35,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? const Color(0xFFA1A1AA)
                      : const Color(0xFF5A626A),
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFBA1A1A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                ref.read(savedVisasProvider.notifier).clear();
                showGlobalToast(
                  message: 'All saved visas cleared',
                  status: 'info',
                );
              },
              child: const Text('Clear All'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final allSaved = ref.watch(savedVisasProvider);
    final displayedVisas = _filterVisas(allSaved);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF000000) : const Color(0xFFF7F9FF);
    final textColor = isDark ? Colors.white : const Color(0xFF171C21);
    final subtitleColor =
        isDark ? const Color(0xFFA1A1AA) : const Color(0xFF5A626A);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60.h),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: Row(
              children: [
                // Back Button
                InkWell(
                  onTap: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go(AppRoutes.home);
                    }
                  },
                  borderRadius: BorderRadius.circular(24.r),
                  child: Container(
                    width: 42.w,
                    height: 42.w,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF18181B)
                          : const Color(0xFFEDF2F8),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF27272A)
                            : const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: isDark ? Colors.white : const Color(0xFF1B3A5C),
                      size: 20,
                    ),
                  ),
                ),
                SizedBox(width: 12.w),

                // Screen Title & Live Badge
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          'Saved Visas',
                          style: TextStyle(
                            fontSize: 18.5.sp,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 2.5.h,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E3A8A).withValues(alpha: 0.5)
                              : const Color(0xFFEBF1FA),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF3B82F6)
                                : const Color(0xFFCCDDF2),
                          ),
                        ),
                        child: Text(
                          '${allSaved.length}',
                          style: TextStyle(
                            fontSize: 11.5.sp,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? const Color(0xFF93C5FD)
                                : const Color(0xFF1B3A5C),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Clear All Action
                if (allSaved.isNotEmpty)
                  InkWell(
                    onTap: () => _showClearAllConfirmDialog(context),
                    borderRadius: BorderRadius.circular(24.r),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF18181B)
                            : const Color(0xFFEDF2F8),
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF27272A)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline_rounded,
                            size: 15.sp,
                            color: isDark ? const Color(0xFFF87171) : const Color(0xFFBA1A1A),
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            'Clear',
                            style: TextStyle(
                              fontSize: 11.5.sp,
                              fontWeight: FontWeight.w700,
                              color: isDark ? const Color(0xFFF87171) : const Color(0xFFBA1A1A),
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
      body: allSaved.isEmpty
          ? _buildEmptyState(context, isDark)
          : Column(
              children: [
                SizedBox(height: 6.h),

                // 1. Search Bar
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Container(
                    height: 46.h,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF18181B) : Colors.white,
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF27272A)
                            : const Color(0xFFDEE5EF),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.3)
                              : const Color(0xFF1B3A5C).withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        SizedBox(width: 12.w),
                        Icon(
                          Icons.search_rounded,
                          size: 20.sp,
                          color: subtitleColor,
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            style: TextStyle(
                              fontSize: 13.5.sp,
                              fontWeight: FontWeight.w500,
                              color: textColor,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search saved visas or countries...',
                              hintStyle: TextStyle(
                                fontSize: 13.sp,
                                color: subtitleColor,
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        if (_searchQuery.isNotEmpty)
                          IconButton(
                            icon: Icon(
                              Icons.clear_rounded,
                              size: 18.sp,
                              color: subtitleColor,
                            ),
                            onPressed: () {
                              _searchController.clear();
                            },
                          ),
                        SizedBox(width: 4.w),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 12.h),

                // 2. Category Filter Chips
                SizedBox(
                  height: 38.h,
                  child: ListView.separated(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    separatorBuilder: (_, __) => SizedBox(width: 8.w),
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      final isSelected = _selectedCategoryIndex == index;

                      return InkWell(
                        onTap: () {
                          setState(() => _selectedCategoryIndex = index);
                        },
                        borderRadius: BorderRadius.circular(20.r),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: EdgeInsets.symmetric(
                            horizontal: 14.w,
                            vertical: 6.h,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isDark
                                    ? const Color(0xFF3B82F6)
                                    : const Color(0xFF002444))
                                : (isDark
                                    ? const Color(0xFF18181B)
                                    : Colors.white),
                            borderRadius: BorderRadius.circular(20.r),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.transparent
                                  : (isDark
                                      ? const Color(0xFF27272A)
                                      : const Color(0xFFDEE5EF)),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              cat,
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight:
                                    isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : (isDark
                                        ? const Color(0xFFA1A1AA)
                                        : const Color(0xFF43474E)),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 12.h),

                // 3. Saved Visas List or Search Empty State
                Expanded(
                  child: displayedVisas.isEmpty
                      ? _buildNoSearchResultsState(context, isDark)
                      : ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 24.h),
                          itemCount: displayedVisas.length,
                          separatorBuilder: (_, __) => SizedBox(height: 12.h),
                          itemBuilder: (context, index) {
                            final item = displayedVisas[index];
                            return _buildSavedVisaCard(context, item, isDark);
                          },
                        ),
                ),
              ],
            ),
      bottomNavigationBar: const AppDashboardBottomNav(currentIndex: 2),
    );
  }

  // ===========================================================================
  // SAVED VISA CARD
  // ===========================================================================
  Widget _buildSavedVisaCard(
    BuildContext context,
    SavedVisaItem item,
    bool isDark,
  ) {
    final cardColor = isDark ? const Color(0xFF121212) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF27272A) : const Color(0xFFE8EEF5);
    final titleColor = isDark ? Colors.white : const Color(0xFF171C21);
    final subtitleColor =
        isDark ? const Color(0xFFA1A1AA) : const Color(0xFF5A626A);

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.25)
                : const Color(0xFF1B3A5C).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Avatar + Title/Badges + Bookmark Button
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Country Code Avatar
                Container(
                  width: 44.w,
                  height: 44.w,
                  decoration: BoxDecoration(
                    color: item.resolvedAvatarBgColor ??
                        (isDark
                            ? const Color(0xFF18181B)
                            : const Color(0xFFEFF4FA)),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Center(
                    child: Text(
                      item.countryCode,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w800,
                        color: item.resolvedAvatarTextColor ??
                            (isDark
                                ? const Color(0xFF93C5FD)
                                : const Color(0xFF1B3A5C)),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),

                // Title, Category & Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 6.w,
                        runSpacing: 4.h,
                        children: [
                          // Category Tag Badge
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 7.w,
                              vertical: 2.h,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF18181B)
                                  : const Color(0xFFEFF4FA),
                              borderRadius: BorderRadius.circular(6.r),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF27272A)
                                    : Colors.transparent,
                              ),
                            ),
                            child: Text(
                              item.categoryTag,
                              style: TextStyle(
                                fontSize: 9.5.sp,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? const Color(0xFF93C5FD)
                                    : const Color(0xFF1B3A5C),
                              ),
                            ),
                          ),

                          // Optional Highlight Badge
                          if (item.badgeText != null)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 7.w,
                                vertical: 2.h,
                              ),
                              decoration: BoxDecoration(
                                color: item.resolvedBadgeBgColor ??
                                    (isDark
                                        ? const Color(0xFF1E3A8A)
                                        : const Color(0xFFE3F2FD)),
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: Text(
                                item.badgeText!,
                                style: TextStyle(
                                  fontSize: 9.5.sp,
                                  fontWeight: FontWeight.w700,
                                  color: item.resolvedBadgeTextColor ??
                                      (isDark
                                          ? const Color(0xFF93C5FD)
                                          : const Color(0xFF1565C0)),
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 5.h),

                      // Title
                      Text(
                        item.title,
                        maxLines: 2,
                        softWrap: true,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: titleColor,
                          height: 1.25,
                        ),
                      ),
                      SizedBox(height: 3.h),

                      // Subtitle
                      Text(
                        item.subtitle,
                        maxLines: 2,
                        softWrap: true,
                        style: TextStyle(
                          fontSize: 11.5.sp,
                          color: subtitleColor,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 6.w),

                // Active Bookmark Button (Filled)
                InkWell(
                  onTap: () {
                    ref.read(savedVisasProvider.notifier).toggle(item);
                    showGlobalToast(
                      message: 'Removed from bookmarks',
                      status: 'info',
                    );
                  },
                  borderRadius: BorderRadius.circular(20.r),
                  child: Container(
                    padding: EdgeInsets.all(7.w),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF18181B)
                          : const Color(0xFFEFF4FA),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF27272A)
                            : Colors.transparent,
                      ),
                    ),
                    child: Icon(
                      Icons.bookmark_rounded,
                      color: isDark
                          ? const Color(0xFF3B82F6)
                          : const Color(0xFF002444),
                      size: 20.sp,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),

            // Metrics Row: Duration, Validity, Approval Rate
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _buildMetricChip(
                    icon: Icons.timer_outlined,
                    label: item.duration,
                    isDark: isDark,
                  ),
                ),
                SizedBox(width: 6.w),
                Expanded(
                  flex: 4,
                  child: _buildMetricChip(
                    icon: Icons.calendar_today_outlined,
                    label: item.validity,
                    isDark: isDark,
                  ),
                ),
                SizedBox(width: 6.w),
                Expanded(
                  flex: 4,
                  child: _buildMetricChip(
                    icon: Icons.verified_outlined,
                    label: item.approvalRate,
                    iconColor: const Color(0xFF16A34A),
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),

            Divider(
              height: 1,
              color: isDark ? const Color(0xFF27272A) : const Color(0xFFEDF2F7),
            ),
            SizedBox(height: 10.h),

            // Fee row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ESTIMATED FEE',
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                    color: subtitleColor,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  item.fee,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? const Color(0xFF60A5FA)
                        : const Color(0xFF002444),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),

            // Two balanced matching action buttons: View Details & Apply Now
            Row(
              children: [
                // View Details Button
                Expanded(
                  child: InkWell(
                    onTap: () {
                      final detail = DetailRepository.getDetailFromGeneric(
                        title: item.title,
                        subtitle: item.subtitle,
                        countryName: item.countryName,
                        categoryTag: item.categoryTag,
                        fee: item.fee,
                        duration: item.duration,
                        validity: item.validity,
                        approvalRate: item.approvalRate,
                      );
                      context.push(AppRoutes.visaDetail, extra: detail);
                    },
                    borderRadius: BorderRadius.circular(10.r),
                    child: Container(
                      height: 38.h,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF18181B)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF27272A)
                              : const Color(0xFFCBD5E1),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.visibility_outlined,
                            size: 15.sp,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF1B3A5C),
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            'View Details',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1B3A5C),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),

                // Apply Now Button
                Expanded(
                  child: InkWell(
                    onTap: () {
                      final detail = DetailRepository.getDetailFromGeneric(
                        title: item.title,
                        subtitle: item.subtitle,
                        countryName: item.countryName,
                        categoryTag: item.categoryTag,
                        fee: item.fee,
                        duration: item.duration,
                        validity: item.validity,
                        approvalRate: item.approvalRate,
                      );
                      context.push(AppRoutes.applicantDetails, extra: detail);
                    },
                    borderRadius: BorderRadius.circular(10.r),
                    child: Container(
                      height: 38.h,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF2563EB)
                            : const Color(0xFF002444),
                        borderRadius: BorderRadius.circular(10.r),
                        boxShadow: [
                          BoxShadow(
                            color: (isDark
                                    ? const Color(0xFF2563EB)
                                    : const Color(0xFF002444))
                                .withValues(alpha: 0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Apply Now',
                            style: TextStyle(
                              fontSize: 13.5.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 5.w),
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
          ],
        ),
      );
    }

  Widget _buildMetricChip({
    required IconData icon,
    required String label,
    Color? iconColor,
    required bool isDark,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18181B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(
          color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 11.5.sp,
            color: iconColor ??
                (isDark
                    ? const Color(0xFFA1A1AA)
                    : const Color(0xFF5A626A)),
          ),
          SizedBox(width: 4.w),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? Colors.white
                      : const Color(0xFF43474E),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // EMPTY STATE (When zero visas are saved in total)
  // ===========================================================================
  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84.w,
              height: 84.w,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF18181B)
                    : const Color(0xFFEFF4FA),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF27272A)
                      : const Color(0xFFDEE5EF),
                  width: 1.5,
                ),
              ),
              child: Icon(
                Icons.bookmark_border_rounded,
                size: 42.sp,
                color: isDark
                    ? const Color(0xFF3B82F6)
                    : const Color(0xFF1B3A5C),
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              'No Saved Visas Yet',
              style: TextStyle(
                fontSize: 19.sp,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF171C21),
                letterSpacing: -0.3,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Bookmark any visa program, university track, or sponsored job while exploring to keep track of requirements and fees in one place.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5.sp,
                color: isDark
                    ? const Color(0xFFA1A1AA)
                    : const Color(0xFF5A626A),
                height: 1.45,
              ),
            ),
            SizedBox(height: 24.h),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark
                    ? const Color(0xFF3B82F6)
                    : const Color(0xFF002444),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: 22.w,
                  vertical: 13.h,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                elevation: isDark ? 2 : 1,
              ),
              icon: const Icon(Icons.explore_rounded, size: 18),
              label: const Text(
                'Explore Visa Programs',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              onPressed: () {
                context.go(AppRoutes.home);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // SEARCH / FILTER EMPTY STATE (When visas exist but none match filter)
  // ===========================================================================
  Widget _buildNoSearchResultsState(BuildContext context, bool isDark) {
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64.w,
              height: 64.w,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF18181B)
                    : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF27272A)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 30.sp,
                color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF64748B),
              ),
            ),
            SizedBox(height: 14.h),
            Text(
              'No Visas Found',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF171C21),
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              'No saved visas match your current keyword or category filter.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.sp,
                color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            SizedBox(height: 18.h),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: isDark ? const Color(0xFF3B82F6) : const Color(0xFF002444),
                side: BorderSide(
                  color: isDark ? const Color(0xFF27272A) : const Color(0xFFCBD5E1),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
              onPressed: () {
                _searchController.clear();
                setState(() => _selectedCategoryIndex = 0);
              },
              child: const Text('Reset Search & Filters'),
            ),
          ],
        ),
      ),
    );
  }
}
