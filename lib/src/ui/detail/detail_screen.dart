import 'package:flutter_sd_consultant/src/data/models/detail_item_model.dart';
import 'package:flutter_sd_consultant/src/data/models/visa_listing_model.dart';
import 'package:flutter_sd_consultant/src/data/repositories/detail_repository.dart';
import 'package:flutter_sd_consultant/src/imports/core_imports.dart';
import 'package:flutter_sd_consultant/src/imports/packages_imports.dart';
import 'package:flutter_sd_consultant/src/services/supabase_database_service.dart';
import 'package:flutter_sd_consultant/src/ui/saved/models/saved_visa_model.dart';
import 'package:flutter_sd_consultant/src/ui/saved/providers/saved_visas_provider.dart';

class DetailScreen extends ConsumerStatefulWidget {
  const DetailScreen({
    super.key,
    required this.item,
  });

  final DetailItemModel item;

  @override
  ConsumerState<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends ConsumerState<DetailScreen> {
  late DetailItemModel _item;
  int _selectedTabIndex = 0;
  final ScrollController _scrollController = ScrollController();

  final GlobalKey _overviewKey = GlobalKey();
  final GlobalKey _requirementsKey = GlobalKey();
  final GlobalKey _documentsKey = GlobalKey();
  final GlobalKey _eligibilityKey = GlobalKey();
  final GlobalKey _feeKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _item = _enrichItem(widget.item);
    _resolveLiveVisa();
  }

  Future<void> _resolveLiveVisa() async {
    final id = widget.item.id;
    if (id.isEmpty) return;

    try {
      final res = await SupabaseDatabaseService.instance.client
          .from('visa_listings')
          .select('*')
          .eq('id', id)
          .maybeSingle();

      if (res != null && mounted) {
        final visaModel = VisaListingModel.fromJson(res);
        if (visaModel.title.trim().isNotEmpty) {
          setState(() {
            _item = DetailRepository.getDetailForVisa(visaModel);
          });
        }
      }
    } catch (_) {}
  }

  DetailItemModel _enrichItem(DetailItemModel item) {
    return item;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToSection(int index) {
    setState(() => _selectedTabIndex = index);
    final key = switch (index) {
      0 => _overviewKey,
      1 => _requirementsKey,
      2 => _documentsKey,
      3 => _eligibilityKey,
      4 => _feeKey,
      _ => _overviewKey,
    };
    final ctx = key.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool get _isScholarshipOrJob {
    final cat = _item.categoryTag.toLowerCase();
    final title = _item.title.toLowerCase();
    final sub = _item.subtitle.toLowerCase();
    final type = _item.type.toLowerCase();
    return cat.contains('scholarship') ||
        cat.contains('job') ||
        title.contains('scholarship') ||
        title.contains('job') ||
        sub.contains('scholarship') ||
        sub.contains('job') ||
        type == 'scholarship' ||
        type == 'job';
  }

  bool get _isJob {
    final cat = _item.categoryTag.toLowerCase();
    final title = _item.title.toLowerCase();
    final sub = _item.subtitle.toLowerCase();
    final type = _item.type.toLowerCase();
    return type == 'job' ||
        cat.contains('job') ||
        cat.contains('sponser') ||
        cat.contains('sponsor') ||
        title.contains('job') ||
        sub.contains('job');
  }

  String _getJobSalaryText(DetailItemModel item) {
    if (item.salary != null && item.salary!.trim().isNotEmpty) {
      return item.salary!.trim();
    }
    return '£36,000 – £44,000 / yr';
  }

  Widget _buildJobSalaryCard(DetailItemModel item, bool isDark) {
    final salary = _getJobSalaryText(item);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF064E3B).withValues(alpha: 0.25)
            : const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: isDark
              ? const Color(0xFF059669).withValues(alpha: 0.45)
              : const Color(0xFFA7F3D0),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42.w,
            height: 42.w,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF047857) : const Color(0xFF10B981),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(Icons.payments_rounded, color: Colors.white, size: 22.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SALARY (PER ANNUM)',
                  style: TextStyle(
                    fontSize: 10.5.sp,
                    fontWeight: FontWeight.w700,
                    color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF047857),
                    letterSpacing: 0.5,
                    fontFamily: 'Poppins',
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  salary,
                  style: TextStyle(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w800,
                    color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF065F46),
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF064E3B) : const Color(0xFFD1FAE5),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.verified_rounded,
                  size: 12.sp,
                  color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF059669),
                ),
                SizedBox(width: 4.w),
                Text(
                  'Sponsored',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF059669),
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _resolveFee(DetailItemModel item) {
    if (item.totalPayable.isNotEmpty && !item.totalPayable.toLowerCase().contains('from')) {
      return item.totalPayable;
    }
    if (item.serviceFeeValue.isNotEmpty && !item.serviceFeeValue.toLowerCase().contains('from')) {
      return item.serviceFeeValue;
    }
    final cat = item.categoryTag.toLowerCase();
    final title = item.title.toLowerCase();
    if (cat.contains('job') || title.contains('job')) return 'PKR 15,000';
    if (cat.contains('scholarship') || title.contains('scholarship')) return 'PKR 25,000';
    if (cat.contains('work') || title.contains('work') || cat.contains('golden') || title.contains('golden')) {
      return 'PKR 40,000';
    }
    return 'PKR 25,000';
  }

  @override
  Widget build(BuildContext context) {
    final item = _item;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isScholarshipOrJob = _isScholarshipOrJob;

    // Design Tokens aligned with the global app theme
    final bgScaffold = isDark ? const Color(0xFF000000) : const Color(0xFFF7F9FF);
    final surfaceWhite = isDark ? const Color(0xFF121212) : Colors.white;
    final surfaceContainerLow = isDark ? const Color(0xFF18181B) : const Color(0xFFF0F4FA);
    final primaryNavy = isDark ? Colors.white : const Color(0xFF002444);
    final secondaryText = isDark ? const Color(0xFFA1A1AA) : const Color(0xFF5A626A);
    final onSurfaceText = isDark ? Colors.white : const Color(0xFF171C21);
    final cardBorder = isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0);
    final cardBg = surfaceWhite;
    const greenAvailable = Color(0xFF2E7D32);

    ref.watch(savedVisasProvider);
    final isBookmarked = ref.read(savedVisasProvider.notifier).isSaved(item.title);

    final feeText = _resolveFee(item);

    return Scaffold(
      backgroundColor: bgScaffold,
      appBar: AppBar(
        backgroundColor: surfaceWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? Colors.white : const Color(0xFF002444),
            size: 22.sp,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        centerTitle: true,
        title: Text(
          (item.type == 'job' || item.categoryTag.toLowerCase().contains('job') || item.title.toLowerCase().contains('job'))
              ? 'Job Details'
              : ((item.type == 'scholarship' || item.categoryTag.toLowerCase().contains('scholarship') || item.title.toLowerCase().contains('scholarship'))
                  ? 'Scholarship Details'
                  : 'Visa Details'),
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF002444),
            fontFamily: 'Poppins',
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              color: isBookmarked
                  ? (isDark ? const Color(0xFF60A5FA) : const Color(0xFF002444))
                  : (isDark ? Colors.white70 : const Color(0xFF171C21)),
              size: 22.sp,
            ),
            onPressed: () {
              final savedItem = SavedVisaItem(
                id: item.id.isNotEmpty ? item.id : item.title,
                title: item.title,
                subtitle: item.subtitle,
                countryName: item.countryName,
                categoryTag: item.categoryTag,
                duration: item.processingTime,
                validity: item.validity,
                approvalRate: item.successRate,
                fee: item.totalPayable,
                badgeText: item.statusBadge,
                flag: item.countryFlag,
              );
              final added = ref.read(savedVisasProvider.notifier).toggle(savedItem);
              showToast(
                context,
                message: added ? 'Saved to Bookmarks' : 'Removed from Bookmarks',
                status: added ? 'success' : 'info',
              );
            },
          ),
          SizedBox(width: 8.w),
        ],
      ),
      bottomNavigationBar: _buildStickyBottomBar(context, item, feeText, isDark, isScholarshipOrJob),
      body: SingleChildScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Hero Image Section
            _buildHeroBanner(item, isDark),

            // 2. Overlapping Rounded Content Sheet (-24px overlap)
            Transform.translate(
              offset: Offset(0, -24.h),
              child: Container(
                decoration: BoxDecoration(
                  color: surfaceWhite,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1B3A5C).withValues(alpha: 0.08),
                      blurRadius: 24,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                padding: EdgeInsets.only(top: 24.h, left: 16.w, right: 16.w, bottom: 40.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title & Category Badge Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: TextStyle(
                                  fontSize: 22.sp,
                                  fontWeight: FontWeight.w800,
                                  color: primaryNavy,
                                  letterSpacing: -0.3,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              SizedBox(height: 3.h),
                              Text(
                                item.subtitle.isNotEmpty ? item.subtitle : 'Official Advisory Route',
                                style: TextStyle(
                                  fontSize: 13.5.sp,
                                  color: secondaryText,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E3A8A).withValues(alpha: 0.35)
                                : const Color(0xFF002444).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Text(
                            item.categoryTag.isNotEmpty ? item.categoryTag : 'Visa',
                            style: TextStyle(
                              fontSize: 11.5.sp,
                              fontWeight: FontWeight.w700,
                              color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF002444),
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),

                    // Country Flag & Status Sub-row
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            '${item.countryFlag.isNotEmpty ? item.countryFlag : "🌍"} ${item.countryName}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13.5.sp,
                              fontWeight: FontWeight.w600,
                              color: secondaryText,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: surfaceContainerLow,
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7.w,
                                height: 7.w,
                                decoration: const BoxDecoration(
                                  color: greenAvailable,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: 5.w),
                              Text(
                                item.statusBadge.isNotEmpty ? item.statusBadge : 'Available',
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w700,
                                  color: greenAvailable,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 18.h),

                    // Salary Card (Only for Sponsored Jobs)
                    if (_isJob) ...[
                      _buildJobSalaryCard(item, isDark),
                      SizedBox(height: 16.h),
                    ],

                    // 3. 4-Key Metrics Row
                    _buildStatsGrid(item, surfaceContainerLow, onSurfaceText, secondaryText, greenAvailable, isDark),
                    SizedBox(height: 18.h),

                    // 4. Horizontal Tab Chips
                    _buildTabPills(isDark, isScholarshipOrJob),
                    SizedBox(height: 18.h),

                    // 5. About this visa Card (Overview Key)
                    _buildAboutCard(item, surfaceContainerLow, primaryNavy, secondaryText, isDark),
                    SizedBox(height: 20.h),

                    // 6. Processing Information Timeline (Requirements Key)
                    _buildProcessingTimeline(item, primaryNavy, secondaryText, onSurfaceText, surfaceContainerLow, cardBg, cardBorder, isDark),
                    SizedBox(height: 20.h),

                    // Application Requirements & Checkpoints (Configured dynamically from Admin)
                    _buildApplicationRequirementsCard(item, primaryNavy, secondaryText, onSurfaceText, cardBg, cardBorder, greenAvailable, isDark),
                    SizedBox(height: 20.h),

                    // 7. Eligibility Criteria (Eligibility Key)
                    _buildEligibilitySection(item, primaryNavy, onSurfaceText, greenAvailable, cardBg, cardBorder),
                    SizedBox(height: 20.h),

                    // 8. Mandatory Documents 2-Column Grid (Documents Key)
                    _buildDocumentsGrid(item, surfaceContainerLow, primaryNavy, onSurfaceText, secondaryText, isDark),
                    SizedBox(height: 20.h),

                    // 9. Fee Breakdown Card (Fee Key) - ONLY show for non-scholarship/job visas
                    if (!isScholarshipOrJob) ...[
                      _buildFeeBreakdownCard(item, feeText, primaryNavy, secondaryText, onSurfaceText, surfaceContainerLow, cardBg, cardBorder, isDark),
                      SizedBox(height: 20.h),
                    ],

                    // 10. Official Advisory Guarantee Banner
                    _buildTrustBanner(primaryNavy, secondaryText, onSurfaceText, greenAvailable, cardBg, cardBorder, isDark),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 1. HERO COVER BANNER
  // ===========================================================================
  Widget _buildHeroBanner(DetailItemModel item, bool isDark) {
    return SizedBox(
      height: 220.h,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (item.heroImageUrl.isNotEmpty)
            Image.network(
              item.heroImageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildHeroFallback(item, isDark),
            )
          else
            _buildHeroFallback(item, isDark),

          // Dark gradient overlay at bottom
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.15),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.65),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroFallback(DetailItemModel item, bool isDark) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF18181B), const Color(0xFF121212)]
              : [const Color(0xFF1B3A5C), const Color(0xFF002444)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(item.countryFlag.isNotEmpty ? item.countryFlag : '🌍', style: TextStyle(fontSize: 36.sp)),
                SizedBox(height: 6.h),
                Text(
                  item.countryName,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'SB Consultants Official Visa Program',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11.sp,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 2. 4-KEY METRICS ROW
  // ===========================================================================
  Widget _buildStatsGrid(
    DetailItemModel item,
    Color bg,
    Color onSurface,
    Color secondary,
    Color green,
    bool isDark,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          _buildStatCell(
            Icons.schedule_rounded,
            item.processingTime.isNotEmpty ? item.processingTime : '3-4 wks',
            'Processing',
            onSurface,
            secondary,
            isDark,
            false,
          ),
          _buildStatDivider(isDark),
          _buildStatCell(
            Icons.calendar_month_rounded,
            item.validity.isNotEmpty ? item.validity : 'Up to 3 yrs',
            'Validity',
            onSurface,
            secondary,
            isDark,
            false,
          ),
          _buildStatDivider(isDark),
          _buildStatCell(
            Icons.verified_user_rounded,
            item.successRate.isNotEmpty ? item.successRate : '96%',
            'Success',
            isDark ? const Color(0xFF4ADE80) : green,
            secondary,
            isDark,
            true,
          ),
          _buildStatDivider(isDark),
          _buildStatCell(
            Icons.group_rounded,
            item.applicantsCount.isNotEmpty ? item.applicantsCount : '1,240',
            'Applicants',
            onSurface,
            secondary,
            isDark,
            false,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCell(
    IconData icon,
    String value,
    String label,
    Color valueColor,
    Color labelColor,
    bool isDark,
    bool isGreen,
  ) {
    final circleBg = isGreen
        ? (isDark ? const Color(0xFF064E3B).withValues(alpha: 0.35) : const Color(0xFFE8F5E9))
        : (isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.35) : const Color(0xFFE0EDFA));
    final resolvedIconColor = isGreen
        ? (isDark ? const Color(0xFF4ADE80) : const Color(0xFF2E7D32))
        : (isDark ? const Color(0xFF60A5FA) : const Color(0xFF1B3A5C));

    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32.w,
            height: 32.w,
            decoration: BoxDecoration(
              color: circleBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16.sp, color: resolvedIconColor),
          ),
          SizedBox(height: 6.h),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: valueColor,
              fontFamily: 'Poppins',
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5.sp,
              fontWeight: FontWeight.w500,
              color: labelColor,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider(bool isDark) {
    return Container(
      width: 1.w,
      height: 26.h,
      color: isDark ? const Color(0xFF27272A) : const Color(0xFFCBD5E1),
    );
  }

  // ===========================================================================
  // 3. TAB PILLS (Overview, Requirements, Documents, Eligibility, Fees)
  // ===========================================================================
  Widget _buildTabPills(bool isDark, bool isScholarshipOrJob) {
    final tabs = isScholarshipOrJob
        ? const ['Overview', 'Requirements', 'Documents', 'Eligibility']
        : const ['Overview', 'Requirements', 'Documents', 'Eligibility', 'Fees'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          for (int i = 0; i < tabs.length; i++) ...[
            InkWell(
              onTap: () => _scrollToSection(i),
              borderRadius: BorderRadius.circular(20.r),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 7.h),
                decoration: BoxDecoration(
                  color: _selectedTabIndex == i
                      ? (isDark ? const Color(0xFF3B82F6) : const Color(0xFF002444))
                      : (isDark ? const Color(0xFF18181B) : const Color(0xFFEAEEF5)),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: _selectedTabIndex == i
                        ? (isDark ? const Color(0xFF3B82F6) : const Color(0xFF002444))
                        : (isDark ? const Color(0xFF27272A) : const Color(0xFFCBD5E1)),
                  ),
                ),
                child: Text(
                  tabs[i],
                  style: TextStyle(
                    fontSize: 12.5.sp,
                    fontWeight: _selectedTabIndex == i ? FontWeight.w700 : FontWeight.w500,
                    color: _selectedTabIndex == i
                        ? Colors.white
                        : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF43474E)),
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ),
            if (i < tabs.length - 1) SizedBox(width: 8.w),
          ],
        ],
      ),
    );
  }

  // ===========================================================================
  // 4. ABOUT THIS VISA CARD
  // ===========================================================================
  Widget _buildAboutCard(DetailItemModel item, Color bg, Color primary, Color secondary, bool isDark) {
    final aboutDesc = item.aboutDescription.isNotEmpty
        ? item.aboutDescription
        : '${item.title} allows international candidates to live, study, or work in ${item.countryName}. SB Consultants assists applicants with verified document assessment, appointment scheduling, and end-to-end consular filing.';

    return Container(
      key: _overviewKey,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B3A5C).withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: isDark ? const Color(0xFF60A5FA) : primary,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  item.aboutTitle.isNotEmpty ? item.aboutTitle : 'About this visa',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: primary,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            aboutDesc,
            style: TextStyle(
              fontSize: 13.sp,
              height: 1.5,
              color: secondary,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 5. PROCESSING INFORMATION TIMELINE
  // ===========================================================================
  Widget _buildProcessingTimeline(
    DetailItemModel item,
    Color primary,
    Color secondary,
    Color onSurface,
    Color bg,
    Color cardBg,
    Color cardBorder,
    bool isDark,
  ) {
    final steps = item.timelineSteps.isNotEmpty
        ? item.timelineSteps
        : [
            const TimelineStepItem(
              title: 'University Offer & CAS',
              duration: '1-2 wks',
              description: 'Receive official CAS from a licensed UK sponsor after preliminary screening.',
              icon: Icons.school_rounded,
            ),
            const TimelineStepItem(
              title: 'Financial Proof & Biometrics',
              duration: '1 wk',
              description: '28-day bank balance holding certificate & VFS appointment scheduling.',
              icon: Icons.account_balance_rounded,
            ),
            const TimelineStepItem(
              title: 'Decision & Visa Stamp',
              duration: '3-4 wks',
              description: 'Standard UKVI processing or Priority clearance (within 5 working days).',
              icon: Icons.verified_rounded,
            ),
          ];

    return Column(
      key: _requirementsKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Processing Information',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: primary,
            fontFamily: 'Poppins',
          ),
        ),
        SizedBox(height: 12.h),
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: cardBorder),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1B3A5C).withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              for (int i = 0; i < steps.length; i++) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Step Icon Circle + line
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 30.w,
                          height: 30.w,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF2563EB) : const Color(0xFF002444),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.circle, size: 8.sp, color: Colors.white),
                        ),
                        if (i < steps.length - 1)
                          Container(
                            width: 2.w,
                            height: 36.h,
                            color: cardBorder,
                            margin: EdgeInsets.symmetric(vertical: 4.h),
                          ),
                      ],
                    ),
                    SizedBox(width: 12.w),
                    // Step Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  steps[i].title,
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w700,
                                    color: onSurface,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                                decoration: BoxDecoration(
                                  color: bg,
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                                child: Text(
                                  steps[i].duration,
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w600,
                                    color: secondary,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            steps[i].description,
                            style: TextStyle(
                              fontSize: 12.sp,
                              height: 1.4,
                              color: secondary,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          if (i < steps.length - 1) SizedBox(height: 12.h),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 6. ELIGIBILITY CRITERIA
  // ===========================================================================
  Widget _buildEligibilitySection(
    DetailItemModel item,
    Color primary,
    Color onSurface,
    Color green,
    Color cardBg,
    Color cardBorder,
  ) {
    final criteria = item.eligibilityCriteria.isNotEmpty
        ? item.eligibilityCriteria
        : [
            'Unconditional offer letter & valid CAS issued by an approved UK sponsor.',
            'English language proficiency (IELTS UKVI min 6.0 overall or equivalent score).',
            'Proof of funds for course fees and living costs (min £1,334/mo inside London, £1,023/mo outside).',
            'Valid ATAS clearance certificate (if applicable for sensitive technical or engineering courses).',
          ];

    return Column(
      key: _eligibilityKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Eligibility Criteria',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: primary,
            fontFamily: 'Poppins',
          ),
        ),
        SizedBox(height: 12.h),
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: cardBorder),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1B3A5C).withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              for (int i = 0; i < criteria.length; i++) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle_rounded, color: green, size: 18.sp),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        criteria[i],
                        style: TextStyle(
                          fontSize: 13.sp,
                          height: 1.4,
                          color: onSurface,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ],
                ),
                if (i < criteria.length - 1) SizedBox(height: 12.h),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 7. MANDATORY DOCUMENTS 2-COLUMN GRID
  // ===========================================================================
  Widget _buildDocumentsGrid(
    DetailItemModel item,
    Color bg,
    Color primary,
    Color onSurface,
    Color secondary,
    bool isDark,
  ) {
    final docs = item.mandatoryDocuments.isNotEmpty
        ? item.mandatoryDocuments
        : [
            const DocumentItem(title: 'Current Valid Passport', note: 'With blank stamp pages', icon: Icons.badge_rounded),
            const DocumentItem(title: 'Academic Transcripts', note: 'Original degrees & certificates', icon: Icons.school_rounded),
            const DocumentItem(title: 'CAS Letter', note: 'From UK Institution', icon: Icons.description_rounded),
            const DocumentItem(title: 'Bank Statement', note: '28-day holding record', icon: Icons.account_balance_wallet_rounded),
            const DocumentItem(title: 'IELTS Certificate', note: 'UKVI accredited test', icon: Icons.translate_rounded),
            const DocumentItem(title: 'Biometric Photos', note: 'Standard UKVI specification', icon: Icons.photo_camera_rounded),
          ];

    return Column(
      key: _documentsKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mandatory Documents',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: primary,
            fontFamily: 'Poppins',
          ),
        ),
        SizedBox(height: 12.h),
        Column(
          children: [
            for (int i = 0; i < docs.length; i += 2) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildDocCard(docs[i], bg, primary, onSurface, secondary, isDark)),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: (i + 1 < docs.length)
                        ? _buildDocCard(docs[i + 1], bg, primary, onSurface, secondary, isDark)
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
              if (i + 2 < docs.length) SizedBox(height: 10.h),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildDocCard(DocumentItem doc, Color bg, Color primary, Color onSurface, Color secondary, bool isDark) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            doc.icon,
            color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF002444),
            size: 20.sp,
          ),
          SizedBox(height: 8.h),
          Text(
            doc.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5.sp,
              fontWeight: FontWeight.w700,
              color: onSurface,
              fontFamily: 'Poppins',
            ),
          ),
          SizedBox(height: 3.h),
          Text(
            doc.note,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.sp,
              color: secondary,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 8. FEE BREAKDOWN CARD
  // ===========================================================================
  List<FeeItem> _getRelevantFeeBreakdown(DetailItemModel item, String feeText) {
    if (item.feeBreakdown.isNotEmpty) {
      final hasEmbassyFee = item.feeBreakdown.any((f) => f.label.toLowerCase().contains('embassy'));
      if (!hasEmbassyFee) {
        return item.feeBreakdown;
      }
    }

    final cat = item.categoryTag.toLowerCase();
    final title = item.title.toLowerCase();

    // 1. Study Visa: University Application, Tuition Deposit, Student Visa Processing
    if (cat.contains('study') || title.contains('study') || cat.contains('student')) {
      return [
        FeeItem(
          label: 'SB Consultation & University Filing',
          amount: feeText,
          subNote: 'Application file preparation & CAS/I-20 guidance',
        ),
        const FeeItem(
          label: 'University Application & Admission Fee',
          amount: 'Direct to Uni',
          subNote: 'Paid directly to accredited university portal',
        ),
        const FeeItem(
          label: 'University Tuition Fee Deposit',
          amount: 'As per Offer',
          subNote: 'Directly applicable as per admission letter',
        ),
        const FeeItem(
          label: 'Student Visa & CAS / SEVIS Processing',
          amount: 'Govt Portal',
          subNote: 'Official student visa & immigration processing',
        ),
      ];
    }

    // 2. Work Visa: Work Permit, LMIA / Sponsorship, Government Levy
    if (cat.contains('work') || title.contains('work')) {
      return [
        FeeItem(
          label: 'SB Work Visa Case Dossier & Filing',
          amount: feeText,
          subNote: 'Legal case preparation & employer compliance review',
        ),
        const FeeItem(
          label: 'Work Permit & LMIA / Sponsorship Endorsement',
          amount: 'By Sponsor/Govt',
          subNote: 'Employer Certificate of Sponsorship (CoS) / permit levy',
        ),
        const FeeItem(
          label: 'Government Work Visa & Biometrics Fee',
          amount: 'Govt Portal',
          subNote: 'Official work visa processing & biometrics verification',
        ),
      ];
    }

    // 3. Business / Golden Visa: Investment Registration, Commercial Audit, Due Diligence
    if (cat.contains('golden') || cat.contains('business') || cat.contains('investor') || title.contains('golden')) {
      return [
        FeeItem(
          label: 'SB Executive Residency Advisory Fee',
          amount: feeText,
          subNote: 'Comprehensive investor portfolio & legal representation',
        ),
        const FeeItem(
          label: 'Government Golden Visa / Investor Registration',
          amount: 'Official Authority',
          subNote: 'Directly payable to government residency authority',
        ),
        const FeeItem(
          label: 'Commercial Audit & Due Diligence Clearance',
          amount: 'Certified Body',
          subNote: 'Background check & verified asset audit clearance',
        ),
      ];
    }

    // 4. Visit / Tourist / Other Visas: Government Visit Visa Fee, VFS Biometrics
    return [
      FeeItem(
        label: 'SB Visa Consultation & File Preparation',
        amount: feeText,
        subNote: 'Dossier preparation, SOP & appointment scheduling',
      ),
      const FeeItem(
        label: 'Government Visa Application Fee',
        amount: 'Govt Portal',
        subNote: 'Official visa application fee paid on consular portal',
      ),
      const FeeItem(
        label: 'Biometrics & VFS Center Appointment',
        amount: 'VFS / Gerrys',
        subNote: 'Biometric capture & physical document submission',
      ),
    ];
  }

  Widget _buildFeeBreakdownCard(
    DetailItemModel item,
    String feeText,
    Color primary,
    Color secondary,
    Color onSurface,
    Color bg,
    Color cardBg,
    Color cardBorder,
    bool isDark,
  ) {
    final breakdownList = _getRelevantFeeBreakdown(item, feeText);
    final cat = item.categoryTag.toLowerCase();
    final title = item.title.toLowerCase();

    final transparentNote = (cat.contains('study') || title.contains('study') || cat.contains('student'))
        ? 'Transparent Pricing: You only pay the SB consultancy fee ($feeText) in this app. University tuition fee deposit and student visa processing are paid directly to the university and government portal.'
        : (cat.contains('work') || title.contains('work'))
            ? 'Transparent Pricing: You only pay the SB legal filing fee ($feeText) in this app. Work permit and employer sponsorship levies are handled directly with the employer and immigration authority.'
            : (cat.contains('golden') || cat.contains('business') || cat.contains('investor') || title.contains('golden'))
                ? 'Transparent Pricing: You only pay the SB executive filing fee ($feeText) in this app. Government investment registration is paid directly to official residency authorities.'
                : 'Transparent Pricing: You only pay the consultancy fee ($feeText) in this app. Official visa & biometric appointment fees are paid directly to the government portal.';

    return Container(
      key: _feeKey,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B3A5C).withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fee Breakdown',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: primary,
              fontFamily: 'Poppins',
            ),
          ),
          SizedBox(height: 12.h),

          for (int i = 0; i < breakdownList.length; i++) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        breakdownList[i].label,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: i == 0 ? FontWeight.w600 : FontWeight.w500,
                          color: i == 0
                              ? (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155))
                              : secondary,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      if (breakdownList[i].subNote != null && breakdownList[i].subNote!.isNotEmpty) ...[
                        SizedBox(height: 2.h),
                        Text(
                          breakdownList[i].subNote!,
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: secondary,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  breakdownList[i].amount,
                  style: TextStyle(
                    fontSize: i == 0 ? 14.5.sp : 13.5.sp,
                    fontWeight: i == 0 ? FontWeight.w800 : FontWeight.w700,
                    color: i == 0
                        ? (isDark ? const Color(0xFF60A5FA) : const Color(0xFF002444))
                        : onSurface,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
            if (i < breakdownList.length - 1) SizedBox(height: 10.h),
          ],

          SizedBox(height: 12.h),
          Divider(color: cardBorder, height: 1),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Payable Now',
                      style: TextStyle(
                        fontSize: 14.5.sp,
                        fontWeight: FontWeight.w700,
                        color: primary,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    Text(
                      'SB Consultancy & Filing Fee',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF16A34A),
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                feeText,
                style: TextStyle(
                  fontSize: 17.5.sp,
                  fontWeight: FontWeight.w800,
                  color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF002444),
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFBFDBFE),
                width: 0.8,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.shield_outlined,
                    size: 14.sp, color: const Color(0xFF2563EB)),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    transparentNote,
                    style: TextStyle(
                      fontSize: 10.5.sp,
                      color: isDark
                          ? const Color(0xFF93C5FD)
                          : const Color(0xFF1E40AF),
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 9. OFFICIAL ADVISORY GUARANTEE
  // ===========================================================================
  Widget _buildTrustBanner(
    Color primary,
    Color secondary,
    Color onSurface,
    Color green,
    Color cardBg,
    Color cardBorder,
    bool isDark,
  ) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 38.w,
            height: 38.w,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2563EB) : const Color(0xFF002444),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.verified_user_rounded, color: Colors.white, size: 19.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Official Advisory Guarantee',
                  style: TextStyle(
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w700,
                    color: onSurface,
                    fontFamily: 'Poppins',
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'Certified visa consultants & end-to-end filing',
                  style: TextStyle(
                    fontSize: 11.5.sp,
                    color: secondary,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.5.h),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF064E3B).withValues(alpha: 0.35)
                  : const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  size: 13.sp,
                  color: isDark ? const Color(0xFF4ADE80) : green,
                ),
                SizedBox(width: 4.w),
                Text(
                  'Verified Partner',
                  style: TextStyle(
                    fontSize: 10.5.sp,
                    fontWeight: FontWeight.w700,
                    color: isDark ? const Color(0xFF4ADE80) : green,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 10. STICKY BOTTOM BAR
  // ===========================================================================
  Widget _buildStickyBottomBar(
    BuildContext context,
    DetailItemModel item,
    String feeText,
    bool isDark,
    bool isScholarshipOrJob,
  ) {
    final bgColor = isDark ? const Color(0xFF121212) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF27272A) : const Color(0xFFE8EEF5);
    final primaryBtnColor = isDark ? const Color(0xFF3B82F6) : const Color(0xFF002444);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          top: BorderSide(color: cardBorder, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: Row(
            children: [
              if (_isJob) ...[
                // Left: Salary Info for Sponsored Jobs
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SALARY / YR',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.5.sp,
                          fontWeight: FontWeight.w700,
                          color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF047857),
                          letterSpacing: 0.5,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        _getJobSalaryText(item),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w800,
                          color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF065F46),
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12.w),
              ] else if (!isScholarshipOrJob) ...[
                // Left: Fee Info (Only for standard visa applications)
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SERVICE FEE',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.5.sp,
                          fontWeight: FontWeight.w700,
                          color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF73777F),
                          letterSpacing: 0.5,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        feeText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF171C21),
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12.w),
              ],

              // Right / Full: Apply CTA Button
              Expanded(
                flex: (isScholarshipOrJob && !_isJob) ? 1 : 0,
                child: SizedBox(
                  height: 48.h,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBtnColor,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: isScholarshipOrJob ? 16.w : 24.w,
                      ),
                    ),
                    onPressed: () async {
                      if (isScholarshipOrJob) {
                        final rawUrl = item.externalUrl?.trim();
                        final targetUrl = (rawUrl != null && rawUrl.isNotEmpty)
                            ? rawUrl
                            : (_isJob
                                ? 'https://uk.indeed.com/jobs?q=${Uri.encodeComponent('${item.title} visa sponsorship')}'
                                : 'https://www.google.com/search?q=${Uri.encodeComponent('${item.title} ${item.countryName} official application')}');

                        final res = await UrlLauncherService.instance.launch(targetUrl);
                        res.fold(
                          (failure) {
                            if (context.mounted) {
                              showToast(
                                context,
                                message: 'Unable to open application link. Please check your browser.',
                                status: 'error',
                              );
                            }
                          },
                          (_) {
                            if (context.mounted) {
                              showToast(
                                context,
                                message: 'Opening application link...',
                                status: 'success',
                              );
                            }
                          },
                        );
                        return;
                      }

                      // Standard Visa Application Flow (Consultancy file prep)
                      final updatedItem = item.copyWith(
                        serviceFeeValue: feeText,
                        totalPayable: feeText,
                      );
                      context.push(AppRoutes.applicantDetails, extra: updatedItem);
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isScholarshipOrJob
                              ? 'Apply on Link'
                              : 'Apply Now',
                          style: TextStyle(
                            fontSize: 14.5.sp,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                            color: Colors.white,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Icon(
                          isScholarshipOrJob
                              ? Icons.open_in_new_rounded
                              : Icons.arrow_forward_rounded,
                          size: 16.sp,
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
      ),
    );
  }
  // ===========================================================================
  // APPLICATION REQUIREMENTS & CHECKPOINTS (DYNAMICALLY LOADED FROM ADMIN)
  // ===========================================================================
  Widget _buildApplicationRequirementsCard(
    DetailItemModel item,
    Color primary,
    Color secondary,
    Color onSurface,
    Color cardBg,
    Color cardBorder,
    Color green,
    bool isDark,
  ) {
    final reqs = item.applicationRequirements;
    if (reqs is! Map) return const SizedBox.shrink();

    final ageReq = reqs['age_requirement'];
    final eduReq = reqs['education_requirement'];
    final langReq = reqs['language_requirement'];
    final expReq = reqs['experience_requirement'];
    final finReq = reqs['financial_requirement'];
    final travelReq = reqs['travel_history_requirement'];
    final customQuestions = reqs['custom_questions'];

    final hasAge = ageReq is Map && ageReq['enabled'] == true;
    final hasEdu = eduReq is Map && eduReq['enabled'] == true;
    final hasLang = langReq is Map && langReq['enabled'] == true;
    final hasExp = expReq is Map && expReq['enabled'] == true;
    final hasFin = finReq is Map && finReq['enabled'] == true;

    final hasTravel = travelReq is Map &&
        (travelReq['prior_travel_required'] == true ||
            travelReq['rejection_declaration_required'] == true ||
            travelReq['police_certificate_required'] == true ||
            travelReq['medical_check_required'] == true);

    final hasQuestions = customQuestions is List && customQuestions.isNotEmpty;

    if (!hasAge && !hasEdu && !hasLang && !hasExp && !hasFin && !hasTravel && !hasQuestions) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.checklist_rounded, color: primary, size: 20.sp),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                'Application Requirements & Criteria',
                style: TextStyle(
                  fontSize: 15.5.sp,
                  fontWeight: FontWeight.w700,
                  color: primary,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: cardBorder),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1B3A5C).withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Age
              if (hasAge) ...[
                _buildRequirementTile(
                  icon: Icons.cake_rounded,
                  title: 'Age Eligibility',
                  value: '${ageReq['min_age']} - ${ageReq['max_age']} Years',
                  subtitle: ageReq['bracket']?.toString() ?? '',
                  primary: primary,
                  secondary: secondary,
                  onSurface: onSurface,
                  isDark: isDark,
                ),
                SizedBox(height: 10.h),
              ],

              // 2. Education
              if (hasEdu) ...[
                _buildRequirementTile(
                  icon: Icons.school_rounded,
                  title: 'Academic Qualification',
                  value: eduReq['min_qualification']?.toString() ?? "Bachelor's Degree",
                  subtitle: [
                    if (eduReq['min_cgpa_or_marks'] != null && eduReq['min_cgpa_or_marks'].toString().isNotEmpty)
                      'Min Marks: ${eduReq['min_cgpa_or_marks']}',
                    if (eduReq['field_of_study'] != null && eduReq['field_of_study'].toString().isNotEmpty)
                      'Field: ${eduReq['field_of_study']}',
                  ].join(' • '),
                  primary: primary,
                  secondary: secondary,
                  onSurface: onSurface,
                  isDark: isDark,
                ),
                SizedBox(height: 10.h),
              ],

              // 3. Language
              if (hasLang) ...[
                _buildRequirementTile(
                  icon: Icons.translate_rounded,
                  title: 'Language Proficiency',
                  value: '${langReq['test_type'] ?? 'IELTS'} (Score: ${langReq['min_score'] ?? '6.5'})',
                  badge: langReq['is_mandatory'] != false ? 'MANDATORY' : 'RECOMMENDED',
                  badgeColor: langReq['is_mandatory'] != false
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF10B981),
                  primary: primary,
                  secondary: secondary,
                  onSurface: onSurface,
                  isDark: isDark,
                ),
                SizedBox(height: 10.h),
              ],

              // 4. Experience
              if (hasExp) ...[
                _buildRequirementTile(
                  icon: Icons.work_outline_rounded,
                  title: 'Work Experience',
                  value: '${expReq['min_years']}+ Years Required',
                  subtitle: expReq['role_level']?.toString() ?? '',
                  primary: primary,
                  secondary: secondary,
                  onSurface: onSurface,
                  isDark: isDark,
                ),
                SizedBox(height: 10.h),
              ],

              // 5. Financial
              if (hasFin) ...[
                _buildRequirementTile(
                  icon: Icons.account_balance_rounded,
                  title: 'Financial Solvency & Balance',
                  value: finReq['min_bank_balance']?.toString() ?? '',
                  subtitle: [
                    if (finReq['holding_period'] != null && finReq['holding_period'].toString().isNotEmpty)
                      'Holding: ${finReq['holding_period']}',
                    if (finReq['proof_type'] != null && finReq['proof_type'].toString().isNotEmpty)
                      'Proof: ${finReq['proof_type']}',
                  ].join(' • '),
                  primary: primary,
                  secondary: secondary,
                  onSurface: onSurface,
                  isDark: isDark,
                ),
                SizedBox(height: 10.h),
              ],

              // 6. Security & Travel Checkpoints
              if (hasTravel) ...[
                const Divider(height: 20),
                Text(
                  'Security & Travel Clearance Checkpoints',
                  style: TextStyle(
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w700,
                    color: primary,
                    fontFamily: 'Poppins',
                  ),
                ),
                SizedBox(height: 8.h),
                if (travelReq['prior_travel_required'] == true)
                  _buildCheckpointRow('Prior International Travel History Required', green, isDark),
                if (travelReq['rejection_declaration_required'] == true)
                  _buildCheckpointRow('Mandatory Past Visa Rejection Declaration', green, isDark),
                if (travelReq['police_certificate_required'] == true)
                  _buildCheckpointRow('Police Character Certificate (Last 6 Months)', green, isDark),
                if (travelReq['medical_check_required'] == true)
                  _buildCheckpointRow('Certified Medical & Physical Fitness Clearance', green, isDark),
              ],

              // 7. Custom Dynamic Applicant Questions
              if (hasQuestions) ...[
                const Divider(height: 20),
                Text(
                  'Required Applicant Declarations & Questions',
                  style: TextStyle(
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w700,
                    color: primary,
                    fontFamily: 'Poppins',
                  ),
                ),
                SizedBox(height: 8.h),
                for (int i = 0; i < customQuestions.length; i++) ...[
                  if (customQuestions[i] is Map)
                    Container(
                      margin: EdgeInsets.only(bottom: 6.h),
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E24) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 10.r,
                            backgroundColor: primary.withValues(alpha: 0.1),
                            child: Text(
                              '${i + 1}',
                              style: TextStyle(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.bold,
                                color: primary,
                              ),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              customQuestions[i]['question']?.toString() ?? '',
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w500,
                                color: onSurface,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                          if (customQuestions[i]['is_required'] != false) ...[
                            SizedBox(width: 6.w),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                              child: Text(
                                'REQUIRED',
                                style: TextStyle(
                                  fontSize: 8.5.sp,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFB45309),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRequirementTile({
    required IconData icon,
    required String title,
    required String value,
    String? subtitle,
    String? badge,
    Color? badgeColor,
    required Color primary,
    required Color secondary,
    required Color onSurface,
    required bool isDark,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E24) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(7.w),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(icon, size: 18.sp, color: primary),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w500,
                          color: secondary,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                    if (badge != null) ...[
                      SizedBox(width: 6.w),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: (badgeColor ?? primary).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w700,
                            color: badgeColor ?? primary,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 3.h),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: onSurface,
                    fontFamily: 'Poppins',
                  ),
                ),
                if (subtitle != null && subtitle.trim().isNotEmpty) ...[
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: secondary,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckpointRow(String title, Color green, bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 3.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 2.h),
            child: Icon(Icons.check_circle_rounded, size: 16.sp, color: green),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12.5.sp,
                fontWeight: FontWeight.w500,
                color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }

}
