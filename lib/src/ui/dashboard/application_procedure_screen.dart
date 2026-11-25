import 'package:flutter/material.dart';
import 'package:flutter_sd_consultant/src/imports/packages_imports.dart';
import 'package:flutter_sd_consultant/src/routing/app_routes.dart';
import 'package:flutter_sd_consultant/src/services/supabase_database_service.dart';
import 'package:flutter_sd_consultant/src/shared/helpers/show_toast.dart';
import 'package:flutter_sd_consultant/src/shared/helpers/whatsapp_helper.dart';
import 'package:flutter_sd_consultant/src/ui/dashboard/my_applications_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Screen representing the full Visa & Opportunity Application Procedure with Stepper.
///
/// Matches specifications of media_1790708096474.png:
/// 1. Top custom AppBar with back button, brand emblem, title, share, download & profile actions.
/// 2. Deep Navy canopy with status pill (e.g. Visa Decision Received), reference badge,
///    category tag (e.g. TIER 4 CATEGORY), bold title, university subtitle, and lead consultant sub-card.
/// 3. Case progress header with step badge (Step 5 of 5).
/// 4. Connected vertical procedure stepper:
///    - Step 1: Profile Review
///    - Step 2: Consultant Call (with interactive Reschedule Call button as requested)
///    - Step 3: Ready Case
///    - Step 4: Embassy Submission (Visa Issued)
///    - Step 5: Feedback & Case Rating card with 5 interactive stars, stand-out pills, feedback input & submit.
/// 5. NOTE: Case Documents section has been EXCLUDED as explicitly requested by user.
/// 6. Sticky bottom action bar with phone call button and "Chat with Consultant" CTA.
class ApplicationProcedureScreen extends StatefulWidget {
  const ApplicationProcedureScreen({
    super.key,
    this.application,
  });

  final ApplicationRecordItem? application;

  @override
  State<ApplicationProcedureScreen> createState() =>
      _ApplicationProcedureScreenState();
}

class _ApplicationProcedureScreenState
    extends State<ApplicationProcedureScreen> {
  // Feedback rating state
  int _selectedStars = 5;
  String _selectedTag = 'Helpful Consultant';
  final TextEditingController _feedbackController = TextEditingController();
  bool _isSubmittingFeedback = false;

  int _currentStep = 1;
  RealtimeChannel? _subscription;
  Map<String, dynamic>? _existingFeedback;


  final List<String> _standoutTags = const [
    'Fast Processing',
    'Helpful Consultant',
    'Accurate Guidance',
    'Smooth Filing',
  ];

  Future<void> _loadExistingFeedback(String appId) async {
    final res = await SupabaseDatabaseService.instance.getApplicationFeedback(appId);
    if (!mounted) return;
    res.fold((_) {}, (fb) {
      if (fb != null && mounted) {
        setState(() {
          _existingFeedback = fb;
        });
      }
    });
  }

  Future<void> _handleSubmitFeedback(BuildContext context) async {
    if (_isSubmittingFeedback) return;
    final appId = widget.application?.id;
    if (appId == null || appId.isEmpty) {
      showToast(context, message: 'Application reference not found', status: 'error');
      return;
    }

    setState(() => _isSubmittingFeedback = true);

    final comment = _feedbackController.text.trim();
    final res = await SupabaseDatabaseService.instance.submitApplicationFeedback(
      applicationId: appId,
      rating: _selectedStars,
      standoutTag: _selectedTag,
      comments: comment.isNotEmpty ? comment : 'Excellent guidance and fast visa clearance.',
    );

    if (!mounted) return;
    setState(() => _isSubmittingFeedback = false);

    res.fold(
      (failure) {
        showToast(context, message: failure.message, status: 'error');
      },
      (data) {
        setState(() {
          _currentStep = 5;
          _existingFeedback = {
            'rating': _selectedStars,
            'standout_tag': _selectedTag,
            'comments': comment.isNotEmpty ? comment : 'Excellent guidance and fast visa clearance.',
          };
        });
        showToast(
          context,
          message: 'Thank you! Your feedback has been submitted successfully.',
          status: 'success',
        );
        // Move to home screen as requested
        context.go(AppRoutes.home);
      },
    );
  }

  @override
  void initState() {
    super.initState();
    final p = widget.application?.progressPercent;
    if (p != null && p > 0) {
      _currentStep = (p / 20).ceil().clamp(1, 5);
    }
    _initLiveSync();
    final appId = widget.application?.id;
    if (appId != null && appId.isNotEmpty) {
      _loadExistingFeedback(appId);
    }
  }

  void _initLiveSync() {
    final appId = widget.application?.id;
    if (appId == null || appId.isEmpty) return;

    try {
      SupabaseDatabaseService.instance.client
          .from('applications')
          .select('current_step, progress_percent, status')
          .eq('id', appId)
          .maybeSingle()
          .then((row) {
        if (row != null && mounted) {
          final s = row['current_step'] as int?;
          final status = (row['status'] as String? ?? '').toLowerCase();
          final progress = (row['progress_percent'] as num?)?.toInt() ?? 0;
          if (s != null) {
            setState(() {
              if (status == 'completed' || progress >= 100 || s >= 5) {
                _currentStep = 5;
              } else {
                _currentStep = s.clamp(1, 5);
              }
            });
            if (_currentStep >= 5) {
              _loadExistingFeedback(appId);
            }
          }
        }
      });

      _subscription = SupabaseDatabaseService.instance.client
          .channel('app_live_stepper_$appId')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'applications',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'id',
              value: appId,
            ),
            callback: (payload) {
              final newStep = payload.newRecord['current_step'] as int?;
              if (newStep != null && mounted) {
                setState(() => _currentStep = newStep.clamp(1, 5));
                showToast(
                  context,
                  message: 'Application progressed to Step $newStep of 5',
                  status: 'info',
                );
              }
            },
          )
          .subscribe();
    } catch (_) {}
  }

  @override
  void dispose() {
    _subscription?.unsubscribe();
    _feedbackController.dispose();
    super.dispose();
  }

  String get _title => widget.application?.title ?? 'Visa Application';
  String get _ref => widget.application?.reference ?? '';
  String get _category => widget.application?.categoryType ?? 'CONSULTANCY SERVICE';
  String get _subtitle =>
      widget.application?.subtitle ?? widget.application?.stepText ?? 'Processing Application';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? const Color(0xFF000000) : const Color(0xFFF7F9FF);
    final surfaceBg = isDark ? const Color(0xFF121212) : Colors.white;
    final iconOnSurface = isDark ? Colors.white : const Color(0xFF171C21);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: _buildTopAppBar(context, isDark, surfaceBg: surfaceBg, iconColor: iconOnSurface),
      body: Column(
        children: [
          // Scrollable Procedure Content
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Deep Navy Hero Header Card
                  _buildHeroHeaderCard(),
                  SizedBox(height: 20.h),

                  // 2. Case Progress Header Row
                  _buildCaseProgressHeader(isDark),
                  SizedBox(height: 16.h),

                  // 3. Connected Vertical Stepper Procedure
                  _buildVerticalProcedureStepper(context, isDark),
                  SizedBox(height: 24.h),
                ],
              ),
            ),
          ),

          // Sticky Bottom Action Bar (Phone Call + Chat with Consultant)
          _buildBottomStickyBar(context),
        ],
      ),
    );
  }

  // ===========================================================================
  // 1. TOP APP BAR (Standardized clean header)
  // ===========================================================================
  PreferredSizeWidget _buildTopAppBar(
    BuildContext context,
    bool isDark, {
    required Color surfaceBg,
    required Color iconColor,
  }) {
    final titleColor = isDark ? Colors.white : const Color(0xFF171C21);
    return AppBar(
      backgroundColor: surfaceBg,
      elevation: 0,
      scrolledUnderElevation: 1,
      surfaceTintColor: Colors.transparent,
      leadingWidth: 48.w,
      leading: Padding(
        padding: EdgeInsets.only(left: 8.w),
        child: InkWell(
          onTap: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/dashboard');
            }
          },
          borderRadius: BorderRadius.circular(20.r),
          child: Center(
            child: Icon(
              Icons.arrow_back_rounded,
              color: iconColor,
              size: 22,
            ),
          ),
        ),
      ),
      centerTitle: true,
      title: Text(
        'Application Details',
        style: TextStyle(
          fontSize: 17.sp,
          fontWeight: FontWeight.w700,
          color: titleColor,
          letterSpacing: -0.2,
        ),
      ),
      actions: const [],
    );
  }

  // ===========================================================================
  // 2. HERO HEADER CARD (Matches media_1790708096474.png)
  // ===========================================================================
  Widget _buildHeroHeaderCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFF002444),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF002444).withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Status Pill & Reference Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0E3D35),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: const Color(0xFF22C55E).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7.w,
                        height: 7.w,
                        decoration: const BoxDecoration(
                          color: Color(0xFF22C55E),
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Flexible(
                        child: Text(
                          _currentStep >= 5
                              ? '100% Process Complete'
                              : 'Visa Decision Received',
                          softWrap: true,
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF4ADE80),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Flexible(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    _ref,
                    softWrap: true,
                    style: TextStyle(
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFABC9F2),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),

          // Category Row: Cap Icon + Category Tag
          Row(
            children: [
              Icon(
                widget.application?.categoryIcon ?? Icons.school_outlined,
                size: 15.sp,
                color: const Color(0xFFA8C4D9),
              ),
              SizedBox(width: 6.w),
              Flexible(
                child: Text(
                  _category.toUpperCase(),
                  softWrap: true,
                  style: TextStyle(
                    fontSize: 11.5.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFA8C4D9),
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),

          // Title
          Text(
            _title,
            maxLines: 2,
            softWrap: true,
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          SizedBox(height: 4.h),

          // Subtitle
          Text(
            _subtitle,
            softWrap: true,
            style: TextStyle(
              fontSize: 12.5.sp,
              color: const Color(0xFFC3D5E8),
              fontWeight: FontWeight.w400,
            ),
          ),
          SizedBox(height: 16.h),

          // Lead Consultant Sub-Card
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
            child: Row(
              children: [
                // Consultant Avatar
                Container(
                  width: 36.w,
                  height: 36.w,
                  decoration: const BoxDecoration(
                    color: Color(0xFF005EB8),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      'UT',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),

                // Name & Role
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LEAD CONSULTANT',
                        style: TextStyle(
                          fontSize: 9.5.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF8FAEC9),
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'Assigned Consultant',
                        style: TextStyle(
                          fontSize: 13.5.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                // Finalized Badge
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 14.sp,
                      color: const Color(0xFF4ADE80),
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      'Finalized',
                      style: TextStyle(
                        fontSize: 11.5.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF4ADE80),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 3. CASE PROGRESS HEADER
  // ===========================================================================
  Widget _buildCaseProgressHeader(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Case Progress',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF171C21),
                  letterSpacing: -0.2,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                'Managed by your accredited consultant',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF5A626A),
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 8.w),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF18181B) : const Color(0xFFEDF4FC),
            borderRadius: BorderRadius.circular(16.r),
            border: isDark ? Border.all(color: const Color(0xFF27272A)) : null,
          ),
          child: Text(
            'Step $_currentStep of 5',
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 4. VERTICAL PROCEDURE STEPPER (Synchronized with Supabase & Admin Dashboard)
  // ===========================================================================
  Widget _buildVerticalProcedureStepper(BuildContext context, bool isDark) {
    final subtextColor = isDark ? const Color(0xFFA1A1AA) : const Color(0xFF5A626A);
    final cardBorder = isDark ? const Color(0xFF27272A) : const Color(0xFFCBD5E1);

    return Column(
      children: [
        // Step 1: Profile Review
        _buildStepperItem(
          isDark: isDark,
          nodeIcon: _currentStep > 1
              ? Icons.check_rounded
              : (_currentStep == 1 ? Icons.hourglass_top_rounded : Icons.radio_button_unchecked),
          isCompleted: _currentStep > 1,
          showConnectingLine: true,
          lineColor: _currentStep > 1 ? const Color(0xFF10B981) : cardBorder,
          title: 'Profile Review',
          date: _currentStep > 1 ? 'Completed' : (_currentStep == 1 ? 'In Progress' : 'Pending'),
          dateColor: _currentStep > 1 ? const Color(0xFF16A34A) : (_currentStep == 1 ? (isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB)) : null),
          subtitleWidget: Text(
            _currentStep > 1
                ? 'Academic transcripts & eligibility verified.'
                : 'Legal compliance officer reviewing uploaded credentials.',
            style: TextStyle(
              fontSize: 12.sp,
              color: subtextColor,
            ),
          ),
        ),

        // Step 2: Consultancy Call (No date)
        _buildStepperItem(
          isDark: isDark,
          nodeIcon: _currentStep > 2
              ? Icons.check_rounded
              : (_currentStep == 2 ? Icons.phone_in_talk_rounded : Icons.radio_button_unchecked),
          isCompleted: _currentStep > 2,
          showConnectingLine: true,
          lineColor: _currentStep > 2 ? const Color(0xFF10B981) : cardBorder,
          title: 'Consultancy Call',
          date: '',
          dateColor: null,
          subtitleWidget: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Strategy session & financial compliance mapped.',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: subtextColor,
                ),
              ),
            ],
          ),
        ),

        // Step 3: Ready Case
        _buildStepperItem(
          isDark: isDark,
          nodeIcon: _currentStep > 3
              ? Icons.check_rounded
              : (_currentStep == 3 ? Icons.folder_zip_rounded : Icons.radio_button_unchecked),
          isCompleted: _currentStep > 3,
          showConnectingLine: true,
          lineColor: _currentStep > 3 ? const Color(0xFF10B981) : cardBorder,
          title: 'Ready Case',
          date: _currentStep > 3 ? 'Completed' : (_currentStep == 3 ? 'In Progress' : 'Pending'),
          dateColor: _currentStep > 3 ? const Color(0xFF16A34A) : (_currentStep == 3 ? (isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB)) : null),
          subtitleWidget: Text(
            _currentStep > 3
                ? 'CAS document linked and legal dossier compiled.'
                : 'Compiling documentation package for embassy readiness.',
            style: TextStyle(
              fontSize: 12.sp,
              color: subtextColor,
            ),
          ),
        ),

        // Step 4: Embassy Submission
        _buildStepperItem(
          isDark: isDark,
          nodeIcon: _currentStep > 4
              ? Icons.check_rounded
              : (_currentStep == 4 ? Icons.send_rounded : Icons.radio_button_unchecked),
          isCompleted: _currentStep > 4,
          showConnectingLine: true,
          lineColor: _currentStep > 4 ? const Color(0xFF10B981) : cardBorder,
          title: 'Embassy Submission',
          date: _currentStep > 4 ? 'Visa Issued' : (_currentStep == 4 ? 'In Review' : 'Upcoming'),
          dateColor: _currentStep > 4 ? const Color(0xFF16A34A) : (_currentStep == 4 ? (isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB)) : null),
          subtitleWidget: Text(
            _currentStep > 4
                ? 'Official visa stamped & passport dispatch complete.'
                : 'Filing with high commission embassy portal.',
            style: TextStyle(
              fontSize: 12.sp,
              color: subtextColor,
            ),
          ),
        ),

        // Step 5: Feedback & Case Rating
        if (_currentStep == 5)
          _buildStep5FeedbackCard(context)
        else
          _buildStepperItem(
            isDark: isDark,
            nodeIcon: Icons.star_border_rounded,
            isCompleted: false,
            showConnectingLine: false,
            lineColor: cardBorder,
            title: 'Feedback & Case Rating',
            date: 'Upcoming',
            subtitleWidget: Text(
              'Final review & case rating unlocks after embassy determination.',
              style: TextStyle(
                fontSize: 12.sp,
                color: subtextColor,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStepperItem({
    required bool isDark,
    required IconData nodeIcon,
    required bool isCompleted,
    required bool showConnectingLine,
    required Color lineColor,
    required String title,
    required String date,
    Color? dateColor,
    required Widget subtitleWidget,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Vertical Track (Circle Node + Rail)
          SizedBox(
            width: 32.w,
            child: Column(
              children: [
                Container(
                  width: 26.w,
                  height: 26.w,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF3B82F6) : const Color(0xFF002444),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      nodeIcon,
                      size: 15.sp,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (showConnectingLine)
                  Expanded(
                    child: Container(
                      width: 2.5.w,
                      color: lineColor,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: 12.w),

          // Right Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: 22.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          maxLines: 2,
                          softWrap: true,
                          style: TextStyle(
                            fontSize: 14.5.sp,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF171C21),
                          ),
                        ),
                      ),
                      if (date.trim().isNotEmpty) ...[
                        SizedBox(width: 8.w),
                        Text(
                          date,
                          style: TextStyle(
                            fontSize: 11.5.sp,
                            fontWeight: FontWeight.w600,
                            color: dateColor ?? (isDark ? const Color(0xFF94A3B8) : const Color(0xFF5A626A)),
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 3.h),
                  subtitleWidget,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Step 5: Feedback & Case Rating Interactive Card
  Widget _buildStep5FeedbackCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF18181B) : const Color(0xFFF0F4FA);
    final cardBorder = isDark ? const Color(0xFF27272A) : const Color(0xFFDDE4ED);
    final textPrimary = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF171C21);
    final textSecondary = isDark ? const Color(0xFFA1A1AA) : const Color(0xFF5A626A);
    final navyAccent = isDark ? const Color(0xFF3B82F6) : const Color(0xFF002444);
    final innerBoxBg = isDark ? const Color(0xFF121212) : Colors.white;
    final innerBoxBorder = isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Star Node
        Container(
          width: 26.w,
          height: 26.w,
          decoration: BoxDecoration(
            color: navyAccent,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              Icons.star_rounded,
              size: 16.sp,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(width: 12.w),

        // Interactive Feedback Card
        Expanded(
          child: Container(
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.rate_review_outlined,
                            size: 16.sp,
                            color: textPrimary,
                          ),
                          SizedBox(width: 6.w),
                          Flexible(
                            child: Text(
                              'Feedback & Case Rating',
                              softWrap: true,
                              style: TextStyle(
                                fontSize: 13.5.sp,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 8.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        color: navyAccent,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        'Current Step',
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),

                // Description
                Text(
                  'Your visa process is now complete! Please share your experience with SB Consultants and advisor Usman Tariq.',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: textSecondary,
                    height: 1.35,
                  ),
                ),
                SizedBox(height: 12.h),

                if (_existingFeedback != null) ...[
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(14.w),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F291E) : const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: const Color(0xFF2E7D32).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32), size: 20),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                'Feedback Submitted (100% Complete)',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.sp,
                                  color: const Color(0xFF2E7D32),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        Row(
                          children: List.generate(
                            5,
                            (i) => Icon(
                              i < ((_existingFeedback?['rating'] as num?)?.toInt() ?? 5)
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              color: const Color(0xFFF59E0B),
                              size: 20.sp,
                            ),
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          'Standout: ${_existingFeedback?['standout_tag'] ?? 'Professional Service'}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12.sp,
                            color: textPrimary,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          '"${_existingFeedback?['comments'] ?? ''}"',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            fontSize: 12.sp,
                            color: textSecondary,
                          ),
                        ),
                        SizedBox(height: 14.h),
                        SizedBox(
                          width: double.infinity,
                          height: 46.h,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: navyAccent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                            ),
                            onPressed: () => context.go(AppRoutes.home),
                            child: const Text('Back to Home Screen'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Star Rating Sub-Box
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    decoration: BoxDecoration(
                      color: innerBoxBg,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: innerBoxBorder),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (int i = 1; i <= 5; i++)
                              InkWell(
                                onTap: () {
                                  setState(() => _selectedStars = i);
                                },
                                borderRadius: BorderRadius.circular(20.r),
                                child: Padding(
                                  padding:
                                      EdgeInsets.symmetric(horizontal: 4.w),
                                  child: Icon(
                                    i <= _selectedStars
                                        ? Icons.star_rounded
                                        : Icons.star_outline_rounded,
                                    size: 26.sp,
                                    color: const Color(0xFFF59E0B),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'Tap to rate ($_selectedStars.0 / 5.0)',
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w500,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12.h),

                  // Question 1: What stood out most?
                  Text(
                    'What stood out most?',
                    style: TextStyle(
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Wrap(
                    spacing: 6.w,
                    runSpacing: 6.h,
                    children: [
                      for (final tag in _standoutTags)
                        InkWell(
                          onTap: () => setState(() => _selectedTag = tag),
                          borderRadius: BorderRadius.circular(20.r),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 10.w, vertical: 5.h),
                            decoration: BoxDecoration(
                              color: _selectedTag == tag
                                  ? navyAccent
                                  : (isDark ? const Color(0xFF18181B) : Colors.white),
                              borderRadius: BorderRadius.circular(20.r),
                              border: Border.all(
                                color: _selectedTag == tag
                                    ? navyAccent
                                    : (isDark ? const Color(0xFF27272A) : const Color(0xFFCBD5E1)),
                              ),
                            ),
                            child: Text(
                              tag,
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: _selectedTag == tag
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: _selectedTag == tag
                                    ? Colors.white
                                    : textPrimary,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 12.h),

                  // Question 2: Tell us about your experience
                  Text(
                    'Tell us about your experience',
                    style: TextStyle(
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: innerBoxBg,
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(color: innerBoxBorder),
                    ),
                    child: TextField(
                      controller: _feedbackController,
                      maxLines: 3,
                      maxLength: 500,
                      style: TextStyle(
                        fontSize: 12.5.sp,
                        color: textPrimary,
                      ),
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.all(10.w),
                        hintText:
                            'Write your review or feedback for your consultant...',
                        hintStyle: TextStyle(
                          fontSize: 11.5.sp,
                          color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF8FAEC9),
                        ),
                        border: InputBorder.none,
                        counterStyle: TextStyle(
                          fontSize: 10.sp,
                          color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF73777F),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),

                  // Submit Feedback Button (Consistent button system: 48.h, 12.r)
                  SizedBox(
                    width: double.infinity,
                    height: 48.h,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: navyAccent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      onPressed: _isSubmittingFeedback
                          ? null
                          : () => _handleSubmitFeedback(context),
                      child: _isSubmittingFeedback
                          ? SizedBox(
                              width: 20.w,
                              height: 20.w,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.send_rounded, size: 15),
                                SizedBox(width: 8.w),
                                Text(
                                  'Submit Feedback',
                                  style: TextStyle(
                                    fontSize: 13.5.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 5. STICKY BOTTOM ACTION BAR (Matches media_1790708096474.png)
  // ===========================================================================
  Widget _buildBottomStickyBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF27272A) : const Color(0xFFE8EEF5);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          top: BorderSide(color: borderColor, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : const Color(0xFF1B3A5C).withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: SizedBox(
            width: double.infinity,
            height: 48.h,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                padding: EdgeInsets.symmetric(horizontal: 14.w),
              ),
              onPressed: () {
                final appTitle = widget.application?.title ?? 'Visa Application';
                WhatsAppHelper.launchChat(
                  phone: '923155440606',
                  message:
                      'Hello SB Consultants, I would like to chat regarding my application procedure: $appTitle.',
                );
              },
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.chat_bubble_rounded,
                      size: 17,
                      color: Colors.white,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'Chat on WhatsApp',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
