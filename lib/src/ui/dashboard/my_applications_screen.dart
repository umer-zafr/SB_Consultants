import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_sd_consultant/src/data/models/detail_item_model.dart';
import 'package:flutter_sd_consultant/src/imports/packages_imports.dart';
import 'package:flutter_sd_consultant/src/routing/app_routes.dart';
import 'package:flutter_sd_consultant/src/services/supabase_database_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_sd_consultant/src/shared/helpers/show_toast.dart';
import 'package:flutter_sd_consultant/src/shared/widgets/app_dashboard_bottom_nav.dart';
import 'package:flutter_sd_consultant/src/ui/home/providers/home_provider.dart';

/// Data model representing an application tracking entry in My Applications.
class ApplicationRecordItem {
  ApplicationRecordItem({
    required this.id,
    this.listingId,
    required this.categoryType,
    required this.categoryIcon,
    required this.title,
    required this.reference,
    required this.statusLabel,
    required this.statusBgColor,
    required this.statusTextColor,
    required this.leftStripeColor,
    this.subtitle,
    this.stepText,
    this.progressPercent,
    this.progressBarColor,
    this.hasAlert = false,
    this.alertTitle,
    this.alertBody,
    this.bodyText,
    required this.appliedDateOrStatus,
    required this.actionLabel,
    this.actionIsRed = false,
    this.actionIsNavy = false,
    this.externalUrl,
  });

  final String id;
  final String? listingId;
  final String categoryType;
  final IconData categoryIcon;
  final String title;
  final String reference;
  final String statusLabel;
  final int statusBgColor;
  final int statusTextColor;
  final int leftStripeColor;
  final String? subtitle;
  final String? stepText;
  final int? progressPercent;
  final int? progressBarColor;
  final bool hasAlert;
  final String? alertTitle;
  final String? alertBody;
  final String? bodyText;
  final String appliedDateOrStatus;
  final String actionLabel;
  final bool actionIsRed;
  final bool actionIsNavy;
  final String? externalUrl;

    ApplicationRecordItem copyWith({
    String? id,
    String? listingId,
    String? categoryType,
    IconData? categoryIcon,
    String? title,
    String? reference,
    String? statusLabel,
    int? statusBgColor,
    int? statusTextColor,
    int? leftStripeColor,
    String? subtitle,
    String? stepText,
    int? progressPercent,
    int? progressBarColor,
    bool? hasAlert,
    String? alertTitle,
    String? alertBody,
    String? bodyText,
    String? appliedDateOrStatus,
    String? actionLabel,
    bool? actionIsRed,
    bool? actionIsNavy,
    String? externalUrl,
  }) {
    return ApplicationRecordItem(
      id: id ?? this.id,
      listingId: listingId ?? this.listingId,
      categoryType: categoryType ?? this.categoryType,
      categoryIcon: categoryIcon ?? this.categoryIcon,
      title: title ?? this.title,
      reference: reference ?? this.reference,
      statusLabel: statusLabel ?? this.statusLabel,
      statusBgColor: statusBgColor ?? this.statusBgColor,
      statusTextColor: statusTextColor ?? this.statusTextColor,
      leftStripeColor: leftStripeColor ?? this.leftStripeColor,
      subtitle: subtitle ?? this.subtitle,
      stepText: stepText ?? this.stepText,
      progressPercent: progressPercent ?? this.progressPercent,
      progressBarColor: progressBarColor ?? this.progressBarColor,
      hasAlert: hasAlert ?? this.hasAlert,
      alertTitle: alertTitle,
      alertBody: alertBody,
      bodyText: bodyText ?? this.bodyText,
      appliedDateOrStatus: appliedDateOrStatus ?? this.appliedDateOrStatus,
      actionLabel: actionLabel ?? this.actionLabel,
      actionIsRed: actionIsRed ?? this.actionIsRed,
      actionIsNavy: actionIsNavy ?? this.actionIsNavy,
      externalUrl: externalUrl ?? this.externalUrl,
    );
  }

  bool get isApproved {
    final l = statusLabel.toLowerCase();
    return l.contains('approved') || l.contains('completed') || (progressPercent ?? 0) >= 100;
  }

  /// Returns true if this application's payment is unverified / awaiting admin approval
  bool get isPaymentPending {
    if (isApproved || isCompleted) return false;
    final l = statusLabel.toLowerCase();
    if (l.contains('payment pending') ||
        l.contains('payment under verification') ||
        l.contains('awaiting payment') ||
        l.contains('payment unverified')) {
      return true;
    }
    if (hasAlert == true) {
      final a = (alertTitle ?? '').toLowerCase();
      final b = (alertBody ?? '').toLowerCase();
      if (a.contains('payment pending') ||
          a.contains('payment verification') ||
          a.contains('unverified payment') ||
          b.contains('payment is currently being reviewed')) {
        return true;
      }
    }
    return false;
  }

  /// Returns true if this application has completed the entire 5-step process
  bool get isCompleted {
    final l = statusLabel.toLowerCase();
    return (progressPercent ?? 0) >= 100 ||
        l.contains('100%') ||
        l.contains('completed');
  }
}

ApplicationRecordItem _applicationFromRow(Map<String, dynamic> row) {
  final cat = (row['category_type'] as String? ?? 'VISA').toUpperCase();
  IconData icon = Icons.school_outlined;
  if (cat.contains('SCHOLARSHIP')) {
    icon = Icons.military_tech_outlined;
  } else if (cat.contains('JOB') || cat.contains('OPPORTUNITY')) {
    icon = Icons.apartment_rounded;
  } else if (cat.contains('BUSINESS')) {
    icon = Icons.work_outline_rounded;
  } else if (cat.contains('WORK')) {
    icon = Icons.badge_outlined;
  }

  final step = (row['current_step'] as int?) ?? 1;
  final dbStatus = (row['status'] as String? ?? '').toLowerCase();
  final formData = row['form_data'] as Map<String, dynamic>?;

  // Strict payment verification check:
  // If payment is explicitly marked verified in formData OR payment_status is completed/approved/success/paid OR status is approved/completed OR admin moved beyond step 1:
  final paymentStatus = (row['payment_status'] as String? ?? '').toLowerCase();
  final bool isExplicitlyVerified = (formData?['payment_verified'] == true) ||
      paymentStatus == 'completed' ||
      paymentStatus == 'approved' ||
      paymentStatus == 'success' ||
      paymentStatus == 'paid' ||
      dbStatus == 'approved' ||
      dbStatus == 'completed' ||
      step > 1;

  final bool isPaymentUnverified = !isExplicitlyVerified &&
      (row['has_alert'] == true ||
          (row['alert_title'] as String? ?? '').toLowerCase().contains('payment'));

  final is100Done = !isPaymentUnverified && (step >= 5 ||
      dbStatus == 'completed' ||
      ((row['progress_percent'] as num?)?.toInt() ?? 0) >= 100);
  final progress = isPaymentUnverified
      ? 15
      : (is100Done
          ? 100
          : (((row['progress_percent'] as num?)?.toInt()) ?? (step * 20)));

  String appliedText = 'Applied Today';
  final rawDate = row['applied_at'] as String?;
  if (rawDate != null) {
    try {
      final dt = DateTime.parse(rawDate);
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      appliedText = 'Applied ${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {}
  }

  final String statusLabel;
  final int statusBgColor;
  final int statusTextColor;
  const String actionLabel = 'View Details';

  if (isPaymentUnverified) {
    statusLabel = 'Payment Pending';
    statusBgColor = 0xFFFFF8E1;
    statusTextColor = 0xFFB76E00;
  } else if (is100Done) {
    statusLabel = '✓ 100% Completed';
    statusBgColor = 0xFFD9E8F9;
    statusTextColor = 0xFF1B5299;
  } else if (step >= 5 || dbStatus == 'approved') {
    statusLabel = '✓ Approved';
    statusBgColor = 0xFFDCFCE7;
    statusTextColor = 0xFF15803D;
  } else {
    statusLabel = row['status_label'] as String? ?? '• In Progress';
    statusBgColor = (row['status_bg_color'] as num?)?.toInt() ?? 0xFFEDF3F9;
    statusTextColor = (row['status_text_color'] as num?)?.toInt() ?? 0xFF3D6186;
  }

  final defaultStepText = isPaymentUnverified
      ? 'Payment Verification Pending (Awaiting Admin)'
      : (is100Done
          ? 'Step 5 of 5: Feedback & Case Rating (Completed)'
          : 'Step $step of 5: Profile Review');
  final stepText = row['step_text'] as String? ?? defaultStepText;

  return ApplicationRecordItem(
    id: row['id'] as String,
    listingId: row['listing_id'] as String?,
    categoryType: cat,
    categoryIcon: icon,
    title: row['title'] as String? ?? 'Visa Application',
    reference: row['reference_number'] != null
        ? 'Ref: ${row['reference_number']}'
        : 'Ref: SB-2026-${row['id'].toString().substring(0, 4)}',
    statusLabel: statusLabel,
    statusBgColor: statusBgColor,
    statusTextColor: statusTextColor,
    leftStripeColor: isPaymentUnverified ? 0xFFED6C02 : 0xFF002444,
    subtitle: row['subtitle'] as String?,
    stepText: stepText,
    progressPercent: progress,
    hasAlert: isPaymentUnverified || (row['has_alert'] == true),
    alertTitle: isPaymentUnverified
        ? 'Payment Verification Pending'
        : row['alert_title'] as String?,
    alertBody: isPaymentUnverified
        ? 'Your application payment is currently being reviewed by admin. Full procedure steps will unlock once verified.'
        : row['alert_body'] as String?,
    appliedDateOrStatus: appliedText,
    actionLabel: actionLabel,
  );
}

class UserApplicationsNotifier extends StateNotifier<List<ApplicationRecordItem>> {
  UserApplicationsNotifier()
      : super(const []) {
    _initAuthListener();
    _initLiveApplications();
  }

  StreamSubscription<AuthState>? _authSub;
  StreamSubscription<List<Map<String, dynamic>>>? _streamSub;
  RealtimeChannel? _broadcastChannel;
  final List<ApplicationRecordItem> _localApplications = [];

  void _initAuthListener() {
    try {
      _authSub = SupabaseDatabaseService.instance.client.auth.onAuthStateChange.listen((data) {
        if (data.session == null || data.event == AuthChangeEvent.signedOut) {
          // Clear old local cache ONLY on explicit logout or session expiry
          _localApplications.clear();
          _streamSub?.cancel();
          _streamSub = null;
          state = const [];
        } else if (data.event == AuthChangeEvent.signedIn ||
            data.event == AuthChangeEvent.userUpdated) {
          _initLiveApplications();
        }
      });
    } catch (_) {}
  }

  static String normalizeTitle(String s) {
    return s
        .toLowerCase()
        .replaceAll('– application', '')
        .replaceAll('- application', '')
        .replaceAll('application', '')
        .replaceAll('visa', '')
        .replaceAll(RegExp(r'[^a-z0-9]'), '')
        .trim();
  }

  void add(ApplicationRecordItem item) {
    final cat = item.categoryType.toUpperCase();
    final title = item.title.toUpperCase();
    final id = item.id.toLowerCase();
    final listingId = (item.listingId ?? '').toLowerCase();

    // Strict Rule: Scholarships and Sponsored Jobs (and unlock passes) NEVER show in App Dashboard
    final isScholarshipOrJob = cat.contains('SCHOLARSHIP') ||
        cat.contains('JOB') ||
        cat.contains('SPONSORED') ||
        cat.contains('OPPORTUNITY') ||
        title.contains('SCHOLARSHIP') ||
        title.contains('SPONSORED JOB') ||
        title.contains('UNLOCK') ||
        id.contains('scholarship') ||
        id.contains('job') ||
        id.contains('unlock') ||
        listingId.contains('scholarship') ||
        listingId.contains('job') ||
        listingId.contains('unlock');

    if (isScholarshipOrJob) return;

    final itemNorm = normalizeTitle(item.title);
    if (_localApplications.any((a) {
      if (a.id == item.id) return true;
      if (a.listingId != null && a.listingId == item.id) return true;
      final aNorm = normalizeTitle(a.title);
      return aNorm == itemNorm ||
          (aNorm.isNotEmpty && itemNorm.isNotEmpty && (aNorm.contains(itemNorm) || itemNorm.contains(aNorm)));
    })) {
      return;
    }
    _localApplications.insert(0, item);
    _mergeAndEmit(state);
  }

  void clearAll() {
    _localApplications.clear();
    state = const [];
  }

  void _mergeAndEmit(List<ApplicationRecordItem> remoteItems) {
    // Database rows are the single source of truth - strictly filter out non-visas
    final map = <String, ApplicationRecordItem>{};
    for (final remote in remoteItems) {
      final cat = remote.categoryType.toUpperCase();
      final title = remote.title.toUpperCase();
      final id = remote.id.toLowerCase();
      final listingId = (remote.listingId ?? '').toLowerCase();

      final isScholarshipOrJob = cat.contains('SCHOLARSHIP') ||
          cat.contains('JOB') ||
          cat.contains('SPONSORED') ||
          cat.contains('OPPORTUNITY') ||
          title.contains('SCHOLARSHIP') ||
          title.contains('SPONSORED JOB') ||
          title.contains('UNLOCK') ||
          id.contains('scholarship') ||
          id.contains('job') ||
          id.contains('unlock') ||
          listingId.contains('scholarship') ||
          listingId.contains('job') ||
          listingId.contains('unlock');

      if (!isScholarshipOrJob) {
        map[remote.id] = remote;
      }
    }

    // Clean up local applications that already have matching remote counterparts
    _localApplications.removeWhere((local) {
      final lNorm = normalizeTitle(local.title);
      return remoteItems.any((r) {
        if (r.id == local.id) return true;
        if (r.listingId != null && r.listingId == local.id) return true;
        if (local.listingId != null && local.listingId == r.listingId) return true;
        final rNorm = normalizeTitle(r.title);
        return rNorm == lNorm ||
            (rNorm.isNotEmpty && lNorm.isNotEmpty && (rNorm.contains(lNorm) || lNorm.contains(rNorm)));
      });
    });

    // Include any locally added items that haven't synchronized to remote yet
    for (final local in _localApplications) {
      if (!map.containsKey(local.id)) {
        map[local.id] = local;
      }
    }
    state = map.values.toList();
  }

  void _initLiveApplications() {
    _streamSub?.cancel();
    _streamSub = null;

    try {
      final client = SupabaseDatabaseService.instance.client;
      final user = client.auth.currentUser;

      if (user == null) {
        _mergeAndEmit(const <ApplicationRecordItem>[]);
        return;
      }

      // Initial direct fetch strictly for this user
      fetchLive();

      // Realtime stream strictly for this user
      _streamSub = client
          .from('applications')
          .stream(primaryKey: ['id'])
          .eq('user_id', user.id)
          .listen((rows) {
        final filteredRows = rows.where((r) {
          final uid = r['user_id'] as String?;
          final fd = r['form_data'] as Map?;
          final isArchived = (fd?['is_deleted'] == true) || (fd?['is_archived'] == true);
          final cat = (r['category_type']?.toString() ?? '').toUpperCase();
          final title = (r['title']?.toString() ?? '').toUpperCase();
          final listingId = (r['listing_id']?.toString() ?? '').toLowerCase();

          // Exclude scholarships and sponsored jobs from App Dashboard
          final isScholarshipOrJob = cat.contains('SCHOLARSHIP') ||
              cat.contains('JOB') ||
              cat.contains('SPONSORED') ||
              cat.contains('OPPORTUNITY') ||
              title.contains('SCHOLARSHIP') ||
              title.contains('SPONSORED JOB') ||
              title.contains('UNLOCK') ||
              listingId.contains('scholarship') ||
              listingId.contains('job') ||
              listingId.contains('unlock') ||
              listingId.contains('pass');

          return uid == user.id && !isArchived && !isScholarshipOrJob;
        }).toList();

        _mergeAndEmit(filteredRows.map(_applicationFromRow).toList());
      }, onError: (err) {
        debugPrint('[MyApplications] applications stream notice: $err');
      }, cancelOnError: false);

      // Real-time broadcast channel for payment verification & approvals
      _broadcastChannel ??= client.channel('admin-dashboard-realtime-channel')
        ..onBroadcast(
          event: 'payment_verified',
          callback: (payload) => _handlePaymentVerified(payload),
        )
        ..onBroadcast(
          event: 'payment_approved',
          callback: (payload) => _handlePaymentVerified(payload),
        )
        ..onBroadcast(
          event: 'application_updated',
          callback: (payload) => _handleStepUpdated(payload),
        )
        ..onBroadcast(
          event: 'step_updated',
          callback: (payload) => _handleStepUpdated(payload),
        )
        ..onBroadcast(
          event: 'application_approved',
          callback: (payload) => _handleStepUpdated(payload),
        )
        ..subscribe();
    } catch (_) {
      fetchLive();
    }
  }

  void _handlePaymentVerified(Map<String, dynamic> payload) {
    final targetRef = payload['reference_number']?.toString().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase() ?? '';
    final targetAppId = payload['application_id']?.toString().toLowerCase() ?? '';

    // 1. Update state directly for instant UI refresh
    state = state.map((app) {
      final appRef = app.reference.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
      final appId = app.id.toLowerCase();

      final matches = (targetRef.isEmpty && targetAppId.isEmpty) ||
          (targetRef.isNotEmpty && (appRef.contains(targetRef) || targetRef.contains(appRef))) ||
          (targetAppId.isNotEmpty && (appId == targetAppId));

      if (matches) {
        return app.copyWith(
          statusLabel: '✓ Profile Review',
          statusBgColor: 0xFFEDF3F9,
          statusTextColor: 0xFF3D6186,
          leftStripeColor: 0xFF1B3A5C,
          hasAlert: false,
          alertTitle: null,
          alertBody: null,
          stepText: 'Step 1 of 5: Profile Review',
          progressPercent: 20,
        );
      }
      return app;
    }).toList();

    // 2. Also update local applications list
    for (int i = 0; i < _localApplications.length; i++) {
      final app = _localApplications[i];
      final appRef = app.reference.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
      final appId = app.id.toLowerCase();

      final matches = (targetRef.isEmpty && targetAppId.isEmpty) ||
          (targetRef.isNotEmpty && (appRef.contains(targetRef) || targetRef.contains(appRef))) ||
          (targetAppId.isNotEmpty && (appId == targetAppId));

      if (matches) {
        _localApplications[i] = app.copyWith(
          statusLabel: '✓ Profile Review',
          statusBgColor: 0xFFEDF3F9,
          statusTextColor: 0xFF3D6186,
          leftStripeColor: 0xFF1B3A5C,
          hasAlert: false,
          alertTitle: null,
          alertBody: null,
          stepText: 'Step 1 of 5: Profile Review',
          progressPercent: 20,
        );
      }
    }
    fetchLive();
  }

  void _handleStepUpdated(Map<String, dynamic> payload) {
    final targetRef = payload['reference_number']?.toString().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase() ?? '';
    final targetAppId = payload['application_id']?.toString().toLowerCase() ?? '';
    final newStep = (payload['current_step'] as num?)?.toInt() ?? 1;
    final stepText = payload['step_text']?.toString() ?? 'Step $newStep of 5';
    final progress = (payload['progress_percent'] as num?)?.toInt() ?? (newStep * 20);
    final statusLabel = payload['status_label']?.toString() ?? (newStep >= 5 ? '✓ Approved' : 'Step $newStep of 5');

    // 1. Update state directly for instant UI refresh
    state = state.map((app) {
      final appRef = app.reference.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
      final appId = app.id.toLowerCase();

      final matches = (targetRef.isNotEmpty && (appRef.contains(targetRef) || targetRef.contains(appRef))) ||
          (targetAppId.isNotEmpty && (appId == targetAppId));

      if (matches) {
        return app.copyWith(
          statusLabel: statusLabel,
          statusBgColor: newStep >= 5 ? 0xFFDCFCE7 : 0xFFEDF3F9,
          statusTextColor: newStep >= 5 ? 0xFF15803D : 0xFF3D6186,
          leftStripeColor: newStep >= 5 ? 0xFF2E7D32 : 0xFF1B3A5C,
          hasAlert: false,
          alertTitle: null,
          alertBody: null,
          stepText: stepText,
          progressPercent: progress,
        );
      }
      return app;
    }).toList();

    // 2. Also update local applications list
    for (int i = 0; i < _localApplications.length; i++) {
      final app = _localApplications[i];
      final appRef = app.reference.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
      final appId = app.id.toLowerCase();

      final matches = (targetRef.isNotEmpty && (appRef.contains(targetRef) || targetRef.contains(appRef))) ||
          (targetAppId.isNotEmpty && (appId == targetAppId));

      if (matches) {
        _localApplications[i] = app.copyWith(
          statusLabel: statusLabel,
          statusBgColor: newStep >= 5 ? 0xFFDCFCE7 : 0xFFEDF3F9,
          statusTextColor: newStep >= 5 ? 0xFF15803D : 0xFF3D6186,
          leftStripeColor: newStep >= 5 ? 0xFF2E7D32 : 0xFF1B3A5C,
          hasAlert: false,
          alertTitle: null,
          alertBody: null,
          stepText: stepText,
          progressPercent: progress,
        );
      }
    }
    fetchLive();
  }

  Future<void> fetchLive() async {
    try {
      final client = SupabaseDatabaseService.instance.client;
      final user = client.auth.currentUser;
      if (user == null) {
        _mergeAndEmit(const <ApplicationRecordItem>[]);
        return;
      }
      final res = await client
          .from('applications')
          .select('*')
          .eq('user_id', user.id)
          .order('applied_at', ascending: false);
      final rows = List<Map<String, dynamic>>.from(res);
      final filteredRows = rows.where((r) {
        final fd = r['form_data'] as Map?;
        final isArchived = fd?['is_deleted'] == true || fd?['is_archived'] == true;
        final cat = (r['category_type']?.toString() ?? '').toUpperCase();
        final title = (r['title']?.toString() ?? '').toUpperCase();
        final listingId = (r['listing_id']?.toString() ?? '').toLowerCase();

        // Strict Rule: Exclude scholarships and sponsored jobs from App Dashboard
        final isScholarshipOrJob = cat.contains('SCHOLARSHIP') ||
            cat.contains('JOB') ||
            cat.contains('SPONSORED') ||
            cat.contains('OPPORTUNITY') ||
            title.contains('SCHOLARSHIP') ||
            title.contains('SPONSORED JOB') ||
            title.contains('UNLOCK') ||
            listingId.contains('scholarship') ||
            listingId.contains('job') ||
            listingId.contains('unlock') ||
            listingId.contains('pass');

        return !isArchived && !isScholarshipOrJob;
      }).toList();
      _mergeAndEmit(filteredRows.map(_applicationFromRow).toList());
    } catch (_) {}
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _streamSub?.cancel();
    _broadcastChannel?.unsubscribe();
    super.dispose();
  }
}

/// Global provider for user's applications list.
final userApplicationsListProvider =
    StateNotifierProvider<UserApplicationsNotifier, List<ApplicationRecordItem>>(
  (ref) => UserApplicationsNotifier(),
);

void addApplicationRecord(WidgetRef ref, DetailItemModel item) {
  final idLower = item.id.toLowerCase();
  final catLower = item.categoryTag.toLowerCase();
  final titleLower = item.title.toLowerCase();

  // Strict Rule: Scholarships and Sponsored Jobs (and unlock passes) NEVER show in App Dashboard
  final isScholarshipOrJob = idLower.contains('scholarship') ||
      idLower.contains('job') ||
      idLower.contains('unlock') ||
      idLower.contains('pass') ||
      catLower.contains('scholarship') ||
      catLower.contains('job') ||
      catLower.contains('sponsored') ||
      catLower.contains('opportunity') ||
      titleLower.contains('scholarship') ||
      titleLower.contains('sponsored job') ||
      titleLower.contains('unlock');

  if (isScholarshipOrJob) {
    return;
  }

  final current = ref.read(userApplicationsListProvider);
  final itemNorm = UserApplicationsNotifier.normalizeTitle(item.title);
  if (current.any((a) {
    if (a.id == item.id) return true;
    if (a.listingId != null && a.listingId == item.id) return true;
    final aNorm = UserApplicationsNotifier.normalizeTitle(a.title);
    return aNorm == itemNorm ||
        (aNorm.isNotEmpty && itemNorm.isNotEmpty && (aNorm.contains(itemNorm) || itemNorm.contains(aNorm)));
  })) {
    return;
  }

  final newItem = ApplicationRecordItem(
    id: item.id,
    listingId: item.id,
    categoryType: '${item.categoryTag.toUpperCase()} VISA',
    categoryIcon: Icons.school_outlined,
    title: item.title,
    reference: 'Ref: SB-2026-${(current.length + 1).toString().padLeft(4, '0')}',
    statusLabel: 'Payment Pending',
    statusBgColor: 0xFFFFF8E1,
    statusTextColor: 0xFFB76E00,
    leftStripeColor: 0xFFED6C02,
    hasAlert: true,
    alertTitle: 'Payment Pending',
    alertBody: 'Your visa application payment is currently being reviewed by admin. View Details will unlock once approved.',
    stepText: 'Payment Verification Pending (Awaiting Admin)',
    progressPercent: 15,
    appliedDateOrStatus: 'Applied Today',
    actionLabel: 'View Details',
    subtitle: item.subtitle,
  );

  ref.read(userApplicationsListProvider.notifier).add(newItem);
}

/// Comprehensive, pixel-perfect "My Applications" & "Dashboard" screen
/// matching media_1790706470515.png (Empty State) and media_1790706482350.png (Populated State).
///
/// Features:
/// 1. Top custom AppBar with logo, "SB Consultants" title, and user profile avatar.
/// 2. Deep Navy Canopy with "PORTAL OVERVIEW", watermark shield, "My Applications" title,
///    and filter sliders icon.
/// 3. Floating 3 metric summary cards (Active, Review, Completed).
/// 4. Horizontal filter pills (All Visas, Study Visa, Work Visa, Visit Visa, Golden & Business).
/// 5. Full support for Populated applications list and Empty State view.
/// 6. Interactive Demo Switcher banner to toggle between Empty and Populated states.
/// 7. Persistent 4-item bottom navigation bar with active "Dashboard" pill.
class MyApplicationsScreen extends ConsumerStatefulWidget {
  const MyApplicationsScreen({
    super.key,
    this.newlyAddedItem,
    this.forceEmptyState,
  });

  final DetailItemModel? newlyAddedItem;
  final bool? forceEmptyState;

  @override
  ConsumerState<MyApplicationsScreen> createState() =>
      _MyApplicationsScreenState();
}

class _MyApplicationsScreenState extends ConsumerState<MyApplicationsScreen> {
  int _selectedFilterIndex = 0;

  final List<String> _filters = const [
    'All Visas',
    'Study Visa',
    'Work Visa',
    'Visit Visa',
    'Golden & Business',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.newlyAddedItem != null) {
        addApplicationRecord(ref, widget.newlyAddedItem!);
      }
      ref.read(userApplicationsListProvider.notifier).fetchLive();
      syncDirectoryUnlocks(ref);
    });
  }

  bool get _isEmptyState {
    if (widget.forceEmptyState != null) {
      return widget.forceEmptyState!;
    }
    final apps = ref.watch(userApplicationsListProvider);
    final displayed = _getFilteredApplications(apps);
    return displayed.isEmpty;
  }

  List<ApplicationRecordItem> _getFilteredApplications(
      List<ApplicationRecordItem> all) {
    // Strictly only visa applications are displayed in My Applications dashboard
    final visasOnly = all.where((a) {
      final cat = a.categoryType.toUpperCase();
      final title = a.title.toUpperCase();
      final id = a.id.toLowerCase();
      final listingId = (a.listingId ?? '').toLowerCase();

      final isScholarshipOrJob = cat.contains('SCHOLARSHIP') ||
          cat.contains('JOB') ||
          cat.contains('SPONSORED') ||
          cat.contains('OPPORTUNITY') ||
          title.contains('SCHOLARSHIP') ||
          title.contains('SPONSORED JOB') ||
          title.contains('UNLOCK') ||
          id.contains('scholarship') ||
          id.contains('job') ||
          id.contains('unlock') ||
          listingId.contains('scholarship') ||
          listingId.contains('job') ||
          listingId.contains('unlock') ||
          listingId.contains('pass');

      return !isScholarshipOrJob;
    }).toList();

    if (_selectedFilterIndex == 0) return visasOnly;
    if (_selectedFilterIndex == 1) {
      return visasOnly.where((a) {
        final cat = a.categoryType.toUpperCase();
        final title = a.title.toUpperCase();
        return cat.contains('STUDY') || title.contains('STUDY') || cat.contains('STUDENT') || title.contains('STUDENT');
      }).toList();
    }
    if (_selectedFilterIndex == 2) {
      return visasOnly.where((a) {
        final cat = a.categoryType.toUpperCase();
        final title = a.title.toUpperCase();
        return cat.contains('WORK') || title.contains('WORK') || cat.contains('SKILLED') || title.contains('SKILLED');
      }).toList();
    }
    if (_selectedFilterIndex == 3) {
      return visasOnly.where((a) {
        final cat = a.categoryType.toUpperCase();
        final title = a.title.toUpperCase();
        return cat.contains('VISIT') || title.contains('VISIT') || cat.contains('TOURIST') || title.contains('TOURIST') || cat.contains('SCHENGEN') || title.contains('SCHENGEN');
      }).toList();
    }
    if (_selectedFilterIndex == 4) {
      return visasOnly.where((a) {
        final cat = a.categoryType.toUpperCase();
        final title = a.title.toUpperCase();
        return cat.contains('BUSINESS') || title.contains('BUSINESS') || cat.contains('GOLDEN') || title.contains('GOLDEN') || cat.contains('INVEST');
      }).toList();
    }
    return visasOnly;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allApps = ref.watch(userApplicationsListProvider);
    final displayedApps = _getFilteredApplications(allApps);
    final isEmpty = _isEmptyState;

    // Metrics count strictly for visas
    final completedCount = isEmpty
        ? 0
        : displayedApps.where((a) => a.isCompleted).length;
    final reviewCount = isEmpty
        ? 0
        : displayedApps.where((a) => !a.isCompleted && a.statusLabel.toLowerCase().contains('review')).length;
    final activeCount = isEmpty
        ? 0
        : displayedApps.where((a) => !a.isCompleted).length;

    final bgColor = isDark ? const Color(0xFF000000) : const Color(0xFFF7F9FF);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: _buildTopAppBar(context, isDark),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Deep Navy Canopy Header
              _buildTopCanopyHeader(context),
              SizedBox(height: 12.h),

              // 2. Floating 3 Metric Cards Row
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: _buildMetricsRow(
                  active: activeCount,
                  review: reviewCount,
                  completed: completedCount,
                  isDark: isDark,
                ),
              ),
              SizedBox(height: 16.h),

              // 4. Horizontal Filter Pills Row
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: _buildFilterChips(isDark),
              ),
              SizedBox(height: 16.h),

              // 5. Dynamic Content: Populated List OR Empty State
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: isEmpty
                    ? _buildEmptyStateView(context)
                    : _buildPopulatedApplicationsList(context, displayedApps, isDark),
              ),
              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppDashboardBottomNav(currentIndex: 1),
    );
  }

  // ===========================================================================
  // 1. TOP APP BAR
  // ===========================================================================
  PreferredSizeWidget _buildTopAppBar(BuildContext context, bool isDark) {
    return AppBar(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      elevation: 0,
      scrolledUnderElevation: 1,
      surfaceTintColor: Colors.transparent,
      title: Text(
        'My Applications',
        style: TextStyle(
          fontSize: 18.sp,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : const Color(0xFF002444),
          letterSpacing: -0.2,
        ),
      ),
      centerTitle: true,
      actions: const [],
    );
  }

  // ===========================================================================
  // 2. DEEP NAVY CANOPY HEADER
  // ===========================================================================
  Widget _buildTopCanopyHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121212) : const Color(0xFF1B3A5C),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(24.r),
        ),
        border: isDark
            ? const Border(
                bottom: BorderSide(color: Color(0xFF27272A), width: 1),
              )
            : null,
      ),
      child: Stack(
        children: [
          // Watermark shield icon on top-right background
          Positioned(
            right: 8.w,
            top: 2.h,
            child: Opacity(
              opacity: 0.08,
              child: Icon(
                Icons.shield_outlined,
                size: 96.sp,
                color: Colors.white,
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 20.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Tracker / Overview Subtitle
                Text(
                  'PORTAL OVERVIEW',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF90A8C0),
                    letterSpacing: 0.8,
                  ),
                ),
                SizedBox(height: 8.h),

                // Large Main Title
                Text(
                  'My Applications',
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 4.h),

                // Subtitle
                Text(
                  'Track your visa and opportunity applications',
                  style: TextStyle(
                    fontSize: 12.5.sp,
                    color: Colors.white.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w400,
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
  // 3. FLOATING 3 METRIC CARDS ROW
  // ===========================================================================
  Widget _buildMetricsRow({
    required int active,
    required int review,
    required int completed,
    required bool isDark,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            icon: Icons.assignment_outlined,
            count: active,
            label: 'Active',
            isDark: isDark,
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: _buildMetricCard(
            icon: Icons.find_in_page_outlined,
            count: review,
            label: 'Review',
            isDark: isDark,
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: _buildMetricCard(
            icon: Icons.verified_outlined,
            count: completed,
            label: 'Completed',
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required int count,
    required String label,
    required bool isDark,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 8.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121212) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : const Color(0xFF1B3A5C).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34.w,
            height: 34.w,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE8F1FB),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 18.sp,
              color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1B3A5C),
            ),
          ),
          SizedBox(height: 8.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF171C21),
                letterSpacing: -0.5,
              ),
            ),
          ),
          SizedBox(height: 2.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11.5.sp,
                fontWeight: FontWeight.w500,
                color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF5A626A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 4. HORIZONTAL FILTER PILLS ROW
  // ===========================================================================
  Widget _buildFilterChips(bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          for (int i = 0; i < _filters.length; i++) ...[
            _buildFilterPill(
              index: i,
              label: _filters[i],
              isSelected: _selectedFilterIndex == i,
              isDark: isDark,
            ),
            if (i < _filters.length - 1) SizedBox(width: 8.w),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterPill({
    required int index,
    required String label,
    required bool isSelected,
    required bool isDark,
  }) {
    return InkWell(
      onTap: () => setState(() => _selectedFilterIndex = index),
      borderRadius: BorderRadius.circular(20.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 7.h),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF3B82F6) : const Color(0xFF002444))
              : (isDark ? const Color(0xFF18181B) : const Color(0xFFEDF2F8)),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected
                ? (isDark ? const Color(0xFF3B82F6) : const Color(0xFF002444))
                : (isDark ? const Color(0xFF27272A) : const Color(0xFFD0D7E2)),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5.sp,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected
                ? Colors.white
                : (isDark ? const Color(0xFFA1A1AA) : const Color(0xFF0F172A)),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 5. EMPTY STATE VIEW (Matches media_1790706470515.png)
  // ===========================================================================
  Widget _buildEmptyStateView(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final browseBtnBg = isDark ? const Color(0xFF121212) : const Color(0xFFF0F4FA);
    final browseBtnBorder = isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0);
    final browseBtnIconColor = isDark ? const Color(0xFF60A5FA) : const Color(0xFF1B3A5C);
    return Column(
      children: [
        SizedBox(height: 18.h),

        // Concentric Rings Empty Folder Graphic with Magnifier Badge
        Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer soft ring
              Container(
                width: 128.w,
                height: 128.w,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF18181B) : const Color(0xFFE8F1FB),
                  shape: BoxShape.circle,
                ),
              ),
              // Inner soft ring
              Container(
                width: 96.w,
                height: 96.w,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF27272A) : const Color(0xFFF3F7FC),
                  shape: BoxShape.circle,
                ),
              ),
              // Center folder circle
              Container(
                width: 68.w,
                height: 68.w,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF121212) : Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.folder_open_rounded,
                  size: 32.sp,
                  color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF002444),
                ),
              ),
              // Overlapping bottom-right search circle badge
              Positioned(
                right: 8.w,
                bottom: 8.h,
                child: Container(
                  width: 32.w,
                  height: 32.w,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF3B82F6) : const Color(0xFF002444),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.search_rounded,
                    size: 17,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 22.h),

        // Headline
        Text(
          'No applications yet',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF002444),
            letterSpacing: -0.3,
          ),
        ),
        SizedBox(height: 8.h),

        // Subtitle
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Text(
            'Start by applying for a visa or exploring scholarships to track your journey in real time.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5.sp,
              color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF5A626A),
              height: 1.4,
            ),
          ),
        ),
        SizedBox(height: 24.h),

        // Primary Action: Explore Visa Services
        SizedBox(
          width: double.infinity,
          height: 50.h,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? const Color(0xFF3B82F6) : const Color(0xFF002444),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14.r),
              ),
            ),
            onPressed: () => context.go(AppRoutes.home),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Explore Visa Services',
                  style: TextStyle(
                    fontSize: 14.5.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(width: 8.w),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 12.h),

        // Secondary Action: Browse 2025 Scholarships
        SizedBox(
          width: double.infinity,
          height: 50.h,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              backgroundColor: browseBtnBg,
              side: BorderSide(color: browseBtnBorder),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14.r),
              ),
            ),
            onPressed: () => context.push(AppRoutes.scholarships),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.school_outlined,
                  size: 18.sp,
                  color: browseBtnIconColor,
                ),
                SizedBox(width: 8.w),
                Text(
                  'Browse 2025 Scholarships',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1B3A5C),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 20.h),

        // Text Link: Looking for job sponsorships? View Sponsored Jobs
        InkWell(
          onTap: () => context.push(AppRoutes.sponsoredJobs),
          borderRadius: BorderRadius.circular(6.r),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 8.w),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Looking for job sponsorships? ',
                    style: TextStyle(
                      fontSize: 12.5.sp,
                      color: const Color(0xFF5A626A),
                    ),
                  ),
                  TextSpan(
                    text: 'View Sponsored Jobs',
                    style: TextStyle(
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1B3A5C),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        SizedBox(height: 24.h),

        // Bottom Advisory Card: Need a custom roadmap?
        _buildAdvisorRoadmapCard(context),
      ],
    );
  }

  Widget _buildAdvisorRoadmapCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFE8EEF5)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B3A5C).withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: const BoxDecoration(
              color: Color(0xFFD6E6FB),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.support_agent_rounded,
              size: 22.sp,
              color: const Color(0xFF1B3A5C),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Need a custom roadmap?',
                  style: TextStyle(
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF171C21),
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'Book a 1-on-1 advisor consultation to verify eligibility before submitting.',
                  style: TextStyle(
                    fontSize: 11.5.sp,
                    color: const Color(0xFF5A626A),
                    height: 1.35,
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
  // 6. POPULATED APPLICATIONS LIST (Matches media_1790706482350.png)
  // ===========================================================================
  Widget _buildPopulatedApplicationsList(
    BuildContext context,
    List<ApplicationRecordItem> apps,
    bool isDark,
  ) {
    if (apps.isEmpty) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF121212) : Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: isDark ? const Color(0xFF27272A) : const Color(0xFFE8EEF5)),
        ),
        child: Center(
          child: Text(
            'No applications found in this category',
            style: TextStyle(
              fontSize: 13.sp,
              color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF5A626A),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        for (final app in apps) _buildApplicationCard(context, app, isDark),
      ],
    );
  }

  Widget _buildApplicationCard(
    BuildContext context,
    ApplicationRecordItem app,
    bool isDark,
  ) {
    final statusBgDark = app.statusBgColor == 0xFFFFDAD6
        ? const Color(0xFF450A0A)
        : const Color(0xFF18181B);
    final statusTextDark = app.statusTextColor == 0xFFBA1A1A
        ? const Color(0xFFFCA5A5)
        : const Color(0xFF93C5FD);

    return Container(
      margin: EdgeInsets.only(bottom: 14.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121212) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B3A5C).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: () {
            if (app.isPaymentPending) {
              _showPaymentVerificationPendingSheet(context, app);
            } else {
              context.push(AppRoutes.applicationProcedure, extra: app);
            }
          },
          onLongPress: () {
            _showApplicationDetailsSheet(context, app);
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16.r),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left Colored Accent Stripe (4.w)
                  Container(
                    width: 4.w,
                    color: Color(app.leftStripeColor),
                  ),

                  // Card Main Content Body
                  Expanded(
                child: Padding(
                  padding: EdgeInsets.all(14.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Category Tag with Icon & Status Badge Pill
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  app.categoryIcon,
                                  size: 14.sp,
                                  color: isDark ? Colors.white : const Color(0xFF171C21),
                                ),
                                SizedBox(width: 5.w),
                                Flexible(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      app.categoryType,
                                      style: TextStyle(
                                        fontSize: 11.sp,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF171C21),
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 9.w, vertical: 3.h),
                                decoration: BoxDecoration(
                                  color: isDark ? statusBgDark : Color(app.statusBgColor),
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: Text(
                                  app.statusLabel,
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? statusTextDark : Color(app.statusTextColor),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),

                      // Title
                      Text(
                        app.title,
                        maxLines: 2,
                        softWrap: true,
                        style: TextStyle(
                          fontSize: 15.5.sp,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF171C21),
                          letterSpacing: -0.2,
                        ),
                      ),

                      // Optional Subtitle (e.g. for Sponsored Jobs)
                      if (app.subtitle != null) ...[
                        SizedBox(height: 2.h),
                        Text(
                          app.subtitle!,
                          maxLines: 2,
                          softWrap: true,
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF5A626A),
                          ),
                        ),
                      ],
                      SizedBox(height: 2.h),

                      // Reference ID
                      Text(
                        app.reference,
                        style: TextStyle(
                          fontSize: 11.5.sp,
                          color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF5A626A),
                        ),
                      ),

                      // Alert Box (e.g. for Action Needed / Document re-upload)
                      if (app.hasAlert) ...[
                        SizedBox(height: 10.h),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(10.w),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF0EE),
                            borderRadius: BorderRadius.circular(10.r),
                            border: Border.all(color: const Color(0xFFFFD4D0)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.error_outline_rounded,
                                size: 16.sp,
                                color: const Color(0xFFBA1A1A),
                              ),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      app.alertTitle ?? 'Action Required',
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFFBA1A1A),
                                      ),
                                    ),
                                    SizedBox(height: 2.h),
                                    Text(
                                      app.alertBody ?? '',
                                      style: TextStyle(
                                        fontSize: 11.5.sp,
                                        color: const Color(0xFF7D1616),
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Body text (e.g. for Unlocked Opportunity pass)
                      if (app.bodyText != null) ...[
                        SizedBox(height: 8.h),
                        Text(
                          app.bodyText!,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF43474E),
                            height: 1.35,
                          ),
                        ),
                      ],

                      // Step Milestone Progress Bar (if stepText & progressPercent are provided)
                      if (app.stepText != null &&
                          app.progressPercent != null) ...[
                        SizedBox(height: 10.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                app.stepText!,
                                softWrap: true,
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : const Color(0xFF171C21),
                                ),
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              '${app.progressPercent}%',
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w700,
                                color: app.progressBarColor != null
                                    ? Color(app.progressBarColor!)
                                    : (isDark ? Colors.white : const Color(0xFF171C21)),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 6.h),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2.r),
                          child: LinearProgressIndicator(
                            value: (app.progressPercent! / 100.0).clamp(0.0, 1.0),
                            minHeight: 4.h,
                            backgroundColor: isDark ? const Color(0xFF27272A) : const Color(0xFFEAEFF5),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              app.progressBarColor != null
                                  ? Color(app.progressBarColor!)
                                  : const Color(0xFF002444),
                            ),
                          ),
                        ),
                      ],

                      SizedBox(height: 12.h),

                      // Bottom Action Row: Date / Member Status on left & CTA Button on right
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  app.appliedDateOrStatus.contains('Active')
                                      ? Icons.check_circle_outline_rounded
                                      : Icons.calendar_today_outlined,
                                  size: 13.sp,
                                  color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF5A626A),
                                ),
                                SizedBox(width: 5.w),
                                Flexible(
                                  child: Text(
                                    app.appliedDateOrStatus,
                                    softWrap: true,
                                    style: TextStyle(
                                      fontSize: 11.5.sp,
                                      fontWeight: app.appliedDateOrStatus
                                              .contains('Active')
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF5A626A),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 8.w),

                          // CTA Button (View Details / Resolve / Browse Jobs)
                          _buildCardCTAButton(context, app),
                        ],
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
  ),
);
}

  Widget _buildCardCTAButton(BuildContext context, ApplicationRecordItem app) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (app.actionIsRed) {
      // Resolve Button
      return InkWell(
        onTap: () {
          _showDocumentResolveSheet(context, app);
        },
        borderRadius: BorderRadius.circular(8.r),
        child: Container(
          height: 32.h,
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          decoration: BoxDecoration(
            color: const Color(0xFFBA1A1A),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.upload_file_rounded,
                size: 13.sp,
                color: Colors.white,
              ),
              SizedBox(width: 5.w),
              Text(
                app.actionLabel,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (app.actionIsNavy) {
      // Browse Jobs Button - navy bg both modes
      return InkWell(
        onTap: () {
          if (app.externalUrl != null) {
            context.push(app.externalUrl!);
          } else {
            context.push(AppRoutes.sponsoredJobs);
          }
        },
        borderRadius: BorderRadius.circular(8.r),
        child: Container(
          height: 32.h,
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF3B82F6) : const Color(0xFF002444),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                app.actionLabel,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 4.w),
              Icon(
                Icons.open_in_new_rounded,
                size: 13.sp,
                color: Colors.white,
              ),
            ],
          ),
        ),
      );
    }

    // If payment is unapproved / pending admin verification: "View Details" button is DISABLED
    if (app.isPaymentPending) {
      return InkWell(
        onTap: () => _showPaymentVerificationPendingSheet(context, app),
        borderRadius: BorderRadius.circular(8.r),
        child: Container(
          height: 32.h,
          padding: EdgeInsets.symmetric(horizontal: 10.w),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color: isDark ? const Color(0xFF3F3F46) : const Color(0xFFCBD5E1),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: 13.sp,
                color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF64748B),
              ),
              SizedBox(width: 5.w),
              Text(
                'View Details',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Default "View Details →" button - ACTIVE & ENABLED after approval
    return InkWell(
      onTap: () {
        context.push(AppRoutes.applicationProcedure, extra: app);
      },
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        height: 32.h,
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF3B82F6) : const Color(0xFF002444),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'View Details',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 4.w),
            Icon(
              Icons.arrow_forward_rounded,
              size: 13.sp,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  void _showDocumentResolveSheet(
      BuildContext context, ApplicationRecordItem app) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF121212) : Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 32.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFDAD6),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFBA1A1A),
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Resolve Required Document',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF171C21),
                          ),
                        ),
                        Text(
                          app.title,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF5A626A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 14.h),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0EE),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: const Color(0xFFFFD4D0)),
                ),
                child: Text(
                  'Bank statement closing balance blurred. Please submit a clearer copy in high resolution PDF or JPG.',
                  style: TextStyle(
                    fontSize: 12.5.sp,
                    color: const Color(0xFF7D1616),
                    height: 1.4,
                  ),
                ),
              ),
              SizedBox(height: 18.h),
              SizedBox(
                width: double.infinity,
                height: 48.h,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFBA1A1A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  icon: const Icon(Icons.upload_file_rounded, size: 18),
                  label: const Text('Upload Clear Bank Statement'),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    showToast(
                      context,
                      message: 'Document successfully re-uploaded for officer review',
                      status: 'success',
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

  void _showApplicationDetailsSheet(
      BuildContext context, ApplicationRecordItem app) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF121212) : Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 28.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    app.title,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF171C21),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '${app.categoryType} • ${app.reference}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF5A626A),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 14.h),
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F6FA),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 18.sp,
                          color: const Color(0xFF1B3A5C),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            app.stepText ?? 'Your file is currently under accredited evaluation.',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: const Color(0xFF171C21),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20.h),
                  SizedBox(
                    width: double.infinity,
                    height: 48.h,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: app.isPaymentPending
                            ? (isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0))
                            : (isDark ? const Color(0xFF3B82F6) : const Color(0xFF002444)),
                        foregroundColor: app.isPaymentPending
                            ? (isDark ? const Color(0xFFA1A1AA) : const Color(0xFF64748B))
                            : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      icon: Icon(
                        app.isPaymentPending ? Icons.lock_outline_rounded : Icons.timeline_rounded,
                        size: 18,
                      ),
                      label: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          app.isPaymentPending
                              ? 'View Details (Locked - Awaiting Admin Approval)'
                              : 'View Details & Procedure Timeline',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: app.isPaymentPending
                                ? (isDark ? const Color(0xFFA1A1AA) : const Color(0xFF64748B))
                                : Colors.white,
                          ),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        if (app.isPaymentPending) {
                          _showPaymentVerificationPendingSheet(context, app);
                        } else {
                          context.push(AppRoutes.applicationProcedure, extra: app);
                        }
                      },
                    ),
                  ),
                  SizedBox(height: 10.h),
                  SizedBox(
                    width: double.infinity,
                    height: 44.h,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF5A626A),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showPaymentVerificationPendingSheet(BuildContext context, ApplicationRecordItem app) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (ctx) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF121212) : Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 28.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                  SizedBox(height: 18.h),
                  Container(
                    width: 58.w,
                    height: 58.w,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFFFECB3), width: 2),
                    ),
                    child: Icon(
                      Icons.hourglass_top_rounded,
                      size: 28.sp,
                      color: const Color(0xFFED6C02),
                    ),
                  ),
                  SizedBox(height: 14.h),
                  Text(
                    'Payment Under Verification',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF002444),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Your bank transfer payment for ${app.title} (${app.reference}) is currently under verification by SB Consultants Admin.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF5A626A),
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 14.h),
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF18181B) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.verified_user_outlined,
                          size: 20.sp,
                          color: const Color(0xFFED6C02),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Text(
                            'As soon as Admin verifies your payment, the "View Details" procedure tracking button will unlock automatically in real-time.',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white70 : const Color(0xFF334155),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20.h),
                  SizedBox(
                    width: double.infinity,
                    height: 46.h,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? const Color(0xFF3B82F6) : const Color(0xFF1B3A5C),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Understood'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
