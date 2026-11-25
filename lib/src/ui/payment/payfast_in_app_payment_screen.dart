import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_sd_consultant/src/data/models/detail_item_model.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Result object returned by the PayFast In-App gateway.
class PayFastCheckoutResult {
  final bool isSuccess;
  final String? errorCode;
  final String? errorMessage;
  final String? transactionId;
  final String? basketId;
  final bool userCancelled;

  const PayFastCheckoutResult({
    required this.isSuccess,
    this.errorCode,
    this.errorMessage,
    this.transactionId,
    this.basketId,
    this.userCancelled = false,
  });

  bool get isMerchantNotReady =>
      errorCode == '001' ||
      (errorMessage != null &&
          (errorMessage!.toLowerCase().contains('invalid merchant') ||
           errorMessage!.toLowerCase().contains('not ready') ||
           errorMessage!.toLowerCase().contains('service not ready')));
}

/// Official In-App PayFast IPG Gateway screen.
/// Renders the real PayFast Pakistan payment portal inside the app without external browser redirection.
class PayFastInAppPaymentScreen extends ConsumerStatefulWidget {
  const PayFastInAppPaymentScreen({
    super.key,
    required this.checkoutUrl,
    this.checkoutHtml,
    required this.transactionId,
    required this.referenceId,
    required this.amount,
    this.merchantId = '102',
    this.isSandbox = true,
    this.item,
    this.finalPaidItem,
  });

  final String checkoutUrl;
  final String? checkoutHtml;
  final String transactionId;
  final String referenceId;
  final double amount;
  final String merchantId;
  final bool isSandbox;
  final DetailItemModel? item;
  final DetailItemModel? finalPaidItem;

  @override
  ConsumerState<PayFastInAppPaymentScreen> createState() =>
      _PayFastInAppPaymentScreenState();
}

class _PayFastInAppPaymentScreenState
    extends ConsumerState<PayFastInAppPaymentScreen> {
  late final WebViewController _controller;
  int _loadingProgress = 0;
  bool _hasError = false;
  bool _hasNavigatedBack = false;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (mounted) setState(() => _loadingProgress = progress);
          },
          onPageStarted: (url) {
            if (mounted) {
              setState(() {
                _hasError = false;
                _loadingProgress = 15;
              });
            }
            _checkCallbackUrl(url);
          },
          onPageFinished: (url) {
            if (mounted) setState(() => _loadingProgress = 100);
            _checkCallbackUrl(url);
          },
          onWebResourceError: (error) {
            debugPrint(
                'PayFast WebView Resource Notice: [${error.errorCode}] ${error.description}');
          },
          onNavigationRequest: (request) {
            if (_checkCallbackUrl(request.url)) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );

    _loadContent();
  }

  void _loadContent() {
    if (widget.checkoutHtml != null && widget.checkoutHtml!.isNotEmpty) {
      _controller.loadHtmlString(
        widget.checkoutHtml!,
        baseUrl: 'https://ipg1.apps.net.pk',
      );
    } else {
      final uri = Uri.tryParse(widget.checkoutUrl);
      if (uri != null) {
        _controller.loadRequest(uri);
      }
    }
  }

  bool _checkCallbackUrl(String url) {
    if (_hasNavigatedBack) return true;
    final lower = url.toLowerCase();
    final uri = Uri.tryParse(url);
    final errCode = uri?.queryParameters['err_code'];
    final errMsg = uri?.queryParameters['err_msg'] ?? uri?.queryParameters['message'];
    final txId = uri?.queryParameters['transaction_id'] ?? uri?.queryParameters['tx'];
    final basketId = uri?.queryParameters['basket_id'];

    // Intercept callback URLs returned by PayFast
    if (lower.contains('status=success') ||
        lower.contains('response_code=000') ||
        lower.contains('status=completed')) {
      _hasNavigatedBack = true;
      if (mounted) {
        Navigator.of(context).pop(PayFastCheckoutResult(
          isSuccess: true,
          transactionId: txId ?? widget.transactionId,
          basketId: basketId ?? widget.referenceId,
        ));
      }
      return true;
    } else if (lower.contains('status=cancel') ||
        lower.contains('status=failed') ||
        lower.contains('status=failure') ||
        errCode != null) {
      _hasNavigatedBack = true;
      if (mounted) {
        Navigator.of(context).pop(PayFastCheckoutResult(
          isSuccess: false,
          errorCode: errCode,
          errorMessage: errMsg,
          transactionId: txId ?? widget.transactionId,
          basketId: basketId ?? widget.referenceId,
          userCancelled: lower.contains('cancel') && errCode == null,
        ));
      }
      return true;
    }
    return false;
  }

  Future<bool> _handleWillPop() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: const Color(0xFFD97706), size: 22.sp),
              SizedBox(width: 8.w),
              const Text('Cancel Payment?'),
            ],
          ),
          content: const Text(
            'Are you sure you want to exit the PayFast payment gateway? Your transaction will not be processed.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: const Text('Stay'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              onPressed: () => Navigator.of(dialogCtx).pop(true),
              child: const Text('Cancel Payment'),
            ),
          ],
        );
      },
    );
    return shouldExit ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await _handleWillPop();
        if (shouldExit && context.mounted) {
          Navigator.of(context).pop(PayFastCheckoutResult(
            isSuccess: false,
            userCancelled: true,
            transactionId: widget.transactionId,
            basketId: widget.referenceId,
          ));
        }
      },
      child: Scaffold(
        backgroundColor:
            isDark ? const Color(0xFF000000) : const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor:
              isDark ? const Color(0xFF121212) : const Color(0xFF002244),
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            tooltip: 'Cancel Payment',
            onPressed: () async {
              final shouldExit = await _handleWillPop();
              if (shouldExit && context.mounted) {
                Navigator.of(context).pop(PayFastCheckoutResult(
                  isSuccess: false,
                  userCancelled: true,
                  transactionId: widget.transactionId,
                  basketId: widget.referenceId,
                ));
              }
            },
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'PayFast Official Gateway',
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.5.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_rounded, size: 9.sp, color: Colors.white),
                        SizedBox(width: 2.w),
                        Text(
                          'SSL',
                          style: TextStyle(
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Text(
                'State Bank SBP Regulated • All Info Secure',
                style: TextStyle(
                  fontSize: 10.5.sp,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              tooltip: 'Reload',
              onPressed: () {
                setState(() {
                  _hasError = false;
                  _loadingProgress = 10;
                });
                _controller.reload();
              },
            ),
          ],
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(3.h),
            child: _loadingProgress < 100
                ? LinearProgressIndicator(
                    value: _loadingProgress / 100.0,
                    backgroundColor: Colors.white24,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Color(0xFF22C55E)),
                    minHeight: 3.h,
                  )
                : const SizedBox.shrink(),
          ),
        ),
        body: Column(
          children: [
            if (widget.isSandbox || widget.merchantId == '102')
              _buildSandboxTestingToolbar(isDark),
            Expanded(
              child: Stack(
                children: [
                  // 1. Official Hosted PayFast Payment Gateway WebView
                  WebViewWidget(controller: _controller),

            // 2. Clean Connection Retry Screen (Only shown if device has network failure)
            if (_hasError)
              Container(
                color: isDark ? const Color(0xFF000000) : Colors.white,
                padding: EdgeInsets.all(28.w),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 64.w,
                        height: 64.w,
                        decoration: BoxDecoration(
                          color: const Color(0xFF002244).withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.wifi_off_rounded,
                          size: 30.sp,
                          color: const Color(0xFF002244),
                        ),
                      ),
                      SizedBox(height: 18.h),
                      Text(
                        'Connection Issue',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w700,
                          color:
                              isDark ? Colors.white : const Color(0xFF171C21),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Unable to connect to PayFast payment gateway.\nPlease check your internet connection and try again.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12.5.sp,
                          color: const Color(0xFF64748B),
                          height: 1.5,
                        ),
                      ),
                      SizedBox(height: 24.h),
                      SizedBox(
                        width: 200.w,
                        height: 44.h,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF002244),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                          ),
                          onPressed: () {
                            setState(() => _hasError = false);
                            _loadContent();
                          },
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: Text(
                            'Retry Connection',
                            style: TextStyle(
                              fontSize: 13.5.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // 3. Security Padlock Footer Banner
            Positioned(
              left: 16.w,
              right: 16.w,
              bottom: 16.h,
              child: IgnorePointer(
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: (isDark
                            ? const Color(0xFF18181B)
                            : const Color(0xFF002244))
                        .withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(30.r),
                    border: Border.all(
                      color: isDark ? const Color(0xFF27272A) : Colors.transparent,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.verified_user_rounded,
                        size: 13.sp,
                        color: const Color(0xFF22C55E),
                      ),
                      SizedBox(width: 6.w),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'All Info Secure • Official PayFast Pakistan IPG',
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  ),
  ),
);
}

Widget _buildSandboxTestingToolbar(bool isDark) {
  return Container(
    width: double.infinity,
    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
    decoration: BoxDecoration(
      color: isDark ? const Color(0xFF18181B) : const Color(0xFFFFFBEB),
      border: Border(
        bottom: BorderSide(
          color: isDark ? const Color(0xFF27272A) : const Color(0xFFFDE68A),
        ),
      ),
    ),
    child: Row(
      children: [
        Icon(Icons.science_rounded, size: 15.sp, color: const Color(0xFFD97706)),
        SizedBox(width: 8.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'PayFast Testing Card (Merchant ID: 102)',
                style: TextStyle(
                  fontSize: 10.5.sp,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF92400E),
                ),
              ),
              Text(
                '5123-4500-0000-0008  •  Exp: 01/39  •  CVV: 100',
                style: TextStyle(
                  fontSize: 10.sp,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFFB45309),
                ),
              ),
            ],
          ),
        ),
        InkWell(
          onTap: () {
            Clipboard.setData(const ClipboardData(text: '5123450000000008'));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Copied card number 5123-4500-0000-0008'),
                duration: Duration(seconds: 2),
              ),
            );
          },
          borderRadius: BorderRadius.circular(6.r),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: const Color(0xFFD97706),
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.copy_rounded, size: 11.sp, color: Colors.white),
                SizedBox(width: 3.w),
                Text(
                  'Copy Card',
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: 6.w),
        InkWell(
          onTap: _fillWebViewForm,
          borderRadius: BorderRadius.circular(6.r),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: const Color(0xFF1B3A5C),
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_fix_high_rounded, size: 11.sp, color: Colors.white),
                SizedBox(width: 3.w),
                Text(
                  'Auto-fill',
                  style: TextStyle(
                    fontSize: 10.sp,
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
  );
}

void _fillWebViewForm() {
  _controller.runJavaScript('''
    (function() {
      const inputs = document.querySelectorAll('input');
      for (const input of inputs) {
        const id = (input.id || '').toLowerCase();
        const name = (input.name || '').toLowerCase();
        const placeholder = (input.placeholder || '').toLowerCase();
        if (id.includes('card') || name.includes('card') || placeholder.includes('card') || id.includes('pan')) {
          input.value = '5123450000000008';
          input.dispatchEvent(new Event('input', { bubbles: true }));
          input.dispatchEvent(new Event('change', { bubbles: true }));
        } else if (id.includes('exp') || name.includes('exp') || placeholder.includes('exp') || placeholder.includes('mm/yy')) {
          input.value = '01/39';
          input.dispatchEvent(new Event('input', { bubbles: true }));
          input.dispatchEvent(new Event('change', { bubbles: true }));
        } else if (id.includes('cvv') || name.includes('cvv') || id.includes('cvc') || placeholder.includes('cvv')) {
          input.value = '100';
          input.dispatchEvent(new Event('input', { bubbles: true }));
          input.dispatchEvent(new Event('change', { bubbles: true }));
        }
      }
    })();
  ''');
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Attempted auto-fill on PayFast web portal'),
      duration: Duration(seconds: 1),
    ),
  );
}
}
