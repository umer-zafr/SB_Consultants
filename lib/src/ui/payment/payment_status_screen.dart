import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_sd_consultant/src/services/supabase_database_service.dart';
import 'package:flutter_sd_consultant/src/data/models/detail_item_model.dart';
import 'package:flutter_sd_consultant/src/imports/core_imports.dart';
import 'package:flutter_sd_consultant/src/imports/packages_imports.dart';
import 'package:flutter_sd_consultant/src/shared/helpers/reference_generator.dart';
import 'package:flutter_sd_consultant/src/ui/dashboard/my_applications_screen.dart';
import 'package:flutter_sd_consultant/src/ui/home/providers/home_provider.dart';
import 'package:flutter_sd_consultant/src/ui/profile/providers/transactions_provider.dart';

/// Payment status states supported by the application.
enum PaymentStatus {
  success,
  pending,
  failed,
}

/// Comprehensive, high-precision Payment Status screen supporting:
/// 1. Payment Successful (matching `media_1790620598075.png`)
/// 2. Payment Verification Pending (matching `media_1790620614176.png`)
/// 3. Payment Failed (ready for the upcoming prompt's screen reference)
class PaymentStatusScreen extends ConsumerStatefulWidget {
  const PaymentStatusScreen({
    super.key,
    this.initialStatus = PaymentStatus.success,
    this.item,
    this.amount,
    this.transactionId,
    this.referenceId,
    this.paymentMethod,
    this.applicationRef,
  });

  final PaymentStatus initialStatus;
  final DetailItemModel? item;
  final String? amount;
  final String? transactionId;
  final String? referenceId;
  final String? paymentMethod;
  final String? applicationRef;

  @override
  ConsumerState<PaymentStatusScreen> createState() => _PaymentStatusScreenState();
}

class _PaymentStatusScreenState extends ConsumerState<PaymentStatusScreen> {
  late PaymentStatus _currentStatus;
  bool _isCheckingStatus = false;
  bool _isRetrying = false;
  RealtimeChannel? _paymentRealtimeSub;
  RealtimeChannel? _adminBroadcastSub;
  Timer? _statusPollTimer;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.initialStatus;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_currentStatus == PaymentStatus.success) {
        _unlockDirectoryIfApplicable();
      }
      if (widget.item != null) {
        addApplicationRecord(ref, widget.item!);
      }
      recordAppTransaction(
        ref,
        title: widget.item?.title ?? 'Consultation Retainer',
        amount: _effectiveAmount,
        referenceId: widget.referenceId ?? widget.transactionId ?? 'TX-${DateTime.now().millisecondsSinceEpoch}',
        paymentMethod: widget.paymentMethod ?? 'Direct Bank Transfer (1Link IBFT)',
        status: _currentStatus == PaymentStatus.success ? 'completed' : 'pending',
        applicationRef: widget.applicationRef,
        category: widget.item?.categoryTag,
      );
      ref.read(userApplicationsListProvider.notifier).fetchLive();
      syncDirectoryUnlocks(ref);
    });

    if (_currentStatus == PaymentStatus.pending) {
      _startPendingWatcher();
    }
  }

  void _startPendingWatcher() {
    final client = SupabaseDatabaseService.instance.client;
    final user = client.auth.currentUser;

    // 1. Subscribe to instant admin approval broadcast
    try {
      _adminBroadcastSub = client.channel('admin-dashboard-realtime-channel')
        ..onBroadcast(
          event: 'payment_verified',
          callback: (payload) => _handleAdminApproval(payload),
        )
        ..onBroadcast(
          event: 'payment_approved',
          callback: (payload) => _handleAdminApproval(payload),
        )
        ..onBroadcast(
          event: 'directory_unlocked',
          callback: (payload) => _handleAdminApproval(payload),
        )
        ..subscribe();
    } catch (_) {}

    // 2. Direct postgres listener on payments table
    if (user != null) {
      try {
        _paymentRealtimeSub = client
            .channel('payment_status_${user.id}_${DateTime.now().millisecondsSinceEpoch}')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'payments',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'user_id',
                value: user.id,
              ),
              callback: (_) {
                if (mounted) _checkPaymentInDb();
              },
            )
            .subscribe();
      } catch (_) {}
    }

    // 3. Fallback polling heartbeat
    _statusPollTimer = Timer.periodic(const Duration(milliseconds: 2000), (_) {
      if (!mounted) return;
      if (_currentStatus == PaymentStatus.pending) {
        _checkPaymentInDb();
      } else {
        _statusPollTimer?.cancel();
      }
    });
  }

  void _handleAdminApproval(Map<String, dynamic> payload) {
    final targetUserId = payload['user_id']?.toString();
    final currentUser = SupabaseDatabaseService.instance.client.auth.currentUser;
    if (targetUserId != null && currentUser != null && targetUserId != currentUser.id) {
      return;
    }

    final dirType = payload['directory_type']?.toString().toLowerCase();
    if (dirType != null) {
      if (_isScholarshipPass && (dirType != 'scholarships' && dirType != 'scholarship')) return;
      if (_isJobPass && (dirType != 'sponsored_jobs' && dirType != 'job' && dirType != 'jobs')) return;
    }

    if (!mounted) return;
    setState(() {
      _currentStatus = PaymentStatus.success;
    });
    _unlockDirectoryIfApplicable();
    ref.read(userApplicationsListProvider.notifier).fetchLive();
    syncDirectoryUnlocks(ref);
    showToast(
      context,
      message: 'Payment Verified & Approved!',
      status: 'success',
    );
    _statusPollTimer?.cancel();

    if (_isJobPass) {
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) context.go(AppRoutes.sponsoredJobs);
      });
    } else if (_isScholarshipPass) {
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) context.go(AppRoutes.scholarships);
      });
    }
  }

  Future<void> _checkPaymentInDb({bool showFeedback = false}) async {
    try {
      final client = SupabaseDatabaseService.instance.client;
      final refId = widget.referenceId?.trim() ?? '';
      final txId = widget.transactionId?.trim() ?? '';
      final user = client.auth.currentUser;

      var query = client.from('payments').select('status, id, reference_id');
      final isTxUuid = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$').hasMatch(txId);
      if (refId.isNotEmpty && txId.isNotEmpty) {
        query = isTxUuid
            ? query.or('reference_id.eq.$refId,transaction_id.eq.$txId,id.eq.$txId')
            : query.or('reference_id.eq.$refId,transaction_id.eq.$txId');
      } else if (refId.isNotEmpty) {
        query = query.eq('reference_id', refId);
      } else if (txId.isNotEmpty) {
        query = isTxUuid
            ? query.or('transaction_id.eq.$txId,id.eq.$txId')
            : query.eq('transaction_id', txId);
      } else if (user != null) {
        query = query.eq('user_id', user.id);
      }

      final res = await query.order('created_at', ascending: false).limit(1);
      final list = List<Map<String, dynamic>>.from(res);
      if (list.isNotEmpty) {
        final row = list.first;
        final st = (row['status'] as String? ?? '').toLowerCase();
        if (st == 'completed' || st == 'success') {
          if (mounted) {
            setState(() {
              _currentStatus = PaymentStatus.success;
            });
            _unlockDirectoryIfApplicable();
            ref.read(userApplicationsListProvider.notifier).fetchLive();
            syncDirectoryUnlocks(ref);
            showToast(
              context,
              message: 'Payment Verified & Approved!',
              status: 'success',
            );
            _statusPollTimer?.cancel();
          }
          return;
        }
      }

      if (showFeedback && mounted) {
        showToast(
          context,
          message: 'Verification in progress. Admin is reviewing your deposit receipt.',
          status: 'info',
        );
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _statusPollTimer?.cancel();
    if (_paymentRealtimeSub != null) {
      try {
        SupabaseDatabaseService.instance.client.removeChannel(_paymentRealtimeSub!);
      } catch (_) {}
    }
    if (_adminBroadcastSub != null) {
      try {
        SupabaseDatabaseService.instance.client.removeChannel(_adminBroadcastSub!);
      } catch (_) {}
    }
    super.dispose();
  }

  bool get _isScholarshipPass {
    final item = widget.item;
    if (item == null) return false;
    final id = item.id.toLowerCase();
    final tag = item.categoryTag.toLowerCase();
    final type = item.type.toLowerCase();
    final title = item.title.toLowerCase();
    return id.contains('scholarship') ||
        tag.contains('scholarship') ||
        type.contains('scholarship') ||
        title.contains('scholarship');
  }

  bool get _isJobPass {
    final item = widget.item;
    if (item == null || _isScholarshipPass) return false;
    final id = item.id.toLowerCase();
    final tag = item.categoryTag.toLowerCase();
    final type = item.type.toLowerCase();
    final title = item.title.toLowerCase();
    return id == 'unlock-jobs-pass' ||
        tag == 'sponsored jobs' ||
        type == 'job' ||
        title.contains('sponsored job') ||
        (id.contains('job') && !id.contains('scholarship'));
  }

  void _unlockDirectoryIfApplicable() {
    if (_isScholarshipPass) {
      persistDirectoryUnlock(ref, directoryType: 'scholarships');
    } else if (_isJobPass) {
      persistDirectoryUnlock(ref, directoryType: 'sponsored_jobs');
    }
  }

  String get _effectiveAmount {
    if (widget.amount != null && widget.amount!.isNotEmpty) {
      var amt = widget.amount!.trim();
      while (amt.startsWith('PKR PKR')) {
        amt = amt.replaceFirst('PKR PKR', 'PKR');
      }
      return amt;
    }
    if (widget.item != null) {
      final item = widget.item!;
      final cat = item.categoryTag.toLowerCase();
      final title = item.title.toLowerCase();
      final type = item.type.toLowerCase();

      // 1. Sponsored Jobs fee is PKR 15,000
      if (cat.contains('job') ||
          title.contains('job') ||
          type.contains('job') ||
          title.contains('employer') ||
          title.contains('license')) {
        return 'PKR 15,000';
      }

      // 2. Scholarships fee is PKR 25,000
      if (cat.contains('scholarship') ||
          title.contains('scholarship') ||
          type.contains('scholarship')) {
        return 'PKR 25,000';
      }

      // 3. Work Visa & Golden Visa fee is PKR 40,000
      if (cat.contains('work') ||
          title.contains('work') ||
          cat.contains('golden') ||
          title.contains('golden')) {
        return 'PKR 40,000';
      }

      // 4. Visit, Business, and Study Visa fee is PKR 30,000
      if (cat.contains('visit') ||
          title.contains('visit') ||
          cat.contains('tourist') ||
          title.contains('tourist') ||
          cat.contains('business') ||
          title.contains('business') ||
          cat.contains('investor') ||
          title.contains('investor') ||
          cat.contains('study') ||
          title.contains('study') ||
          cat.contains('student') ||
          title.contains('student')) {
        return 'PKR 30,000';
      }

      if (item.serviceFeeValue.isNotEmpty &&
          !item.serviceFeeValue.toLowerCase().contains('tuition') &&
          item.serviceFeeValue.length <= 25) {
        var fee = item.serviceFeeValue.trim();
        while (fee.startsWith('PKR PKR')) {
          fee = fee.replaceFirst('PKR PKR', 'PKR');
        }
        return fee;
      }
    }
    return 'PKR 30,000';
  }
  String get _effectiveTransactionId =>
      widget.transactionId ?? 'TXN-SB-9842104';
  String get _effectiveReferenceId =>
      widget.referenceId ?? 'REF-PEND-884192';
  String get _effectiveApplicationRef {
    if (widget.applicationRef != null && widget.applicationRef!.isNotEmpty) {
      return widget.applicationRef!;
    }
    if (widget.referenceId != null && widget.referenceId!.isNotEmpty) {
      return widget.referenceId!;
    }
    if (widget.transactionId != null && widget.transactionId!.isNotEmpty) {
      return widget.transactionId!;
    }
    if (widget.item != null) {
      return ReferenceCodeGenerator.generate(
        category: widget.item!.categoryTag,
        title: widget.item!.title,
        listingId: widget.item!.id,
      );
    }
    return 'SB-VV-01';
  }
  String get _effectiveApplicationTitle =>
      widget.item?.title ?? 'Visa Application';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF7F9FF),
      appBar: _buildAppBar(context, isDark),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
          child: Column(
            children: [
              // Dynamic View based on status
              switch (_currentStatus) {
                PaymentStatus.success => _buildSuccessView(context, isDark),
                PaymentStatus.pending => _buildPendingView(context, isDark),
                PaymentStatus.failed => _buildFailedView(context, isDark),
              },
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // TOP APP BAR (Standardized clean header)
  // ===========================================================================
  PreferredSizeWidget _buildAppBar(BuildContext context, bool isDark) {
    final title = _currentStatus == PaymentStatus.success
        ? 'Payment Successful'
        : _currentStatus == PaymentStatus.pending
            ? 'Payment Pending'
            : 'Payment Failed';
    final surfaceBg = isDark ? const Color(0xFF121212) : Colors.white;
    final iconColor = isDark ? Colors.white : const Color(0xFF171C21);
    final titleColor = isDark ? Colors.white : const Color(0xFF171C21);
    final badgeBg = isDark ? const Color(0xFF18181B) : const Color(0xFFEFF3F8);
    final badgeBorder = isDark ? const Color(0xFF27272A) : const Color(0xFFDEE5EF);
    final badgeText = isDark ? const Color(0xFFA1A1AA) : const Color(0xFF1B3A5C);

    return AppBar(
      backgroundColor: surfaceBg,
      elevation: 0,
      scrolledUnderElevation: 1,
      surfaceTintColor: Colors.transparent,
      leadingWidth: 48.w,
      leading: Padding(
        padding: EdgeInsets.only(left: 8.w),
        child: Center(
          child: InkWell(
            onTap: () {
              if (_currentStatus == PaymentStatus.pending) {
                context.go(AppRoutes.dashboard);
              } else if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            },
            borderRadius: BorderRadius.circular(20.r),
            child: Icon(
              Icons.arrow_back_rounded,
              color: iconColor,
              size: 22,
            ),
          ),
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16.5.sp,
          fontWeight: FontWeight.w700,
          color: titleColor,
          letterSpacing: -0.2,
        ),
      ),
      centerTitle: true,
      actions: [
        // SSL Security Badge (Clean, without avatar)
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          margin: EdgeInsets.symmetric(vertical: 12.h),
          decoration: BoxDecoration(
            color: badgeBg,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: badgeBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.verified_user_outlined,
                size: 12.sp,
                color: badgeText,
              ),
              SizedBox(width: 3.w),
              Text(
                'SSL',
                style: TextStyle(
                  fontSize: 10.5.sp,
                  fontWeight: FontWeight.w700,
                  color: badgeText,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 14.w),
      ],
    );
  }

  // ===========================================================================
  // STATE SWITCHER BANNER (Allows instant switching between Success & Pending)
  // ===========================================================================
  // ===========================================================================
  // 1. PAYMENT SUCCESSFUL VIEW
  // ===========================================================================
  Widget _buildSuccessView(BuildContext context, bool isDark) {
    final textPrimary = isDark ? Colors.white : const Color(0xFF171C21);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF5A626A);

    return Column(
      children: [
        // 1. Progress Stepper Bar
        _buildSuccessStepper(isDark),
        SizedBox(height: 20.h),

        // 2. Concentric Circular Glowing Success Icon
        _buildSuccessGraphic(),
        SizedBox(height: 16.h),

        // 3. Headline & Subtitle
        Text(
          'Payment Successful!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 23.sp,
            fontWeight: FontWeight.w800,
            color: textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        SizedBox(height: 6.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Text(
            'Your application payment has been securely received and verified.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.sp,
              color: textSecondary,
              height: 1.35,
            ),
          ),
        ),
        SizedBox(height: 20.h),

        // 4. Transaction Receipt Card
        _buildTransactionReceiptCard(isDark),
        SizedBox(height: 16.h),

        // 5. Application Under Review Card
        _buildUnderReviewCard(isDark),
        SizedBox(height: 24.h),

        // 6. Action Buttons
        _buildSuccessActions(context, isDark),
        SizedBox(height: 16.h),

        // 7. Helpline Footer Link
        _buildHelplineFooter(context, isDark),
        SizedBox(height: 16.h),
      ],
    );
  }

  Widget _buildSuccessStepper(bool isDark) {
    final cardBg = isDark ? const Color(0xFF121212) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF27272A) : const Color(0xFFE8EEF5);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: cardBorder),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildCheckNode('Details', isDark),
            _buildCheckRail(isDark),
            _buildCheckNode('Payment', isDark),
            _buildCheckRail(isDark),
            _buildConfirmedNode('Confirmed', isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckNode(String label, bool isDark) {
    final activeColor = isDark ? const Color(0xFF3B82F6) : const Color(0xFF002444);
    final textColor = isDark ? Colors.white : const Color(0xFF171C21);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22.w,
          height: 22.w,
          decoration: BoxDecoration(
            color: activeColor,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_rounded,
            color: Colors.white,
            size: 14.sp,
          ),
        ),
        SizedBox(width: 5.w),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5.sp,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmedNode(String label, bool isDark) {
    final activeColor = isDark ? const Color(0xFF3B82F6) : const Color(0xFF002444);
    final textColor = isDark ? Colors.white : const Color(0xFF171C21);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22.w,
          height: 22.w,
          decoration: BoxDecoration(
            color: activeColor,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.verified_rounded,
            color: Colors.white,
            size: 13.sp,
          ),
        ),
        SizedBox(width: 5.w),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5.sp,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildCheckRail(bool isDark) {
    final railColor = isDark ? const Color(0xFF3B82F6) : const Color(0xFF002444);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8.w),
      width: 24.w,
      height: 2.h,
      color: railColor,
    );
  }

  Widget _buildSuccessGraphic() {
    return Center(
      child: Container(
        width: 88.w,
        height: 88.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFE3EDFA),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF002444).withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: EdgeInsets.all(8.w),
        child: Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF153353),
          ),
          padding: EdgeInsets.all(6.w),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF002444),
            ),
            child: Center(
              child: Container(
                width: 38.w,
                height: 38.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                ),
                child: Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 24.sp,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionReceiptCard(bool isDark) {
    final cardBg = isDark ? const Color(0xFF121212) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF27272A) : const Color(0xFFE8EEF5);
    final textPrimary = isDark ? Colors.white : const Color(0xFF171C21);
    final textSecondary = isDark ? const Color(0xFFA1A1AA) : const Color(0xFF5A626A);
    final dividerColor = isDark ? const Color(0xFF27272A) : const Color(0xFFF1F4F8);
    final chipBg = isDark ? const Color(0xFF18181B) : const Color(0xFFF1F5FA);
    final chipText = isDark ? const Color(0xFF60A5FA) : const Color(0xFF002444);
    final clearedBg = isDark ? const Color(0xFF1E3A8A) : const Color(0xFFD6E6FB);
    final clearedText = isDark ? const Color(0xFF93C5FD) : const Color(0xFF002444);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Receipt Card Header
          Row(
            children: [
              Icon(
                Icons.receipt_long_rounded,
                size: 19.sp,
                color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1B3A5C),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'Transaction Receipt',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: clearedBg,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  'Cleared',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: clearedText,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),

          // Amount Paid Row
          _buildReceiptRow(
            label: 'Amount Paid',
            labelColor: textSecondary,
            valueWidget: Text(
              _effectiveAmount,
              style: TextStyle(
                fontSize: 16.5.sp,
                fontWeight: FontWeight.w800,
                color: textPrimary,
              ),
            ),
          ),
          Divider(height: 20.h, color: dividerColor),

          // Transaction ID Row
          _buildReceiptRow(
            label: 'Transaction ID',
            labelColor: textSecondary,
            valueWidget: InkWell(
              onTap: () => _copyToClipboard(_effectiveTransactionId),
              borderRadius: BorderRadius.circular(6.r),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.5.h),
                decoration: BoxDecoration(
                  color: chipBg,
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _effectiveTransactionId,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Icon(
                      Icons.content_copy_rounded,
                      size: 13.sp,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF5B7FA5),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Divider(height: 20.h, color: dividerColor),

          // Payment Method Row
          _buildReceiptRow(
            label: 'Payment Method',
            labelColor: textSecondary,
            valueWidget: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.credit_card_rounded,
                  size: 16.sp,
                  color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1B3A5C),
                ),
                SizedBox(width: 5.w),
                Text(
                  widget.paymentMethod ?? 'Direct Bank Transfer (1Link IBFT)',
                  style: TextStyle(
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 20.h, color: dividerColor),

          // Date & Time Row
          _buildReceiptRow(
            label: 'Date & Time',
            labelColor: textSecondary,
            valueWidget: Text(
              'Today, 10:45 AM',
              softWrap: true,
              style: TextStyle(
                fontSize: 12.5.sp,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
          ),
          Divider(height: 20.h, color: dividerColor),

          // Application Ref Row
          _buildReceiptRow(
            label: 'Application Ref',
            labelColor: textSecondary,
            valueWidget: Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.5.h),
              decoration: BoxDecoration(
                color: chipBg,
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Text(
                _effectiveApplicationRef,
                softWrap: true,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: chipText,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptRow({
    required String label,
    required Widget valueWidget,
    Color? labelColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 4,
          child: Text(
            label,
            softWrap: true,
            style: TextStyle(
              fontSize: 13.sp,
              color: labelColor ?? const Color(0xFF5A626A),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          flex: 6,
          child: Align(
            alignment: Alignment.centerRight,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: valueWidget,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUnderReviewCard(bool isDark) {
    final cardBg = isDark ? const Color(0xFF121212) : const Color(0xFFF0F5FA);
    final cardBorder = isDark ? const Color(0xFF27272A) : const Color(0xFFDEE7F2);
    final textPrimary = isDark ? Colors.white : const Color(0xFF171C21);
    final textSecondary = isDark ? const Color(0xFFA1A1AA) : const Color(0xFF5A626A);
    final turnaroundBg = isDark ? const Color(0xFF18181B) : Colors.white;
    final turnaroundBorder = isDark ? const Color(0xFF27272A) : Colors.transparent;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36.w,
                height: 36.w,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF3B82F6) : const Color(0xFF002444),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: const Icon(
                  Icons.verified_user_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  'Application Under Review',
                  style: TextStyle(
                    fontSize: 14.5.sp,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.5.h),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF18181B) : const Color(0xFFE4E8EF),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: isDark ? const Color(0xFF27272A) : Colors.transparent,
                  ),
                ),
                child: Text(
                  'Priority',
                  style: TextStyle(
                    fontSize: 10.5.sp,
                    fontWeight: FontWeight.w700,
                    color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF43474E),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            'Your verified dossier is being queued for assigned RCIC consultant evaluation. You will receive an official SMS and email confirmation within 2 hours.',
            style: TextStyle(
              fontSize: 12.sp,
              color: textSecondary,
              height: 1.35,
            ),
          ),
          SizedBox(height: 12.h),

          // Estimated Turnaround Box
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: turnaroundBg,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: turnaroundBorder),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: 16.sp,
                  color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1B3A5C),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Estimated Turnaround',
                        softWrap: true,
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w500,
                          color: textSecondary,
                        ),
                      ),
                      Text(
                        'Tomorrow, 5:00 PM (GMT+5)',
                        softWrap: true,
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessActions(BuildContext context, bool isDark) {
    final isJobPass = _isJobPass;
    final isScholarshipPass = _isScholarshipPass;
    final primaryBtnBg = isDark ? const Color(0xFF3B82F6) : const Color(0xFF002444);

    return Column(
      children: [
        if (isJobPass) ...[
          // Primary Action: Explore Sponsored Jobs Directory
          SizedBox(
            width: double.infinity,
            height: 48.h,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBtnBg,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              onPressed: () async {
                await persistDirectoryUnlock(ref, directoryType: 'sponsored_jobs');
                if (widget.item != null) {
                  addApplicationRecord(ref, widget.item!);
                }
                ref.read(userApplicationsListProvider.notifier).fetchLive();
                if (context.mounted) {
                  context.go(AppRoutes.sponsoredJobs);
                }
              },
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Explore Sponsored Jobs Directory',
                      style: TextStyle(
                        fontSize: 14.5.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 17,
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 10.h),
          // Secondary Action: View Receipt in Dashboard
          SizedBox(
            width: double.infinity,
            height: 48.h,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: isDark ? const Color(0xFF3B82F6) : const Color(0xFF002444),
                  width: 1.4,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              onPressed: () {
                if (widget.item != null) {
                  addApplicationRecord(ref, widget.item!);
                }
                ref.read(userApplicationsListProvider.notifier).fetchLive();
                context.push(
                  AppRoutes.myApplications,
                  extra: widget.item,
                );
              },
              child: Text(
                'View Receipt in Dashboard',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF002444),
                ),
              ),
            ),
          ),
        ] else if (isScholarshipPass) ...[
          // Primary Action: Explore Scholarships Directory
          SizedBox(
            width: double.infinity,
            height: 48.h,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBtnBg,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              onPressed: () async {
                await persistDirectoryUnlock(ref, directoryType: 'scholarships');
                if (widget.item != null) {
                  addApplicationRecord(ref, widget.item!);
                }
                ref.read(userApplicationsListProvider.notifier).fetchLive();
                if (context.mounted) {
                  context.go(AppRoutes.scholarships);
                }
              },
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Explore Scholarships Directory',
                      style: TextStyle(
                        fontSize: 14.5.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 17,
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 10.h),
          // Secondary Action: View Receipt in Dashboard
          SizedBox(
            width: double.infinity,
            height: 48.h,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: isDark ? const Color(0xFF3B82F6) : const Color(0xFF002444),
                  width: 1.4,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              onPressed: () {
                if (widget.item != null) {
                  addApplicationRecord(ref, widget.item!);
                }
                ref.read(userApplicationsListProvider.notifier).fetchLive();
                context.push(
                  AppRoutes.myApplications,
                  extra: widget.item,
                );
              },
              child: Text(
                'View Receipt in Dashboard',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF002444),
                ),
              ),
            ),
          ),
        ] else ...[
          // Standard Visa Application -> View in Dashboard
          SizedBox(
            width: double.infinity,
            height: 48.h,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBtnBg,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              onPressed: () {
                if (widget.item != null) {
                  addApplicationRecord(ref, widget.item!);
                }
                ref.read(userApplicationsListProvider.notifier).fetchLive();
                context.push(
                  AppRoutes.myApplications,
                  extra: widget.item,
                );
              },
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'View Application in Dashboard',
                      style: TextStyle(
                        fontSize: 14.5.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 17,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],

        // WhatsApp Chat Support (+92 315 5440606)
        SizedBox(
          width: double.infinity,
          height: 48.h,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF25D366), width: 1.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              backgroundColor: const Color(0xFF25D366).withValues(alpha: 0.08),
            ),
            onPressed: () {
              WhatsAppHelper.launchChat(
                phone: '923155440606',
                message:
                    'Hello SB Consultants, I completed payment for $_effectiveApplicationTitle. Reference: $_effectiveReferenceId. Transaction ID: $_effectiveTransactionId. Please confirm.',
              );
            },
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_rounded,
                    color: const Color(0xFF16A34A),
                    size: 17.sp,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'Chat on WhatsApp (+92 315 5440606)',
                    style: TextStyle(
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF16A34A),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 2. PAYMENT VERIFICATION PENDING VIEW
  // ===========================================================================
  Widget _buildPendingView(BuildContext context, bool isDark) {
    final textPrimary = isDark ? Colors.white : const Color(0xFF002444);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF5A626A);

    return Column(
      children: [
        // 1. Top Reference Tag Banner
        _buildPendingTopTag(isDark),
        SizedBox(height: 20.h),

        // 2. Amber Glowing Hourglass Icon
        _buildPendingGraphic(),
        SizedBox(height: 16.h),

        // 3. Headline & Subtitle
        Text(
          'Payment Verification Pending',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22.sp,
            fontWeight: FontWeight.w800,
            color: textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        SizedBox(height: 6.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Text(
            "We're verifying your payment with the banking network. Your application is safely reserved.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.sp,
              color: textSecondary,
              height: 1.35,
            ),
          ),
        ),
        SizedBox(height: 20.h),

        // 4. Pending Details Card with Info Banner
        _buildPendingDetailsCard(isDark),
        SizedBox(height: 16.h),

        // 5. "What happens next?" Card
        _buildWhatHappensNextCard(isDark),
        SizedBox(height: 16.h),

        // 6. 1Link Gateway Health Pill
        _buildGatewayHealthCard(isDark),
        SizedBox(height: 24.h),

        // 7. Action Buttons (Check Status / Back to Dashboard)
        _buildPendingActions(context, isDark),
        SizedBox(height: 16.h),

        // 8. Bottom Proof of Payment Link
        _buildProofOfPaymentFooter(context, isDark),
        SizedBox(height: 16.h),
      ],
    );
  }

  Widget _buildPendingTopTag(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8.w,
                height: 8.w,
                decoration: const BoxDecoration(
                  color: Color(0xFFED6C02),
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  'Reference: $_effectiveReferenceId',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1B3A5C),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 8.w),
        InkWell(
          onTap: () {
            context.go(AppRoutes.dashboard);
          },
          borderRadius: BorderRadius.circular(16.r),
          child: Container(
            width: 30.w,
            height: 30.w,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF18181B) : const Color(0xFFEFF3F8),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.close_rounded,
              size: 17,
              color: isDark ? Colors.white : const Color(0xFF5A626A),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPendingGraphic() {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 90.w,
            height: 90.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFFF7E6),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFED6C02).withValues(alpha: 0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                Icons.hourglass_top_rounded,
                size: 42.sp,
                color: const Color(0xFFED6C02),
              ),
            ),
          ),
          Positioned(
            bottom: 4.h,
            right: 4.w,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.access_time_filled_rounded,
                color: const Color(0xFFED6C02),
                size: 18.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingDetailsCard(bool isDark) {
    final cardBg = isDark ? const Color(0xFF121212) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF27272A) : const Color(0xFFE8EEF5);
    final textPrimary = isDark ? Colors.white : const Color(0xFF171C21);
    final textSecondary = isDark ? const Color(0xFFA1A1AA) : const Color(0xFF5A626A);
    final dividerColor = isDark ? const Color(0xFF27272A) : const Color(0xFFF1F4F8);
    final noticeBg = isDark ? const Color(0xFF18181B) : const Color(0xFFEFF5FB);
    final noticeText = isDark ? const Color(0xFFA1A1AA) : const Color(0xFF43474E);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1Link Notice Banner
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: noticeBg,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 18.sp,
                  color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1B3A5C),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'Transactions via 1Link or Mobile Wallets can take between 5 to 15 minutes to reflect in your application portal.',
                    style: TextStyle(
                      fontSize: 11.5.sp,
                      color: noticeText,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 14.h),

          // Reference ID Row
          _buildReceiptRow(
            label: 'Reference ID',
            labelColor: textSecondary,
            valueWidget: InkWell(
              onTap: () => _copyToClipboard(_effectiveReferenceId),
              borderRadius: BorderRadius.circular(6.r),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _effectiveReferenceId,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  SizedBox(width: 5.w),
                  Icon(
                    Icons.content_copy_rounded,
                    size: 13.sp,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF5B7FA5),
                  ),
                ],
              ),
            ),
          ),
          Divider(height: 20.h, color: dividerColor),

          // Amount Payable Row
          _buildReceiptRow(
            label: 'Amount Payable',
            labelColor: textSecondary,
            valueWidget: Text(
              _effectiveAmount,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w800,
                color: textPrimary,
              ),
            ),
          ),
          Divider(height: 20.h, color: dividerColor),

          // Payment Channel Row
          _buildReceiptRow(
            label: 'Payment Channel',
            labelColor: textSecondary,
            valueWidget: Text(
              widget.paymentMethod ?? 'Easypaisa / 1Link Bank Transfer',
              softWrap: true,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12.5.sp,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
          ),
          Divider(height: 20.h, color: dividerColor),

          // Current Status Row
          _buildReceiptRow(
            label: 'Current Status',
            labelColor: textSecondary,
            valueWidget: Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6.w,
                    height: 6.w,
                    decoration: const BoxDecoration(
                      color: Color(0xFFED6C02),
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    'Awaiting Bank Settlement',
                    style: TextStyle(
                      fontSize: 10.5.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFB76E00),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhatHappensNextCard(bool isDark) {
    final cardBg = isDark ? const Color(0xFF121212) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF27272A) : const Color(0xFFE8EEF5);
    final textPrimary = isDark ? Colors.white : const Color(0xFF171C21);
    final badgeBg = isDark ? const Color(0xFF18181B) : const Color(0xFFEFF3F8);
    final badgeText = isDark ? const Color(0xFFA1A1AA) : const Color(0xFF5A626A);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'What happens next?',
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(6.r),
                  border: Border.all(
                    color: isDark ? const Color(0xFF27272A) : Colors.transparent,
                  ),
                ),
                child: Text(
                  'Automated',
                  style: TextStyle(
                    fontSize: 10.5.sp,
                    fontWeight: FontWeight.w700,
                    color: badgeText,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),

          // Step 1: Confirmation Ping
          _buildNextStepItem(
            icon: Icons.notifications_none_rounded,
            title: 'Confirmation Ping',
            description:
                "Once the funds clear, your application status automatically switches to 'Under Review'.",
            isDark: isDark,
          ),
          SizedBox(height: 12.h),

          // Step 2: Receipt by Email
          _buildNextStepItem(
            icon: Icons.receipt_long_rounded,
            title: 'Receipt by Email',
            description:
                'An official FBR-compliant tax invoice and SB Consultants receipt will be dispatched to your registered email.',
            isDark: isDark,
          ),
          SizedBox(height: 12.h),

          // Step 3: No Duplicate Charges
          _buildNextStepItem(
            icon: Icons.security_rounded,
            title: 'No Duplicate Charges',
            description:
                'Please do not re-submit payment while this transaction is processing to prevent accidental holds.',
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildNextStepItem({
    required IconData icon,
    required String title,
    required String description,
    required bool isDark,
  }) {
    final iconBg = isDark ? const Color(0xFF18181B) : const Color(0xFFEFF4FA);
    final iconColor = isDark ? const Color(0xFF60A5FA) : const Color(0xFF1B3A5C);
    final textPrimary = isDark ? Colors.white : const Color(0xFF171C21);
    final textSecondary = isDark ? const Color(0xFFA1A1AA) : const Color(0xFF5A626A);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32.w,
          height: 32.w,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color: isDark ? const Color(0xFF27272A) : Colors.transparent,
            ),
          ),
          child: Icon(
            icon,
            size: 16.sp,
            color: iconColor,
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                description,
                style: TextStyle(
                  fontSize: 11.5.sp,
                  color: textSecondary,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGatewayHealthCard(bool isDark) {
    final cardBg = isDark ? const Color(0xFF121212) : const Color(0xFFF7F9FC);
    final cardBorder = isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : const Color(0xFF171C21);
    final textSecondary = isDark ? const Color(0xFFA1A1AA) : const Color(0xFF5A626A);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8.w,
                  height: 8.w,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2E7D32),
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    '1Link Gateway Health',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Text(
            'Normal Traffic (99.8%)',
            style: TextStyle(
              fontSize: 11.5.sp,
              fontWeight: FontWeight.w600,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingActions(BuildContext context, bool isDark) {
    final primaryBtnBg = isDark ? const Color(0xFF3B82F6) : const Color(0xFF002444);
    final secondaryBtnBg = isDark ? const Color(0xFF18181B) : const Color(0xFFEAEFF6);
    final secondaryBtnText = isDark ? Colors.white : const Color(0xFF171C21);

    return Column(
      children: [
        // Primary Button: Check Verification Status
        SizedBox(
          width: double.infinity,
          height: 48.h,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBtnBg,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            onPressed: () async {
              setState(() => _isCheckingStatus = true);
              await _checkPaymentInDb(showFeedback: true);
              if (mounted) setState(() => _isCheckingStatus = false);
            },
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isCheckingStatus)
                    SizedBox(
                      width: 16.w,
                      height: 16.w,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  else
                    const Icon(
                      Icons.refresh_rounded,
                      size: 18,
                    ),
                  SizedBox(width: 8.w),
                  Text(
                    'Check Verification Status',
                    style: TextStyle(
                      fontSize: 14.5.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: 10.h),

        // Secondary Button: Back to Applications Dashboard
        SizedBox(
          width: double.infinity,
          height: 48.h,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: secondaryBtnBg,
              foregroundColor: secondaryBtnText,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
                side: BorderSide(
                  color: isDark ? const Color(0xFF27272A) : Colors.transparent,
                ),
              ),
            ),
            onPressed: () => context.go(AppRoutes.dashboard),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.dashboard_outlined,
                    size: 18.sp,
                    color: secondaryBtnText,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'Go to Applications Dashboard',
                    style: TextStyle(
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.w700,
                      color: secondaryBtnText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProofOfPaymentFooter(BuildContext context, bool isDark) {
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF5A626A);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Text(
        'Your bank transfer receipt is safely recorded and queued for admin verification. Once verified, your application tracking details will unlock automatically in real-time.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12.sp,
          color: textSecondary,
          height: 1.45,
        ),
      ),
    );
  }

  // ===========================================================================
  // 3. PAYMENT FAILED VIEW
  // ===========================================================================
  Widget _buildFailedView(BuildContext context, bool isDark) {
    final textPrimary = isDark ? Colors.white : const Color(0xFF002444);
    final textSecondary = isDark ? const Color(0xFFA1A1AA) : const Color(0xFF43474E);
    final cardBg = isDark ? const Color(0xFF121212) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF27272A) : const Color(0xFFE8EEF5);
    final innerBg = isDark ? const Color(0xFF18181B) : const Color(0xFFF0F4FA);
    final detailLabel = isDark ? const Color(0xFFA1A1AA) : const Color(0xFF3D6186);
    final detailVal = isDark ? Colors.white : const Color(0xFF171C21);
    final primaryBtnBg = isDark ? const Color(0xFF3B82F6) : const Color(0xFF002444);
    final secondaryBtnBg = isDark ? const Color(0xFF18181B) : const Color(0xFFE4E8EF);
    final secondaryBtnText = isDark ? Colors.white : const Color(0xFF002444);

    return Column(
      children: [
        // Subtle Top Decorative Gradient Bar
        Container(
          width: double.infinity,
          height: 3.h,
          margin: EdgeInsets.only(bottom: 16.h),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0x4DBA1A1A),
                Color(0xFFBA1A1A),
                Color(0x4DBA1A1A),
              ],
            ),
          ),
        ),

        // Hero Section
        Center(
          child: SizedBox(
            width: 88.w,
            height: 88.w,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer soft halo
                Container(
                  width: 88.w,
                  height: 88.w,
                  decoration: const BoxDecoration(
                    color: Color(0x33FFDAD6),
                    shape: BoxShape.circle,
                  ),
                ),
                // Mid ring
                Container(
                  width: 72.w,
                  height: 72.w,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFDAD6),
                    shape: BoxShape.circle,
                  ),
                ),
                // Inner white circle with error icon
                Container(
                  width: 44.w,
                  height: 44.w,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFBA1A1A).withValues(alpha: 0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.error_outline_rounded,
                      color: Color(0xFFBA1A1A),
                      size: 26,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 14.h),
        Text(
          'Payment Failed',
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.w700,
            color: textPrimary,
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 6.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Text(
            "We couldn't process your transaction. No funds were debited from your account.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5.sp,
              color: textSecondary,
              height: 1.4,
            ),
          ),
        ),
        SizedBox(height: 20.h),

        // Failure Reason & Transaction Summary Card
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: cardBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 18,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Error Badge & Attempt
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFDAD6),
                        borderRadius: BorderRadius.circular(999.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.cancel_rounded,
                            size: 14.sp,
                            color: const Color(0xFF93000A),
                          ),
                          SizedBox(width: 5.w),
                          Flexible(
                            child: Text(
                              'Declined by Issuing Bank',
                              softWrap: true,
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF93000A),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'Attempt #1',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF3D6186),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Text(
                'Your card issuer reported an authentication failure or insufficient international e-commerce limit. Please ensure your online banking session is active.',
                style: TextStyle(
                  fontSize: 13.sp,
                  color: textSecondary,
                  height: 1.45,
                ),
              ),
              SizedBox(height: 14.h),
              // Inner low container with key details
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: innerBg,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          flex: 4,
                          child: Text(
                            'Attempted Amount',
                            softWrap: true,
                            style: TextStyle(
                              fontSize: 12.5.sp,
                              color: detailLabel,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Flexible(
                          flex: 6,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              _effectiveAmount,
                              softWrap: true,
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w800,
                                color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF002444),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          flex: 4,
                          child: Text(
                            'Payment Method',
                            softWrap: true,
                            style: TextStyle(
                              fontSize: 12.5.sp,
                              color: detailLabel,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Flexible(
                          flex: 6,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Icon(
                                Icons.credit_card_rounded,
                                size: 15.sp,
                                color: detailLabel,
                              ),
                              SizedBox(width: 5.w),
                              Flexible(
                                child: Text(
                                  'Card ending in 8102',
                                  softWrap: true,
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w600,
                                    color: detailVal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          flex: 4,
                          child: Text(
                            'Reference Code',
                            softWrap: true,
                            style: TextStyle(
                              fontSize: 12.5.sp,
                              color: detailLabel,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Flexible(
                          flex: 6,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 6.w, vertical: 2.h),
                              decoration: BoxDecoration(
                                color: const Color(0x66FFDAD6),
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                              child: Text(
                                'ERR_AUTH_TIMEOUT_502',
                                softWrap: true,
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFBA1A1A),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          flex: 4,
                          child: Text(
                            'Timestamp',
                            softWrap: true,
                            style: TextStyle(
                              fontSize: 12.5.sp,
                              color: detailLabel,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Flexible(
                          flex: 6,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              'Today, 10:48 AM',
                              softWrap: true,
                              style: TextStyle(
                                fontSize: 12.5.sp,
                                fontWeight: FontWeight.w600,
                                color: detailVal,
                              ),
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
        SizedBox(height: 16.h),

        // Suggested Remedies Card
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: cardBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 18,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline_rounded,
                    size: 20.sp,
                    color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF002444),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'How to resolve this',
                    style: TextStyle(
                      fontSize: 15.5.sp,
                      fontWeight: FontWeight.w700,
                      color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF002444),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              _buildRemedyItem(
                icon: Icons.credit_score_rounded,
                title: 'Check e-commerce authorization',
                description:
                    'Ensure online/international transactions are activated in your banking app.',
                isDark: isDark,
              ),
              SizedBox(height: 14.h),
              _buildRemedyItem(
                icon: Icons.password_rounded,
                title: 'Verify 3D Secure OTP',
                description:
                    'Double-check CVV and submit the SMS authentication OTP within 120 seconds.',
                isDark: isDark,
              ),
              SizedBox(height: 14.h),
              _buildRemedyItem(
                icon: Icons.sync_alt_rounded,
                title: 'Switch payment channel',
                description:
                    '1Link IBFT or ATM Transfer provides instant clearance.',
                isDark: isDark,
              ),
            ],
          ),
        ),
        SizedBox(height: 20.h),

        // Interactive Primary Actions
        SizedBox(
          width: double.infinity,
          height: 48.h,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBtnBg,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            onPressed: () async {
              setState(() => _isRetrying = true);
              await Future<void>.delayed(const Duration(milliseconds: 1400));
              if (!context.mounted) return;
              setState(() => _isRetrying = false);
              showToast(
                context,
                message:
                    'Reconnecting with payment gateway. Please re-enter card CVV.',
                status: 'info',
              );
            },
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isRetrying)
                    SizedBox(
                      width: 16.w,
                      height: 16.w,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  else
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Try Again',
                          style: TextStyle(
                            fontSize: 14.5.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: 10.h),
        SizedBox(
          width: double.infinity,
          height: 48.h,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: secondaryBtnBg,
              foregroundColor: secondaryBtnText,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
                side: BorderSide(
                  color: isDark ? const Color(0xFF27272A) : Colors.transparent,
                ),
              ),
            ),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(
                  AppRoutes.applicantDetails,
                  extra: widget.item,
                );
              }
            },
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 18,
                    color: secondaryBtnText,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'Choose Another Payment Method',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: secondaryBtnText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: 18.h),

        // Live Support Hotline / WhatsApp Support
        InkWell(
          onTap: () {
            WhatsAppHelper.launchChat(
              phone: '923155440606',
              message:
                  'Hello SB Consultants, my payment attempt failed for $_effectiveApplicationTitle. Reference: $_effectiveReferenceId. Please guide me.',
            );
          },
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_rounded,
                    size: 16.sp,
                    color: const Color(0xFF16A34A),
                  ),
                  SizedBox(width: 5.w),
                  Flexible(
                    child: Text(
                      'Chat on WhatsApp Support: +92 315 5440606',
                      softWrap: true,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF16A34A),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 3.h),
              Text(
                '24/7 Dedicated Client Escalation Desk • Instant WhatsApp Response',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF73777F),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 20.h),
      ],
    );
  }

  Widget _buildRemedyItem({
    required IconData icon,
    required String title,
    required String description,
    required bool isDark,
  }) {
    final textPrimary = isDark ? Colors.white : const Color(0xFF171C21);
    final textSecondary = isDark ? const Color(0xFFA1A1AA) : const Color(0xFF43474E);
    final iconBg = isDark ? const Color(0xFF18181B) : const Color(0xFFD0E4FF);
    final iconColor = isDark ? const Color(0xFF60A5FA) : const Color(0xFF001D34);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30.w,
          height: 30.w,
          decoration: BoxDecoration(
            color: iconBg,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              icon,
              size: 16.sp,
              color: iconColor,
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13.5.sp,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // HELPERS
  // ===========================================================================
  Widget _buildHelplineFooter(BuildContext context, bool isDark) {
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF43474E);
    final linkColor = isDark ? const Color(0xFF60A5FA) : const Color(0xFF002444);

    return InkWell(
      onTap: () {
        showToast(
          context,
          message: 'Connecting to 24/7 Visa Helpline (+92 42 111-SB-VISA)',
          status: 'info',
        );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.headset_mic_rounded,
            size: 15.sp,
            color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1B3A5C),
          ),
          SizedBox(width: 5.w),
          Flexible(
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: TextStyle(
                  fontSize: 12.sp,
                  color: textSecondary,
                ),
                children: [
                  const TextSpan(text: 'Need assistance? '),
                  TextSpan(
                    text: 'Contact 24/7 Visa Helpline',
                    style: TextStyle(
                      color: linkColor,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    showToast(
      context,
      message: 'Copied to clipboard: $text',
      status: 'success',
    );
  }
}
