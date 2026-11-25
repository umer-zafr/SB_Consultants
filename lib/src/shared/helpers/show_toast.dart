import '../../imports/imports.dart';

/// Displays a modern, clean, floating in-app notification popup toast.
///
/// Features:
/// - Safe area aware, non-intrusive floating pill card
/// - Distinct status color coding (success, error, warning, info)
/// - High-contrast typography with auto-wrapping up to 3 lines
/// - One-tap dismiss and swipe-up to dismiss gestures
void showToast(
  BuildContext context, {
  required String message,
  String? status = 'success',
  dynamic icon,
  Duration? duration,
  bool? autoDismiss,
}) {
  final safeContext = (context.mounted ? context : rootContext) ?? context;
  if (!safeContext.mounted && rootContext == null) return;
  final effectiveContext = safeContext.mounted ? safeContext : (rootContext ?? safeContext);

  final isDark = Theme.of(effectiveContext).brightness == Brightness.dark;
  final toastStatus = (status ?? 'info').toLowerCase();

  final (IconData defaultIcon, Color iconColor, Color badgeBg, Color borderColor) = switch (toastStatus) {
    'error' => (
        Icons.error_rounded,
        const Color(0xFFDC2626),
        isDark ? const Color(0xFF450A0A) : const Color(0xFFFEE2E2),
        isDark ? const Color(0xFF991B1B) : const Color(0xFFFECACA),
      ),
    'warning' => (
        Icons.warning_amber_rounded,
        const Color(0xFFD97706),
        isDark ? const Color(0xFF451A03) : const Color(0xFFFEF3C7),
        isDark ? const Color(0xFF92400E) : const Color(0xFFFDE68A),
      ),
    'info' => (
        Icons.info_rounded,
        const Color(0xFF2563EB),
        isDark ? const Color(0xFF172554) : const Color(0xFFDBEAFE),
        isDark ? const Color(0xFF1E40AF) : const Color(0xFFBFDBFE),
      ),
    _ => ( // 'success'
        Icons.check_circle_rounded,
        const Color(0xFF16A34A),
        isDark ? const Color(0xFF052E16) : const Color(0xFFDCFCE7),
        isDark ? const Color(0xFF166534) : const Color(0xFFBBF7D0),
      ),
  };

  late final ToastBar toastBar;

  toastBar = ToastBar(
    position: ToastPosition.top,
    autoDismiss: autoDismiss ?? true,
    toastDuration: duration ?? const Duration(milliseconds: 2800),
    animationDuration: const Duration(milliseconds: 280),
    animationCurve: Curves.easeOutCubic,
    builder: (ctx) => ToastCard(
      color: isDark ? const Color(0xFF18181B) : Colors.white,
      borderColor: borderColor,
      shadowColor: isDark
          ? Colors.black.withValues(alpha: 0.4)
          : const Color(0xFF0F172A).withValues(alpha: 0.1),
      leading: Container(
        padding: EdgeInsets.all(7.w),
        decoration: BoxDecoration(
          color: badgeBg,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon is IconData ? icon : defaultIcon,
          color: iconColor,
          size: 18.sp,
        ),
      ),
      title: Text(
        message,
        style: TextStyle(
          fontSize: 12.5.sp,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : const Color(0xFF0F172A),
          height: 1.35,
        ),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: InkWell(
        onTap: () {
          HapticFeedback.selectionClick().ignore();
          toastBar.remove();
        },
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Icon(
            Icons.close_rounded,
            size: 16.sp,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
      ),
    ),
  );

  toastBar.show(effectiveContext);
}

/// Dispatches a modern toast globally using [rootContext].
void showGlobalToast({
  required String message,
  String? status = 'success',
  dynamic icon,
  Duration? duration,
  bool? autoDismiss,
}) {
  final ctx = rootContext;
  if (ctx == null) return;

  showToast(
    ctx,
    message: message,
    status: status,
    icon: icon,
    duration: duration,
    autoDismiss: autoDismiss,
  );
}
