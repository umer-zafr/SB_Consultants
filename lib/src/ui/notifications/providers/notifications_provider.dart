import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_sd_consultant/src/imports/packages_imports.dart';
import 'package:flutter_sd_consultant/src/routing/app_routes.dart';
import 'package:flutter_sd_consultant/src/services/supabase_database_service.dart';
import 'package:flutter_sd_consultant/src/ui/notifications/models/notification_item_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Notifier providing strictly isolated, user-specific dynamic notifications.
///
/// Features:
/// 1. Complete User Isolation: User A only sees User A's data; User B only sees User B's.
/// 2. Live Supabase Sync: Dynamically reflects real visa file submissions, payment approvals,
///    and procedure milestones from the `applications` and `payments` tables.
/// 3. Real-time Listening: Automatically updates when an application is filed or payment is approved.
/// 4. Persistent Preferences: Preserves read and dismissed states per authenticated user ID.
class NotificationsNotifier extends StateNotifier<List<NotificationItemModel>> {
  NotificationsNotifier() : super(const []) {
    _init();
  }

  StreamSubscription<AuthState>? _authSub;
  StreamSubscription<List<Map<String, dynamic>>>? _appsStreamSub;
  StreamSubscription<List<Map<String, dynamic>>>? _paymentsStreamSub;
  StreamSubscription<List<Map<String, dynamic>>>? _notifsStreamSub;
  RealtimeChannel? _broadcastChannel;
  String? _activeUserId;

  void _init() {
    // 1. Initial check for current authenticated user
    final currentSupabaseUser = SupabaseDatabaseService.instance.client.auth.currentUser;
    _handleUserChange(currentSupabaseUser?.id);

    // 2. Listen to Supabase auth state changes
    _authSub = SupabaseDatabaseService.instance.client.auth.onAuthStateChange.listen((data) {
      final newUserId = data.session?.user.id;
      if (newUserId != _activeUserId) {
        _handleUserChange(newUserId);
      }
    });

    // 3. Listen to realtime payment verification broadcasts
    try {
      final client = SupabaseDatabaseService.instance.client;
      _broadcastChannel = client.channel('notifications-user-realtime-channel')
        ..onBroadcast(
          event: 'payment_verified',
          callback: (_) {
            if (_activeUserId != null) {
              fetchLiveUserNotifications(_activeUserId!);
            }
          },
        )
        ..subscribe();
    } catch (_) {}
  }

  void _handleUserChange(String? userId) {
    _activeUserId = userId;
    _appsStreamSub?.cancel();
    _paymentsStreamSub?.cancel();
    _notifsStreamSub?.cancel();

    if (userId == null || userId.isEmpty) {
      // Guest state: strictly 0 notifications for new/unauthenticated visitors
      state = const [];
      return;
    }

    // Authenticated user:
    // 1. Load user-specific cached notifications
    _loadFromCache(userId);

    // 2. Fetch live applications, payments & notifications from Supabase
    fetchLiveUserNotifications(userId);

    // 3. Subscribe to real-time changes on applications, payments & notifications for this user
    _subscribeToUserRealtime(userId);
  }

  void _subscribeToUserRealtime(String userId) {
    try {
      final client = SupabaseDatabaseService.instance.client;
      _appsStreamSub = client
          .from('applications')
          .stream(primaryKey: ['id'])
          .eq('user_id', userId)
          .listen(
            (_) => fetchLiveUserNotifications(userId),
            onError: (err) {
              debugPrint('[NotificationsProvider] apps stream notice: $err');
            },
            cancelOnError: false,
          );

      _paymentsStreamSub = client
          .from('payments')
          .stream(primaryKey: ['id'])
          .eq('user_id', userId)
          .listen(
            (_) => fetchLiveUserNotifications(userId),
            onError: (err) {
              debugPrint('[NotificationsProvider] payments stream notice: $err');
            },
            cancelOnError: false,
          );

      _notifsStreamSub = client
          .from('notifications')
          .stream(primaryKey: ['id'])
          .eq('user_id', userId)
          .listen(
            (_) => fetchLiveUserNotifications(userId),
            onError: (err) {
              debugPrint('[NotificationsProvider] notifications stream notice: $err');
            },
            cancelOnError: false,
          );
    } catch (_) {}
  }

  Future<void> refresh() async {
    final user = SupabaseDatabaseService.instance.client.auth.currentUser;
    if (user != null) {
      await fetchLiveUserNotifications(user.id);
    }
  }

  Future<void> fetchLiveUserNotifications(String userId) async {
    try {
      final client = SupabaseDatabaseService.instance.client;

      // 1. Fetch user applications strictly for this user
      final appsRes = await client
          .from('applications')
          .select('*')
          .eq('user_id', userId)
          .order('applied_at', ascending: false);

      final List<Map<String, dynamic>> appRows =
          List<Map<String, dynamic>>.from(appsRes);

      // 2. Fetch user payments strictly for this user
      final paymentsRes = await client
          .from('payments')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> paymentRows =
          List<Map<String, dynamic>>.from(paymentsRes);

      // Read sets of read and deleted IDs for this specific user
      final prefs = await SharedPreferences.getInstance();
      final readIds = prefs.getStringList('sb_read_notifs_$userId')?.toSet() ?? <String>{};
      final deletedIds = prefs.getStringList('sb_deleted_notifs_$userId')?.toSet() ?? <String>{};

      final List<NotificationItemModel> generated = [];

      for (final app in appRows) {
        final appId = app['id'] as String;
        final appTitle = (app['title'] as String?)?.isNotEmpty ?? false
            ? app['title'] as String
            : 'Visa Application';
        final refNo = app['reference_number'] as String? ?? 'SB-APP';
        final status = app['status'] as String? ?? 'submitted';
        final step = app['current_step'] as int? ?? 1;
        final stepText = app['step_text'] as String? ?? 'Step 1 of 5: Profile Review';
        final appliedAt = DateTime.tryParse(app['applied_at'] as String? ?? '') ?? DateTime.now();
        final updatedAt = DateTime.tryParse(app['updated_at'] as String? ?? '') ?? appliedAt;
        final formData = app['form_data'] is Map ? Map<String, dynamic>.from(app['form_data'] as Map) : <String, dynamic>{};
        final isVerified = (formData['payment_verified'] == true) ||
            (status == 'submitted' && step >= 1 && (app['progress_percent'] ?? 0) >= 20);

        // A. Visa File Submission Notification
        final subId = 'app_filed_$appId';
        if (!deletedIds.contains(subId)) {
          generated.add(
            NotificationItemModel(
              id: subId,
              title: 'Visa File Submitted',
              body:
                  'Your visa application for "$appTitle" (Ref: $refNo) has been successfully registered. SB Consultants immigration attorneys are reviewing your file.',
              timestamp: appliedAt,
              category: NotificationCategory.applications,
              isRead: readIds.contains(subId),
              actionRoute: AppRoutes.dashboard,
              actionLabel: 'Track File',
            ),
          );
        }

        // B. Payment Approval & Verification Notification
        if (isVerified) {
          final approvedId = 'pay_verified_$appId';
          if (!deletedIds.contains(approvedId)) {
            generated.add(
              NotificationItemModel(
                id: approvedId,
                title: 'Payment Approved & Verified',
                body:
                    'Payment for your "$appTitle" application (Ref: $refNo) has been verified and confirmed. Case Assessment & Strategy is underway.',
                timestamp: updatedAt,
                category: NotificationCategory.applications,
                isRead: readIds.contains(approvedId),
                actionRoute: AppRoutes.dashboard,
                actionLabel: 'View Application',
              ),
            );
          }
        } else if (status == 'under_review' || stepText.contains('Verification')) {
          final pendingId = 'pay_pending_$appId';
          if (!deletedIds.contains(pendingId)) {
            generated.add(
              NotificationItemModel(
                id: pendingId,
                title: 'Payment Verification in Progress',
                body:
                    'Your bank deposit / transfer slip for "$appTitle" (Ref: $refNo) has been received. Our finance desk is verifying clearance.',
                timestamp: appliedAt,
                category: NotificationCategory.applications,
                isRead: readIds.contains(pendingId),
                actionRoute: AppRoutes.dashboard,
                actionLabel: 'Check Status',
              ),
            );
          }
        }

        // C. Step Milestone Notification (for Step 2+)
        if (step >= 2) {
          final milestoneId = 'milestone_${appId}_$step';
          if (!deletedIds.contains(milestoneId)) {
            generated.add(
              NotificationItemModel(
                id: milestoneId,
                title: 'Case Progress: Step $step of 5',
                body:
                    'Milestone reached on "$appTitle": $stepText. Follow your scheduled procedure milestones in the portal.',
                timestamp: updatedAt,
                category: NotificationCategory.applications,
                isRead: readIds.contains(milestoneId),
                actionRoute: AppRoutes.dashboard,
                actionLabel: 'View Procedure',
              ),
            );
          }
        }
      }

      // D. User-Specific Payment Records
      for (final p in paymentRows) {
        final pId = p['id'] as String;
        final notifPId = 'payment_rcpt_$pId';
        if (deletedIds.contains(notifPId)) continue;

        final pStatus = p['status'] as String? ?? 'pending';
        final amount = p['amount'];
        final method = p['payment_method'] as String? ?? 'Bank Transfer';
        final createdAt = DateTime.tryParse(p['created_at'] as String? ?? '') ?? DateTime.now();

        if (pStatus == 'completed') {
          generated.add(
            NotificationItemModel(
              id: notifPId,
              title: 'Payment Confirmed',
              body:
                  'Official transaction of PKR $amount via $method was verified and confirmed.',
              timestamp: createdAt,
              category: NotificationCategory.applications,
              isRead: readIds.contains(notifPId),
              actionRoute: AppRoutes.dashboard,
              actionLabel: 'View Receipt',
            ),
          );
        }
      }

      // E. Custom Admin / Broadcast Announcements from public.notifications
      try {
        final notifsRes = await client
            .from('notifications')
            .select('*')
            .or('user_id.eq.$userId,user_id.is.null')
            .order('created_at', ascending: false);

        final notifRows = List<Map<String, dynamic>>.from(notifsRes);
        for (final row in notifRows) {
          final rowId = row['id']?.toString() ?? '';
          if (deletedIds.contains(rowId)) continue;

          final title = row['title']?.toString() ?? 'Notification';
          final body = row['body']?.toString() ?? '';
          final categoryStr = (row['category']?.toString() ?? 'system').toLowerCase();
          final actionRoute = row['action_route']?.toString();
          final actionLabel = row['action_label']?.toString();
          final createdAt = DateTime.tryParse(row['created_at']?.toString() ?? '') ?? DateTime.now();

          NotificationCategory cat = NotificationCategory.system;
          if (categoryStr.contains('app')) {
            cat = NotificationCategory.applications;
          } else if (categoryStr.contains('visa')) {
            cat = NotificationCategory.visaUpdates;
          } else if (categoryStr.contains('offer')) {
            cat = NotificationCategory.offers;
          }

          generated.add(
            NotificationItemModel(
              id: rowId,
              title: title,
              body: body,
              timestamp: createdAt,
              category: cat,
              isRead: readIds.contains(rowId) || (row['is_read'] == true),
              actionRoute: actionRoute,
              actionLabel: actionLabel,
            ),
          );
        }
      } catch (_) {}

      // Sort newest notifications first
      generated.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      state = generated;
      await _saveToCache(userId);
    } catch (_) {}
  }

  Future<void> _loadFromCache(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('sb_user_notifications_$userId');
      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(jsonString) as List<dynamic>;
        final items = decoded
            .map((item) => NotificationItemModel.fromJson(item as Map<String, dynamic>))
            .toList();
        if (items.isNotEmpty && _activeUserId == userId) {
          state = items;
        }
      }
    } catch (_) {}
  }

  Future<void> _saveToCache(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(state.map((e) => e.toJson()).toList());
      await prefs.setString('sb_user_notifications_$userId', encoded);
    } catch (_) {}
  }

  void markAsRead(String id) async {
    state = [
      for (final n in state)
        if (n.id == id) n.copyWith(isRead: true) else n,
    ];
    if (_activeUserId != null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final readIds = prefs.getStringList('sb_read_notifs_$_activeUserId')?.toSet() ?? <String>{};
        readIds.add(id);
        await prefs.setStringList('sb_read_notifs_$_activeUserId', readIds.toList());
        await _saveToCache(_activeUserId!);
      } catch (_) {}
    }
  }

  void markAllAsRead() async {
    state = [
      for (final n in state) n.copyWith(isRead: true),
    ];
    if (_activeUserId != null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final readIds = state.map((n) => n.id).toList();
        await prefs.setStringList('sb_read_notifs_$_activeUserId', readIds);
        await _saveToCache(_activeUserId!);
      } catch (_) {}
    }
  }

  void deleteNotification(String id) async {
    state = state.where((n) => n.id != id).toList();
    if (_activeUserId != null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final deletedIds = prefs.getStringList('sb_deleted_notifs_$_activeUserId')?.toSet() ?? <String>{};
        deletedIds.add(id);
        await prefs.setStringList('sb_deleted_notifs_$_activeUserId', deletedIds.toList());
        await _saveToCache(_activeUserId!);
      } catch (_) {}
    }
  }

  void clearAll() async {
    final allIds = state.map((n) => n.id).toList();
    state = [];
    if (_activeUserId != null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList('sb_deleted_notifs_$_activeUserId', allIds);
        await _saveToCache(_activeUserId!);
      } catch (_) {}
    }
  }

  /// Manually pushes a notification into the user's feed
  void pushNotification(NotificationItemModel item) {
    state = [item, ...state.where((n) => n.id != item.id)];
    if (_activeUserId != null) {
      _saveToCache(_activeUserId!);
    }
  }

  /// Helper to push visa file submission notification
  void pushVisaFileSubmitted({required String title, required String reference}) {
    pushNotification(
      NotificationItemModel(
        id: 'push_file_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Visa File Submitted',
        body: 'Your visa file for "$title" (Ref: $reference) has been filed and is undergoing legal review.',
        timestamp: DateTime.now(),
        category: NotificationCategory.applications,
        isRead: false,
        actionRoute: AppRoutes.dashboard,
        actionLabel: 'Track File',
      ),
    );
  }

  /// Helper to push payment approved notification
  void pushPaymentApproved({required String title, required String amount}) {
    pushNotification(
      NotificationItemModel(
        id: 'push_pay_approved_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Payment Approved & Verified',
        body: 'Your payment of PKR $amount for "$title" has been approved and confirmed. Tracking unlocked.',
        timestamp: DateTime.now(),
        category: NotificationCategory.applications,
        isRead: false,
        actionRoute: AppRoutes.dashboard,
        actionLabel: 'View Application',
      ),
    );
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _appsStreamSub?.cancel();
    _paymentsStreamSub?.cancel();
    _notifsStreamSub?.cancel();
    _broadcastChannel?.unsubscribe();
    super.dispose();
  }
}

/// Global provider for notifications list
final StateNotifierProvider<NotificationsNotifier, List<NotificationItemModel>> notificationsListProvider =
    StateNotifierProvider<NotificationsNotifier, List<NotificationItemModel>>(
  (ref) => NotificationsNotifier(),
);

/// Count of unread notifications
final Provider<int> unreadNotificationsCountProvider = Provider<int>((ref) {
  final notifs = ref.watch<List<NotificationItemModel>>(notificationsListProvider);
  return notifs.where((n) => !n.isRead).length;
});

/// Category filter state: null represents "All"
final StateProvider<NotificationCategory?> notificationCategoryFilterProvider =
    StateProvider<NotificationCategory?>((ref) => null);

/// Filtered notifications list according to selected category
final Provider<List<NotificationItemModel>> filteredNotificationsProvider =
    Provider<List<NotificationItemModel>>((ref) {
  final all = ref.watch<List<NotificationItemModel>>(notificationsListProvider);
  final filter = ref.watch<NotificationCategory?>(notificationCategoryFilterProvider);
  if (filter == null) return all;
  return all.where((n) => n.category == filter).toList();
});
