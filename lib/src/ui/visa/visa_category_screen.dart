import 'dart:async';
import 'package:flutter_sd_consultant/src/data/repositories/detail_repository.dart';
import 'package:flutter_sd_consultant/src/imports/core_imports.dart';
import 'package:flutter_sd_consultant/src/imports/packages_imports.dart';
import 'package:flutter_sd_consultant/src/services/live_visa_sync_service.dart';
import 'package:flutter_sd_consultant/src/shared/widgets/app_dashboard_bottom_nav.dart';
import 'package:flutter_sd_consultant/src/ui/home/providers/home_provider.dart';
import 'package:flutter_sd_consultant/src/ui/saved/models/saved_visa_model.dart';
import 'package:flutter_sd_consultant/src/ui/saved/providers/saved_visas_provider.dart';
import 'package:flutter_sd_consultant/src/ui/visa/widgets/category_banner_carousel.dart';

/// Data model representing each visa item card in the category listings screen.
class VisaItemData {
  const VisaItemData({
    this.id,
    required this.countryCode,
    required this.countryName,
    required this.title,
    required this.subtitle,
    required this.duration,
    required this.validity,
    required this.approvalRate,
    required this.fee,
    this.badgeText,
    this.badgeBgColor,
    this.badgeTextColor,
    this.avatarBgColor,
    this.avatarTextColor,
  });

  final String? id;
  final String countryCode;
  final String countryName;
  final String title;
  final String subtitle;
  final String duration;
  final String validity;
  final String approvalRate;
  final String fee;
  final String? badgeText;
  final Color? badgeBgColor;
  final Color? badgeTextColor;
  final Color? avatarBgColor;
  final Color? avatarTextColor;
}

/// Unified, pixel-perfect category listing screen based on the standard Visa Advisory Design System.
/// Reused across Visit Visa, Business Visa, and Golden Visa with tailored titles & datasets.
class VisaCategoryScreen extends ConsumerStatefulWidget {
  const VisaCategoryScreen({
    super.key,
    required this.screenTitle,
    required this.bannerHeadline,
    required this.bannerSubtitle,
    required this.watermarkIcon,
    required this.visas,
  });

  final String screenTitle;
  final String bannerHeadline;
  final String bannerSubtitle;
  final IconData watermarkIcon;
  final List<VisaItemData> visas;

  @override
  ConsumerState<VisaCategoryScreen> createState() => _VisaCategoryScreenState();
}

class _VisaCategoryScreenState extends ConsumerState<VisaCategoryScreen> {
  int _selectedFilterIndex = 0;
  String _selectedSort = 'Popular';
  String _selectedDestination = 'All';
  String _selectedDurationFilter = 'All';
  String _selectedFeeFilter = 'All';
  String _selectedProcessingFilter = 'All';

  bool _isSearchOpen = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  List<VisaItemData>? _liveVisas;
  StreamSubscription<List<VisaItemData>>? _visaSub;

  @override
  void initState() {
    super.initState();
    _subscribeLiveVisas();
  }

  void _subscribeLiveVisas() {
    String catId = 'visit';
    final t = widget.screenTitle.toLowerCase();
    if (t.contains('study') || t.contains('student')) {
      catId = 'study';
    } else if (t.contains('work') || t.contains('job')) {
      catId = 'work';
    } else if (t.contains('business')) {
      catId = 'business';
    } else if (t.contains('golden')) {
      catId = 'golden';
    }

    LiveVisaSyncService.instance.fetchVisasByCategory(catId).then((liveList) {
      if (mounted) {
        setState(() {
          _liveVisas = liveList;
        });
      }
    });

    _visaSub = LiveVisaSyncService.instance
        .streamVisasByCategory(catId)
        .listen((liveList) {
      if (mounted) {
        setState(() {
          _liveVisas = liveList;
        });
      }
    });
  }

  String get _catId {
    final t = widget.screenTitle.toLowerCase();
    if (t.contains('study') || t.contains('student')) return 'study';
    if (t.contains('work') || t.contains('job')) return 'work';
    if (t.contains('business')) return 'business';
    if (t.contains('golden')) return 'golden';
    if (t.contains('visit')) return 'visit';
    return 'visas';
  }

  @override
  void dispose() {
    _visaSub?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  final List<Map<String, dynamic>> _destinations = [
    {
      'name': 'All',
      'fullName': 'All Destinations',
      'flag': '🌍',
      'code': 'ALL',
      'badge': 'All Visas',
      'color': const Color(0xFF1B3A5C),
      'bgColor': const Color(0xFFEFF4FA),
    },
    {
      'name': 'United Kingdom',
      'fullName': 'United Kingdom',
      'flag': '🇬🇧',
      'code': 'GB',
      'badge': 'Popular',
      'color': const Color(0xFFB76E00),
      'bgColor': const Color(0xFFFFF3E0),
    },
    {
      'name': 'Canada',
      'fullName': 'Canada',
      'flag': '🇨🇦',
      'code': 'CA',
      'badge': 'High Demand',
      'color': const Color(0xFF1565C0),
      'bgColor': const Color(0xFFE3F2FD),
    },
    {
      'name': 'Australia',
      'fullName': 'Australia',
      'flag': '🇦🇺',
      'code': 'AU',
      'badge': 'Fast Track',
      'color': const Color(0xFF2E7D32),
      'bgColor': const Color(0xFFE8F5E9),
    },
    {
      'name': 'United States',
      'fullName': 'United States',
      'flag': '🇺🇸',
      'code': 'US',
      'badge': '10 Years',
      'color': const Color(0xFF5E35B1),
      'bgColor': const Color(0xFFEDE7F6),
    },
    {
      'name': 'Germany',
      'fullName': 'Germany / Schengen',
      'flag': '🇩🇪',
      'code': 'DE',
      'badge': 'Schengen 29',
      'color': const Color(0xFFE65100),
      'bgColor': const Color(0xFFFFF7E6),
    },
    {
      'name': 'Dubai (UAE)',
      'fullName': 'Dubai (UAE)',
      'flag': '🇦🇪',
      'code': 'AE',
      'badge': 'Instant eVisa',
      'color': const Color(0xFF00796B),
      'bgColor': const Color(0xFFE0F2F1),
    },
    {
      'name': 'Turkey',
      'fullName': 'Turkey',
      'flag': '🇹🇷',
      'code': 'TR',
      'badge': 'Express 24h',
      'color': const Color(0xFFC62828),
      'bgColor': const Color(0xFFFFEBEE),
    },
    {
      'name': 'Saudi Arabia',
      'fullName': 'Saudi Arabia',
      'flag': '🇸🇦',
      'code': 'SA',
      'badge': 'Tourist & Umrah',
      'color': const Color(0xFF1B5E20),
      'bgColor': const Color(0xFFE8F5E9),
    },
    {
      'name': 'Malaysia',
      'fullName': 'Malaysia',
      'flag': '🇲🇾',
      'code': 'MY',
      'badge': 'Social Visit',
      'color': const Color(0xFF0277BD),
      'bgColor': const Color(0xFFE1F5FE),
    },
  ];

  List<VisaItemData> get _displayVisas {
    final baseVisas = _liveVisas ?? widget.visas;
    var list = baseVisas;

    // 1. Destination / Country filter
    if (_selectedDestination != 'All') {
      final dest = _selectedDestination.toLowerCase();
      list = list.where((v) {
        final country = v.countryName.toLowerCase();
        final title = v.title.toLowerCase();
        final code = v.countryCode.toLowerCase();
        return country.contains(dest) ||
            dest.contains(country) ||
            title.contains(dest) ||
            code == dest;
      }).toList();
    }

    // 2. Duration filter
    if (_selectedDurationFilter != 'All') {
      final dur = _selectedDurationFilter.toLowerCase();
      list = list.where((v) {
        final val = v.validity.toLowerCase();
        final desc = v.subtitle.toLowerCase();
        final durTime = v.duration.toLowerCase();
        if (dur.contains('< 1') || dur.contains('1 month') || dur.contains('30 days')) {
          return val.contains('30') || val.contains('1 month') || durTime.contains('30') || durTime.contains('1 month') || val.contains('days');
        }
        if (dur.contains('1 - 6') || dur.contains('6 months')) {
          return val.contains('6 month') || val.contains('3 month') || durTime.contains('6 month') || durTime.contains('3 month') || val.contains('90');
        }
        if (dur.contains('1 - 2') || dur.contains('2 years')) {
          return val.contains('1 year') || val.contains('2 year') || val.contains('up to 2') || durTime.contains('1 year') || durTime.contains('2 year');
        }
        if (dur.contains('5+') || dur.contains('5 years') || dur.contains('10')) {
          return val.contains('5 year') || val.contains('10 year') || desc.contains('golden') || desc.contains('residency');
        }
        return true;
      }).toList();
    }

    // 3. Fee filter
    if (_selectedFeeFilter != 'All') {
      final fee = _selectedFeeFilter.toLowerCase();
      list = list.where((v) {
        final vFee = v.fee.toLowerCase();
        if (fee.contains('free')) {
          return vFee.contains('free') || vFee.contains('0');
        }
        if (fee.contains('under 50') || fee.contains('< 50') || fee.contains('under pkr 50')) {
          return !vFee.contains('free') && (vFee.contains('2') || vFee.contains('3') || vFee.contains('4') || vFee.contains('30,000') || vFee.contains('45,000') || vFee.contains('25,000') || vFee.contains('35,000'));
        }
        if (fee.contains('50k - 100k') || fee.contains('50,000')) {
          return vFee.contains('50,000') || vFee.contains('60,000') || vFee.contains('75,000') || vFee.contains('80,000') || vFee.contains('95,000');
        }
        if (fee.contains('100k+') || fee.contains('above')) {
          return vFee.contains('120') || vFee.contains('150') || vFee.contains('200') || vFee.contains('350') || vFee.contains('500') || vFee.contains('100,000');
        }
        return true;
      }).toList();
    }

    // 4. Processing filter
    if (_selectedProcessingFilter != 'All') {
      final proc = _selectedProcessingFilter.toLowerCase();
      list = list.where((v) {
        final pt = v.duration.toLowerCase();
        final badge = (v.badgeText ?? '').toLowerCase();
        if (proc.contains('fast') || proc.contains('express') || proc.contains('< 2')) {
          return badge.contains('fast') || badge.contains('express') || pt.contains('day') || pt.contains('1-2') || pt.contains('2-3') || pt.contains('express');
        }
        if (proc.contains('standard') || proc.contains('3 - 6')) {
          return pt.contains('3-4') || pt.contains('4-6') || pt.contains('week') || pt.contains('month');
        }
        return true;
      }).toList();
    }

    // 5. Search query
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      list = list.where((v) {
        return v.title.toLowerCase().contains(q) ||
            v.countryName.toLowerCase().contains(q) ||
            v.subtitle.toLowerCase().contains(q) ||
            v.validity.toLowerCase().contains(q) ||
            v.fee.toLowerCase().contains(q);
      }).toList();
    }

    // 6. Sort
    if (_selectedSort == 'Fastest Processing') {
      list.sort((a, b) => a.duration.compareTo(b.duration));
    } else if (_selectedSort == 'Highest Approval') {
      list.sort((a, b) => b.approvalRate.compareTo(a.approvalRate));
    } else if (_selectedSort == 'Lowest Fee') {
      list.sort((a, b) => a.fee.compareTo(b.fee));
    }

    return list;
  }

  List<String> get _filterChips => [
    'All',
    if (_selectedDestination != 'All') _selectedDestination else 'Country',
    if (_selectedDurationFilter != 'All') _selectedDurationFilter else 'Duration',
    if (_selectedFeeFilter != 'All') _selectedFeeFilter else 'Fee',
    if (_selectedProcessingFilter != 'All') _selectedProcessingFilter else 'Processing',
  ];

  @override
  Widget build(BuildContext context) {
    final tt = context.textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final asyncBanners = ref.watch(liveTargetedBannersStreamProvider(_catId));
    final targetedBanners = (asyncBanners.hasValue && asyncBanners.value != null)
        ? asyncBanners.value!
        : const <Map<String, String>>[];

    final bgColor = isDark ? const Color(0xFF000000) : const Color(0xFFF7F9FF);
    final textPrimary =
        isDark ? Colors.white : const Color(0xFF171C21);
    final iconBtnBg =
        isDark ? const Color(0xFF18181B) : const Color(0xFFEDF2F8);
    final iconBtnBorder =
        isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0);
    final iconBtnColor =
        isDark ? const Color(0xFF93C5FD) : const Color(0xFF1B3A5C);

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
                      color: iconBtnBg,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: iconBtnBorder,
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: iconBtnColor,
                      size: 20,
                    ),
                  ),
                ),

                // Screen Title or Interactive Search Bar
                if (_isSearchOpen) ...[
                  Expanded(
                    child: Container(
                      height: 42.h,
                      margin: EdgeInsets.symmetric(horizontal: 8.w),
                      padding: EdgeInsets.symmetric(horizontal: 10.w),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF18181B) : Colors.white,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: isDark ? const Color(0xFF27272A) : const Color(0xFFCBD5E1),
                        ),
                      ),
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: textPrimary,
                        ),
                        onChanged: (val) {
                          setState(() => _searchQuery = val);
                        },
                        decoration: InputDecoration(
                          hintText: 'Search in ${widget.screenTitle}...',
                          hintStyle: TextStyle(
                            fontSize: 12.sp,
                            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 10.h),
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: Text(
                      widget.screenTitle,
                      textAlign: TextAlign.center,
                      style: tt.headlineSmall?.copyWith(
                        fontSize: 19.sp,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ],

                // Search Icon Button
                InkWell(
                  onTap: () {
                    setState(() {
                      _isSearchOpen = !_isSearchOpen;
                      if (!_isSearchOpen) {
                        _searchQuery = '';
                        _searchController.clear();
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(24.r),
                  child: Container(
                    width: 42.w,
                    height: 42.w,
                    decoration: BoxDecoration(
                      color: iconBtnBg,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: iconBtnBorder,
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      _isSearchOpen ? Icons.close_rounded : Icons.search_rounded,
                      color: iconBtnColor,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const AppDashboardBottomNav(currentIndex: 0),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 8.h),

            // 1. Promotional Hero Banner Carousel (Live synced with Admin Dashboard)
            CategoryBannerCarousel(
              banners: targetedBanners,
              defaultHeadline: widget.bannerHeadline,
              defaultSubtitle: widget.bannerSubtitle,
              watermarkIcon: widget.watermarkIcon,
              screenTitle: widget.screenTitle,
            ),
            SizedBox(height: 16.h),

            // 2. Horizontal Filter Chips Row
            SizedBox(
              height: 40.h,
              child: ListView.separated(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                scrollDirection: Axis.horizontal,
                itemCount: _filterChips.length,
                separatorBuilder: (_, __) => SizedBox(width: 8.w),
                itemBuilder: (context, index) {
                  final label = _filterChips[index];
                  final isFilterSet = (index == 0 &&
                          _selectedDestination == 'All' &&
                          _selectedDurationFilter == 'All' &&
                          _selectedFeeFilter == 'All' &&
                          _selectedProcessingFilter == 'All') ||
                      (index == 1 && _selectedDestination != 'All') ||
                      (index == 2 && _selectedDurationFilter != 'All') ||
                      (index == 3 && _selectedFeeFilter != 'All') ||
                      (index == 4 && _selectedProcessingFilter != 'All');
                  final isSelected = _selectedFilterIndex == index || isFilterSet;
                  final hasDropdown = index > 0;

                  return InkWell(
                    onTap: () {
                      if (index == 0) {
                        setState(() {
                          _selectedFilterIndex = 0;
                          _selectedDestination = 'All';
                          _selectedDurationFilter = 'All';
                          _selectedFeeFilter = 'All';
                          _selectedProcessingFilter = 'All';
                          _searchQuery = '';
                          _searchController.clear();
                        });
                        showToast(context, message: 'Showing all visas');
                      } else if (index == 1) {
                        _showCountryFilterModal(context);
                      } else if (index == 2) {
                        _showDurationFilterModal(context);
                      } else if (index == 3) {
                        _showFeeFilterModal(context);
                      } else if (index == 4) {
                        _showProcessingFilterModal(context);
                      }
                    },
                    borderRadius: BorderRadius.circular(20.r),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: EdgeInsets.symmetric(
                        horizontal: 14.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark
                                ? const Color(0xFF3B82F6)
                                : const Color(0xFF1B3A5C))
                            : (isDark
                                ? const Color(0xFF18181B)
                                : const Color(0xFFEDF2F8)),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: isSelected
                              ? (isDark
                                  ? const Color(0xFF3B82F6)
                                  : const Color(0xFF1B3A5C))
                              : (isDark
                                  ? const Color(0xFF27272A)
                                  : const Color(0xFFD0D7E2)),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 12.5.sp,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark
                                      ? const Color(0xFFE2E8F0)
                                      : const Color(0xFF0F172A)),
                            ),
                          ),
                          if (hasDropdown) ...[
                            SizedBox(width: 4.w),
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 16.sp,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF0F172A)),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
             SizedBox(height: 14.h),

            // 2B. Choose Your Destination Section (Only shown on non-golden visa screens)
            if (!widget.screenTitle.toLowerCase().contains('golden')) ...[
              _buildChooseDestinationSection(isDark),
              SizedBox(height: 14.h),
            ],

            // 3. Count & Sort Bar
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                children: [
                  Container(
                    width: 6.w,
                    height: 6.w,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF3B82F6)
                          : const Color(0xFF1B3A5C),
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _selectedDestination == 'All'
                            ? '${_displayVisas.length} visas available'
                            : '${_displayVisas.length} visas available for $_selectedDestination',
                        style: TextStyle(
                          fontSize: 12.5.sp,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF5A626A),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  InkWell(
                    onTap: () {
                      _showSortBottomSheet(context, isDark);
                    },
                    borderRadius: BorderRadius.circular(8.r),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 5.h,
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF18181B) : Colors.white,
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF27272A)
                              : const Color(0xFFDEE4ED),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Sort: $_selectedSort',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF171C21),
                            ),
                          ),
                          SizedBox(width: 3.w),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 15,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF5A626A),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),

            // 4. Visa Listing Cards
            if (_displayVisas.isEmpty)
              _buildEmptyDestinationState(isDark)
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h),
                itemCount: _displayVisas.length,
                separatorBuilder: (_, __) => SizedBox(height: 12.h),
                itemBuilder: (context, index) {
                  final item = _displayVisas[index];
                  ref.watch(savedVisasProvider);
                  final isBookmarked = ref
                      .read(savedVisasProvider.notifier)
                      .isSaved(item.title);

                  return _VisaCardView(
                    item: item,
                    isBookmarked: isBookmarked,
                    onBookmarkTap: () {
                      final savedItem = SavedVisaItem(
                        id: item.title,
                        title: item.title,
                        subtitle: item.subtitle,
                        countryName: item.countryName,
                        countryCode: item.countryCode,
                        categoryTag: widget.screenTitle,
                        duration: item.duration,
                        validity: item.validity,
                        approvalRate: item.approvalRate,
                        fee: item.fee,
                        badgeText: item.badgeText,
                        badgeBgColor: item.badgeBgColor?.toARGB32(),
                        badgeTextColor: item.badgeTextColor?.toARGB32(),
                        avatarBgColor: item.avatarBgColor?.toARGB32(),
                        avatarTextColor: item.avatarTextColor?.toARGB32(),
                      );
                      final wasAdded = ref
                          .read(savedVisasProvider.notifier)
                          .toggle(savedItem);
                      showGlobalToast(
                        message: wasAdded
                            ? 'Saved to Bookmarks'
                            : 'Removed from Bookmarks',
                        status: wasAdded ? 'success' : 'info',
                      );
                    },
                    onTap: () {
                      final detail = DetailRepository.getDetailFromGeneric(
                        id: item.id,
                        title: item.title,
                        subtitle: item.subtitle,
                        countryName: item.countryName,
                        categoryTag: widget.screenTitle,
                        fee: item.fee,
                        duration: item.duration,
                        validity: item.validity,
                        approvalRate: item.approvalRate,
                      );
                      context.push(AppRoutes.visaDetail, extra: detail);
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // CHOOSE YOUR DESTINATION SECTION (PREMIUM MODERN DESIGN)
  // ===========================================================================
  Widget _buildChooseDestinationSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(5.w),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E3A8A).withValues(alpha: 0.3)
                              : const Color(0xFF002444).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Icon(
                          Icons.travel_explore_rounded,
                          size: 16.sp,
                          color: isDark
                              ? const Color(0xFF60A5FA)
                              : const Color(0xFF002444),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'Choose Destination',
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF171C21),
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'Select a country to browse permits',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF73777F),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              if (_selectedDestination != 'All')
                InkWell(
                  onTap: () => setState(() => _selectedDestination = 'All'),
                  borderRadius: BorderRadius.circular(20.r),
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF18181B)
                          : const Color(0xFFEFF4FA),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF27272A)
                            : const Color(0xFFD2E0F0),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.close_rounded,
                          size: 13.sp,
                          color: isDark
                              ? const Color(0xFF60A5FA)
                              : const Color(0xFF002444),
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          'Show All',
                          style: TextStyle(
                            fontSize: 11.5.sp,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? const Color(0xFF60A5FA)
                                : const Color(0xFF002444),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF18181B)
                        : const Color(0xFFF1F5FA),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    '${_destinations.length - 1} Countries',
                    style: TextStyle(
                      fontSize: 10.5.sp,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF5A626A),
                    ),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(height: 12.h),
        SizedBox(
          height: 98.h,
          child: ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _destinations.length,
            separatorBuilder: (_, __) => SizedBox(width: 10.w),
            itemBuilder: (context, index) {
              final dest = _destinations[index];
              final isSelected = _selectedDestination == dest['name'] ||
                  (_selectedDestination == 'All' && dest['name'] == 'All');

              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedDestination = dest['name'] as String;
                  });
                },
                borderRadius: BorderRadius.circular(16.r),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  width: 116.w,
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? const LinearGradient(
                            colors: [Color(0xFF002444), Color(0xFF133E68)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isSelected
                        ? null
                        : (isDark ? const Color(0xFF18181B) : Colors.white),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF002444)
                          : (isDark
                              ? const Color(0xFF27272A)
                              : const Color(0xFFE5EBF2)),
                      width: isSelected ? 1.5 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected
                            ? const Color(0xFF002444).withValues(alpha: 0.22)
                            : (isDark
                                ? Colors.black.withValues(alpha: 0.2)
                                : const Color(0xFF1B3A5C).withValues(alpha: 0.04)),
                        blurRadius: isSelected ? 10 : 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Top Row: Circular Flag and checkmark/status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 32.w,
                            height: 32.w,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white.withValues(alpha: 0.15)
                                  : (isDark
                                      ? const Color(0xFF121212)
                                      : const Color(0xFFF4F7FB)),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? Colors.white.withValues(alpha: 0.25)
                                    : (isDark
                                        ? const Color(0xFF27272A)
                                        : const Color(0xFFE2EAF2)),
                                width: 0.8,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                dest['flag'] as String,
                                style: TextStyle(fontSize: 16.sp),
                              ),
                            ),
                          ),
                          if (isSelected)
                            Container(
                              padding: EdgeInsets.all(3.w),
                              decoration: const BoxDecoration(
                                color: Color(0xFF4ADE80),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.check,
                                size: 10.sp,
                                color: const Color(0xFF002444),
                              ),
                            )
                          else
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 5.w, vertical: 1.5.h),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF18181B)
                                    : const Color(0xFFF1F5FA),
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                              child: Text(
                                dest['code'] as String,
                                style: TextStyle(
                                  fontSize: 8.5.sp,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? const Color(0xFFA1A1AA)
                                      : const Color(0xFF73777F),
                                ),
                              ),
                            ),
                        ],
                      ),
                      // Country Name & Tagline
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              dest['name'] as String,
                              style: TextStyle(
                                fontSize: 11.5.sp,
                                fontWeight: isSelected
                                    ? FontWeight.w800
                                    : FontWeight.w700,
                                color: isSelected
                                    ? Colors.white
                                    : (isDark
                                        ? const Color(0xFFF8FAFC)
                                        : const Color(0xFF171C21)),
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                          SizedBox(height: 2.h),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              dest['badge'] as String,
                              style: TextStyle(
                                fontSize: 9.sp,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? const Color(0xFFB5D3F0)
                                    : (dest['color'] as Color),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showCountryFilterModal(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filter by Destination Country',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF002444),
                  ),
                ),
                SizedBox(height: 12.h),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: _destinations.map((dest) {
                    final isSel = _selectedDestination == dest['name'];
                    return FilterChip(
                      selected: isSel,
                      selectedColor: isDark
                          ? const Color(0xFF3B82F6)
                          : const Color(0xFF002444),
                      backgroundColor: isDark
                          ? const Color(0xFF18181B)
                          : const Color(0xFFF1F5FA),
                      checkmarkColor: Colors.white,
                      side: BorderSide(
                        color: isSel
                            ? (isDark
                                ? const Color(0xFF3B82F6)
                                : const Color(0xFF002444))
                            : (isDark
                                ? const Color(0xFF27272A)
                                : const Color(0xFFD2E0F0)),
                      ),
                      label: Text(
                        '${dest['flag']} ${dest['name']}',
                        style: TextStyle(
                          color: isSel
                              ? Colors.white
                              : (isDark
                                  ? const Color(0xFFF1F5F9)
                                  : const Color(0xFF0F172A)),
                          fontWeight: isSel ? FontWeight.w700 : FontWeight.w600,
                        ),
                      ),
                      onSelected: (_) {
                        setState(() {
                          _selectedDestination = dest['name'] as String;
                          _selectedFilterIndex = 1;
                        });
                        Navigator.pop(ctx);
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDurationFilterModal(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const durations = [
      'All',
      'Short Stay (< 1 Month)',
      'Medium Stay (1 - 6 Months)',
      'Long Stay (1 - 2 Years)',
      'Residency / Long Term (5+ Years)',
    ];
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filter by Visa Duration',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF002444),
                  ),
                ),
                SizedBox(height: 12.h),
                for (final d in durations)
                  ListTile(
                    title: Text(
                      d,
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFFF8FAFC)
                            : const Color(0xFF0F172A),
                        fontWeight: _selectedDurationFilter == d
                            ? FontWeight.w700
                            : FontWeight.w500,
                        fontSize: 14.sp,
                      ),
                    ),
                    trailing: _selectedDurationFilter == d
                        ? Icon(Icons.check_circle_rounded,
                            color: isDark
                                ? const Color(0xFF60A5FA)
                                : const Color(0xFF002444))
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedDurationFilter = d;
                        _selectedFilterIndex = d == 'All' ? 0 : 2;
                      });
                      Navigator.pop(ctx);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFeeFilterModal(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const fees = [
      'All',
      'Free Consultation',
      'Under PKR 50,000',
      'PKR 50k - 100k',
      'Above PKR 100,000',
    ];
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filter by Fee / Cost',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF002444),
                  ),
                ),
                SizedBox(height: 12.h),
                for (final f in fees)
                  ListTile(
                    title: Text(
                      f,
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFFF8FAFC)
                            : const Color(0xFF0F172A),
                        fontWeight: _selectedFeeFilter == f
                            ? FontWeight.w700
                            : FontWeight.w500,
                        fontSize: 14.sp,
                      ),
                    ),
                    trailing: _selectedFeeFilter == f
                        ? Icon(Icons.check_circle_rounded,
                            color: isDark
                                ? const Color(0xFF60A5FA)
                                : const Color(0xFF002444))
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedFeeFilter = f;
                        _selectedFilterIndex = f == 'All' ? 0 : 3;
                      });
                      Navigator.pop(ctx);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showProcessingFilterModal(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const proc = [
      'All',
      'Fast-Track / Express (< 2 Weeks)',
      'Standard Processing (3 - 6 Weeks)',
    ];
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filter by Processing Speed',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF002444),
                  ),
                ),
                SizedBox(height: 12.h),
                for (final p in proc)
                  ListTile(
                    title: Text(
                      p,
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFFF8FAFC)
                            : const Color(0xFF0F172A),
                        fontWeight: _selectedProcessingFilter == p
                            ? FontWeight.w700
                            : FontWeight.w500,
                        fontSize: 14.sp,
                      ),
                    ),
                    trailing: _selectedProcessingFilter == p
                        ? Icon(Icons.check_circle_rounded,
                            color: isDark
                                ? const Color(0xFF60A5FA)
                                : const Color(0xFF002444))
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedProcessingFilter = p;
                        _selectedFilterIndex = p == 'All' ? 0 : 4;
                      });
                      Navigator.pop(ctx);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyDestinationState(bool isDark) {
    final hasActiveFilters = _selectedDestination != 'All' ||
        _selectedDurationFilter != 'All' ||
        _selectedFeeFilter != 'All' ||
        _selectedProcessingFilter != 'All' ||
        _searchQuery.isNotEmpty;

    final title = hasActiveFilters
        ? 'No Visas Found with Current Filters'
        : 'No services available in this category yet.';
    final subtitle = hasActiveFilters
        ? 'Try broadening your duration, fee, or country filters to view available permits.'
        : 'There are currently no services available in this category.';

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF121212) : Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.flight_takeoff_rounded,
              size: 44.sp,
              color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF73777F),
            ),
            SizedBox(height: 10.h),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5.sp,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF5A626A),
              ),
            ),
            if (hasActiveFilters) ...[
              SizedBox(height: 14.h),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark
                      ? const Color(0xFF2563EB)
                      : const Color(0xFF002444),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                ),
                onPressed: () {
                  setState(() {
                    _selectedFilterIndex = 0;
                    _selectedDestination = 'All';
                    _selectedDurationFilter = 'All';
                    _selectedFeeFilter = 'All';
                    _selectedProcessingFilter = 'All';
                    _searchQuery = '';
                    _searchController.clear();
                  });
                  showToast(context, message: 'All filters reset');
                },
                child: const Text('Reset All Filters'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showSortBottomSheet(BuildContext context, bool isDark) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sort Visas By',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF002444),
                  ),
                ),
                SizedBox(height: 12.h),
                for (final option in [
                  'Popular',
                  'Fastest Processing',
                  'Lowest Fee',
                  'Highest Approval'
                ])
                  ListTile(
                    title: Text(
                      option,
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFFF8FAFC)
                            : const Color(0xFF0F172A),
                        fontWeight: _selectedSort == option
                            ? FontWeight.w700
                            : FontWeight.w500,
                        fontSize: 14.sp,
                      ),
                    ),
                    trailing: _selectedSort == option
                        ? Icon(
                            Icons.check_circle_rounded,
                            color: isDark
                                ? const Color(0xFF60A5FA)
                                : const Color(0xFF002444),
                          )
                        : null,
                    onTap: () {
                      setState(() => _selectedSort = option);
                      Navigator.pop(context);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Dedicated Card View exactly matching the uploaded mobile system UI.
class _VisaCardView extends StatelessWidget {
  const _VisaCardView({
    required this.item,
    required this.isBookmarked,
    required this.onBookmarkTap,
    required this.onTap,
  });

  final VisaItemData item;
  final bool isBookmarked;
  final VoidCallback onBookmarkTap;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF121212) : Colors.white;
    final cardBorder =
        isDark ? const Color(0xFF27272A) : const Color(0xFFE8EEF5);
    final titleColor =
        isDark ? Colors.white : const Color(0xFF171C21);
    final subtitleColor =
        isDark ? const Color(0xFFA1A1AA) : const Color(0xFF5A626A);
    final chipBg =
        isDark ? const Color(0xFF18181B) : const Color(0xFFF1F4F9);
    final chipText =
        isDark ? const Color(0xFFE2E8F0) : const Color(0xFF43474E);
    final dividerColor =
        isDark ? const Color(0xFF27272A) : const Color(0xFFF1F4F8);
    final feeColor =
        isDark ? const Color(0xFF60A5FA) : const Color(0xFF171C21);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: cardBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.25)
                : const Color(0xFF1B3A5C).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16.r),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16.r),
          child: Padding(
            padding: EdgeInsets.all(14.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Country Code Avatar + Title & Subtitle + Bookmark
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Country 2-letter Avatar
                    Container(
                      width: 44.w,
                      height: 44.w,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF18181B)
                            : (item.avatarBgColor ?? const Color(0xFFEBF1FA)),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Center(
                        child: Text(
                          item.countryCode,
                          style: TextStyle(
                            color: isDark
                                ? const Color(0xFF60A5FA)
                                : (item.avatarTextColor ??
                                    const Color(0xFF1B3A5C)),
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),

                    // Title & Badges
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.title,
                                  maxLines: 2,
                                  softWrap: true,
                                  style: TextStyle(
                                    fontSize: 14.5.sp,
                                    fontWeight: FontWeight.w700,
                                    color: titleColor,
                                  ),
                                ),
                              ),
                              if (item.badgeText != null) ...[
                                SizedBox(width: 6.w),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 6.w,
                                    vertical: 2.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF78350F)
                                        : (item.badgeBgColor ??
                                            const Color(0xFFFFF3E0)),
                                    borderRadius: BorderRadius.circular(4.r),
                                  ),
                                  child: Text(
                                    item.badgeText!,
                                    style: TextStyle(
                                      color: isDark
                                          ? const Color(0xFFFDE68A)
                                          : (item.badgeTextColor ??
                                              const Color(0xFFB76E00)),
                                      fontSize: 9.5.sp,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          SizedBox(height: 3.h),
                          Text(
                            item.subtitle,
                            softWrap: true,
                            style: TextStyle(
                              fontSize: 12.5.sp,
                              fontWeight: FontWeight.w400,
                              color: subtitleColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 6.w),

                    // Bookmark Button
                    InkWell(
                      onTap: onBookmarkTap,
                      borderRadius: BorderRadius.circular(16.r),
                      child: Padding(
                        padding: EdgeInsets.all(2.w),
                        child: Icon(
                          isBookmarked
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_border_rounded,
                          color: isBookmarked
                              ? (isDark
                                  ? const Color(0xFF3B82F6)
                                  : const Color(0xFF1B3A5C))
                              : (isDark
                                  ? const Color(0xFF64748B)
                                  : const Color(0xFF8C939E)),
                          size: 20.sp,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),

                // Middle Chips: Duration, Validity, Approval Rate
                Wrap(
                  spacing: 6.w,
                  runSpacing: 6.h,
                  children: [
                    // Duration Chip
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 3.5.h,
                      ),
                      decoration: BoxDecoration(
                        color: chipBg,
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 11.5.sp,
                            color: subtitleColor,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            item.duration,
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w500,
                              color: chipText,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Validity Chip
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 3.5.h,
                      ),
                      decoration: BoxDecoration(
                        color: chipBg,
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 11.sp,
                            color: subtitleColor,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            item.validity,
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w500,
                              color: chipText,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Approval Rate Chip
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 3.5.h,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF064E3B)
                            : const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            size: 11.5.sp,
                            color: isDark
                                ? const Color(0xFF34D399)
                                : const Color(0xFF2E7D32),
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            item.approvalRate,
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? const Color(0xFF34D399)
                                  : const Color(0xFF2E7D32),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),

                // Bottom Divider & Fee / View Details Row
                Container(
                  height: 1,
                  color: dividerColor,
                ),
                SizedBox(height: 8.h),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Consultation & Fee',
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? const Color(0xFFA1A1AA)
                                  : const Color(0xFF73777F),
                            ),
                          ),
                          SizedBox(height: 2.h),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              item.fee,
                              style: TextStyle(
                                fontSize: 14.5.sp,
                                fontWeight: FontWeight.w800,
                                color: feeColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 14.w,
                        vertical: 7.h,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF3B82F6)
                            : const Color(0xFF002444),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'View Details',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5.sp,
                            ),
                          ),
                          SizedBox(width: 5.w),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 13,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


