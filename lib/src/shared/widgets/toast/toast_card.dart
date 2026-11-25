import '../../../imports/imports.dart';

/// Modern, clean, and premium notification toast card widget.
///
/// Features:
/// - Floating capsule / card with subtle border and elevation
/// - Balanced status badge with clean icon and typography
/// - Support for title, description, and dismiss trailing action
class ToastCard extends StatelessWidget {
  final Widget title;
  final Widget? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final Color? color;
  final Color? borderColor;
  final Color? shadowColor;
  final void Function()? onTap;

  const ToastCard({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.color,
    this.borderColor,
    this.shadowColor,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final defaultBg = isDark ? const Color(0xFF18181B) : Colors.white;
    final defaultBorder = isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0);
    final defaultShadow = isDark
        ? Colors.black.withValues(alpha: 0.35)
        : const Color(0xFF0F172A).withValues(alpha: 0.08);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: color ?? defaultBg,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: borderColor ?? defaultBorder,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 16,
            spreadRadius: 0,
            offset: const Offset(0, 6),
            color: shadowColor ?? defaultShadow,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            child: Row(
              children: [
                if (leading != null) ...[
                  leading!,
                  SizedBox(width: 12.w),
                ],
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      title,
                      if (subtitle != null) ...[
                        SizedBox(height: 2.h),
                        subtitle!,
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  SizedBox(width: 8.w),
                  trailing!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
