import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_sd_consultant/src/routing/app_routes.dart';
import 'package:flutter_sd_consultant/src/services/supabase_database_service.dart';
import 'package:flutter_sd_consultant/src/shared/helpers/show_toast.dart';

/// Admin Dashboard Screen for Managing Production Visa Listings
/// and User Applications in Supabase.
class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Visas management state
  List<Map<String, dynamic>> _visas = [];
  bool _isLoadingVisas = true;
  String _visaSearchQuery = '';
  String _selectedVisaCategoryFilter = 'All';

  // Applications management state
  List<Map<String, dynamic>> _applications = [];
  bool _isLoadingApplications = true;
  StreamSubscription<List<Map<String, dynamic>>>? _applicationsSub;
  String _appSearchQuery = '';
  String _selectedAppStatusFilter = 'All';

  // Feedback management state
  List<Map<String, dynamic>> _feedback = [];
  bool _isLoadingFeedback = true;
  String _feedbackSearchQuery = '';
  int? _selectedFeedbackRating;

  final List<String> _categories = [
    'All',
    'visit',
    'study',
    'work',
    'business',
    'golden',
    'sponsored_jobs',
    'scholarships',
  ];

  final List<String> _appStatuses = [
    'All',
    'Needs Payment Approval',
    'submitted',
    'in_progress',
    'approved',
    'completed',
    'rejected',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadVisas();
    _loadApplications();
    _loadFeedback();
    _subscribeRealtimeApplications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _applicationsSub?.cancel();
    super.dispose();
  }

  void _showRealtimeAlertModal({
    required String title,
    required String badgeText,
    required String message,
    required bool isPayment,
  }) {
    if (!mounted) return;
    final themeColor = isPayment ? const Color(0xFF10B981) : const Color(0xFFF59E0B);
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        backgroundColor: const Color(0xFF0F172A),
        child: Container(
          width: 440.w,
          padding: EdgeInsets.all(22.w),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: themeColor, width: 2),
            boxShadow: [
              BoxShadow(
                color: themeColor.withValues(alpha: 0.3),
                blurRadius: 28,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: themeColor.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isPayment ? Icons.payments_rounded : Icons.assignment_ind_rounded,
                      color: themeColor,
                      size: 26.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.5.h),
                          decoration: BoxDecoration(
                            color: themeColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            badgeText,
                            style: TextStyle(
                              fontSize: 9.5.sp,
                              fontWeight: FontWeight.w800,
                              color: themeColor,
                              letterSpacing: 0.7,
                            ),
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white60),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: Colors.white12),
                ),
                child: Text(
                  message,
                  style: TextStyle(
                    fontSize: 13.5.sp,
                    color: Colors.white,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text(
                      'Dismiss',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor,
                      foregroundColor: const Color(0xFF0F172A),
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _tabController.animateTo(1);
                      _loadApplications();
                    },
                    icon: Icon(Icons.arrow_forward_rounded, size: 14.sp),
                    label: Text(
                      'View Applicants',
                      style: TextStyle(
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.w800,
                      ),
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

  void _subscribeRealtimeApplications() {
    try {
      final client = SupabaseDatabaseService.instance.client;
      _applicationsSub = client
          .from('applications')
          .stream(primaryKey: ['id'])
          .order('applied_at', ascending: false)
          .listen(
            (rows) {
              if (mounted) {
                final isInitial = _applications.isEmpty;
                final hasNew = rows.length > _applications.length;
                setState(() {
                  _applications = List<Map<String, dynamic>>.from(rows);
                  _isLoadingApplications = false;
                });
                if (!isInitial && hasNew && rows.isNotEmpty) {
                  final latest = rows.first;
                  _showRealtimeAlertModal(
                    title: 'New Visa Application Received',
                    badgeText: '🚨 REALTIME VISA ALERT',
                    message:
                        '${latest['applicant_name'] ?? 'Applicant'} submitted: ${latest['title'] ?? 'Application'} (${latest['reference_number'] ?? ''})',
                    isPayment: false,
                  );
                }
              }
            },
            onError: (_) {
              if (mounted) {
                setState(() => _isLoadingApplications = false);
              }
            },
          );

      // Listen on broadcast channel for instant notification events from mobile app
      final channel = client.channel('admin-dashboard-realtime-channel');
      channel
        ..onBroadcast(
          event: 'new_booking_or_application',
          callback: (payload) {
            _loadApplications();
            final title = payload['title']?.toString() ?? 'Visa Application';
            final applicant = payload['applicant_name']?.toString() ?? 'Applicant';
            final refNum = payload['reference_number']?.toString() ?? '';
            _showRealtimeAlertModal(
              title: 'New Visa Application Received',
              badgeText: '🚨 NEW VISA FILED',
              message: '$applicant has just filed an application for $title ${refNum.isNotEmpty ? "($refNum)" : ""}',
              isPayment: false,
            );
          },
        )
        ..onBroadcast(
          event: 'new_visa_application',
          callback: (payload) {
            _loadApplications();
            final title = payload['title']?.toString() ?? 'Visa Application';
            final applicant = payload['applicant_name']?.toString() ?? 'Applicant';
            final refNum = payload['reference_number']?.toString() ?? '';
            _showRealtimeAlertModal(
              title: 'New Visa Application Received',
              badgeText: '🚨 NEW VISA FILED',
              message: '$applicant has just filed an application for $title ${refNum.isNotEmpty ? "($refNum)" : ""}',
              isPayment: false,
            );
          },
        )
        ..onBroadcast(
          event: 'new_application',
          callback: (payload) {
            _loadApplications();
            final title = payload['title']?.toString() ?? 'Visa Application';
            final applicant = payload['applicant_name']?.toString() ?? 'Applicant';
            final refNum = payload['reference_number']?.toString() ?? '';
            _showRealtimeAlertModal(
              title: 'New Visa Application Received',
              badgeText: '🚨 NEW VISA FILED',
              message: '$applicant has just filed an application for $title ${refNum.isNotEmpty ? "($refNum)" : ""}',
              isPayment: false,
            );
          },
        )
        ..onBroadcast(
          event: 'new_payment_received',
          callback: (payload) {
            _loadApplications();
            final title = payload['title']?.toString() ?? 'Application';
            final applicant = payload['applicant_name']?.toString() ?? 'Applicant';
            final refNum = payload['reference_number']?.toString() ?? '';
            final fee = payload['fee_amount']?.toString() ?? '';
            final method = payload['payment_method']?.toString() ?? 'Bank Transfer';
            _showRealtimeAlertModal(
              title: 'Client Payment Received',
              badgeText: '💳 IMMEDIATE PAYMENT ALERT',
              message: '$applicant paid PKR $fee via $method for $title ${refNum.isNotEmpty ? "($refNum)" : ""}',
              isPayment: true,
            );
          },
        );
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingApplications = false);
      }
    }
  }

  Future<void> _loadVisas() async {
    if (_visas.isEmpty) {
      setState(() => _isLoadingVisas = true);
    }
    try {
      final res =
          await SupabaseDatabaseService.instance.getAllVisaListingsAdmin();
      if (!mounted) return;
      res.fold(
        (failure) {
          setState(() => _isLoadingVisas = false);
          showToast(context,
              message: 'Failed to load visas: ${failure.message}',
              status: 'error');
        },
        (data) {
          setState(() {
            _visas = data;
            _isLoadingVisas = false;
          });
        },
      );
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingVisas = false);
      }
    }
  }

  Future<void> _loadApplications() async {
    if (_applications.isEmpty) {
      setState(() => _isLoadingApplications = true);
    }
    try {
      final res =
          await SupabaseDatabaseService.instance.getAllApplicationsAdmin();
      if (!mounted) return;
      res.fold(
        (failure) {
          setState(() => _isLoadingApplications = false);
          showToast(context,
              message: 'Failed to load applications: ${failure.message}',
              status: 'error');
        },
        (data) {
          setState(() {
            _applications = data;
            _isLoadingApplications = false;
          });
        },
      );
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingApplications = false);
      }
    }
  }

  Future<void> _loadFeedback() async {
    if (_feedback.isEmpty) {
      setState(() => _isLoadingFeedback = true);
    }
    try {
      final res =
          await SupabaseDatabaseService.instance.getAllFeedbackAdmin();
      if (!mounted) return;
      res.fold(
        (failure) {
          setState(() => _isLoadingFeedback = false);
        },
        (data) {
          setState(() {
            _feedback = data;
            _isLoadingFeedback = false;
          });
        },
      );
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingFeedback = false);
      }
    }
  }

  // ===========================================================================
  // COMPUTED METRICS & HELPERS
  // ===========================================================================
  bool _isPendingVerification(Map<String, dynamic> item) {
    final statusLabel = (item['status_label']?.toString() ?? '').toLowerCase();
    final alertTitle = (item['alert_title']?.toString() ?? '').toLowerCase();
    final formData = item['form_data'] as Map<String, dynamic>? ?? {};
    final paymentVerified = formData['payment_verified'] == true;
    final status = (item['status'] as String? ?? '').toLowerCase();

    return !paymentVerified &&
        (statusLabel.contains('verification') ||
            alertTitle.contains('verification') ||
            (item['has_alert'] == true && alertTitle.contains('payment')) ||
            status == 'under_review' ||
            statusLabel.contains('payment'));
  }

  int get _pendingPaymentsCount =>
      _applications.where((a) => _isPendingVerification(a)).length;

  int get _inProgressCount => _applications.where((a) {
        final status = (a['status'] as String? ?? '').toLowerCase();
        return status == 'in_progress' || status == 'submitted';
      }).length;

  int get _completedCount => _applications.where((a) {
        final status = (a['status'] as String? ?? '').toLowerCase();
        final step = a['current_step'] as int? ?? 1;
        return status == 'completed' || status == 'approved' || step == 5;
      }).length;

  String _formatDate(dynamic dateVal) {
    if (dateVal == null) return 'N/A';
    try {
      final dt = DateTime.tryParse(dateVal.toString())?.toLocal();
      if (dt == null) return dateVal.toString();
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      final minute = dt.minute.toString().padLeft(2, '0');
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $hour:$minute $ampm';
    } catch (_) {
      return dateVal.toString();
    }
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 1:
        return 'Profile Review & Intake';
      case 2:
        return 'Consultancy Call';
      case 3:
        return 'Ready Case & Documents';
      case 4:
        return 'Embassy Filing';
      case 5:
        return 'Feedback & Completed';
      default:
        return 'Step $step';
    }
  }

  String _getStepDescription(int step) {
    switch (step) {
      case 1:
        return 'Step 1 of 5: Profile Review & Intake';
      case 2:
        return 'Step 2 of 5: Consultancy Call';
      case 3:
        return 'Step 3 of 5: Ready Case & Documents';
      case 4:
        return 'Step 4 of 5: Embassy Filing';
      case 5:
        return 'Step 5 of 5: Feedback & Rating (100% Completed)';
      default:
        return 'Step $step of 5: In Progress';
    }
  }

  // Direct Verification Handler
  Future<void> _verifyPaymentDirect(Map<String, dynamic> item) async {
    final appId = item['id'] as String;
    final applicantName = item['applicant_name'] as String? ?? 'Applicant';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Row(
          children: [
            const Icon(Icons.verified_rounded,
                color: Color(0xFF16A34A), size: 24),
            SizedBox(width: 8.w),
            const Text('Verify Bank Payment'),
          ],
        ),
        content: Text(
          'Approve bank transfer payment for $applicantName?\n\n'
          'This will immediately clear the verification hold and unlock the full procedure tracking for the user.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm & Verify'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final res = await SupabaseDatabaseService.instance
        .verifyBankTransferPaymentAdmin(applicationId: appId);

    if (!mounted) return;
    res.fold(
      (f) => showToast(context, message: f.message, status: 'error'),
      (_) {
        showToast(
          context,
          message: 'Payment verified! Applicant tracking unlocked.',
          status: 'success',
        );
        _loadApplications();
      },
    );
  }

  // Direct Quick Step Advancement
  Future<void> _quickAdvanceStep(Map<String, dynamic> item) async {
    final appId = item['id'] as String;
    final currentStep = item['current_step'] as int? ?? 1;
    if (currentStep >= 5) return;
    final nextStep = currentStep + 1;
    final stepText = _getStepDescription(nextStep);
    final newStatus = nextStep == 5 ? 'completed' : 'in_progress';
    final progressPercent = (nextStep * 20).clamp(0, 100);

    final res =
        await SupabaseDatabaseService.instance.updateApplicationStepAndStatus(
      appId,
      newStep: nextStep,
      newStatus: newStatus,
      stepText: stepText,
      progressPercent: progressPercent,
    );

    if (!mounted) return;
    res.fold(
      (f) => showToast(context, message: f.message, status: 'error'),
      (_) {
        showToast(
          context,
          message: 'Advanced to Step $nextStep: ${_getStepTitle(nextStep)}',
          status: 'success',
        );
        _loadApplications();
      },
    );
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    showToast(context, message: '$label copied to clipboard', status: 'info');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF000000) : const Color(0xFFF7F9FF);
    final cardBg = isDark ? const Color(0xFF121212) : Colors.white;
    const primaryNavy = Color(0xFF1B3A5C);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF121212) : primaryNavy,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.home);
            }
          },
        ),
        title: Text(
          'Admin Management Portal',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: () {
              _loadVisas();
              _loadApplications();
              _loadFeedback();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF60A5FA),
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withValues(alpha: 0.65),
          tabs: [
            Tab(
              icon: const Icon(Icons.card_travel_rounded),
              text: 'Visa Catalog (${_visas.length})',
            ),
            Tab(
              icon: Badge(
                isLabelVisible: _pendingPaymentsCount > 0,
                backgroundColor: const Color(0xFFEF4444),
                label: Text('$_pendingPaymentsCount'),
                child: const Icon(Icons.assignment_ind_rounded),
              ),
              text: 'Applicants (${_applications.length})',
            ),
            Tab(
              icon: const Icon(Icons.rate_review_rounded),
              text: 'Feedback (${_feedback.length})',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildVisasTab(isDark, cardBg),
          _buildApplicationsTab(isDark, cardBg),
          _buildFeedbackTab(isDark, cardBg),
        ],
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _tabController,
        builder: (context, _) {
          if (_tabController.index != 0) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            backgroundColor: const Color(0xFF1B3A5C),
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add_rounded),
            label: const Text('New Visa'),
            onPressed: () => _showAddEditVisaDialog(context, isDark: isDark),
          );
        },
      ),
    );
  }

  // ===========================================================================
  // 1. VISAS MANAGEMENT TAB
  // ===========================================================================
  Widget _buildVisasTab(bool isDark, Color cardBg) {
    if (_isLoadingVisas) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredVisas = _visas.where((v) {
      final title = (v['title'] as String? ?? '').toLowerCase();
      final cat = (v['category_id'] as String? ?? '').toLowerCase();
      final country = (v['country_name'] as String? ?? '').toLowerCase();

      final matchesQuery = _visaSearchQuery.isEmpty ||
          title.contains(_visaSearchQuery.toLowerCase()) ||
          country.contains(_visaSearchQuery.toLowerCase());

      final matchesCat = _selectedVisaCategoryFilter == 'All' ||
          cat == _selectedVisaCategoryFilter.toLowerCase() ||
          (_selectedVisaCategoryFilter == 'sponsored_jobs' &&
              (cat.contains('job') || cat == 'sponsored_job')) ||
          (_selectedVisaCategoryFilter == 'scholarships' &&
              cat.contains('scholarship'));

      return matchesQuery && matchesCat;
    }).toList();

    final activeCount = _visas.where((v) => v['is_active'] == true).length;
    final inactiveCount = _visas.length - activeCount;

    return Column(
      children: [
        // Visas Summary Metric Banner (Wrapped to avoid horizontal overflow)
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 4.h),
          child: Wrap(
            spacing: 8.w,
            runSpacing: 6.h,
            children: [
              _buildMetricChip(
                label: 'Total Visas',
                count: '${_visas.length}',
                color: const Color(0xFF1B3A5C),
                icon: Icons.public_rounded,
                isDark: isDark,
              ),
              _buildMetricChip(
                label: 'Active in App',
                count: '$activeCount',
                color: const Color(0xFF16A34A),
                icon: Icons.check_circle_rounded,
                isDark: isDark,
              ),
              _buildMetricChip(
                label: 'Hidden',
                count: '$inactiveCount',
                color: const Color(0xFF64748B),
                icon: Icons.visibility_off_rounded,
                isDark: isDark,
              ),
            ],
          ),
        ),

        // Search Bar & VERTICAL WRAP Categories (No horizontal sliding needed!)
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                onChanged: (val) => setState(() => _visaSearchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search visas by title or country...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _visaSearchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () =>
                              setState(() => _visaSearchQuery = ''),
                        )
                      : null,
                  filled: true,
                  fillColor: cardBg,
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 0, horizontal: 16.w),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(
                      color: isDark
                          ? const Color(0xFF27272A)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 8.h),

              // Categories Header Label
              Text(
                'Filter by Visa Category:',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? const Color(0xFFA1A1AA)
                      : const Color(0xFF475569),
                ),
              ),
              SizedBox(height: 6.h),

              // ALL Category Buttons are wrapped and 100% visible immediately (NO horizontal scroll required!)
              Wrap(
                spacing: 8.w,
                runSpacing: 6.h,
                children: _categories.map((cat) {
                  final isSelected = _selectedVisaCategoryFilter == cat;
                  String displayLabel;
                  if (cat == 'sponsored_jobs') {
                    displayLabel = 'SPONSORED JOBS';
                  } else if (cat == 'scholarships') {
                    displayLabel = 'SCHOLARSHIPS';
                  } else if (cat == 'All') {
                    displayLabel = 'ALL';
                  } else {
                    displayLabel = cat.toUpperCase();
                  }

                  return ChoiceChip(
                    label: Text(displayLabel),
                    selected: isSelected,
                    selectedColor: const Color(0xFF1B3A5C),
                    labelStyle: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white70 : Colors.black87),
                    ),
                    onSelected: (_) {
                      setState(() => _selectedVisaCategoryFilter = cat);
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),

        // Visa Listings
        Expanded(
          child: filteredVisas.isEmpty
              ? _buildEmptyState(
                  icon: Icons.travel_explore_rounded,
                  title: 'No visas found',
                  subtitle:
                      'No visa records match your current search or filter criteria.',
                )
              : ListView.separated(
                  padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 80.h),
                  itemCount: filteredVisas.length,
                  separatorBuilder: (_, __) => SizedBox(height: 14.h),
                  itemBuilder: (context, index) {
                    final item = filteredVisas[index];
                    final id = item['id'] as String;
                    final title = item['title'] as String? ?? 'Untitled Visa';
                    final cat =
                        (item['category_id'] as String? ?? '').toUpperCase();
                    final country =
                        item['country_name'] as String? ?? 'International';
                    // Extract consultancy fee (payable to SB Consultants in-app)
                    String consultancyFee = 'PKR 30,000';
                    if (item['service_fee_value'] != null &&
                        item['service_fee_value']
                            .toString()
                            .trim()
                            .isNotEmpty) {
                      consultancyFee =
                          item['service_fee_value'].toString().trim();
                    } else if (item['total_payable'] != null &&
                        item['total_payable'].toString().trim().isNotEmpty) {
                      consultancyFee = item['total_payable'].toString().trim();
                    } else if (item['fee'] != null &&
                        item['fee'].toString().trim().isNotEmpty &&
                        (item['fee'].toString().contains('PKR') ||
                            item['fee'].toString().contains('Rs'))) {
                      consultancyFee = item['fee'].toString().trim();
                    }

                    final isActive = item['is_active'] as bool? ?? true;
                    final processing =
                        item['processing_time'] as String? ?? '3-4 weeks';
                    final validity =
                        item['validity'] as String? ?? 'Up to 2 Years';

                    final salary = (item['salary'] ??
                            item['salary_or_funding'] ??
                            item['salary_range'])
                        ?.toString()
                        .trim();
                    final isJobListing = cat.contains('JOB') ||
                        cat == 'WORK' ||
                        title.toLowerCase().contains('job') ||
                        title.toLowerCase().contains('sponsored');
                    final isScholarshipListing = cat.contains('SCHOLARSHIP') ||
                        title.toLowerCase().contains('scholarship');

                    return DecoratedBox(
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF27272A)
                              : const Color(0xFFE2E8F0),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? Colors.transparent
                                : Colors.black.withValues(alpha: 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(14.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header: Category and Country
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8.w, vertical: 4.h),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1B3A5C)
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6.r),
                                  ),
                                  child: Text(
                                    cat,
                                    style: TextStyle(
                                      fontSize: 10.5.sp,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF1B3A5C),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                Expanded(
                                  child: Text(
                                    country,
                                    style: TextStyle(
                                      fontSize: 12.5.sp,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? const Color(0xFFA1A1AA)
                                          : const Color(0xFF475569),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8.h),

                            // Visa Title
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                            SizedBox(height: 8.h),

                            // Badges
                            Wrap(
                              spacing: 8.w,
                              runSpacing: 6.h,
                              children: [
                                // Salary Per Annum Badge (Matches Flutter mobile app!)
                                if (salary != null && salary.isNotEmpty)
                                  _buildPillBadge(
                                    icon: Icons.payments_rounded,
                                    label: 'Salary: $salary',
                                    color: const Color(0xFF16A34A),
                                    isDark: isDark,
                                  ),
                                // Scholarship Status
                                if (isScholarshipListing)
                                  _buildPillBadge(
                                    icon: Icons.school_rounded,
                                    label: (salary != null && salary.isNotEmpty)
                                        ? salary
                                        : '100% Fully Funded',
                                    color: const Color(0xFF00897B),
                                    isDark: isDark,
                                  ),
                                // Consultancy Service Fee (for paid routes)
                                if (!isScholarshipListing &&
                                    (!isJobListing || consultancyFee.contains('PKR')) &&
                                    consultancyFee != 'Free' &&
                                    consultancyFee != 'Free / Direct' &&
                                    consultancyFee != '0')
                                  _buildPillBadge(
                                    icon: Icons.receipt_long_rounded,
                                    label: 'Fee: $consultancyFee',
                                    color: const Color(0xFF1B3A5C),
                                    isDark: isDark,
                                  ),
                                _buildPillBadge(
                                  icon: Icons.schedule_rounded,
                                  label: processing,
                                  color: const Color(0xFF0284C7),
                                  isDark: isDark,
                                ),
                                _buildPillBadge(
                                  icon: Icons.calendar_today_rounded,
                                  label: validity,
                                  color: const Color(0xFF7C3AED),
                                  isDark: isDark,
                                ),
                              ],
                            ),
                            SizedBox(height: 10.h),

                            // DEDICATED VERTICAL SETTING TILE: Active in App Switch
                            // (No longer shoved on a side corner where people can't see it!)
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12.w, vertical: 8.h),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF1E1E24)
                                    : const Color(0xFFF1F5F9),
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
                                    isActive
                                        ? Icons.check_circle_rounded
                                        : Icons.visibility_off_rounded,
                                    size: 16.sp,
                                    color: isActive
                                        ? const Color(0xFF16A34A)
                                        : const Color(0xFF94A3B8),
                                  ),
                                  SizedBox(width: 8.w),
                                  Expanded(
                                    child: Text(
                                      isActive
                                          ? 'Status: Active in App (Visible)'
                                          : 'Status: Hidden (Not visible)',
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w700,
                                        color: isActive
                                            ? const Color(0xFF16A34A)
                                            : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                  Switch(
                                    value: isActive,
                                    activeThumbColor: const Color(0xFF1B3A5C),
                                    onChanged: (val) async {
                                      final res = await SupabaseDatabaseService
                                          .instance
                                          .toggleVisaActiveStatus(id, val);
                                      res.fold(
                                        (f) => showToast(context,
                                            message: f.message,
                                            status: 'error'),
                                        (_) {
                                          setState(() {
                                            item['is_active'] = val;
                                          });
                                          showToast(
                                            context,
                                            message: val
                                                ? 'Visa is now visible in the app'
                                                : 'Visa is now hidden from the app',
                                            status: 'info',
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: 10.h),
                            const Divider(height: 1),
                            SizedBox(height: 10.h),

                            // VERTICAL FULL-WIDTH ACTION BUTTONS
                            // (Completely visible to anyone without sliding!)
                            SizedBox(
                              width: double.infinity,
                              height: 40.h,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: const Color(0xFF1B3A5C)
                                        .withValues(alpha: 0.3),
                                  ),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8.r)),
                                ),
                                icon: const Icon(Icons.edit_rounded,
                                    size: 16, color: Color(0xFF1B3A5C)),
                                label: const Text(
                                  'Edit Visa Details & Pricing',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1B3A5C),
                                  ),
                                ),
                                onPressed: () {
                                  _showAddEditVisaDialog(
                                    context,
                                    existingVisa: item,
                                    isDark: isDark,
                                  );
                                },
                              ),
                            ),
                            SizedBox(height: 6.h),
                            SizedBox(
                              width: double.infinity,
                              child: TextButton.icon(
                                style: TextButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  foregroundColor: const Color(0xFFEF4444),
                                ),
                                icon: const Icon(Icons.delete_outline_rounded,
                                    size: 16),
                                label: const Text(
                                  'Delete Visa Record',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                onPressed: () =>
                                    _confirmDeleteVisa(context, id, title),
                              ),
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

  // ===========================================================================
  // 2. APPLICATIONS MANAGEMENT TAB
  // ===========================================================================
  Widget _buildApplicationsTab(bool isDark, Color cardBg) {
    if (_isLoadingApplications) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredApps = _applications.where((a) {
      final name = (a['applicant_name'] as String? ?? '').toLowerCase();
      final ref = (a['reference_number'] as String? ?? '').toLowerCase();
      final status = (a['status'] as String? ?? '').toLowerCase();
      final isPending = _isPendingVerification(a);

      final matchesQuery = _appSearchQuery.isEmpty ||
          name.contains(_appSearchQuery.toLowerCase()) ||
          ref.contains(_appSearchQuery.toLowerCase());

      bool matchesStatus = true;
      if (_selectedAppStatusFilter == 'Needs Payment Approval') {
        matchesStatus = isPending;
      } else if (_selectedAppStatusFilter != 'All') {
        matchesStatus = status == _selectedAppStatusFilter.toLowerCase();
      }

      return matchesQuery && matchesStatus;
    }).toList();

    return Column(
      children: [
        // 1. EXECUTIVE SUMMARY STATS: 2x2 GRID
        // (Replaces cramped 4-in-a-row layout with spacious, clearly readable cards!)
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 6.h),
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8.h,
            crossAxisSpacing: 8.w,
            childAspectRatio: 2.3,
            children: [
              _buildExecutiveStatCard(
                title: 'Total Files',
                count: '${_applications.length}',
                color: const Color(0xFF1B3A5C),
                icon: Icons.folder_shared_rounded,
                isSelected: _selectedAppStatusFilter == 'All',
                onTap: () => setState(() => _selectedAppStatusFilter = 'All'),
                isDark: isDark,
              ),
              _buildExecutiveStatCard(
                title: 'Needs Payment',
                count: '$_pendingPaymentsCount',
                color: const Color(0xFFD97706),
                icon: Icons.warning_amber_rounded,
                highlight: _pendingPaymentsCount > 0,
                isSelected:
                    _selectedAppStatusFilter == 'Needs Payment Approval',
                onTap: () => setState(
                    () => _selectedAppStatusFilter = 'Needs Payment Approval'),
                isDark: isDark,
              ),
              _buildExecutiveStatCard(
                title: 'In Progress',
                count: '$_inProgressCount',
                color: const Color(0xFF0284C7),
                icon: Icons.sync_rounded,
                isSelected: _selectedAppStatusFilter == 'in_progress',
                onTap: () =>
                    setState(() => _selectedAppStatusFilter = 'in_progress'),
                isDark: isDark,
              ),
              _buildExecutiveStatCard(
                title: 'Completed',
                count: '$_completedCount',
                color: const Color(0xFF16A34A),
                icon: Icons.check_circle_rounded,
                isSelected: _selectedAppStatusFilter == 'completed',
                onTap: () =>
                    setState(() => _selectedAppStatusFilter = 'completed'),
                isDark: isDark,
              ),
            ],
          ),
        ),

        // 2. Search & VERTICAL WRAPPED Filter Chips
        // (All buttons are visible immediately, NO HORIZONTAL SLIDING NEEDED!)
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                onChanged: (val) => setState(() => _appSearchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search by applicant name or reference...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _appSearchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () => setState(() => _appSearchQuery = ''),
                        )
                      : null,
                  filled: true,
                  fillColor: cardBg,
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 0, horizontal: 16.w),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(
                      color: isDark
                          ? const Color(0xFF27272A)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 8.h),

              Text(
                'Filter by Status:',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? const Color(0xFFA1A1AA)
                      : const Color(0xFF475569),
                ),
              ),
              SizedBox(height: 6.h),

              // ALL STATUS BUTTONS ARE WRAPPED INTO FULL VIEW
              // (Anyone opening the app can see every single button without sliding!)
              Wrap(
                spacing: 8.w,
                runSpacing: 6.h,
                children: _appStatuses.map((status) {
                  final isSelected = _selectedAppStatusFilter == status;
                  final isPaymentFilter = status == 'Needs Payment Approval';

                  return ChoiceChip(
                    avatar: isPaymentFilter && _pendingPaymentsCount > 0
                        ? CircleAvatar(
                            backgroundColor: Colors.white,
                            radius: 8,
                            child: Text(
                              '$_pendingPaymentsCount',
                              style: const TextStyle(
                                color: Color(0xFFD97706),
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          )
                        : null,
                    label: Text(status.toUpperCase()),
                    selected: isSelected,
                    selectedColor: isPaymentFilter
                        ? const Color(0xFFD97706)
                        : const Color(0xFF1B3A5C),
                    labelStyle: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white70 : Colors.black87),
                    ),
                    onSelected: (_) {
                      setState(() => _selectedAppStatusFilter = status);
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),

        // 3. Applications List View
        Expanded(
          child: filteredApps.isEmpty
              ? _buildEmptyState(
                  icon: Icons.folder_open_rounded,
                  title: 'No applications found',
                  subtitle:
                      'No applicant records match the current search or status filter.',
                )
              : ListView.separated(
                  padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 24.h),
                  itemCount: filteredApps.length,
                  separatorBuilder: (_, __) => SizedBox(height: 14.h),
                  itemBuilder: (context, index) {
                    final item = filteredApps[index];
                    final refNo = item['reference_number'] as String? ?? 'N/A';
                    final name =
                        item['applicant_name'] as String? ?? 'Applicant';
                    final email =
                        item['applicant_email'] as String? ?? 'No email';
                    final phone =
                        item['applicant_phone'] as String? ?? 'No phone';
                    final title =
                        item['title'] as String? ?? 'Visa Application';
                    final status = item['status'] as String? ?? 'submitted';
                    final currentStep = item['current_step'] as int? ?? 1;
                    final appliedAt = item['applied_at'] ?? item['created_at'];
                    final isPendingVerification = _isPendingVerification(item);
                    final progressPercent = (currentStep * 20).clamp(20, 100);

                    final formData =
                        item['form_data'] as Map<String, dynamic>? ?? {};
                    final paymentsList = item['payments'] as List<dynamic>? ?? [];
                    final paymentMap = paymentsList.isNotEmpty &&
                            paymentsList.first is Map
                        ? Map<String, dynamic>.from(paymentsList.first as Map)
                        : null;

                    final txnId = (paymentMap?['transaction_id']
                                    ?.toString()
                                    .trim()
                                    .isNotEmpty ??
                                false)
                        ? paymentMap!['transaction_id'].toString().trim()
                        : (formData['transaction_ref'] ??
                                formData['transaction_id'] ??
                                formData['txn_id'])
                            ?.toString()
                            .trim();

                    final txnAmount = paymentMap?['amount'] != null
                        ? '${paymentMap!['currency'] ?? 'PKR'} ${paymentMap['amount']}'
                        : (formData['fee'] ?? formData['amount']) != null
                            ? 'PKR ${formData['fee'] ?? formData['amount']}'
                            : null;

                    final txnMethod = paymentMap?['payment_method']?.toString() ??
                        formData['payment_method']?.toString() ??
                        'Bank Transfer';

                    final txnStatus = paymentMap?['status']?.toString() ??
                        (formData['payment_verified'] == true
                            ? 'completed'
                            : 'pending');

                    final passport = (item['applicant_passport']
                                    ?.toString()
                                    .trim()
                                    .isNotEmpty ??
                                false)
                        ? item['applicant_passport'].toString().trim()
                        : (formData['passport_number'] ?? formData['passport'])
                            ?.toString()
                            .trim();

                    final nationality = formData['nationality']?.toString().trim();

                    return DecoratedBox(
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: isPendingVerification
                              ? const Color(0xFFF59E0B)
                              : (isDark
                                  ? const Color(0xFF27272A)
                                  : const Color(0xFFE2E8F0)),
                          width: isPendingVerification ? 1.8 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? Colors.transparent
                                : Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top Reference & Status Bar with IMMEDIATE Manage Button
                          Padding(
                            padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 8.h),
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8.w, vertical: 4.h),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1B3A5C)
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6.r),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        refNo,
                                        style: TextStyle(
                                          fontSize: 11.5.sp,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF1B3A5C),
                                        ),
                                      ),
                                      SizedBox(width: 4.w),
                                      InkWell(
                                        onTap: () => _copyToClipboard(
                                            refNo, 'Reference ID'),
                                        child: const Icon(
                                          Icons.copy_rounded,
                                          size: 13,
                                          color: Color(0xFF1B3A5C),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Spacer(),
                                _buildStatusBadge(status),
                                SizedBox(width: 8.w),
                                InkWell(
                                  onTap: () => _showApplicationDetailSheet(
                                      context, item, isDark),
                                  borderRadius: BorderRadius.circular(6.r),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 8.w, vertical: 4.h),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1B3A5C),
                                      borderRadius:
                                          BorderRadius.circular(6.r),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.folder_open_rounded,
                                            size: 11.sp, color: Colors.white),
                                        SizedBox(width: 3.w),
                                        Text(
                                          'Manage →',
                                          style: TextStyle(
                                            fontSize: 10.5.sp,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // High Visibility Alert Banner if Payment Verification Needed
                          if (isPendingVerification) ...[
                            Container(
                              width: double.infinity,
                              margin: EdgeInsets.symmetric(horizontal: 14.w),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12.w, vertical: 10.h),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFFBEB),
                                borderRadius: BorderRadius.circular(10.r),
                                border:
                                    Border.all(color: const Color(0xFFFCD34D)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.warning_amber_rounded,
                                          size: 18, color: Color(0xFFB45309)),
                                      SizedBox(width: 6.w),
                                      Expanded(
                                        child: Text(
                                          'Payment Verification Required',
                                          style: TextStyle(
                                            fontSize: 12.5.sp,
                                            fontWeight: FontWeight.w800,
                                            color: const Color(0xFFB45309),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    'Applicant uploaded bank proof. Tracking is paused until verified.',
                                    style: TextStyle(
                                      fontSize: 11.5.sp,
                                      color: const Color(0xFF78350F),
                                    ),
                                  ),
                                  SizedBox(height: 8.h),
                                  // Direct Full-Width Verify Button
                                  SizedBox(
                                    width: double.infinity,
                                    height: 40.h,
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF16A34A),
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8.r),
                                        ),
                                      ),
                                      icon: const Icon(Icons.verified_rounded,
                                          size: 16),
                                      label: const Text(
                                        '✓ Verify & Approve Payment',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w700),
                                      ),
                                      onPressed: () =>
                                          _verifyPaymentDirect(item),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 10.h),
                          ],

                          // Applicant Core Information
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 14.w),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: TextStyle(
                                    fontSize: 16.5.sp,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF0F172A),
                                  ),
                                ),
                                SizedBox(height: 3.h),
                                Row(
                                  children: [
                                    Icon(Icons.public_rounded,
                                        size: 14.sp,
                                        color: const Color(0xFF64748B)),
                                    SizedBox(width: 4.w),
                                    Expanded(
                                      child: Text(
                                        title,
                                        style: TextStyle(
                                          fontSize: 13.sp,
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? const Color(0xFFA1A1AA)
                                              : const Color(0xFF475569),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 4.h),
                                Row(
                                  children: [
                                    Icon(Icons.schedule_rounded,
                                        size: 13.sp,
                                        color: const Color(0xFF94A3B8)),
                                    SizedBox(width: 4.w),
                                    Text(
                                      'Applied: ${_formatDate(appliedAt)}',
                                      style: TextStyle(
                                        fontSize: 11.5.sp,
                                        color: const Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 10.h),

                          // Contact Rows (Clean, separated vertical rows with copy actions)
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 14.w),
                            child: Column(
                              children: [
                                _buildContactRow(
                                  icon: Icons.email_outlined,
                                  value: email,
                                  label: 'Email',
                                  onCopy: () =>
                                      _copyToClipboard(email, 'Email address'),
                                  isDark: isDark,
                                ),
                                SizedBox(height: 6.h),
                                _buildContactRow(
                                  icon: Icons.phone_outlined,
                                  value: phone,
                                  label: 'Phone',
                                  onCopy: () =>
                                      _copyToClipboard(phone, 'Phone number'),
                                  isDark: isDark,
                                ),
                                if (passport != null && passport.isNotEmpty) ...[
                                  SizedBox(height: 6.h),
                                  _buildContactRow(
                                    icon: Icons.badge_outlined,
                                    value: passport,
                                    label: 'Passport #',
                                    onCopy: () => _copyToClipboard(
                                        passport, 'Passport number'),
                                    isDark: isDark,
                                  ),
                                ],
                                if (nationality != null &&
                                    nationality.isNotEmpty) ...[
                                  SizedBox(height: 6.h),
                                  _buildContactRow(
                                    icon: Icons.public_rounded,
                                    value: nationality,
                                    label: 'Nationality',
                                    onCopy: () => _copyToClipboard(
                                        nationality, 'Nationality'),
                                    isDark: isDark,
                                  ),
                                ],
                              ],
                            ),
                          ),

                          // HIGH-VISIBILITY TRANSACTION FEE NUMBER BOX
                          if (txnId != null || txnAmount != null) ...[
                            SizedBox(height: 10.h),
                            Container(
                              width: double.infinity,
                              margin: EdgeInsets.symmetric(horizontal: 14.w),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12.w, vertical: 10.h),
                              decoration: BoxDecoration(
                                color: isPendingVerification
                                    ? const Color(0xFFFFFBEB)
                                    : (isDark
                                        ? const Color(0xFF052E16)
                                        : const Color(0xFFF0FDF4)),
                                borderRadius: BorderRadius.circular(10.r),
                                border: Border.all(
                                  color: isPendingVerification
                                      ? const Color(0xFFFCD34D)
                                      : const Color(0xFF86EFAC),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(7.w),
                                    decoration: BoxDecoration(
                                      color: isPendingVerification
                                          ? const Color(0xFFD97706)
                                              .withValues(alpha: 0.15)
                                          : const Color(0xFF16A34A)
                                              .withValues(alpha: 0.15),
                                      borderRadius:
                                          BorderRadius.circular(8.r),
                                    ),
                                    child: Icon(
                                      isPendingVerification
                                          ? Icons.receipt_long_rounded
                                          : Icons.verified_rounded,
                                      color: isPendingVerification
                                          ? const Color(0xFFD97706)
                                          : const Color(0xFF16A34A),
                                      size: 18.sp,
                                    ),
                                  ),
                                  SizedBox(width: 10.w),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              'TRANSACTION FEE REF: ',
                                              style: TextStyle(
                                                fontSize: 9.5.sp,
                                                fontWeight: FontWeight.w800,
                                                color: isPendingVerification
                                                    ? const Color(0xFF92400E)
                                                    : const Color(0xFF166534),
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                            if (txnId != null) ...[
                                              Flexible(
                                                child: Text(
                                                  txnId,
                                                  style: TextStyle(
                                                    fontSize: 12.sp,
                                                    fontWeight: FontWeight.w900,
                                                    color: isPendingVerification
                                                        ? const Color(0xFFB45309)
                                                        : const Color(
                                                            0xFF15803D),
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              SizedBox(width: 4.w),
                                              InkWell(
                                                onTap: () => _copyToClipboard(
                                                    txnId,
                                                    'Transaction reference number'),
                                                child: Icon(
                                                  Icons.copy_rounded,
                                                  size: 12.sp,
                                                  color: isPendingVerification
                                                      ? const Color(0xFFB45309)
                                                      : const Color(
                                                          0xFF15803D),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        SizedBox(height: 3.h),
                                        Wrap(
                                          spacing: 8.w,
                                          children: [
                                            if (txnAmount != null)
                                              Text(
                                                'Amount: $txnAmount',
                                                style: TextStyle(
                                                  fontSize: 11.sp,
                                                  fontWeight: FontWeight.w700,
                                                  color: isDark
                                                      ? Colors.white
                                                      : Colors.black87,
                                                ),
                                              ),
                                            Text(
                                              'Method: $txnMethod',
                                              style: TextStyle(
                                                fontSize: 11.sp,
                                                color: isDark
                                                    ? Colors.white70
                                                    : Colors.black54,
                                              ),
                                            ),
                                            Text(
                                              'Status: ${txnStatus.toUpperCase()}',
                                              style: TextStyle(
                                                fontSize: 11.sp,
                                                fontWeight: FontWeight.w700,
                                                color: isPendingVerification
                                                    ? const Color(0xFFD97706)
                                                    : const Color(0xFF16A34A),
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
                          ],

                          SizedBox(height: 12.h),

                          // Progress Bar & Step Tracker
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 14.w),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Step $currentStep of 5: ${_getStepTitle(currentStep)}',
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF1B3A5C),
                                      ),
                                    ),
                                    Text(
                                      '$progressPercent%',
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF1B3A5C),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 6.h),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4.r),
                                  child: LinearProgressIndicator(
                                    value: progressPercent / 100,
                                    minHeight: 7.h,
                                    backgroundColor: isDark
                                        ? const Color(0xFF27272A)
                                        : const Color(0xFFE2E8F0),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      progressPercent == 100
                                          ? const Color(0xFF16A34A)
                                          : const Color(0xFF1B3A5C),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 12.h),
                          const Divider(height: 1),

                          // VERTICAL FULL-WIDTH ACTION BUTTONS
                          // (Stacked vertically with full width so nobody misses them!)
                          Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 14.w, vertical: 10.h),
                            child: Column(
                              children: [
                                // Primary Action Button (Full Width)
                                SizedBox(
                                  width: double.infinity,
                                  height: 44.h,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1B3A5C),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10.r),
                                      ),
                                    ),
                                    onPressed: () =>
                                        _showApplicationDetailSheet(
                                            context, item, isDark),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.folder_open_rounded,
                                            size: 18),
                                        SizedBox(width: 8.w),
                                        const Text(
                                          'Manage Application & Procedure Steps',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        SizedBox(width: 6.w),
                                        const Icon(
                                            Icons.arrow_forward_ios_rounded,
                                            size: 12),
                                      ],
                                    ),
                                  ),
                                ),

                                // Quick Advance Shortcut Button (Full Width)
                                if (currentStep < 5) ...[
                                  SizedBox(height: 8.h),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 40.h,
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(
                                          color: const Color(0xFF1B3A5C)
                                              .withValues(alpha: 0.3),
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10.r),
                                        ),
                                      ),
                                      icon: const Icon(
                                          Icons.fast_forward_rounded,
                                          size: 16,
                                          color: Color(0xFF1B3A5C)),
                                      label: Text(
                                        'Quick Advance: Move to Step ${currentStep + 1} (${_getStepTitle(currentStep + 1)})',
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF1B3A5C),
                                        ),
                                      ),
                                      onPressed: () => _quickAdvanceStep(item),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 3. CUSTOMER FEEDBACK TAB
  // ===========================================================================
  Widget _buildFeedbackTab(bool isDark, Color cardBg) {
    if (_isLoadingFeedback) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredFeedback = _feedback.where((f) {
      final comments = (f['comments']?.toString() ?? '').toLowerCase();
      final tag = (f['standout_tag']?.toString() ?? '').toLowerCase();
      final profile = f['profiles'] as Map<String, dynamic>?;
      final app = f['applications'] as Map<String, dynamic>?;

      final name = ((f['applicant_name'] ??
                  profile?['full_name'] ??
                  f['user_name'])
              ?.toString() ??
          '')
          .toLowerCase();
      final email = ((f['applicant_email'] ??
                  profile?['email'] ??
                  f['user_email'])
              ?.toString() ??
          '')
          .toLowerCase();
      final phone = ((f['applicant_phone'] ??
                  profile?['phone'] ??
                  f['user_phone'])
              ?.toString() ??
          '')
          .toLowerCase();
      final ref = ((app?['reference_number'] ?? f['app_reference'])
              ?.toString() ??
          '')
          .toLowerCase();
      final title = ((app?['title'] ?? f['visa_title'])?.toString() ?? '')
          .toLowerCase();
      final rating = (f['rating'] as num?)?.toInt() ?? 5;

      final q = _feedbackSearchQuery.toLowerCase();
      final matchesQuery = q.isEmpty ||
          comments.contains(q) ||
          tag.contains(q) ||
          name.contains(q) ||
          email.contains(q) ||
          phone.contains(q) ||
          ref.contains(q) ||
          title.contains(q);

      final matchesRating = _selectedFeedbackRating == null ||
          rating == _selectedFeedbackRating;

      return matchesQuery && matchesRating;
    }).toList();

    final totalCount = _feedback.length;
    final avgRating = totalCount == 0
        ? 0.0
        : _feedback.fold<double>(
                0,
                (sum, item) =>
                    sum + ((item['rating'] as num?)?.toDouble() ?? 5.0)) /
            totalCount;
    final fiveStarCount = _feedback.where((i) => i['rating'] == 5).length;

    return Column(
      children: [
        // 1. Executive Feedback Metrics Banner
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 4.h),
          child: Wrap(
            spacing: 8.w,
            runSpacing: 6.h,
            children: [
              _buildMetricChip(
                label: 'Total Reviews',
                count: '$totalCount',
                color: const Color(0xFF1B3A5C),
                icon: Icons.reviews_rounded,
                isDark: isDark,
              ),
              _buildMetricChip(
                label: 'Average Score',
                count: '${avgRating.toStringAsFixed(1)} ★',
                color: const Color(0xFFD97706),
                icon: Icons.star_rounded,
                isDark: isDark,
              ),
              _buildMetricChip(
                label: '5-Star Reviews',
                count: '$fiveStarCount',
                color: const Color(0xFF16A34A),
                icon: Icons.thumb_up_rounded,
                isDark: isDark,
              ),
            ],
          ),
        ),

        // 2. Search & Rating Filter Chips (All vertically visible, NO horizontal scroll!)
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                onChanged: (val) => setState(() => _feedbackSearchQuery = val),
                decoration: InputDecoration(
                  hintText:
                      'Search feedback by client name, email, or comment...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _feedbackSearchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () =>
                              setState(() => _feedbackSearchQuery = ''),
                        )
                      : null,
                  filled: true,
                  fillColor: cardBg,
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 0, horizontal: 16.w),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(
                      color: isDark
                          ? const Color(0xFF27272A)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 8.h),

              Text(
                'Filter by Rating:',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? const Color(0xFFA1A1AA)
                      : const Color(0xFF475569),
                ),
              ),
              SizedBox(height: 6.h),

              Wrap(
                spacing: 8.w,
                runSpacing: 6.h,
                children: [
                  ChoiceChip(
                    label: const Text('ALL RATINGS'),
                    selected: _selectedFeedbackRating == null,
                    selectedColor: const Color(0xFF1B3A5C),
                    labelStyle: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: _selectedFeedbackRating == null
                          ? Colors.white
                          : (isDark ? Colors.white70 : Colors.black87),
                    ),
                    onSelected: (_) =>
                        setState(() => _selectedFeedbackRating = null),
                  ),
                  ...[5, 4, 3, 2, 1].map((rating) {
                    final isSelected = _selectedFeedbackRating == rating;
                    return ChoiceChip(
                      avatar: Icon(Icons.star_rounded,
                          size: 14.sp,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFFF59E0B)),
                      label: Text('$rating STARS'),
                      selected: isSelected,
                      selectedColor: const Color(0xFFD97706),
                      labelStyle: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.white70 : Colors.black87),
                      ),
                      onSelected: (_) => setState(() =>
                          _selectedFeedbackRating = isSelected ? null : rating),
                    );
                  }),
                ],
              ),
            ],
          ),
        ),

        // 3. Feedback List View
        Expanded(
          child: filteredFeedback.isEmpty
              ? _buildEmptyState(
                  icon: Icons.rate_review_outlined,
                  title: 'No client feedback found',
                  subtitle:
                      'Customer ratings and reviews submitted from the mobile app will be displayed here with full details.',
                )
              : ListView.separated(
                  padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 24.h),
                  itemCount: filteredFeedback.length,
                  separatorBuilder: (_, __) => SizedBox(height: 14.h),
                  itemBuilder: (context, index) {
                    final item = filteredFeedback[index];
                    final rating = (item['rating'] as num?)?.toInt() ?? 5;
                    final standoutTag = item['standout_tag']?.toString() ??
                        'Accurate Guidance';
                    final comments = item['comments']?.toString() ?? '';
                    final createdAt = item['created_at'];

                    final profile = item['profiles'] as Map<String, dynamic>?;
                    final app = item['applications'] as Map<String, dynamic>?;

                    final clientName = (item['applicant_name'] ??
                            profile?['full_name'] ??
                            item['user_name'])
                        ?.toString() ??
                        'Client Applicant';
                    final clientEmail = (item['applicant_email'] ??
                            profile?['email'] ??
                            item['user_email'])
                        ?.toString() ??
                        'No email provided';
                    final clientPhone = (item['applicant_phone'] ??
                            profile?['phone'] ??
                            item['user_phone'])
                        ?.toString() ??
                        'No phone';
                    final appRef = (app?['reference_number'] ??
                            item['app_reference'])
                        ?.toString() ??
                        '';
                    final visaTitle = (app?['title'] ??
                            item['visa_title'])
                        ?.toString() ??
                        'Visa Consultation';
                    final appId = item['application_id']?.toString();

                    return DecoratedBox(
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF27272A)
                              : const Color(0xFFE2E8F0),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? Colors.transparent
                                : Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Top Row: Star Rating + Standout Tag + Date
                            Row(
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: List.generate(
                                    5,
                                    (i) => Icon(
                                      i < rating
                                          ? Icons.star_rounded
                                          : Icons.star_border_rounded,
                                      color: const Color(0xFFF59E0B),
                                      size: 18.sp,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8.w, vertical: 3.h),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF16A34A)
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6.r),
                                    border: Border.all(
                                      color: const Color(0xFF16A34A)
                                          .withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Text(
                                    standoutTag,
                                    style: TextStyle(
                                      fontSize: 10.5.sp,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF16A34A),
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  _formatDate(createdAt),
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12.h),

                            // Applicant Name
                            Text(
                              clientName,
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                            SizedBox(height: 4.h),

                            // Visa Title and App Reference
                            Row(
                              children: [
                                Icon(Icons.flight_takeoff_rounded,
                                    size: 14.sp,
                                    color: const Color(0xFF1B3A5C)),
                                SizedBox(width: 4.w),
                                Expanded(
                                  child: Text(
                                    visaTitle,
                                    style: TextStyle(
                                      fontSize: 12.5.sp,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF1B3A5C),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (appRef.isNotEmpty) ...[
                                  SizedBox(width: 6.w),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 6.w, vertical: 2.h),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1B3A5C)
                                          .withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(4.r),
                                    ),
                                    child: Text(
                                      appRef,
                                      style: TextStyle(
                                        fontSize: 10.5.sp,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF1B3A5C),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            SizedBox(height: 10.h),

                            // Contact Details: Email & Phone
                            _buildContactRow(
                              icon: Icons.email_outlined,
                              value: clientEmail,
                              label: 'Email',
                              onCopy: () => _copyToClipboard(
                                  clientEmail, 'Email address'),
                              isDark: isDark,
                            ),
                            if (clientPhone.isNotEmpty &&
                                clientPhone != 'No phone') ...[
                              SizedBox(height: 6.h),
                              _buildContactRow(
                                icon: Icons.phone_outlined,
                                value: clientPhone,
                                label: 'Phone',
                                onCopy: () => _copyToClipboard(
                                    clientPhone, 'Phone number'),
                                isDark: isDark,
                              ),
                            ],
                            SizedBox(height: 12.h),

                            // Written Review / Comment in Quote Container
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(12.w),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF1E293B)
                                    : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(10.r),
                                border: Border(
                                  left: BorderSide(
                                    color: const Color(0xFFF59E0B),
                                    width: 3.5.w,
                                  ),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'CLIENT REVIEW:',
                                    style: TextStyle(
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFFB45309),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    comments.isNotEmpty
                                        ? '"$comments"'
                                        : '"Client finished the case successfully and gave a 5-star rating."',
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w500,
                                      color: isDark
                                          ? Colors.white70
                                          : const Color(0xFF334155),
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Action button to open matching application if exists
                            if (appId != null && appId.isNotEmpty) ...[
                              SizedBox(height: 10.h),
                              SizedBox(
                                width: double.infinity,
                                height: 38.h,
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                      color: const Color(0xFF1B3A5C)
                                          .withValues(alpha: 0.3),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(8.r),
                                    ),
                                  ),
                                  icon: const Icon(
                                      Icons.folder_shared_rounded,
                                      size: 15,
                                      color: Color(0xFF1B3A5C)),
                                  label: const Text(
                                    'Open Linked Application Dossier →',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1B3A5C),
                                    ),
                                  ),
                                  onPressed: () {
                                    final matching = _applications.firstWhere(
                                      (a) => a['id'] == appId,
                                      orElse: () => {
                                        'id': appId,
                                        'applicant_name': clientName,
                                        'applicant_email': clientEmail,
                                        'applicant_phone': clientPhone,
                                        'title': visaTitle,
                                        'reference_number': appRef,
                                        'status': 'completed',
                                        'current_step': 5,
                                      },
                                    );
                                    _showApplicationDetailSheet(
                                        context, matching, isDark);
                                  },
                                ),
                              ),
                            ],
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

  // ===========================================================================
  // 4. APPLICATION DETAIL SHEET (VERTICAL INTERACTIVE STEPPER & ACTIONS)
  // ===========================================================================
  void _showApplicationDetailSheet(
    BuildContext context,
    Map<String, dynamic> app,
    bool isDark,
  ) {
    final appId = app['id'] as String;
    int currentStep = app['current_step'] as int? ?? 1;
    String currentStatus = app['status'] as String? ?? 'submitted';
    final formData = app['form_data'] as Map<String, dynamic>? ?? {};
    final appliedAt = app['applied_at'] ?? app['created_at'];

    final paymentsList = app['payments'] as List<dynamic>? ?? [];
    final paymentMap = paymentsList.isNotEmpty && paymentsList.first is Map
        ? Map<String, dynamic>.from(paymentsList.first as Map)
        : null;

    final txnId = (paymentMap?['transaction_id']
                    ?.toString()
                    .trim()
                    .isNotEmpty ??
                false)
        ? paymentMap!['transaction_id'].toString().trim()
        : (formData['transaction_ref'] ??
                formData['transaction_id'] ??
                formData['txn_id'])
            ?.toString()
            .trim();

    final txnAmount = paymentMap?['amount'] != null
        ? '${paymentMap!['currency'] ?? 'PKR'} ${paymentMap['amount']}'
        : (formData['fee'] ?? formData['amount']) != null
            ? 'PKR ${formData['fee'] ?? formData['amount']}'
            : null;

    final txnMethod = paymentMap?['payment_method']?.toString() ??
        formData['payment_method']?.toString() ??
        'Bank Transfer';

    final txnStatus = paymentMap?['status']?.toString() ??
        (formData['payment_verified'] == true ? 'completed' : 'pending');

    final passport = (app['applicant_passport']
                    ?.toString()
                    .trim()
                    .isNotEmpty ??
                false)
        ? app['applicant_passport'].toString().trim()
        : (formData['passport_number'] ?? formData['passport'])
            ?.toString()
            .trim();

    final nationality = formData['nationality']?.toString().trim();

    Map<String, dynamic>? clientFeedback;
    bool isLoadingFeedback = true;
    bool hasFetchedFeedback = false;
    bool showRawJson = false;
    bool isSheetMounted = true;

    // Steps definition with detailed procedure roadmap
    final procedureSteps = [
      (
        step: 1,
        title: 'Profile Review & Intake',
        subtitle:
            'Initial file assessment, basic credentials screening, and candidate profile evaluation.'
      ),
      (
        step: 2,
        title: 'Consultancy Call',
        subtitle:
            'One-on-one expert consultation session, visa roadmap planning, and tailored advisory.'
      ),
      (
        step: 3,
        title: 'Ready Case & Documents',
        subtitle:
            'Case dossier preparation, verified document collation, certifications, and compliance check.'
      ),
      (
        step: 4,
        title: 'Embassy Filing & Submission',
        subtitle:
            'Official application lodgement, appointment biometric scheduling, and embassy tracking.'
      ),
      (
        step: 5,
        title: 'Feedback & Case Completed',
        subtitle:
            'Final visa issuance or closeout, client rating, review collection, and file archived (100%).'
      ),
    ];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22.r)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            if (!hasFetchedFeedback) {
              hasFetchedFeedback = true;
              SupabaseDatabaseService.instance
                  .getApplicationFeedback(appId)
                  .then((res) {
                if (!isSheetMounted) return;
                res.fold(
                  (_) {
                    if (isSheetMounted) {
                      setModalState(() => isLoadingFeedback = false);
                    }
                  },
                  (fb) {
                    if (isSheetMounted) {
                      setModalState(() {
                        clientFeedback = fb;
                        isLoadingFeedback = false;
                      });
                    }
                  },
                );
              }).catchError((_) {
                if (isSheetMounted) {
                  setModalState(() => isLoadingFeedback = false);
                }
              });
            }

            final isPendingVerification = _isPendingVerification(app);

            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.90,
              child: Column(
                children: [
                  // Modal Top Drag Handle & Title
                  Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 8.h),
                    child: Column(
                      children: [
                        Container(
                          width: 40.w,
                          height: 4.h,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade400,
                            borderRadius: BorderRadius.circular(2.r),
                          ),
                        ),
                        SizedBox(height: 10.h),
                        Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Applicant File & Procedure',
                                  style: TextStyle(
                                    fontSize: 17.sp,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF0F172A),
                                  ),
                                ),
                                Text(
                                  'Ref: ${app['reference_number'] ?? 'N/A'}',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1B3A5C),
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  // Scrollable Body
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                          horizontal: 16.w, vertical: 12.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. STICKY TOP PAYMENT VERIFICATION BANNER (IF PENDING)
                          if (isPendingVerification) ...[
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(14.w),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFFBEB),
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(
                                    color: const Color(0xFFF59E0B), width: 1.5),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.warning_amber_rounded,
                                          color: Color(0xFFB45309), size: 22),
                                      SizedBox(width: 8),
                                      Text(
                                        'Payment Awaiting Verification',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14,
                                          color: Color(0xFFB45309),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 6.h),
                                  Text(
                                    'The applicant chose bank transfer and is waiting for payment confirmation. Click below to verify and unlock full tracking for the client.',
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      color: const Color(0xFF78350F),
                                    ),
                                  ),
                                  SizedBox(height: 10.h),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 42.h,
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF16A34A),
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10.r),
                                        ),
                                      ),
                                      icon: const Icon(
                                          Icons.check_circle_rounded,
                                          size: 18),
                                      label: const Text(
                                        'Verify & Approve Payment Now',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w700),
                                      ),
                                      onPressed: () async {
                                        final res =
                                            await SupabaseDatabaseService
                                                .instance
                                                .verifyBankTransferPaymentAdmin(
                                          applicationId: appId,
                                        );
                                        res.fold(
                                          (f) => showToast(context,
                                              message: f.message,
                                              status: 'error'),
                                          (_) {
                                            Navigator.pop(context);
                                            showToast(
                                              context,
                                              message:
                                                  'Payment verified! Client tracking unlocked.',
                                              status: 'success',
                                            );
                                            _loadApplications();
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 16.h),
                          ],

                          // 2. Primary Applicant Profile Card
                          Container(
                            padding: EdgeInsets.all(14.w),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF18181B)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF27272A)
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: const Color(0xFF1B3A5C),
                                      radius: 18.r,
                                      child: Text(
                                        (app['applicant_name'] as String? ??
                                                'A')
                                            .substring(0, 1)
                                            .toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 10.w),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            app['applicant_name'] ??
                                                'Unnamed Applicant',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 15.sp,
                                            ),
                                          ),
                                          Text(
                                            app['title'] ?? 'Visa Case',
                                            style: TextStyle(
                                              fontSize: 12.sp,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFF1B3A5C),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 10.h),
                                const Divider(height: 1),
                                SizedBox(height: 10.h),
                                _buildDetailRow(
                                    'Email', app['applicant_email'] ?? 'N/A'),
                                SizedBox(height: 4.h),
                                _buildDetailRow(
                                    'Phone', app['applicant_phone'] ?? 'N/A'),
                                if (passport != null && passport.isNotEmpty) ...[
                                  SizedBox(height: 4.h),
                                  _buildDetailRow('Passport #', passport),
                                ],
                                if (nationality != null &&
                                    nationality.isNotEmpty) ...[
                                  SizedBox(height: 4.h),
                                  _buildDetailRow('Nationality', nationality),
                                ],
                                if (txnId != null) ...[
                                  SizedBox(height: 4.h),
                                  _buildDetailRow(
                                      'Transaction Fee #', txnId),
                                ],
                                if (txnAmount != null) ...[
                                  SizedBox(height: 4.h),
                                  _buildDetailRow(
                                      'Fee Amount & Method',
                                      '$txnAmount ($txnMethod)'),
                                ],
                                SizedBox(height: 4.h),
                                _buildDetailRow(
                                    'Payment Status', txnStatus.toUpperCase()),
                                SizedBox(height: 4.h),
                                _buildDetailRow(
                                    'Applied On', _formatDate(appliedAt)),
                                SizedBox(height: 4.h),
                                _buildDetailRow('Reference',
                                    app['reference_number'] ?? 'N/A'),
                              ],
                            ),
                          ),

                          SizedBox(height: 18.h),

                          // 3. VERTICAL INTERACTIVE PROCEDURE STEPPER
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Procedure Roadmap (1 - 5)',
                                style: TextStyle(
                                  fontSize: 14.5.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8.w, vertical: 3.h),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1B3A5C)
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6.r),
                                ),
                                child: Text(
                                  'Current: Step $currentStep',
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF1B3A5C),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 6.h),
                          Text(
                            'Tap any step below to select it as the active procedure stage for this applicant.',
                            style: TextStyle(
                              fontSize: 11.5.sp,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          SizedBox(height: 10.h),

                          // Vertical Step Cards
                          Column(
                            children: procedureSteps.map((s) {
                              final isSelected = currentStep == s.step;
                              final isPast = s.step < currentStep;

                              return InkWell(
                                onTap: () =>
                                    setModalState(() => currentStep = s.step),
                                borderRadius: BorderRadius.circular(12.r),
                                child: Container(
                                  margin: EdgeInsets.only(bottom: 8.h),
                                  padding: EdgeInsets.all(12.w),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFF1B3A5C)
                                            .withValues(alpha: 0.08)
                                        : (isDark
                                            ? const Color(0xFF18181B)
                                            : Colors.white),
                                    borderRadius: BorderRadius.circular(12.r),
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFF1B3A5C)
                                          : (isPast
                                              ? const Color(0xFF16A34A)
                                                  .withValues(alpha: 0.4)
                                              : (isDark
                                                  ? const Color(0xFF27272A)
                                                  : const Color(0xFFE2E8F0))),
                                      width: isSelected ? 1.8 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Step Badge
                                      CircleAvatar(
                                        radius: 14.r,
                                        backgroundColor: isSelected
                                            ? const Color(0xFF1B3A5C)
                                            : (isPast
                                                ? const Color(0xFF16A34A)
                                                : const Color(0xFFE2E8F0)),
                                        child: isPast
                                            ? const Icon(Icons.check_rounded,
                                                size: 16, color: Colors.white)
                                            : Text(
                                                '${s.step}',
                                                style: TextStyle(
                                                  color: isSelected
                                                      ? Colors.white
                                                      : const Color(0xFF475569),
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 12.sp,
                                                ),
                                              ),
                                      ),
                                      SizedBox(width: 10.w),
                                      // Step Info
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    s.title,
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      fontSize: 13.5.sp,
                                                      color: isSelected
                                                          ? const Color(
                                                              0xFF1B3A5C)
                                                          : (isDark
                                                              ? Colors.white
                                                              : const Color(
                                                                  0xFF0F172A)),
                                                    ),
                                                  ),
                                                ),
                                                if (isSelected)
                                                  Container(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            horizontal: 6.w,
                                                            vertical: 2.h),
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                          0xFF1B3A5C),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              4.r),
                                                    ),
                                                    child: Text(
                                                      'SELECTED',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 9.sp,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            SizedBox(height: 3.h),
                                            Text(
                                              s.subtitle,
                                              style: TextStyle(
                                                fontSize: 11.5.sp,
                                                color: isDark
                                                    ? const Color(0xFFA1A1AA)
                                                    : const Color(0xFF64748B),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),

                          // Quick Step Advancer Shortcut
                          if (currentStep < 5) ...[
                            SizedBox(height: 4.h),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(10.r)),
                                  side: BorderSide(
                                    color: const Color(0xFF1B3A5C)
                                        .withValues(alpha: 0.3),
                                  ),
                                ),
                                icon: const Icon(Icons.arrow_forward_rounded,
                                    size: 16, color: Color(0xFF1B3A5C)),
                                label: Text(
                                  'Advance to Next Step (Step ${currentStep + 1}: ${_getStepTitle(currentStep + 1)})',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF1B3A5C),
                                  ),
                                ),
                                onPressed: () {
                                  setModalState(
                                      () => currentStep = currentStep + 1);
                                },
                              ),
                            ),
                          ],

                          SizedBox(height: 18.h),

                          // 4. Overall Status Selector
                          Text(
                            'Overall Application Status',
                            style: TextStyle(
                              fontSize: 14.5.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          DropdownButtonFormField<String>(
                            initialValue: currentStatus,
                            items: const [
                              DropdownMenuItem(
                                  value: 'submitted',
                                  child: Text('Submitted (Profile Review)')),
                              DropdownMenuItem(
                                  value: 'in_progress',
                                  child: Text('In Progress (Active Case)')),
                              DropdownMenuItem(
                                  value: 'approved',
                                  child: Text('Approved (Ready)')),
                              DropdownMenuItem(
                                  value: 'completed',
                                  child: Text('Completed (100% Finalized)')),
                              DropdownMenuItem(
                                  value: 'rejected',
                                  child: Text('Rejected / Closed')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setModalState(() => currentStatus = val);
                              }
                            },
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.r)),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12.w, vertical: 10.h),
                            ),
                          ),

                          SizedBox(height: 18.h),

                          // 5. Client Feedback & Rating Section
                          Text(
                            'Client Feedback & Rating (Step 5)',
                            style: TextStyle(
                              fontSize: 14.5.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(12.w),
                            decoration: BoxDecoration(
                              color: clientFeedback != null
                                  ? (isDark
                                      ? const Color(0xFF0F291E)
                                      : const Color(0xFFE8F5E9))
                                  : (isDark
                                      ? const Color(0xFF18181B)
                                      : const Color(0xFFF8FAFC)),
                              borderRadius: BorderRadius.circular(10.r),
                              border: Border.all(
                                color: clientFeedback != null
                                    ? const Color(0xFF2E7D32)
                                        .withValues(alpha: 0.3)
                                    : (isDark
                                        ? const Color(0xFF27272A)
                                        : const Color(0xFFE2E8F0)),
                              ),
                            ),
                            child: isLoadingFeedback
                                ? const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(8),
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    ),
                                  )
                                : clientFeedback != null
                                    ? Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(Icons.stars_rounded,
                                                  color: Color(0xFFF59E0B),
                                                  size: 20),
                                              SizedBox(width: 6.w),
                                              Text(
                                                '${clientFeedback?['rating'] ?? 5}.0 / 5.0 Rating',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 13.sp,
                                                  color:
                                                      const Color(0xFF2E7D32),
                                                ),
                                              ),
                                              const Spacer(),
                                              Container(
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 8.w,
                                                    vertical: 3.h),
                                                decoration: BoxDecoration(
                                                  color:
                                                      const Color(0xFF2E7D32),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          12.r),
                                                ),
                                                child: Text(
                                                  '100% Completed',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10.sp,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 8.h),
                                          Text(
                                            'Standout Highlight: ${clientFeedback?['standout_tag'] ?? 'N/A'}',
                                            style: TextStyle(
                                                fontSize: 12.sp,
                                                fontWeight: FontWeight.w600),
                                          ),
                                          SizedBox(height: 4.h),
                                          Text(
                                            '"${clientFeedback?['comments'] ?? 'No text review'}"',
                                            style: TextStyle(
                                              fontSize: 12.sp,
                                              fontStyle: FontStyle.italic,
                                              color: isDark
                                                  ? Colors.white70
                                                  : const Color(0xFF334155),
                                            ),
                                          ),
                                        ],
                                      )
                                    : Row(
                                        children: [
                                          Icon(Icons.info_outline_rounded,
                                              size: 16.sp,
                                              color: const Color(0xFF94A3B8)),
                                          SizedBox(width: 6.w),
                                          Expanded(
                                            child: Text(
                                              'No feedback submitted yet (Applicant currently on Step $currentStep).',
                                              style: TextStyle(
                                                fontSize: 12.sp,
                                                color: const Color(0xFF64748B),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                          ),

                          SizedBox(height: 18.h),

                          // 6. Form Submission Data & Payload
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Submitted Form Details',
                                style: TextStyle(
                                  fontSize: 14.5.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (formData.isNotEmpty)
                                TextButton.icon(
                                  style: TextButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  icon: Icon(
                                    showRawJson
                                        ? Icons.table_chart_rounded
                                        : Icons.code_rounded,
                                    size: 16,
                                  ),
                                  label: Text(
                                    showRawJson ? 'Card View' : 'View Raw JSON',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  onPressed: () => setModalState(
                                      () => showRawJson = !showRawJson),
                                ),
                            ],
                          ),
                          SizedBox(height: 6.h),
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(12.w),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF18181B)
                                  : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10.r),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF27272A)
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: formData.isEmpty
                                ? const Text(
                                    'No additional form payload submitted.')
                                : showRawJson
                                    ? Text(
                                        const JsonEncoder.withIndent('  ')
                                            .convert(formData),
                                        style: TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 11.sp,
                                          color: isDark
                                              ? Colors.white70
                                              : Colors.black87,
                                        ),
                                      )
                                    : _buildFormattedFormData(formData, isDark),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Save Action Bar
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF18181B) : Colors.white,
                      border: Border(
                        top: BorderSide(
                          color: isDark
                              ? const Color(0xFF27272A)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48.h,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B3A5C),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        onPressed: () async {
                          final stepText = _getStepDescription(currentStep);
                          final progressPercent =
                              (currentStep * 20).clamp(0, 100);

                          final res = await SupabaseDatabaseService.instance
                              .updateApplicationStepAndStatus(
                            appId,
                            newStep: currentStep,
                            newStatus: currentStatus,
                            stepText: stepText,
                            progressPercent: progressPercent,
                          );

                          res.fold(
                            (f) => showToast(context,
                                message: f.message, status: 'error'),
                            (_) {
                              Navigator.pop(context);
                              showToast(
                                context,
                                message:
                                    'Application updated to Step $currentStep ($currentStatus)',
                                status: 'success',
                              );
                              _loadApplications();
                            },
                          );
                        },
                        child: Text(
                          'Save Step $currentStep & Status Update',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      isSheetMounted = false;
    });
  }

  // ===========================================================================
  // 4. ADD / EDIT VISA DIALOG
  // ===========================================================================
  void _showAddEditVisaDialog(
    BuildContext context, {
    Map<String, dynamic>? existingVisa,
    required bool isDark,
  }) {
    final isEditing = existingVisa != null;
    final titleController =
        TextEditingController(text: existingVisa?['title'] ?? '');
    final subtitleController =
        TextEditingController(text: existingVisa?['subtitle'] ?? '');
    final countryNameController =
        TextEditingController(text: existingVisa?['country_name'] ?? '');
    final countryIdController =
        TextEditingController(text: existingVisa?['country_id'] ?? '');
    final durationController = TextEditingController(
        text: existingVisa?['processing_time'] ?? '3-4 weeks');
    final validityController = TextEditingController(
        text: existingVisa?['validity'] ?? 'Up to 2 Years');
    final approvalRateController = TextEditingController(
        text: existingVisa?['approval_rate'] ?? '95% approved');
    final badgeTextController =
        TextEditingController(text: existingVisa?['badge_text'] ?? '');

    // Extract Consultancy Fee (payable to SB Consultants in-app)
    String initConsultancyFee = 'PKR 35,000';
    if (existingVisa != null) {
      if (existingVisa['service_fee_value'] != null &&
          existingVisa['service_fee_value'].toString().trim().isNotEmpty) {
        initConsultancyFee =
            existingVisa['service_fee_value'].toString().trim();
      } else if (existingVisa['total_payable'] != null &&
          existingVisa['total_payable'].toString().trim().isNotEmpty) {
        initConsultancyFee = existingVisa['total_payable'].toString().trim();
      } else if (existingVisa['fee'] != null &&
          existingVisa['fee'].toString().trim().isNotEmpty &&
          (existingVisa['fee'].toString().contains('PKR') ||
              existingVisa['fee'].toString().contains('Rs'))) {
        initConsultancyFee = existingVisa['fee'].toString().trim();
      }
    }
    final consultancyFeeController =
        TextEditingController(text: initConsultancyFee);
    final salaryController = TextEditingController(
      text: (existingVisa?['salary'] ??
              existingVisa?['salary_or_funding'] ??
              existingVisa?['salary_range'] ??
              '')
          .toString(),
    );

    String selectedCategory =
        (existingVisa?['category_id'] as String?) ?? 'visit';
    bool isActive = existingVisa?['is_active'] as bool? ?? true;
    bool isFeatured = existingVisa?['is_featured'] as bool? ?? false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16.w,
                right: 16.w,
                top: 20.h,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20.h,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          isEditing
                              ? 'Edit Visa Record'
                              : 'Add New Visa Record',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w700,
                            color:
                                isDark ? Colors.white : const Color(0xFF171C21),
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),

                    // Category Selector
                    Text('Category',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13.sp)),
                    SizedBox(height: 4.h),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      items: const [
                        DropdownMenuItem(
                            value: 'visit', child: Text('Visit Visa')),
                        DropdownMenuItem(
                            value: 'study', child: Text('Study Visa')),
                        DropdownMenuItem(
                            value: 'work', child: Text('Work Visa')),
                        DropdownMenuItem(
                            value: 'business', child: Text('Business Visa')),
                        DropdownMenuItem(
                            value: 'golden', child: Text('Golden Visa')),
                        DropdownMenuItem(
                            value: 'sponsored_jobs',
                            child: Text('Sponsored Jobs / Direct Placement')),
                        DropdownMenuItem(
                            value: 'scholarships',
                            child: Text('Scholarships / Grants')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() {
                            selectedCategory = val;
                            if (val == 'sponsored_jobs' &&
                                salaryController.text.trim().isEmpty) {
                              salaryController.text = '£36,000 – £44,000 / yr';
                            }
                            if (val == 'scholarships' &&
                                salaryController.text.trim().isEmpty) {
                              salaryController.text = '100% Fully Funded';
                            }
                          });
                        }
                      },
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.r)),
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 12.w, vertical: 10.h),
                      ),
                    ),
                    SizedBox(height: 12.h),

                    // Title
                    Text('Visa Title',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13.sp)),
                    SizedBox(height: 4.h),
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        hintText: 'e.g. UK Skilled Worker Visa',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.r)),
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 12.w, vertical: 10.h),
                      ),
                    ),
                    SizedBox(height: 12.h),

                    // Subtitle / Description
                    Text('Subtitle / Short Details',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13.sp)),
                    SizedBox(height: 4.h),
                    TextField(
                      controller: subtitleController,
                      decoration: InputDecoration(
                        hintText:
                            'e.g. United Kingdom • Direct Settlement Route',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.r)),
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 12.w, vertical: 10.h),
                      ),
                    ),
                    SizedBox(height: 12.h),

                    // Country Name & Code Row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Country Name',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13.sp)),
                              SizedBox(height: 4.h),
                              TextField(
                                controller: countryNameController,
                                decoration: InputDecoration(
                                  hintText: 'e.g. United Kingdom',
                                  border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(10.r)),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12.w, vertical: 10.h),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Country Code',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13.sp)),
                              SizedBox(height: 4.h),
                              TextField(
                                controller: countryIdController,
                                decoration: InputDecoration(
                                  hintText: 'e.g. uk or GB',
                                  border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(10.r)),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12.w, vertical: 10.h),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),

                    // Processing Time & Validity Row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Processing Time',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13.sp)),
                              SizedBox(height: 4.h),
                              TextField(
                                controller: durationController,
                                decoration: InputDecoration(
                                  hintText: 'e.g. 3-4 weeks',
                                  border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(10.r)),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12.w, vertical: 10.h),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Validity',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13.sp)),
                              SizedBox(height: 4.h),
                              TextField(
                                controller: validityController,
                                decoration: InputDecoration(
                                  hintText: 'e.g. Up to 5 Years',
                                  border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(10.r)),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12.w, vertical: 10.h),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),

                    // Approval Rate & Badge Text Row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Approval Rate',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13.sp)),
                              SizedBox(height: 4.h),
                              TextField(
                                controller: approvalRateController,
                                decoration: InputDecoration(
                                  hintText: 'e.g. 96% approved',
                                  border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(10.r)),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12.w, vertical: 10.h),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Badge Text (Optional)',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13.sp)),
                              SizedBox(height: 4.h),
                              TextField(
                                controller: badgeTextController,
                                decoration: InputDecoration(
                                  hintText: 'e.g. Popular, High Demand',
                                  border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(10.r)),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12.w, vertical: 10.h),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 14.h),

                    // SALARY PER ANNUM SECTION (Matches Flutter mobile app!)
                    Builder(
                      builder: (context) {
                        final isJob = selectedCategory == 'sponsored_jobs' ||
                            selectedCategory == 'work' ||
                            titleController.text.toLowerCase().contains('job') ||
                            titleController.text.toLowerCase().contains('sponsored');
                        final isScholarship = selectedCategory == 'scholarships' ||
                            titleController.text.toLowerCase().contains('scholarship');

                        if (isJob) {
                          return Container(
                            margin: EdgeInsets.only(bottom: 14.h),
                            padding: EdgeInsets.all(12.w),
                            decoration: BoxDecoration(
                              color: const Color(0xFF16A34A).withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10.r),
                              border: Border.all(
                                color: const Color(0xFF16A34A).withValues(alpha: 0.3),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.payments_rounded,
                                        color: const Color(0xFF16A34A), size: 18.sp),
                                    SizedBox(width: 6.w),
                                    Text(
                                      'Salary Per Annum (As Displayed in App)',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13.sp,
                                        color: const Color(0xFF16A34A),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 6.h),
                                TextField(
                                  controller: salaryController,
                                  decoration: InputDecoration(
                                    hintText:
                                        r'e.g. £36,000 – £44,000 / yr or CAD$85,000 / yr',
                                    filled: true,
                                    fillColor: isDark ? const Color(0xFF18181B) : Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8.r),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12.w,
                                      vertical: 10.h,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  'Appears prominently on the job listing card and the Salary (Per Annum) section in the mobile app.',
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          );
                        } else if (isScholarship) {
                          return Container(
                            margin: EdgeInsets.only(bottom: 14.h),
                            padding: EdgeInsets.all(12.w),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00897B).withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10.r),
                              border: Border.all(
                                color: const Color(0xFF00897B).withValues(alpha: 0.3),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.school_rounded,
                                        color: const Color(0xFF00897B), size: 18.sp),
                                    SizedBox(width: 6.w),
                                    Text(
                                      'Scholarship Funding / Grant Status',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13.sp,
                                        color: const Color(0xFF00897B),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 6.h),
                                TextField(
                                  controller: salaryController,
                                  decoration: InputDecoration(
                                    hintText: 'e.g. 100% Fully Funded / Free Tuition + Stipend',
                                    filled: true,
                                    fillColor: isDark ? const Color(0xFF18181B) : Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8.r),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12.w,
                                      vertical: 10.h,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return Padding(
                          padding: EdgeInsets.only(bottom: 14.h),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Salary Per Annum (Optional / If Job Route)',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600, fontSize: 13.sp)),
                              SizedBox(height: 4.h),
                              TextField(
                                controller: salaryController,
                                decoration: InputDecoration(
                                  hintText: 'e.g. £34,000 / yr (leave empty if not applicable)',
                                  prefixIcon: const Icon(Icons.payments_outlined, size: 18),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10.r)),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12.w, vertical: 10.h),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    // Visa Service Fee Input (Fee breakdown removed)
                    Builder(
                      builder: (context) {
                        final isJob = selectedCategory == 'sponsored_jobs';
                        final isScholarship = selectedCategory == 'scholarships';
                        final feeLabel = isScholarship
                            ? 'Consultancy / Application Fee (Optional — Free in App)'
                            : isJob
                                ? 'Consultancy Processing Fee (Optional — Free in App)'
                                : 'Visa Service Fee (PKR)';
                        final feeHint = (isJob || isScholarship)
                            ? 'e.g. Free or PKR 0'
                            : 'e.g. PKR 35,000';

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(feeLabel,
                                style: TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 13.sp)),
                            SizedBox(height: 4.h),
                            TextField(
                              controller: consultancyFeeController,
                              decoration: InputDecoration(
                                hintText: feeHint,
                                prefixIcon: const Icon(
                                  Icons.payments_rounded,
                                  color: Color(0xFF1B3A5C),
                                ),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.r)),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12.w, vertical: 10.h),
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              'Note: Embassy fee breakdowns are removed to match the mobile app design.',
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: isDark ? Colors.white54 : const Color(0xFF64748B),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    SizedBox(height: 14.h),

                    // VERTICAL CHECKBOX TILES (Clear & visible, not shoved on the horizontal edge!)
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E1E24)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Column(
                        children: [
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text(
                              'Active in App',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            subtitle: const Text(
                              'Visa will be immediately visible to clients for applications',
                              style: TextStyle(fontSize: 11),
                            ),
                            value: isActive,
                            onChanged: (v) =>
                                setModalState(() => isActive = v ?? true),
                          ),
                          const Divider(height: 1),
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text(
                              'Featured Listing',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            subtitle: const Text(
                              'Show prominently on home screen top carousel',
                              style: TextStyle(fontSize: 11),
                            ),
                            value: isFeatured,
                            onChanged: (v) =>
                                setModalState(() => isFeatured = v ?? false),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 46.h,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B3A5C),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.r)),
                        ),
                        onPressed: () async {
                          final title = titleController.text.trim();
                          if (title.isEmpty) {
                            showToast(context,
                                message: 'Please enter a visa title',
                                status: 'error');
                            return;
                          }

                          final salaryVal = salaryController.text.trim();
                          final isJob = selectedCategory == 'sponsored_jobs' ||
                              selectedCategory == 'work' ||
                              title.toLowerCase().contains('job') ||
                              title.toLowerCase().contains('sponsored');
                          final isScholarship = selectedCategory == 'scholarships' ||
                              title.toLowerCase().contains('scholarship');

                          final consultancyFee =
                              consultancyFeeController.text.trim().isNotEmpty
                                  ? consultancyFeeController.text.trim()
                                  : (isScholarship
                                      ? 'Free'
                                      : (isJob ? 'Free / Direct' : 'PKR 35,000'));

                          final payload = <String, dynamic>{
                            'category_id': selectedCategory,
                            'title': title,
                            'subtitle': subtitleController.text.trim(),
                            'country_name': countryNameController.text.trim(),
                            'country_id': countryIdController.text.trim(),
                            'processing_time': durationController.text.trim(),
                            'validity': validityController.text.trim(),
                            'approval_rate': approvalRateController.text.trim(),
                            'fee': consultancyFee,
                            'service_fee_label': isJob
                                ? 'Direct Placement / Filing'
                                : 'SB Consultancy & Filing Fee',
                            'service_fee_value': consultancyFee,
                            'total_payable': consultancyFee,
                            'fee_breakdown': null,
                            'salary': salaryVal.isNotEmpty ? salaryVal : null,
                            'salary_or_funding':
                                salaryVal.isNotEmpty ? salaryVal : null,
                            'salary_range':
                                salaryVal.isNotEmpty ? salaryVal : null,
                            'badge_text':
                                badgeTextController.text.trim().isNotEmpty
                                    ? badgeTextController.text.trim()
                                    : (isFeatured ? 'Popular' : null),
                            'is_active': isActive,
                            'is_featured': isFeatured,
                          };

                          if (isEditing) {
                            final res = await SupabaseDatabaseService.instance
                                .updateVisaListing(
                                    existingVisa['id'] as String, payload);
                            res.fold(
                              (f) => showToast(context,
                                  message: f.message, status: 'error'),
                              (_) {
                                Navigator.pop(context);
                                showToast(context,
                                    message: 'Visa updated successfully',
                                    status: 'success');
                                _loadVisas();
                              },
                            );
                          } else {
                            final generatedId =
                                'visa-${DateTime.now().millisecondsSinceEpoch}';
                            payload['id'] = generatedId;
                            final res = await SupabaseDatabaseService.instance
                                .createVisaListing(payload);
                            res.fold(
                              (f) => showToast(context,
                                  message: f.message, status: 'error'),
                              (_) {
                                Navigator.pop(context);
                                showToast(context,
                                    message: 'New visa created successfully',
                                    status: 'success');
                                _loadVisas();
                              },
                            );
                          }
                        },
                        child: Text(
                            isEditing ? 'Save Changes' : 'Create Visa Listing'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDeleteVisa(BuildContext context, String id, String title) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Visa'),
        content: Text('Are you sure you want to permanently delete "$title"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444)),
            onPressed: () async {
              Navigator.pop(ctx);
              final res =
                  await SupabaseDatabaseService.instance.deleteVisaListing(id);
              res.fold(
                (f) => showToast(context, message: f.message, status: 'error'),
                (_) {
                  showToast(context,
                      message: 'Visa deleted successfully', status: 'success');
                  _loadVisas();
                },
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }


  // ===========================================================================
  // REUSABLE UI WIDGETS
  // ===========================================================================
  Widget _buildStatusBadge(String status) {
    Color bg = const Color(0xFFE3F2FD);
    Color text = const Color(0xFF1565C0);
    IconData icon = Icons.pending_actions_rounded;

    if (status == 'approved' || status == 'completed') {
      bg = const Color(0xFFE8F5E9);
      text = const Color(0xFF2E7D32);
      icon = Icons.check_circle_rounded;
    } else if (status == 'rejected') {
      bg = const Color(0xFFFFEBEE);
      text = const Color(0xFFC62828);
      icon = Icons.cancel_rounded;
    } else if (status == 'in_progress') {
      bg = const Color(0xFFFFF3E0);
      text = const Color(0xFFB76E00);
      icon = Icons.sync_rounded;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.sp, color: text),
          SizedBox(width: 4.w),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w800,
              color: text,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactRow({
    required IconData icon,
    required String value,
    required String label,
    required VoidCallback onCopy,
    required bool isDark,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18181B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14.sp, color: const Color(0xFF64748B)),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white70 : const Color(0xFF334155),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          InkWell(
            onTap: onCopy,
            borderRadius: BorderRadius.circular(4.r),
            child: Padding(
              padding: EdgeInsets.all(4.w),
              child: const Icon(
                Icons.copy_rounded,
                size: 14,
                color: Color(0xFF1B3A5C),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90.w,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF64748B),
            ),
          ),
        ),
        Text(': ',
            style: TextStyle(fontSize: 12.sp, color: const Color(0xFF64748B))),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPillBadge({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.sp, color: color),
          SizedBox(width: 4.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricChip({
    required String label,
    required String count,
    required Color color,
    required IconData icon,
    required bool isDark,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18181B) : Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.sp, color: color),
          SizedBox(width: 6.w),
          Text(
            '$count $label',
            style: TextStyle(
              fontSize: 11.5.sp,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white70 : const Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExecutiveStatCard({
    required String title,
    required String count,
    required Color color,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
    bool highlight = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 10.w),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.12)
              : (isDark ? const Color(0xFF18181B) : Colors.white),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected
                ? color
                : (highlight
                    ? color.withValues(alpha: 0.6)
                    : (isDark
                        ? const Color(0xFF27272A)
                        : const Color(0xFFE2E8F0))),
            width: isSelected || highlight ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.transparent
                  : Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(7.w),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(icon, size: 18.sp, color: color),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    count,
                    style: TextStyle(
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? const Color(0xFFA1A1AA)
                          : const Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormattedFormData(Map<String, dynamic> data, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: data.entries.map((e) {
        final keyClean = e.key
            .replaceAll('_', ' ')
            .split(' ')
            .map((w) =>
                w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
            .join(' ');
        final val = e.value?.toString() ?? 'N/A';

        return Padding(
          padding: EdgeInsets.symmetric(vertical: 3.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 130.w,
                child: Text(
                  keyClean,
                  style: TextStyle(
                    fontSize: 11.5.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ),
              Text(': ',
                  style: TextStyle(
                      fontSize: 11.5.sp, color: const Color(0xFF64748B))),
              Expanded(
                child: Text(
                  val,
                  style: TextStyle(
                    fontSize: 11.5.sp,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : const Color(0xFF1E293B),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 54.sp, color: const Color(0xFF94A3B8)),
            SizedBox(height: 14.h),
            Text(
              title,
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 6.h),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.sp, color: const Color(0xFF5A626A)),
            ),
          ],
        ),
      ),
    );
  }
}
