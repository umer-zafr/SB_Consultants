import 'package:flutter_sd_consultant/src/imports/core_imports.dart';
import 'package:flutter_sd_consultant/src/imports/packages_imports.dart';

/// Reusable social login button (Google) with professional loading state & styling.
class SocialLoginButton extends StatelessWidget {
  const SocialLoginButton({
    super.key,
    required this.asset,
    required this.label,
    required this.onPressed,
    this.height,
    this.isLoading = false,
    this.loadingLabel = 'Signing in with Google...',
  });

  final String asset;
  final String label;
  final VoidCallback? onPressed;
  final double? height;
  final bool isLoading;
  final String loadingLabel;

  @override
  Widget build(BuildContext context) {
    final tt = context.theme.textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: height ?? 52.h,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          side: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.15)
                : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
          elevation: isDark ? 0 : 0.5,
          shadowColor: Colors.black.withValues(alpha: 0.05),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.r),
          ),
          padding: EdgeInsets.symmetric(horizontal: 16.w),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: isLoading
              ? Row(
                  key: const ValueKey('loading'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 18.w,
                      height: 18.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isDark ? Colors.white : const Color(0xFF1B3A5C),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Flexible(
                      child: Text(
                        loadingLabel,
                        style: tt.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? Colors.white70
                              : const Color(0xFF475569),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                )
              : Row(
                  key: const ValueKey('idle'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      asset,
                      width: 22.w,
                      height: 22.w,
                      fit: BoxFit.contain,
                    ),
                    SizedBox(width: 12.w),
                    Flexible(
                      child: Text(
                        label,
                        style: tt.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF1E293B),
                          letterSpacing: 0.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
