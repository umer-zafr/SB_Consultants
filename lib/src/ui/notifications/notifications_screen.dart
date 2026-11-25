import 'package:flutter_sd_consultant/src/imports/core_imports.dart';
import 'package:flutter_sd_consultant/src/imports/packages_imports.dart';
import 'package:flutter_sd_consultant/src/ui/notifications/models/notification_item_model.dart';
import 'package:flutter_sd_consultant/src/ui/notifications/providers/notifications_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final notifications = ref.watch(filteredNotificationsProvider);
    final allNotifications = ref.watch(notificationsListProvider);
    final unreadCount = ref.watch(unreadNotificationsCountProvider);
    final currentFilter = ref.watch(notificationCategoryFilterProvider);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF6F8FC),
      body: Column(
        children: [
          // 1. Top Custom Canopy AppBar
          _buildTopBar(context, ref, unreadCount, isDark),

          // 2. Filter Pills Row
          _buildFilterBar(ref, currentFilter, allNotifications, isDark),

          // 3. Notifications List or Empty State
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await ref.read(notificationsListProvider.notifier).refresh();
              },
              child: notifications.isEmpty
                  ? SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.6,
                        child: _buildEmptyState(context, ref, currentFilter, isDark),
                      ),
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 32.h),
                      itemCount: notifications.length,
                      separatorBuilder: (_, __) => SizedBox(height: 10.h),
                      itemBuilder: (context, index) {
                        final item = notifications[index];
                        return _buildNotificationCard(context, ref, item, isDark);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(
    BuildContext context,
    WidgetRef ref,
    int unreadCount,
    bool isDark,
  ) {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, MediaQuery.of(context).padding.top + 8.h, 16.w, 16.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121212) : const Color(0xFF1B3A5C),
        border: isDark
            ? const Border(
                bottom: BorderSide(color: Color(0xFF27272A), width: 1),
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button
          InkWell(
            onTap: () => context.pop(),
            borderRadius: BorderRadius.circular(20.r),
            child: Container(
              width: 38.w,
              height: 38.w,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),

          // Title with Unread Indicator
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Notifications',
                style: TextStyle(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              ),
              if (unreadCount > 0) ...[
                SizedBox(width: 8.w),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Text(
                    '$unreadCount new',
                    style: TextStyle(
                      fontSize: 10.5.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),

          // Mark all read action button
          InkWell(
            onTap: () {
              if (unreadCount > 0) {
                ref.read(notificationsListProvider.notifier).markAllAsRead();
                showToast(context, message: 'All notifications marked as read', status: 'success');
              } else {
                showToast(context, message: 'No unread notifications', status: 'info');
              }
            },
            borderRadius: BorderRadius.circular(20.r),
            child: Container(
              width: 38.w,
              height: 38.w,
              decoration: BoxDecoration(
                color: unreadCount > 0
                    ? Colors.white.withValues(alpha: 0.18)
                    : Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Tooltip(
                message: 'Mark all as read',
                child: Icon(
                  Icons.done_all_rounded,
                  color: unreadCount > 0 ? Colors.white : Colors.white.withValues(alpha: 0.45),
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(
    WidgetRef ref,
    NotificationCategory? currentFilter,
    List<NotificationItemModel> allNotifications,
    bool isDark,
  ) {
    final categories = <NotificationCategory?>[
      null,
      NotificationCategory.applications,
      NotificationCategory.visaUpdates,
      NotificationCategory.offers,
      NotificationCategory.system,
    ];

    return Container(
      width: double.infinity,
      color: isDark ? const Color(0xFF131F30) : Colors.white,
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Row(
          children: categories.map((cat) {
            final isSelected = currentFilter == cat;
            final label = cat == null ? 'All' : cat.label;
            final count = cat == null
                ? allNotifications.length
                : allNotifications.where((n) => n.category == cat).length;

            return Padding(
              padding: EdgeInsets.only(right: 8.w),
              child: InkWell(
                onTap: () {
                  ref.read(notificationCategoryFilterProvider.notifier).state = cat;
                },
                borderRadius: BorderRadius.circular(20.r),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark ? const Color(0xFF3B82F6) : const Color(0xFF1B3A5C))
                        : (isDark ? const Color(0xFF18181B) : const Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : (isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0)),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? const Color(0xFFA1A1AA) : const Color(0xFF475569)),
                        ),
                      ),
                      SizedBox(width: 5.w),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.25)
                              : (isDark
                                  ? const Color(0xFF27272A)
                                  : const Color(0xFFE2E8F0)),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? const Color(0xFFA1A1AA) : const Color(0xFF64748B)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    WidgetRef ref,
    NotificationItemModel item,
    bool isDark,
  ) {
    final iconData = _getCategoryIcon(item.category);
    final iconBgColor = _getCategoryBgColor(item.category, isDark);
    final iconColor = _getCategoryColor(item.category, isDark);

    return Dismissible(
      key: Key('notif_item_${item.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        ref.read(notificationsListProvider.notifier).deleteNotification(item.id);
        if (context.mounted) {
          showToast(context, message: 'Notification dismissed', status: 'info');
        }
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20.w),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 24),
      ),
      child: InkWell(
        onTap: () {
          ref.read(notificationsListProvider.notifier).markAsRead(item.id);
          _showNotificationDetailModal(context, ref, item, isDark);
        },
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: isDark
                ? (item.isRead ? const Color(0xFF121212) : const Color(0xFF18181B))
                : (item.isRead ? Colors.white : const Color(0xFFF0F6FD)),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isDark
                  ? (item.isRead ? const Color(0xFF27272A) : const Color(0xFF3B82F6).withValues(alpha: 0.4))
                  : (item.isRead ? const Color(0xFFE8EEF5) : const Color(0xFFBFDBFE)),
              width: item.isRead ? 1 : 1.3,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.2)
                    : const Color(0xFF1B3A5C).withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Icon
              Container(
                width: 42.w,
                height: 42.w,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Center(
                  child: Icon(iconData, color: iconColor, size: 22.sp),
                ),
              ),
              SizedBox(width: 12.w),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 13.5.sp,
                              fontWeight: item.isRead ? FontWeight.w600 : FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        if (!item.isRead) ...[
                          Container(
                            width: 8.w,
                            height: 8.w,
                            margin: EdgeInsets.symmetric(horizontal: 6.w),
                            decoration: const BoxDecoration(
                              color: Color(0xFF2563EB),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                        // Cross / Dismiss button on the card
                        InkWell(
                          onTap: () {
                            HapticFeedback.selectionClick().ignore();
                            ref.read(notificationsListProvider.notifier).deleteNotification(item.id);
                            if (context.mounted) {
                              showToast(context, message: 'Notification dismissed', status: 'info');
                            }
                          },
                          borderRadius: BorderRadius.circular(12.r),
                          child: Padding(
                            padding: EdgeInsets.all(4.w),
                            child: Icon(
                              Icons.close_rounded,
                              size: 16.sp,
                              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      item.body,
                      style: TextStyle(
                        fontSize: 12.sp,
                        height: 1.35,
                        color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF475569),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatRelativeTime(item.timestamp),
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w500,
                            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                          ),
                        ),
                        if (item.actionLabel != null) ...[
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                item.actionLabel!,
                                style: TextStyle(
                                  fontSize: 11.5.sp,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1B3A5C),
                                ),
                              ),
                              SizedBox(width: 2.w),
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 14.sp,
                                color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1B3A5C),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    WidgetRef ref,
    NotificationCategory? currentFilter,
    bool isDark,
  ) {
    final isCategoryFiltered = currentFilter != null;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 76.w,
              height: 76.w,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF18181B) : const Color(0xFFEDF4FC),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isCategoryFiltered ? Icons.filter_list_off_rounded : Icons.notifications_none_rounded,
                size: 38.sp,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF1B3A5C),
              ),
            ),
            SizedBox(height: 18.h),
            Text(
              isCategoryFiltered
                  ? 'No ${currentFilter.label} Notifications'
                  : 'No Notifications Yet',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF171C21),
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              isCategoryFiltered
                  ? 'You have no notifications under this category.'
                  : 'You have no notifications right now. When you submit a visa file, make a payment, or receive updates from your consultant, they will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5.sp,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            SizedBox(height: 20.h),
            if (isCategoryFiltered)
              OutlinedButton.icon(
                onPressed: () {
                  ref.read(notificationCategoryFilterProvider.notifier).state = null;
                },
                icon: const Icon(Icons.clear_all_rounded, size: 16),
                label: const Text('Show All Notifications'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark ? Colors.white : const Color(0xFF1B3A5C),
                  side: BorderSide(
                    color: isDark ? const Color(0xFF27272A) : const Color(0xFF1B3A5C),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: () {
                  context.go(AppRoutes.home);
                },
                icon: const Icon(Icons.explore_outlined, size: 16),
                label: const Text('Explore Visa Categories'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? const Color(0xFF3B82F6) : const Color(0xFF1B3A5C),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 11.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.applications:
        return Icons.assignment_ind_outlined;
      case NotificationCategory.visaUpdates:
        return Icons.public_rounded;
      case NotificationCategory.offers:
        return Icons.card_giftcard_rounded;
      case NotificationCategory.system:
        return Icons.notifications_active_outlined;
    }
  }

  Color _getCategoryColor(NotificationCategory category, bool isDark) {
    switch (category) {
      case NotificationCategory.applications:
        return isDark ? const Color(0xFF60A5FA) : const Color(0xFF0284C7);
      case NotificationCategory.visaUpdates:
        return isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706);
      case NotificationCategory.offers:
        return isDark ? const Color(0xFFA78BFA) : const Color(0xFF7C3AED);
      case NotificationCategory.system:
        return isDark ? const Color(0xFF34D399) : const Color(0xFF059669);
    }
  }

  Color _getCategoryBgColor(NotificationCategory category, bool isDark) {
    switch (category) {
      case NotificationCategory.applications:
        return isDark ? const Color(0xFF0C4A6E) : const Color(0xFFE0F2FE);
      case NotificationCategory.visaUpdates:
        return isDark ? const Color(0xFF78350F) : const Color(0xFFFEF3C7);
      case NotificationCategory.offers:
        return isDark ? const Color(0xFF4C1D95) : const Color(0xFFEDE9FE);
      case NotificationCategory.system:
        return isDark ? const Color(0xFF064E3B) : const Color(0xFFD1FAE5);
    }
  }

  String _formatRelativeTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else {
      return '${diff.inDays}d ago';
    }
  }

  String _getCategoryName(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.applications:
        return 'Application';
      case NotificationCategory.visaUpdates:
        return 'Visa Update';
      case NotificationCategory.offers:
        return 'Exclusive Offer';
      case NotificationCategory.system:
        return 'System Alert';
    }
  }

  void _showNotificationDetailModal(
    BuildContext context,
    WidgetRef ref,
    NotificationItemModel item,
    bool isDark,
  ) {
    final iconData = _getCategoryIcon(item.category);
    final iconBgColor = _getCategoryBgColor(item.category, isDark);
    final iconColor = _getCategoryColor(item.category, isDark);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF121212) : Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 24.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF27272A) : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              SizedBox(height: 16.h),

              // Header Row with Category Badge & Close Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(iconData, color: iconColor, size: 16.sp),
                        SizedBox(width: 6.w),
                        Text(
                          _getCategoryName(item.category),
                          style: TextStyle(
                            fontSize: 11.5.sp,
                            fontWeight: FontWeight.w700,
                            color: iconColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      size: 20.sp,
                    ),
                    onPressed: () => Navigator.of(ctx).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              SizedBox(height: 14.h),

              // Title
              Text(
                item.title,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  height: 1.3,
                ),
              ),
              SizedBox(height: 6.h),

              // Timestamp
              Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 13.sp,
                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    _formatRelativeTime(item.timestamp),
                    style: TextStyle(
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.w500,
                      color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),

              // Body in a subtle styled card
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF18181B) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Text(
                  item.body,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                    height: 1.5,
                  ),
                ),
              ),
              SizedBox(height: 20.h),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFEF4444),
                        side: BorderSide(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        ref.read(notificationsListProvider.notifier).deleteNotification(item.id);
                        if (context.mounted) {
                          showToast(context, message: 'Notification removed', status: 'info');
                        }
                      },
                      icon: const Icon(Icons.delete_outline_rounded, size: 16),
                      label: const Text('Delete'),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  if (item.actionRoute != null && item.actionRoute!.isNotEmpty) ...[
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? const Color(0xFF3B82F6) : const Color(0xFF1B3A5C),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          context.push(item.actionRoute!);
                        },
                        icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                        label: Text(item.actionLabel ?? 'View Details'),
                      ),
                    ),
                  ] else ...[
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          side: BorderSide(
                            color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Close'),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
