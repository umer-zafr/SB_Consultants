import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_sd_consultant/src/data/models/detail_item_model.dart';
import 'package:flutter_sd_consultant/src/data/repositories/detail_repository.dart';
import 'package:flutter_sd_consultant/src/routing/app_routes.dart';
import 'package:flutter_sd_consultant/src/services/live_visa_sync_service.dart';
import 'package:flutter_sd_consultant/src/services/supabase_database_service.dart';
import 'package:flutter_sd_consultant/src/shared/helpers/show_toast.dart';
import 'package:flutter_sd_consultant/src/shared/widgets/app_dashboard_bottom_nav.dart';
import 'package:flutter_sd_consultant/src/ui/home/providers/home_provider.dart';
import 'package:flutter_sd_consultant/src/ui/saved/models/saved_visa_model.dart';
import 'package:flutter_sd_consultant/src/ui/saved/providers/saved_visas_provider.dart';
import 'package:flutter_sd_consultant/src/ui/visa/visa_category_screen.dart';
import 'package:flutter_sd_consultant/src/ui/visa/widgets/category_banner_carousel.dart';

/// Comprehensive Work Visa screen supporting two dedicated pathways:
/// 1. Direct Visa Filing if applicant already holds a work visa / permit / sponsor offer.
/// 2. Program browsing & employer sponsorship pathway if applicant needs a work visa.
class WorkVisaScreen extends ConsumerStatefulWidget {
  const WorkVisaScreen({super.key});

  @override
  ConsumerState<WorkVisaScreen> createState() => _WorkVisaScreenState();
}

class _WorkVisaScreenState extends ConsumerState<WorkVisaScreen> {
  // Toggle: whether applicant has a work visa or not
  bool _hasWorkVisa = false;

  // Controllers for "Yes, Have Work Visa" direct filing route
  late final TextEditingController _directCompanyNameController;
  late final TextEditingController _directCountryController;
  late final TextEditingController _directCityController;
  late final TextEditingController _directNameController;
  late final TextEditingController _directAgeController;
  late final TextEditingController _directContactController;

  // Filter & list state for "No, Need Work Visa" pathway
  int _selectedFilterIndex = 0;

  final List<String> _filterChips = [
    'All',
    'United Kingdom',
    'Canada',
    'Australia',
    'Germany',
    'United Arab Emirates',
    'United States',
  ];

  List<VisaItemData>? _liveVisas;
  StreamSubscription<List<VisaItemData>>? _visaSub;

  List<VisaItemData> get _filteredVisas {
    final baseVisas = _liveVisas ?? const [];
    if (_selectedFilterIndex == 0) return baseVisas;
    final selectedCountry = _filterChips[_selectedFilterIndex];
    return baseVisas
        .where((visa) =>
            visa.countryName.toLowerCase() == selectedCountry.toLowerCase())
        .toList();
  }

  @override
  void initState() {
    super.initState();
    final currentUser = SupabaseDatabaseService.instance.client.auth.currentUser;
    final fullName = currentUser?.userMetadata?['full_name'] as String? ?? '';
    final phone = currentUser?.phone ?? '';

    _directCompanyNameController = TextEditingController();
    _directCountryController = TextEditingController();
    _directCityController = TextEditingController();
    _directNameController = TextEditingController(text: fullName);
    _directAgeController = TextEditingController();
    _directContactController = TextEditingController(text: phone);

    LiveVisaSyncService.instance.fetchVisasByCategory('work').then((liveList) {
      if (mounted) {
        setState(() {
          _liveVisas = liveList;
        });
      }
    });

    _visaSub = LiveVisaSyncService.instance
        .streamVisasByCategory('work')
        .listen((liveList) {
      if (mounted) {
        setState(() {
          _liveVisas = liveList;
        });
      }
    });
  }

  @override
  void dispose() {
    _visaSub?.cancel();
    _directCompanyNameController.dispose();
    _directCountryController.dispose();
    _directCityController.dispose();
    _directNameController.dispose();
    _directAgeController.dispose();
    _directContactController.dispose();
    super.dispose();
  }

  void _proceedToDirectPayment() {
    final company = _directCompanyNameController.text.trim();
    final country = _directCountryController.text.trim();
    final name = _directNameController.text.trim();

    if (company.isEmpty || country.isEmpty || name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all required fields.'),
          backgroundColor: Color(0xFFC62828),
        ),
      );
      return;
    }

    final directItem = DetailItemModel(
      id: 'direct-work-visa-filing',
      type: 'visa',
      title: 'Work Visa Filing (Direct Permit / Offer)',
      subtitle: '$company • $country',
      categoryTag: 'Work Visa',
      countryName: country,
      countryFlag: '💼',
      statusBadge: 'Work Visa Holder',
      heroImageUrl:
          'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?w=1000',
      processingTime: '2-3 weeks',
      validity: 'Contract Duration',
      successRate: '98%',
      applicantsCount: '3,850',
      aboutTitle: 'Direct Work Visa Case Filing',
      aboutDescription:
          'Official visa filing assistance for professionals holding valid job offer letters, employment permits, or Certificate of Sponsorship (CoS).',
      timelineSteps: const [],
      eligibilityCriteria: const [],
      mandatoryDocuments: const [],
      feeBreakdown: const [
        FeeItem(
          label: 'Work Visa Case Preparation & Filing',
          amount: 'PKR 25,000',
        ),
        FeeItem(
          label: 'CoS / LMIA / Offer Verification',
          amount: 'PKR 10,000',
        ),
        FeeItem(
          label: 'Employment Contract & Legal Review',
          amount: 'PKR 5,000',
        ),
      ],
      totalPayable: 'PKR 40,000',
      serviceFeeLabel: 'Visa Processing Fee',
      serviceFeeValue: 'PKR 40,000',
    );

    context.push(AppRoutes.paymentCheckout, extra: directItem);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final asyncBanners = ref.watch(liveTargetedBannersStreamProvider('work'));
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
        preferredSize: Size.fromHeight(56.h),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
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

                // Screen Title
                Expanded(
                  child: Text(
                    'Work Visa',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 19.sp,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),

                // Search Action
                InkWell(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Search Work Visa Programs'),
                      ),
                    );
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
                      Icons.search_rounded,
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
              defaultHeadline: 'Work & Settle in Top\nGlobal Destinations',
              defaultSubtitle: 'Skilled worker permits, employer sponsorships & fast-track PR pathways',
              watermarkIcon: Icons.work_rounded,
              screenTitle: 'Work Visa',
              defaultActionText: 'Explore Work Routes',
              onTapDefault: () {
                final detail = DetailRepository.getUkSkilledWorkerVisaDetail();
                context.push(AppRoutes.visaDetail, extra: detail);
              },
            ),
            SizedBox(height: 16.h),

            // 2. Work Visa Question Card (Same layout as Study Visa, questions tailored)
            _buildWorkVisaQuestionCard(isDark),
            SizedBox(height: 16.h),

            // 3. Conditional Content based on Work Visa Status:
            if (_hasWorkVisa) ...[
              // Branch A: Direct Work Visa Filing Form -> Proceed to Payment
              _buildDirectFilingSection(isDark),
              SizedBox(height: 24.h),
            ] else ...[
              // Branch B: Filter and list of all work visas -> Detail screen -> Applicant details
              _buildWorkVisaListingSection(isDark),
              SizedBox(height: 24.h),
            ],
          ],
        ),
      ),
    );
  }



  // ===========================================================================
  // 2. WORK VISA QUESTION CARD (PROMINENT & HIGH-CONTRAST)
  // "Do you have any work visa or not?"
  // ===========================================================================
  Widget _buildWorkVisaQuestionCard(bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF121212) : Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isDark
                ? const Color(0xFF27272A)
                : const Color(0xFF002444).withValues(alpha: 0.15),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.25)
                  : const Color(0xFF1B3A5C).withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Prominent Header with Icon Badge
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF3B82F6)
                        : const Color(0xFF002444),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: const Icon(
                    Icons.work_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 7.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E3A8A).withValues(alpha: 0.4)
                              : const Color(0xFFEFF4FA),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          'WORK VISA ASSESSMENT',
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? const Color(0xFF93C5FD)
                                : const Color(0xFF1B3A5C),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      SizedBox(height: 3.h),
                      Text(
                        'Do you have any work visa or not?',
                        style: TextStyle(
                          fontSize: 14.5.sp,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? const Color(0xFFF8FAFC)
                              : const Color(0xFF171C21),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              'Select "Yes" if you already hold an official work permit, visa, or Certificate of Sponsorship (CoS). Select "No" to browse global work permit tracks.',
              style: TextStyle(
                fontSize: 11.5.sp,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF5A626A),
                height: 1.35,
              ),
            ),
            SizedBox(height: 14.h),

            // Prominent Yes / No Selection Buttons
            Row(
              children: [
                Expanded(
                  child: _buildWorkOptionButton(
                    label: 'Yes, Have Work Visa',
                    subtitle: 'Have permit / visa in hand',
                    icon: Icons.check_circle_rounded,
                    isSelected: _hasWorkVisa,
                    onTap: () => setState(() => _hasWorkVisa = true),
                    isDark: isDark,
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: _buildWorkOptionButton(
                    label: 'No, Need Work Visa',
                    subtitle: 'Browse all work visas',
                    icon: Icons.explore_rounded,
                    isSelected: !_hasWorkVisa,
                    onTap: () => setState(() => _hasWorkVisa = false),
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkOptionButton({
    required String label,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF3B82F6) : const Color(0xFF002444))
              : (isDark ? const Color(0xFF18181B) : const Color(0xFFF8FAFD)),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected
                ? (isDark ? const Color(0xFF3B82F6) : const Color(0xFF002444))
                : (isDark ? const Color(0xFF27272A) : const Color(0xFFDEE5EF)),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: isDark
                        ? const Color(0xFF3B82F6).withValues(alpha: 0.3)
                        : const Color(0xFF002444).withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 15.sp,
                  color: isSelected
                      ? Colors.white
                      : (isDark
                          ? const Color(0xFF93C5FD)
                          : const Color(0xFF1B3A5C)),
                ),
                SizedBox(width: 5.w),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? Colors.white
                            : (isDark
                                ? const Color(0xFFF8FAFC)
                                : const Color(0xFF171C21)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 3.h),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                subtitle,
                style: TextStyle(
                  fontSize: 9.5.sp,
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? const Color(0xFFC3D5E8)
                      : (isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF73777F)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 3A. DIRECT WORK VISA FILING SECTION (WHEN APPLICANT HAS WORK VISA)
  // ===========================================================================
  Widget _buildDirectFilingSection(bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF121212) : Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isDark ? const Color(0xFF27272A) : const Color(0xFFE8EEF5),
          ),
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
            // Card Title Header
            Row(
              children: [
                Icon(
                  Icons.assignment_turned_in_rounded,
                  color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF002444),
                  size: 20.sp,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'Direct Work Visa Filing Information',
                    softWrap: true,
                    style: TextStyle(
                      fontSize: 14.5.sp,
                      fontWeight: FontWeight.w700,
                      color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF171C21),
                    ),
                  ),
                ),
                SizedBox(width: 6.w),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8.w,
                    vertical: 2.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF064E3B).withValues(alpha: 0.4)
                        : const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    'Visa Holder',
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w700,
                      color: isDark ? const Color(0xFF34D399) : const Color(0xFF2E7D32),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 6.h),
            Text(
              'Please provide your employer/company and applicant details where you hold your work visa to proceed straight to fee payment.',
              style: TextStyle(
                fontSize: 11.5.sp,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF5A626A),
                height: 1.35,
              ),
            ),
            SizedBox(height: 16.h),

            // 1. Company / Employer Name
            _buildFieldLabel('Company / Employer Name (Work Visa Sponsor)', isDark),
            SizedBox(height: 6.h),
            _buildInputBox(
              controller: _directCompanyNameController,
              hint: 'e.g. Amazon UK Operations / Siemens Germany',
              icon: Icons.business_rounded,
              isDark: isDark,
            ),
            SizedBox(height: 14.h),

            // 2. Country & City Row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel('Country', isDark),
                      SizedBox(height: 6.h),
                      _buildInputBox(
                        controller: _directCountryController,
                        hint: 'e.g. United Kingdom',
                        icon: Icons.public_rounded,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel('City', isDark),
                      SizedBox(height: 6.h),
                      _buildInputBox(
                        controller: _directCityController,
                        hint: 'e.g. London',
                        icon: Icons.location_city_rounded,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 14.h),

            // 3. Name & Age Row
            Row(
              children: [
                Expanded(
                  flex: 6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel('Applicant Full Name', isDark),
                      SizedBox(height: 6.h),
                      _buildInputBox(
                        controller: _directNameController,
                        hint: 'As per passport',
                        icon: Icons.person_outline_rounded,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel('Applicant Age', isDark),
                      SizedBox(height: 6.h),
                      _buildInputBox(
                        controller: _directAgeController,
                        hint: 'e.g. 28',
                        icon: Icons.cake_rounded,
                        keyboardType: TextInputType.number,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 14.h),

            // 4. Contact Number (Full width for zero overflow)
            _buildFieldLabel('Contact Number', isDark),
            SizedBox(height: 6.h),
            Container(
              height: 48.h,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF18181B) : const Color(0xFFF9FBFE),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: isDark ? const Color(0xFF27272A) : const Color(0xFFDEE5EF),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w),
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(
                          color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text('🇵🇰', style: TextStyle(fontSize: 14.sp)),
                        SizedBox(width: 4.w),
                        Text(
                          '+92',
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF171C21),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _directContactController,
                      keyboardType: TextInputType.phone,
                      style: TextStyle(
                        fontSize: 13.5.sp,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF171C21),
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 10.w),
                        hintText: '300 1234567',
                        hintStyle: TextStyle(
                          fontSize: 12.sp,
                          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                        ),
                        suffixIcon: Icon(
                          Icons.phone_android_rounded,
                          size: 18,
                          color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF5B7FA5),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 14.h),

            // Direct Route Verification Pill
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF064E3B).withValues(alpha: 0.3)
                    : const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF059669).withValues(alpha: 0.4)
                      : const Color(0xFFBBF7D0),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.verified_user_rounded,
                    color: isDark ? const Color(0xFF34D399) : const Color(0xFF16A34A),
                    size: 16,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'Direct Work Visa Route: Priority processing with dedicated employment visa lawyer.',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF15803D),
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 18.h),

            // Proceed to Payment Button (Right Side, Prominent, No Truncation)
            Align(
              alignment: Alignment.centerRight,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: _proceedToDirectPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? const Color(0xFF2563EB) : const Color(0xFF002444),
                    foregroundColor: Colors.white,
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.lock_outline_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'Proceed to Payment (PKR 40,000)',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 3B. WORK VISA LISTING SECTION (WHEN APPLICANT DOES NOT HAVE WORK VISA)
  // ===========================================================================
  Widget _buildWorkVisaListingSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Horizontal Filter Chips Row
        SizedBox(
          height: 40.h,
          child: ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            scrollDirection: Axis.horizontal,
            itemCount: _filterChips.length,
            separatorBuilder: (_, __) => SizedBox(width: 8.w),
            itemBuilder: (context, index) {
              final label = _filterChips[index];
              final isSelected = _selectedFilterIndex == index;

              return InkWell(
                onTap: () => setState(() => _selectedFilterIndex = index),
                borderRadius: BorderRadius.circular(20.r),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark ? const Color(0xFF3B82F6) : const Color(0xFF002444))
                        : (isDark ? const Color(0xFF18181B) : const Color(0xFFEDF2F8)),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: isSelected
                          ? (isDark ? const Color(0xFF3B82F6) : const Color(0xFF002444))
                          : (isDark ? const Color(0xFF27272A) : const Color(0xFFD0D7E2)),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : (isDark
                                ? const Color(0xFFF1F5F9)
                                : const Color(0xFF0F172A)),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: 14.h),

        // Count Bar
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Row(
            children: [
              Container(
                width: 6.w,
                height: 6.w,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1B3A5C),
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  '${_filteredVisas.length} work permit programs available',
                  style: TextStyle(
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF5A626A),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),

        // List of Work Visas
        if (_filteredVisas.isEmpty)
          Padding(
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
                    Icons.work_outline_rounded,
                    size: 44.sp,
                    color: const Color(0xFF73777F),
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    'No services available in this category yet.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF171C21),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'There are currently no services available in this category.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11.5.sp,
                      color: const Color(0xFF5A626A),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          itemCount: _filteredVisas.length,
          separatorBuilder: (_, __) => SizedBox(height: 12.h),
          itemBuilder: (context, index) {
            final item = _filteredVisas[index];
            ref.watch(savedVisasProvider);
            final isBookmarked = ref
                .read(savedVisasProvider.notifier)
                .isSaved(item.title);

            return _buildWorkVisaCard(
              item: item,
              isBookmarked: isBookmarked,
              isDark: isDark,
              onBookmarkTap: () {
                final savedItem = SavedVisaItem(
                  id: item.title,
                  title: item.title,
                  subtitle: item.subtitle,
                  countryName: item.countryName,
                  countryCode: item.countryCode,
                  categoryTag: 'Work Visa',
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
                  categoryTag: 'Work Visa',
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
    );
  }

  // ===========================================================================
  // WORK VISA CARD ITEM (SAFE AGAINST OVERFLOWS)
  // ===========================================================================
  Widget _buildWorkVisaCard({
    required VisaItemData item,
    required bool isBookmarked,
    required bool isDark,
    required VoidCallback onBookmarkTap,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF121212) : Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isDark ? const Color(0xFF27272A) : const Color(0xFFE8EEF5),
          ),
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
        child: Padding(
          padding: EdgeInsets.all(14.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Avatar, Title, Bookmark
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44.w,
                    height: 44.w,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF18181B)
                          : (item.avatarBgColor ?? const Color(0xFFEBF1FA)),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      item.countryCode,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? const Color(0xFF60A5FA)
                            : (item.avatarTextColor ?? const Color(0xFF1B3A5C)),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (item.badgeText != null) ...[
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 7.w,
                              vertical: 2.h,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1E3A8A).withValues(alpha: 0.5)
                                  : (item.badgeBgColor ?? const Color(0xFFE3F2FD)),
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Text(
                              item.badgeText!,
                              style: TextStyle(
                                fontSize: 9.5.sp,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? const Color(0xFF93C5FD)
                                    : (item.badgeTextColor ?? const Color(0xFF1565C0)),
                              ),
                            ),
                          ),
                          SizedBox(height: 3.h),
                        ],
                        Text(
                          item.title,
                          maxLines: 2,
                          softWrap: true,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                            color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF171C21),
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          item.subtitle,
                          maxLines: 2,
                          softWrap: true,
                          style: TextStyle(
                            fontSize: 11.5.sp,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF5A626A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onBookmarkTap,
                    icon: Icon(
                      isBookmarked
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      color: isBookmarked
                          ? (isDark ? const Color(0xFF60A5FA) : const Color(0xFF002444))
                          : (isDark ? const Color(0xFF64748B) : const Color(0xFF8A94A6)),
                      size: 22,
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

              // Metrics Row (Protected with Expanded and Flexibles)
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: _buildMetricPill(
                      icon: Icons.timer_outlined,
                      label: item.duration,
                      isDark: isDark,
                    ),
                  ),
                  SizedBox(width: 6.w),
                  Expanded(
                    flex: 4,
                    child: _buildMetricPill(
                      icon: Icons.calendar_today_outlined,
                      label: item.validity,
                      isDark: isDark,
                    ),
                  ),
                  SizedBox(width: 6.w),
                  Expanded(
                    flex: 3,
                    child: _buildMetricPill(
                      icon: Icons.check_circle_outline_rounded,
                      label: item.approvalRate,
                      textColor: isDark ? const Color(0xFF34D399) : const Color(0xFF16A34A),
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),

              // Bottom Action Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        item.fee,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w800,
                          color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF002444),
                        ),
                      ),
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
                          ? const Color(0xFF2563EB)
                          : const Color(0xFF002444),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View Details',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 5.w),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 13,
                          color: Colors.white,
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
    );
  }

  Widget _buildMetricPill({
    required IconData icon,
    required String label,
    required bool isDark,
    Color? textColor,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 12.sp,
          color: isDark ? const Color(0xFF64748B) : const Color(0xFF73777F),
        ),
        SizedBox(width: 3.w),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10.5.sp,
                fontWeight: FontWeight.w600,
                color: textColor ?? (isDark ? const Color(0xFF94A3B8) : const Color(0xFF5A626A)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFieldLabel(String label, bool isDark) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13.sp,
        fontWeight: FontWeight.w700,
        color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF171C21),
      ),
    );
  }

  Widget _buildInputBox({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool isDark,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      height: 48.h,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18181B) : const Color(0xFFF9FBFE),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isDark ? const Color(0xFF27272A) : const Color(0xFFDEE5EF),
        ),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(
          fontSize: 13.sp,
          fontWeight: FontWeight.w600,
          color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF171C21),
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 12.w),
          hintText: hint,
          hintStyle: TextStyle(
            fontSize: 12.sp,
            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
          ),
          suffixIcon: Icon(
            icon,
            size: 18.sp,
            color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF5B7FA5),
          ),
        ),
      ),
    );
  }
}
