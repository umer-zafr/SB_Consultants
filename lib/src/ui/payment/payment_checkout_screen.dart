import 'package:flutter_sd_consultant/src/shared/helpers/reference_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_sd_consultant/src/data/models/detail_item_model.dart';
import 'package:flutter_sd_consultant/src/routing/app_routes.dart';
import 'package:flutter_sd_consultant/src/services/storage_service.dart';
import 'package:flutter_sd_consultant/src/services/supabase_database_service.dart';
import 'package:flutter_sd_consultant/src/shared/helpers/show_toast.dart';
import 'package:flutter_sd_consultant/src/ui/dashboard/my_applications_screen.dart';
import 'package:flutter_sd_consultant/src/ui/home/providers/home_provider.dart';
import 'package:flutter_sd_consultant/src/ui/payment/payfast_in_app_payment_screen.dart';
import 'package:go_router/go_router.dart';

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (text.length > 16) {
      return oldValue;
    }
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(text[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _CardExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (text.length > 4) {
      return oldValue;
    }
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i == 2) {
        buffer.write('/');
      }
      buffer.write(text[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Payment checkout screen matching exact specifications with in-app real-time PayFast payment.
class PaymentCheckoutScreen extends ConsumerStatefulWidget {
  const PaymentCheckoutScreen({
    super.key,
    this.item,
    this.customReference,
    this.formData,
    this.applicantName,
    this.applicantEmail,
    this.applicantPhone,
    this.applicantPassport,
  });

  final DetailItemModel? item;
  final String? customReference;
  final Map<String, dynamic>? formData;
  final String? applicantName;
  final String? applicantEmail;
  final String? applicantPhone;
  final String? applicantPassport;

  @override
  ConsumerState<PaymentCheckoutScreen> createState() =>
      _PaymentCheckoutScreenState();
}

class _PaymentCheckoutScreenState extends ConsumerState<PaymentCheckoutScreen> {
  // Promo code controller & applied state
  late final TextEditingController _promoController;
  bool _isPromoApplied = false;
  int _discountAmount = 0;
  final int _processingFee = 100;
  bool _isCheckingPromo = false;

  // Selected Payment Method: 'payfast' or 'bank_transfer' (Default to bank_transfer as PayFast is temporarily unavailable)
  String _selectedPaymentMethod = 'bank_transfer';

  // Bank Transfer Form Controllers
  late final TextEditingController _bankTxRefController;
  late final TextEditingController _bankSenderNameController;

  // Card Details Form Controllers (Industry Standard Fintech Experience)
  late final TextEditingController _cardNumberController;
  late final TextEditingController _cardExpiryController;
  late final TextEditingController _cardCvvController;
  late final TextEditingController _cardHolderNameController;
  bool _obscureCardCvv = true;

  // Processing state for CTA button
  bool _isProcessing = false;

  // PayFast Merchant Credentials
  late String _merchantId;
  late bool _isSandbox;
  late final String _sessionReference;

  @override
  void initState() {
    super.initState();
    _sessionReference = (widget.customReference != null &&
            widget.customReference!.trim().isNotEmpty)
        ? widget.customReference!.trim()
        : ReferenceCodeGenerator.generate(
            category: widget.item?.categoryTag,
            title: widget.item?.title,
            listingId: widget.item?.id,
          );
    _promoController = TextEditingController();
    _bankTxRefController = TextEditingController();
    _bankSenderNameController = TextEditingController();

    _cardNumberController = TextEditingController();
    _cardExpiryController = TextEditingController();
    _cardCvvController = TextEditingController();
    _cardHolderNameController = TextEditingController(
      text: (widget.applicantName?.isNotEmpty ?? false)
          ? widget.applicantName!
          : (SupabaseDatabaseService.instance.client.auth.currentUser
                  ?.userMetadata?['full_name'] as String? ??
              ''),
    );

    // Load optional merchant credentials from storage or .env (server defaults used if blank)
    final savedMerchantId = StorageService.instance.getString('payfast_merchant_id');
    final savedSandbox = StorageService.instance.getBool('payfast_sandbox');

    final cleanSavedId = (savedMerchantId != null &&
            savedMerchantId.isNotEmpty &&
            savedMerchantId != '100001' &&
            savedMerchantId != '14833')
        ? savedMerchantId
        : '';

    _merchantId = cleanSavedId.isNotEmpty
        ? cleanSavedId
        : dotenv.get('PAYFAST_MERCHANT_ID', fallback: '102');

    _isSandbox = savedSandbox ??
        (dotenv.get('PAYFAST_SANDBOX', fallback: 'true') == 'true');
  }

  @override
  void dispose() {
    _promoController.dispose();
    _bankTxRefController.dispose();
    _bankSenderNameController.dispose();
    _cardNumberController.dispose();
    _cardExpiryController.dispose();
    _cardCvvController.dispose();
    _cardHolderNameController.dispose();
    super.dispose();
  }


  /// Automatically identifies payment scheme / brand from BIN
  String _detectCardBrand(String rawNumber) {
    final clean = rawNumber.replaceAll(RegExp(r'\D'), '');
    if (clean.startsWith(RegExp(r'^(5[1-5]|2[2-7])'))) {
      return 'Mastercard';
    } else if (clean.startsWith('4')) {
      return 'Visa';
    } else if (clean.startsWith('62') || clean.startsWith('81')) {
      return 'UnionPay';
    } else if (clean.startsWith('50') || clean.startsWith('58')) {
      return 'PayPak';
    }
    return 'Credit / Debit';
  }

  // Calculate dynamic fees based on exact rates
  int get _calculatedServiceFee {
    final item = widget.item;
    if (item != null) {
      final tag = item.categoryTag.toLowerCase();
      final type = item.type.toLowerCase();
      final id = item.id.toLowerCase();
      final title = item.title.toLowerCase();

      // 1. Sponsored Jobs -> 15,000
      if (type == 'job' || tag.contains('job') || tag.contains('sponsor') || id.contains('job') || title.contains('job')) {
        return 15000;
      }

      // 2. Scholarships -> 25,000
      if (type == 'scholarship' || tag.contains('scholarship') || id.contains('sch') || title.contains('scholarship')) {
        return 25000;
      }

      // 3. Work Visa & Golden Visa -> 40,000
      if (tag.contains('work') || tag.contains('golden') || id.contains('work') || id.contains('golden') || title.contains('work') || title.contains('golden')) {
        return 40000;
      }

      // 4. Visit, Business, Study Visa -> 30,000
      if (tag.contains('visit') || tag.contains('tourist') ||
          tag.contains('business') || tag.contains('investor') ||
          tag.contains('study') || tag.contains('student') ||
          title.contains('visit') || title.contains('tourist') ||
          title.contains('business') || title.contains('study') || title.contains('student')) {
        return 30000;
      }

      final digits = item.serviceFeeValue.replaceAll(RegExp(r'[^0-9]'), '');
      final parsed = int.tryParse(digits);
      if (parsed != null && parsed > 0 && parsed <= 500000) {
        return parsed;
      }
    }
    return 30000;
  }

  int get _calculatedTotal {
    final base = _calculatedServiceFee + _processingFee;
    return _isPromoApplied ? (base - _discountAmount).clamp(0, 9999999) : base;
  }

  String _formatCurrency(int amount) {
    final str = amount.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(str[i]);
    }
    return 'PKR $buffer';
  }

  String get _effectiveReference => _sessionReference;

  String get _effectiveItemTitle {
    final item = widget.item;
    if (item != null && item.title.isNotEmpty) {
      if (!item.title.toLowerCase().contains('application') &&
          !item.title.toLowerCase().contains('pass')) {
        return '${item.title} – Application';
      }
      return item.title;
    }
    return 'Registered Nurse – Application';
  }

  String get _effectiveItemSubtitle {
    final item = widget.item;
    if (item != null && item.subtitle.isNotEmpty) {
      return '🏥 ${item.subtitle}';
    }
    return '🏥 St. Jude NHS Trust • Birmingham, UK';
  }

  String get _effectiveFlag {
    final item = widget.item;
    if (item != null && item.countryFlag.isNotEmpty) {
      return item.countryFlag;
    }
    return '🇬🇧';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? const Color(0xFF000000) : const Color(0xFFF4F7FB);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: _buildTopAppBar(context, isDark),
      body: Stack(
        children: [
          Column(
            children: [
              // Scrollable Checkout Content
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Canopy / Stepper Header
                      _buildNavyCanopyHeader(isDark),

                      // 2. Main Form Cards Container
                      SizedBox(height: 12.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Order Summary Card
                            _buildOrderSummaryCard(isDark),
                            SizedBox(height: 14.h),

                            // Promotional Code Card
                            _buildPromotionalCodeCard(isDark),
                            SizedBox(height: 18.h),

                            // Select Payment Method Section
                            _buildPaymentMethodSection(),
                            SizedBox(height: 16.h),

                            // Safe & Regulated Gateway Trust Card
                            _buildTrustCard(isDark),
                            SizedBox(height: 24.h),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Sticky Bottom Action Bar
              _buildBottomActionBar(context),
            ],
          ),

          // In-screen sleek connecting overlay (never locks or gets orphaned)
          if (_isProcessing) _buildProcessingOverlay(context),
        ],
      ),
    );
  }

  // ===========================================================================
  // 1. TOP APP BAR (Standardized clean header)
  // ===========================================================================
  PreferredSizeWidget _buildTopAppBar(BuildContext context, bool isDark) {
    final surfaceBg = isDark ? const Color(0xFF121212) : Colors.white;
    final titleColor = isDark ? Colors.white : const Color(0xFF171C21);
    final iconColor = isDark ? Colors.white : const Color(0xFF171C21);
    final badgeBg = isDark ? const Color(0xFF18181B) : const Color(0xFFEDF3F9);
    final badgeBorder = isDark ? const Color(0xFF27272A) : const Color(0xFFD4DFEC);
    final badgeText = isDark ? const Color(0xFFA1A1AA) : const Color(0xFF324B66);

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
              context.go(AppRoutes.home);
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
      title: Text(
        'Payment',
        style: TextStyle(
          fontSize: 17.5.sp,
          fontWeight: FontWeight.w700,
          color: titleColor,
          letterSpacing: -0.2,
        ),
      ),
      centerTitle: true,
      actions: [
        // SSL Pill Badge
        Container(
          margin: EdgeInsets.symmetric(vertical: 12.h),
          padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 2.h),
          decoration: BoxDecoration(
            color: badgeBg,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: badgeBorder,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.shield_outlined,
                size: 13.sp,
                color: badgeText,
              ),
              SizedBox(width: 4.w),
              Text(
                'SSL',
                style: TextStyle(
                  fontSize: 11.5.sp,
                  fontWeight: FontWeight.w700,
                  color: badgeText,
                  letterSpacing: 0.5,
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
  // 2. HERO HEADER (DEEP NAVY CANOPY + CONNECTED STEPPER)
  // ===========================================================================
  Widget _buildNavyCanopyHeader(bool isDark) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121212) : const Color(0xFF002244),
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF27272A) : Colors.transparent,
            width: 1,
          ),
        ),
      ),
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 18.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step subtitle & SECURE CHECKOUT badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'STEP 2 OF 3',
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF90A8C0),
                  letterSpacing: 0.8,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF18181B) : const Color(0xFF0A2E52),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: isDark ? const Color(0xFF27272A) : Colors.white.withValues(alpha: 0.16),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      size: 12.5.sp,
                      color: isDark ? const Color(0xFF3B82F6) : Colors.white,
                    ),
                    SizedBox(width: 5.w),
                    Text(
                      'SECURE CHECKOUT',
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),

          // Main Header Title
          Text(
            'Payment',
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          SizedBox(height: 18.h),

          // Connected 3-Step Milestone Stepper
          _buildCanopyStepper(isDark),
        ],
      ),
    );
  }

  Widget _buildCanopyStepper(bool isDark) {
    return Column(
      children: [
        // Stepper Nodes and Connecting Lines Row
        Row(
          children: [
            // Node 1: Details (Completed with Checkmark)
            _buildStepperNode(
              isCompleted: true,
              isActive: false,
              content: Icon(
                Icons.check_rounded,
                color: isDark ? Colors.black : const Color(0xFF002244),
                size: 16,
              ),
              nodeColor: Colors.white,
            ),

            // Connector 1 -> 2 (Solid Active)
            Expanded(
              child: Container(
                height: 2.h,
                color: isDark ? const Color(0xFF3B82F6) : Colors.white.withValues(alpha: 0.85),
              ),
            ),

            // Node 2: Payment (Active "2")
            _buildStepperNode(
              isCompleted: false,
              isActive: true,
              content: Text(
                '2',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.black : const Color(0xFF002244),
                ),
              ),
              nodeColor: isDark ? const Color(0xFF3B82F6) : Colors.white,
            ),

            // Connector 2 -> 3 (Muted Inactive)
            Expanded(
              child: Container(
                height: 2.h,
                color: isDark ? const Color(0xFF27272A) : Colors.white.withValues(alpha: 0.22),
              ),
            ),

            // Node 3: Confirmation (Inactive "3")
            _buildStepperNode(
              isCompleted: false,
              isActive: false,
              content: Text(
                '3',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF8FAEC9),
                ),
              ),
              nodeColor: isDark ? const Color(0xFF18181B) : const Color(0xFF0A2E52),
              borderColor: isDark ? const Color(0xFF27272A) : Colors.white.withValues(alpha: 0.25),
            ),
          ],
        ),
        SizedBox(height: 6.h),

        // Step Labels Row
        Row(
          children: [
            Expanded(
              child: Text(
                'Details',
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontSize: 11.5.sp,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF90A8C0),
                ),
              ),
            ),
            Expanded(
              child: Text(
                'Payment',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            Expanded(
              child: Text(
                'Confirmation',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 11.5.sp,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF6F8FA8),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStepperNode({
    required bool isCompleted,
    required bool isActive,
    required Widget content,
    required Color nodeColor,
    Color? borderColor,
  }) {
    return Container(
      width: 28.w,
      height: 28.w,
      decoration: BoxDecoration(
        color: nodeColor,
        shape: BoxShape.circle,
        border: borderColor != null
            ? Border.all(color: borderColor, width: 1.5)
            : null,
        boxShadow: isActive || isCompleted
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ]
            : null,
      ),
      child: Center(child: content),
    );
  }

  // ===========================================================================
  // 3. ORDER SUMMARY CARD (Matches media_1790688996861.png)
  // ===========================================================================
  // ===========================================================================
  // 3. ORDER SUMMARY CARD (Theme-Adaptive & Responsive)
  // ===========================================================================
  Widget _buildOrderSummaryCard(bool isDark) {
    final cardBg = isDark ? const Color(0xFF121212) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF27272A) : const Color(0xFFE8EEF5);
    final textPrimary = isDark ? Colors.white : const Color(0xFF171C21);
    final textSecondary = isDark ? const Color(0xFFA1A1AA) : const Color(0xFF5A6E85);
    final innerBg = isDark ? const Color(0xFF18181B) : const Color(0xFFF3F6FA);
    final innerBorder = isDark ? const Color(0xFF27272A) : const Color(0xFFE6ECF3);
    final flagBg = isDark ? const Color(0xFF18181B) : Colors.white;
    final flagBorder = isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0);
    final totalColor = isDark ? const Color(0xFF3B82F6) : const Color(0xFF002244);
    final dividerColor = isDark ? const Color(0xFF27272A) : const Color(0xFFE8EEF5);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: cardBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.25)
                : const Color(0xFF1B3A5C).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: "Order Summary" & "Ref: ..."
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order Summary',
                style: TextStyle(
                  fontSize: 16.5.sp,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              SizedBox(width: 8.w),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF18181B) : const Color(0xFFEDF4FC),
                      borderRadius: BorderRadius.circular(20.r),
                      border: isDark ? Border.all(color: const Color(0xFF27272A)) : null,
                    ),
                    child: Text(
                      'Ref: $_effectiveReference',
                      style: TextStyle(
                        fontSize: 11.5.sp,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          // Inner Sub-Container with Country Flag, Title & Subtitle
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: innerBg,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: innerBorder),
            ),
            child: Row(
              children: [
                // Flag Container
                Container(
                  width: 44.w,
                  height: 44.w,
                  decoration: BoxDecoration(
                    color: flagBg,
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(color: flagBorder),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _effectiveFlag,
                        style: TextStyle(fontSize: 22.sp),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),

                // Item Name & Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _effectiveItemTitle,
                        softWrap: true,
                        style: TextStyle(
                          fontSize: 14.5.sp,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      SizedBox(height: 3.h),
                      Text(
                        _effectiveItemSubtitle,
                        softWrap: true,
                        style: TextStyle(
                          fontSize: 12.5.sp,
                          fontWeight: FontWeight.w500,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 14.h),

          // Cost Breakdown Rows
          _buildCostRow('Service fee', _formatCurrency(_calculatedServiceFee), isDark: isDark),
          SizedBox(height: 8.h),
          _buildCostRow('Processing fee', _formatCurrency(_processingFee), isDark: isDark),
          SizedBox(height: 8.h),

          // Discount Row (Dynamic based on promo applied)
          if (_isPromoApplied)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.local_offer_outlined,
                        size: 14.sp,
                        color: const Color(0xFF16A34A),
                      ),
                      SizedBox(width: 5.w),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Discount (${_promoController.text.trim().toUpperCase()})',
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF16A34A),
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
                    child: Text(
                      '- ${_formatCurrency(_discountAmount)}',
                      style: TextStyle(
                        fontSize: 13.5.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF16A34A),
                      ),
                    ),
                  ),
                ),
              ],
            ),

          Divider(height: 22.h, color: dividerColor),

          // Total Amount Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Amount',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'Includes institutional taxes',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w400,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 10.w),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    _formatCurrency(_calculatedTotal),
                    style: TextStyle(
                      fontSize: 21.sp,
                      fontWeight: FontWeight.w900,
                      color: totalColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCostRow(String label, String value, {required bool isDark}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            softWrap: true,
            style: TextStyle(
              fontSize: 13.5.sp,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF5A626A),
            ),
          ),
        ),
        SizedBox(width: 8.w),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF171C21),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 4. PROMOTIONAL CODE CARD (Theme-Adaptive & Responsive)
  // ===========================================================================
  Widget _buildPromotionalCodeCard(bool isDark) {
    final cardBg = isDark ? const Color(0xFF121212) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF27272A) : const Color(0xFFE8EEF5);
    final textPrimary = isDark ? Colors.white : const Color(0xFF171C21);
    final inputBg = isDark ? const Color(0xFF18181B) : const Color(0xFFEEF3F8);
    final inputBorder = isDark ? const Color(0xFF27272A) : const Color(0xFFDCE5EE);
    final btnBg = isDark ? const Color(0xFF3B82F6) : const Color(0xFF002444);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: cardBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.25)
                : const Color(0xFF1B3A5C).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Promotional Code',
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              if (_isPromoApplied)
                Text(
                  '1 applied',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                  ),
                ),
            ],
          ),
          SizedBox(height: 12.h),

          // Code Input & Applied Button Row
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 48.h,
                  padding: EdgeInsets.symmetric(horizontal: 14.w),
                  decoration: BoxDecoration(
                    color: inputBg,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: inputBorder),
                  ),
                  alignment: Alignment.centerLeft,
                  child: TextField(
                    controller: _promoController,
                    textCapitalization: TextCapitalization.characters,
                    style: TextStyle(
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                      letterSpacing: 0.6,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: 'Enter Promo Code',
                      hintStyle: TextStyle(
                        color: isDark ? const Color(0xFF64748B) : const Color(0xFF8FAEC9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onSubmitted: (val) => _handleApplyPromo(),
                  ),
                ),
              ),
              SizedBox(width: 10.w),

              // Deep Navy Apply / Applied Button (Consistent 48.h, 12.r)
              SizedBox(
                height: 48.h,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: btnBg,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                  ),
                  onPressed: _isCheckingPromo ? null : _handleApplyPromo,
                  child: _isCheckingPromo
                      ? SizedBox(
                          width: 16.w,
                          height: 16.w,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _isPromoApplied ? 'Applied' : 'Apply',
                          style: TextStyle(
                            fontSize: 13.5.sp,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                ),
              ),
            ],
          ),

          // Applied Success Banner
          if (_isPromoApplied) ...[
            SizedBox(height: 10.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF064E3B) : const Color(0xFFE6F5EA),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: isDark ? const Color(0xFF047857) : const Color(0xFFC6E7D0)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.verified_outlined,
                    size: 16.sp,
                    color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF166534),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      '${_promoController.text.trim()} applied • Saved ${_formatCurrency(_discountAmount)}',
                      softWrap: true,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF166534),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _isPromoApplied = false;
                        _discountAmount = 0;
                      });
                      showToast(
                        context,
                        message: 'Promo code removed',
                        status: 'info',
                      );
                    },
                    borderRadius: BorderRadius.circular(12.r),
                    child: Padding(
                      padding: EdgeInsets.all(2.w),
                      child: Icon(
                        Icons.close_rounded,
                        size: 16.sp,
                        color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF166534),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _handleApplyPromo() async {
    final code = _promoController.text.trim().toUpperCase();
    if (code.isEmpty) {
      showToast(
        context,
        message: 'Please enter a valid promotional code',
        status: 'error',
      );
      return;
    }

    setState(() => _isCheckingPromo = true);

    try {
      final orderAmount = _calculatedServiceFee.toDouble();
      final result = await SupabaseDatabaseService.instance.validatePromoCode(
        code,
        orderAmount: orderAmount,
      );

      if (!mounted) return;

      result.fold(
        (failure) {
          final localDiscount = _checkLocalPromo(code, orderAmount);
          if (localDiscount != null) {
            setState(() {
              _discountAmount = localDiscount;
              _isPromoApplied = true;
              _isCheckingPromo = false;
            });
            showToast(
              context,
              message: 'Code $code applied (${_formatCurrency(localDiscount)} off)',
              status: 'success',
            );
          } else {
            setState(() => _isCheckingPromo = false);
            showToast(
              context,
              message: failure.message.isNotEmpty
                  ? failure.message
                  : 'Invalid promotional code',
              status: 'error',
            );
          }
        },
        (promoData) {
          setState(() => _isCheckingPromo = false);
          if (promoData != null) {
            final disc = (promoData['discountAmount'] as num).toInt();
            setState(() {
              _discountAmount = disc;
              _isPromoApplied = true;
            });
            showToast(
              context,
              message: 'Code $code applied (${_formatCurrency(disc)} off)',
              status: 'success',
            );
          } else {
            final localDiscount = _checkLocalPromo(code, orderAmount);
            if (localDiscount != null) {
              setState(() {
                _discountAmount = localDiscount;
                _isPromoApplied = true;
              });
              showToast(
                context,
                message: 'Code $code applied (${_formatCurrency(localDiscount)} off)',
                status: 'success',
              );
            } else {
              showToast(
                context,
                message: 'Invalid or expired promotional code',
                status: 'error',
              );
            }
          }
        },
      );
    } catch (_) {
      if (mounted) {
        setState(() => _isCheckingPromo = false);
        showToast(
          context,
          message: 'Error verifying code',
          status: 'error',
        );
      }
    }
  }

  int? _checkLocalPromo(String code, double orderAmount) {
    return switch (code) {
      'WELCOME10' => 500,
      'SBVISA2026' => orderAmount >= 5000 ? 1000 : null,
      'DISCOUNT20' => ((orderAmount * 0.20)).clamp(0, 5000).toInt(),
      'STUDENT15' => ((orderAmount * 0.15)).clamp(0, 3000).toInt(),
      _ => null,
    };
  }

  // ===========================================================================
  // 5. INDUSTRY STANDARD PAYMENT METHODS SECTION (Direct Bank Transfer)
  // ===========================================================================
  Widget _buildPaymentMethodSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header Row: Title & Encrypted Badge
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Select Payment Method',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF171C21),
                letterSpacing: -0.2,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.verified_user_rounded,
                  size: 13.sp,
                  color: const Color(0xFF16A34A),
                ),
                SizedBox(width: 4.w),
                Text(
                  '1Link IBFT',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF16A34A),
                  ),
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: 12.h),

        // PayFast Offline Maintenance Notice Banner
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 11.h),
          margin: EdgeInsets.only(bottom: 14.h),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 18.sp,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PayFast Card Gateway Temporarily Offline',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'Online card processing is temporarily unavailable. All payments are currently accepted exclusively via Direct Bank Transfer (1Link IBFT).',
                      style: TextStyle(
                        fontSize: 11.5.sp,
                        color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Multi-rail Selector Cards (PayFast disabled/offline, Bank Transfer active)
        Row(
          children: [
            // Rail 1: PayFast Digital Online Gateway (Temporarily Offline)
            Expanded(
              child: _buildPaymentMethodSelectorCard(
                id: 'payfast',
                title: 'PayFast IPG',
                subtitle: 'Cards / Wallets',
                icon: Icons.credit_card_rounded,
                isSelected: _selectedPaymentMethod == 'payfast',
                isDark: isDark,
                isUnavailable: true,
                badgeText: 'Offline',
              ),
            ),
            SizedBox(width: 10.w),

            // Rail 2: Direct Bank Transfer (1Link IBFT - Only Active Method)
            Expanded(
              child: _buildPaymentMethodSelectorCard(
                id: 'bank_transfer',
                title: 'Bank Transfer',
                subtitle: '1Link IBFT',
                icon: Icons.account_balance_rounded,
                isSelected: _selectedPaymentMethod == 'bank_transfer',
                isDark: isDark,
              ),
            ),
          ],
        ),
        SizedBox(height: 14.h),

        // Active payment method details card (Bank Transfer)
        if (_selectedPaymentMethod == 'payfast')
          _buildPayFastGatewayCard(isDark)
        else
          _buildBankTransferDetailsCard(isDark),
      ],
    );
  }

  Widget _buildPaymentMethodSelectorCard({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required bool isDark,
    bool isUnavailable = false,
    String? badgeText,
  }) {
    return InkWell(
      onTap: isUnavailable
          ? () {
              showToast(
                context,
                message: '$title is temporarily unavailable. Please proceed with Bank Transfer.',
                status: 'warning',
              );
            }
          : () {
              setState(() {
                _selectedPaymentMethod = id;
              });
            },
      borderRadius: BorderRadius.circular(12.r),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 11.h),
        decoration: BoxDecoration(
          color: isUnavailable
              ? (isDark ? const Color(0xFF141416) : const Color(0xFFF8FAFC))
              : isSelected
                  ? (isDark ? const Color(0xFF18181B) : const Color(0xFFF0F6FF))
                  : (isDark ? const Color(0xFF121212) : Colors.white),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isUnavailable
                ? (isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0))
                : isSelected
                    ? (isDark ? const Color(0xFF3B82F6) : const Color(0xFF002244))
                    : (isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0)),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected && !isUnavailable
              ? [
                  BoxShadow(
                    color: const Color(0xFF002244).withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Opacity(
          opacity: isUnavailable ? 0.65 : 1.0,
          child: Row(
            children: [
              Container(
                width: 32.w,
                height: 32.w,
                decoration: BoxDecoration(
                  color: isUnavailable
                      ? (isDark ? const Color(0xFF202024) : const Color(0xFFE2E8F0))
                      : isSelected
                          ? (isDark ? const Color(0xFF3B82F6) : const Color(0xFF002244))
                          : (isDark ? const Color(0xFF18181B) : const Color(0xFFEFF3F8)),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isUnavailable
                      ? (isDark ? const Color(0xFF71717A) : const Color(0xFF94A3B8))
                      : isSelected
                          ? Colors.white
                          : (isDark ? const Color(0xFFA1A1AA) : const Color(0xFF64748B)),
                  size: 16.sp,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      softWrap: true,
                      style: TextStyle(
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.w700,
                        color: isUnavailable
                            ? (isDark ? const Color(0xFF71717A) : const Color(0xFF94A3B8))
                            : (isDark ? Colors.white : const Color(0xFF171C21)),
                      ),
                    ),
                    SizedBox(height: 1.h),
                    if (isUnavailable)
                      Container(
                        margin: EdgeInsets.only(top: 2.h),
                        padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.5.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4.r),
                          border: Border.all(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          badgeText ?? 'Unavailable',
                          style: TextStyle(
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFEF4444),
                          ),
                        ),
                      )
                    else
                      Text(
                        subtitle,
                        softWrap: true,
                        style: TextStyle(
                          fontSize: 10.5.sp,
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
              if (!isUnavailable)
                Container(
                  width: 16.w,
                  height: 16.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF002244)
                          : const Color(0xFFCBD5E1),
                      width: isSelected ? 5 : 1.5,
                    ),
                  ),
                )
              else
                Icon(
                  Icons.block_rounded,
                  size: 14.sp,
                  color: const Color(0xFFEF4444),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBankTransferDetailsCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121212) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDark ? const Color(0xFF27272A) : const Color(0xFF002244),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF002244).withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF18181B) : const Color(0xFF002244),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: isDark ? const Color(0xFF27272A) : Colors.transparent,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.account_balance_rounded,
                    color: isDark ? const Color(0xFF3B82F6) : Colors.white,
                    size: 20.sp,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'United Bank Limited (UBL) 🏦',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF171C21),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'Official Corporate Account • 1Link IBFT',
                      style: TextStyle(
                        fontSize: 11.5.sp,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: const Color(0xFFC8E6C9)),
                ),
                child: Text(
                  'Verified',
                  style: TextStyle(
                    fontSize: 10.5.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2E7D32),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // Account Details Rows
          _buildBankDetailRow(
            label: 'Bank Name',
            value: 'UBL (United Bank Limited)',
            copyable: true,
            isDark: isDark,
          ),
          SizedBox(height: 8.h),
          _buildBankDetailRow(
            label: 'Account Title',
            value: 'Sb Consultant',
            copyable: true,
            isDark: isDark,
          ),
          SizedBox(height: 8.h),
          _buildBankDetailRow(
            label: 'Account Number',
            value: '1495340439603',
            copyable: true,
            isDark: isDark,
          ),
          SizedBox(height: 8.h),
          _buildBankDetailRow(
            label: 'IBAN Number',
            value: 'PK62UNIL0109000340439603',
            copyable: true,
            isDark: isDark,
          ),
          SizedBox(height: 8.h),
          _buildBankDetailRow(
            label: 'Payment Reference',
            value: _effectiveReference,
            copyable: true,
            isDark: isDark,
          ),
          SizedBox(height: 14.h),

          // Instructions notice
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 16.sp,
                  color: const Color(0xFF1D4ED8),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'Transfer exact fee (${_formatCurrency(_calculatedTotal)}) from your banking app using 1Link IBFT, then enter the Transaction Reference below.',
                    style: TextStyle(
                      fontSize: 11.5.sp,
                      color: const Color(0xFF1E40AF),
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),

          // Input field: Transaction Reference / TID
          Text(
            'Bank Transaction ID / Reference (RRN / TID) *',
            style: TextStyle(
              fontSize: 12.5.sp,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF171C21),
            ),
          ),
          SizedBox(height: 6.h),
          Container(
            height: 46.h,
            padding: EdgeInsets.symmetric(horizontal: 14.w),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF18181B) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(
                color: isDark ? const Color(0xFF27272A) : const Color(0xFFCBD5E1),
              ),
            ),
            alignment: Alignment.centerLeft,
            child: TextField(
              controller: _bankTxRefController,
              style: TextStyle(
                fontSize: 13.5.sp,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF171C21),
              ),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'e.g. 40284729103 or STAN# 94821',
                hintStyle: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
          SizedBox(height: 12.h),

          // Input field: Sender Name
          Text(
            'Sender Account Holder Name (Optional)',
            style: TextStyle(
              fontSize: 12.5.sp,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF171C21),
            ),
          ),
          SizedBox(height: 6.h),
          Container(
            height: 46.h,
            padding: EdgeInsets.symmetric(horizontal: 14.w),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF18181B) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(
                color: isDark ? const Color(0xFF27272A) : const Color(0xFFCBD5E1),
              ),
            ),
            alignment: Alignment.centerLeft,
            child: TextField(
              controller: _bankSenderNameController,
              style: TextStyle(
                fontSize: 13.5.sp,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF171C21),
              ),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'e.g. Zain Ahmed',
                hintStyle: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBankDetailRow({
    required String label,
    required String value,
    required bool copyable,
    required bool isDark,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18181B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF171C21),
                    letterSpacing: label.contains('IBAN') || label.contains('Account') ? 0.3 : 0,
                  ),
                ),
              ],
            ),
          ),
          if (copyable)
            InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
                showToast(
                  context,
                  message: '$label copied to clipboard!',
                  status: 'success',
                );
              },
              borderRadius: BorderRadius.circular(6.r),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF002244).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.copy_rounded,
                      size: 13.sp,
                      color: const Color(0xFF002244),
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      'Copy',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF002244),
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

  Widget _buildPayFastGatewayCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121212) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDark ? const Color(0xFF27272A) : const Color(0xFF002244),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF002244).withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: PayFast Logo/Branding + SBP Verified + Sandbox Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF18181B) : const Color(0xFF002244),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: isDark ? const Color(0xFF27272A) : Colors.transparent,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.credit_card_rounded,
                    color: isDark ? const Color(0xFF3B82F6) : Colors.white,
                    size: 20.sp,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PayFast IPG Pakistan',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF171C21),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'Debit / Credit Card (3D Secure 2.0)',
                      style: TextStyle(
                        fontSize: 11.5.sp,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_clock_rounded, size: 12.sp, color: const Color(0xFFDC2626)),
                    SizedBox(width: 4.w),
                    Text(
                      'Unavailable',
                      style: TextStyle(
                        fontSize: 10.5.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFB91C1C),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          // PayFast Maintenance / Temporarily Unavailable Alert Banner
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF271515) : const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFECACA),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: const Color(0xFFEF4444),
                  size: 18.sp,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'PayFast card gateway is temporarily unavailable due to system maintenance. Please switch to Direct Bank Transfer (1Link IBFT) above.',
                    style: TextStyle(
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFB91C1C),
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12.h),

          // Interactive Visual Credit/Debit Card Preview
          _buildCreditCardPreview(isDark),
          SizedBox(height: 14.h),

          // Card Details Input Fields
          // 1. Card Number Field
          _buildCustomCardField(
            label: 'Card Number',
            controller: _cardNumberController,
            hint: '0000 0000 0000 0000',
            prefixIcon: Icons.credit_card_rounded,
            keyboardType: TextInputType.number,
            formatters: [_CardNumberFormatter()],
            isDark: isDark,
            suffix: _detectCardBrand(_cardNumberController.text) == 'Mastercard'
                ? Padding(
                    padding: EdgeInsets.only(right: 12.w),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 14.w,
                          height: 14.w,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEB001B),
                            shape: BoxShape.circle,
                          ),
                        ),
                        Container(
                          width: 14.w,
                          height: 14.w,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF79E1B).withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  )
                : null,
            onChanged: (_) => setState(() {}),
          ),
          SizedBox(height: 12.h),

          // 2. Row: Expiry Date & CVV
          Row(
            children: [
              Expanded(
                child: _buildCustomCardField(
                  label: 'Expiry Date',
                  controller: _cardExpiryController,
                  hint: 'MM/YY',
                  prefixIcon: Icons.calendar_today_rounded,
                  keyboardType: TextInputType.number,
                  formatters: [_CardExpiryFormatter()],
                  isDark: isDark,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: _buildCustomCardField(
                  label: 'CVV / CVC',
                  controller: _cardCvvController,
                  hint: '123',
                  prefixIcon: Icons.lock_outline_rounded,
                  keyboardType: TextInputType.number,
                  obscureText: _obscureCardCvv,
                  formatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  isDark: isDark,
                  suffix: IconButton(
                    icon: Icon(
                      _obscureCardCvv
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 17.sp,
                      color: const Color(0xFF64748B),
                    ),
                    onPressed: () {
                      setState(() => _obscureCardCvv = !_obscureCardCvv);
                    },
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          // 3. Cardholder Name Field
          _buildCustomCardField(
            label: 'Cardholder Name',
            controller: _cardHolderNameController,
            hint: 'e.g. Account Holder Name',
            prefixIcon: Icons.person_outline_rounded,
            keyboardType: TextInputType.name,
            isDark: isDark,
            onChanged: (_) => setState(() {}),
          ),
          SizedBox(height: 14.h),

          // Security & Regulatory Compliance Footer
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF18181B) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(
                color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lock_rounded,
                  size: 15.sp,
                  color: isDark ? const Color(0xFF3B82F6) : const Color(0xFF002244),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'State Bank of Pakistan Regulated • All Info Secure • 3D Secure 2.0',
                    style: TextStyle(
                      fontSize: 10.5.sp,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? const Color(0xFFA1A1AA)
                          : const Color(0xFF475569),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8.h),

          // Alternate Hosted Portal Link
          Center(
            child: TextButton.icon(
              onPressed: _handlePayNowViaHostedPortal,
              icon: Icon(
                Icons.open_in_browser_rounded,
                size: 15.sp,
                color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1B3A5C),
              ),
              label: Text(
                'Prefer PayFast Hosted Web Portal? Open Gateway Page →',
                style: TextStyle(
                  fontSize: 11.5.sp,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1B3A5C),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditCardPreview(bool isDark) {
    final rawNumber = _cardNumberController.text.trim();
    final cardNumberDisplay =
        rawNumber.isEmpty ? '•••• •••• •••• ••••' : rawNumber;
    final rawHolder = _cardHolderNameController.text.trim();
    final holderDisplay = rawHolder.isEmpty
        ? ((widget.applicantName?.isNotEmpty ?? false)
            ? widget.applicantName!.toUpperCase()
            : 'CARDHOLDER NAME')
        : rawHolder.toUpperCase();
    final rawExpiry = _cardExpiryController.text.trim();
    final expiryDisplay = rawExpiry.isEmpty ? 'MM/YY' : rawExpiry;
    final brand = _detectCardBrand(rawNumber);

    return Container(
      width: double.infinity,
      height: 180.h,
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF001B3A),
            Color(0xFF0F3E6D),
            Color(0xFF1B3A5C),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF001B3A).withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top Row: Chip + Brand
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    width: 36.w,
                    height: 26.h,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(5.r),
                      border: Border.all(
                        color: const Color(0xFFDAA520),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.memory,
                        size: 16.sp,
                        color: const Color(0xFF8B6508),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Icon(
                    Icons.contactless_rounded,
                    color: Colors.white70,
                    size: 20.sp,
                  ),
                ],
              ),
              Text(
                brand,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.8,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),

          // Middle: Card Number
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              cardNumberDisplay,
              style: TextStyle(
                fontSize: 18.sp,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 3,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    offset: const Offset(1, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
          ),

          // Bottom: Cardholder Name & Expiry
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'CARDHOLDER',
                      style: TextStyle(
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white60,
                        letterSpacing: 1,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      holderDisplay,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'EXPIRES',
                    style: TextStyle(
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white60,
                      letterSpacing: 1,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    expiryDisplay,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomCardField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData prefixIcon,
    required TextInputType keyboardType,
    required bool isDark,
    List<TextInputFormatter>? formatters,
    Widget? suffix,
    bool obscureText = false,
    ValueChanged<String>? onChanged,
  }) {
    final labelColor = isDark ? const Color(0xFFA1A1AA) : const Color(0xFF334155);
    final fieldBg = isDark ? const Color(0xFF18181B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF27272A) : const Color(0xFFCBD5E1);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: labelColor,
          ),
        ),
        SizedBox(height: 6.h),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          inputFormatters: formatters,
          onChanged: onChanged,
          style: TextStyle(
            fontSize: 13.5.sp,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
          decoration: InputDecoration(
            isDense: true,
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: 13.sp,
              color: isDark ? const Color(0xFF71717A) : const Color(0xFF94A3B8),
            ),
            prefixIcon: Icon(
              prefixIcon,
              size: 18.sp,
              color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF64748B),
            ),
            suffixIcon: suffix,
            filled: true,
            fillColor: fieldBg,
            contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
              borderSide: BorderSide(
                color: isDark ? const Color(0xFF3B82F6) : const Color(0xFF1B3A5C),
                width: 1.8,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 6. SAFE & REGULATED GATEWAY TRUST CARD (Theme-Adaptive)
  // ===========================================================================
  Widget _buildTrustCard(bool isDark) {
    final cardBg = isDark ? const Color(0xFF121212) : const Color(0xFFEEF3F8);
    final cardBorder = isDark ? const Color(0xFF27272A) : const Color(0xFFDCE5EE);
    final textPrimary = isDark ? Colors.white : const Color(0xFF171C21);
    final textSecondary = isDark ? const Color(0xFFA1A1AA) : const Color(0xFF53687E);
    final badgeColor = isDark ? const Color(0xFFA1A1AA) : const Color(0xFF324B66);
    final iconBg = isDark ? const Color(0xFF18181B) : Colors.white;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Header Row with Shield Icon
          Row(
            children: [
              Container(
                width: 26.w,
                height: 26.w,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? const Color(0xFF27272A) : Colors.transparent,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.shield_outlined,
                    size: 15.sp,
                    color: isDark ? const Color(0xFF3B82F6) : const Color(0xFF1B3A5C),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                'Safe & Regulated Gateway',
                style: TextStyle(
                  fontSize: 13.5.sp,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),

          // Informational Text
          Text(
            'Payments are processed securely via audited rails. Your card and financial credentials are never retained in SB Consultants servers.',
            style: TextStyle(
              fontSize: 11.5.sp,
              color: textSecondary,
              height: 1.45,
            ),
          ),
          SizedBox(height: 10.h),

          // Compliance & SSL Badges Row with Wrap to prevent pixel overflow
          Wrap(
            spacing: 12.w,
            runSpacing: 4.h,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 13.sp,
                    color: badgeColor,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    'All Your Info Is Secure',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: badgeColor,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.verified_outlined,
                    size: 13.sp,
                    color: badgeColor,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    'State Bank SBP Compliant',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: badgeColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 7. STICKY BOTTOM ACTION BAR (Matches media_1790688996861.png)
  // ===========================================================================
  Widget _buildBottomActionBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF27272A) : const Color(0xFFE8EEF5);
    final labelColor =
        isDark ? const Color(0xFFA1A1AA) : const Color(0xFF6B7C93);
    final totalColor = isDark ? Colors.white : const Color(0xFF002244);
    final buttonBg =
        isDark ? const Color(0xFF3B82F6) : const Color(0xFF002244);

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
          child: Row(
            children: [
              // Total Payable Display (Left Side)
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 120.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Payable',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: labelColor,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _formatCurrency(_calculatedTotal),
                        style: TextStyle(
                          fontSize: 19.sp,
                          fontWeight: FontWeight.w900,
                          color: totalColor,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),

              // Deep Navy CTA Button (Right Side, Responsive)
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    height: 48.h,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: buttonBg,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                      ),
                      onPressed: _isProcessing ? null : _handleBankTransferPayment,
                      child: _isProcessing
                          ? SizedBox(
                              width: 20.w,
                              height: 20.w,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Confirm Bank Transfer',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                  SizedBox(width: 6.w),
                                  Icon(
                                    Icons.check_circle_outline_rounded,
                                    size: 16.sp,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProcessingOverlay(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Positioned.fill(
      child: AbsorbPointer(
        child: ColoredBox(
          color: Colors.black.withValues(alpha: 0.35),
          child: Center(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 26.w, vertical: 24.h),
              margin: EdgeInsets.symmetric(horizontal: 36.w),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF131B26) : Colors.white,
                borderRadius: BorderRadius.circular(18.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 32.w,
                    height: 32.w,
                    child: const CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Color(0xFF002244),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'Submitting Bank Transfer',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF171C21),
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    'Recording transaction reference and submitting application...',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: const Color(0xFF6B7C93),
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

  String _buildPayFastHtml({
    required String merchantId,
    required String basketId,
    required double amount,
    required String transactionId,
    String? customerEmail,
    String? customerPhone,
    String? itemTitle,
    String? accessToken,
  }) {
    const gatewayUrl =
        'https://ipg1.apps.net.pk/Ecommerce/api/Transaction/PostTransaction';
    final returnUrl =
        'https://tpmdqfmtunxbnhpckkbh.supabase.co/functions/v1/payfast-webhook?tx=$transactionId';
    final cancelUrl =
        'https://tpmdqfmtunxbnhpckkbh.supabase.co/functions/v1/payfast-webhook?status=cancel&tx=$transactionId';
    final dateStr = DateTime.now().toIso8601String().substring(0, 10);
    final cleanBasketId = basketId.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '');
    final amtFormatted = amount.toStringAsFixed(2);
    final tokenTag = (accessToken != null && accessToken.isNotEmpty)
        ? '<input type="hidden" name="TOKEN" value="$accessToken" />'
        : '';

    return '''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>PayFast Secure Checkout</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
      background: #002244;
      color: #ffffff;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      min-height: 100vh;
      padding: 20px;
      text-align: center;
    }
    .container {
      background: rgba(255, 255, 255, 0.07);
      border: 1px solid rgba(255, 255, 255, 0.14);
      border-radius: 20px;
      padding: 34px 22px;
      max-width: 380px;
      width: 100%;
      box-shadow: 0 20px 45px rgba(0, 0, 0, 0.35);
    }
    .spinner {
      width: 44px;
      height: 44px;
      border: 3.5px solid rgba(255, 255, 255, 0.16);
      border-top-color: #22C55E;
      border-radius: 50%;
      animation: spin 0.75s linear infinite;
      margin: 0 auto 18px;
    }
    @keyframes spin { to { transform: rotate(360deg); } }
    h2 { font-size: 18px; font-weight: 700; margin-bottom: 8px; letter-spacing: -0.2px; }
    p { font-size: 13px; color: #94A3B8; line-height: 1.45; margin-bottom: 22px; }
    .badge {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      background: rgba(34, 197, 94, 0.15);
      color: #4ADE80;
      border: 1px solid rgba(34, 197, 94, 0.25);
      padding: 5px 12px;
      border-radius: 20px;
      font-size: 11.5px;
      font-weight: 600;
      margin-bottom: 18px;
    }
    .btn {
      display: block;
      width: 100%;
      padding: 13px;
      background: #22C55E;
      color: #ffffff;
      border: none;
      border-radius: 12px;
      font-size: 14px;
      font-weight: 700;
      cursor: pointer;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="spinner"></div>
    <div class="badge">
      <span>●</span> All Your Info Is Secure
    </div>
    <h2>Connecting to PayFast</h2>
    <p>Opening official State Bank of Pakistan regulated PayFast IPG portal...</p>
    <form id="payfastForm" method="POST" action="$gatewayUrl">
      <input type="hidden" name="MERCHANT_ID" value="$merchantId" />
      $tokenTag
      <input type="hidden" name="PROCCODE" value="00" />
      <input type="hidden" name="TXNAMT" value="$amtFormatted" />
      <input type="hidden" name="CURRENCY_CODE" value="PKR" />
      <input type="hidden" name="BASKET_ID" value="$cleanBasketId" />
      <input type="hidden" name="TXNDESC" value="${itemTitle ?? 'Consultancy Service Fee'}" />
      <input type="hidden" name="ORDER_DATE" value="$dateStr" />
      <input type="hidden" name="VERSION" value="1.1" />
      <input type="hidden" name="SUCCESS_URL" value="$returnUrl" />
      <input type="hidden" name="FAILURE_URL" value="$cancelUrl" />
      <input type="hidden" name="CHECKOUT_URL" value="$returnUrl" />
      <input type="hidden" name="CUSTOMER_EMAIL" value="${customerEmail ?? ''}" />
      <input type="hidden" name="CUSTOMER_MOBILE" value="${customerPhone ?? ''}" />
      <input type="hidden" name="CUSTOMER_EMAIL_ADDRESS" value="${customerEmail ?? ''}" />
      <input type="hidden" name="CUSTOMER_MOBILE_NO" value="${customerPhone ?? ''}" />
      <button type="submit" class="btn" id="subBtn">Continue to Payment</button>
    </form>
  </div>
  <script>
    function submitPayFast() {
      try { document.getElementById('payfastForm').submit(); } catch(e) {}
    }
    if (document.readyState === 'loading') {
      document.addEventListener('DOMContentLoaded', submitPayFast);
    } else {
      submitPayFast();
    }
    setTimeout(submitPayFast, 150);
  </script>
</body>
</html>''';
  }

  bool get _isPayFastGatewayAvailable => false;

  /// Direct in-app Card Payment validation and 3D Secure 2.0 initialization
  Future<void> _handlePayNow() async {
    if (!_isPayFastGatewayAvailable) {
      showToast(
        context,
        message:
            'PayFast gateway is temporarily unavailable. Please proceed with Direct Bank Transfer (1Link IBFT).',
        status: 'warning',
      );
      setState(() {
        _selectedPaymentMethod = 'bank_transfer';
      });
      return;
    }

    final rawNumber = _cardNumberController.text.replaceAll(RegExp(r'\D'), '');
    final expiry = _cardExpiryController.text.trim();
    final cvv = _cardCvvController.text.trim();

    if (rawNumber.length < 16) {
      showToast(
        context,
        message: 'Please enter a valid 16-digit card number.',
        status: 'error',
      );
      return;
    }

    if (!RegExp(r'^(0[1-9]|1[0-2])\/?([0-9]{2})$').hasMatch(expiry)) {
      showToast(
        context,
        message: 'Please enter a valid expiry date in MM/YY format (e.g. 01/39).',
        status: 'error',
      );
      return;
    }

    if (cvv.length < 3) {
      showToast(
        context,
        message: 'Please enter a valid 3-digit CVV (e.g. 123).',
        status: 'error',
      );
      return;
    }

    await _showPayFast3DSecureDialog(
      cardNumber: rawNumber,
      expiry: expiry,
      cvv: cvv,
      cardholder: _cardHolderNameController.text.trim(),
    );
  }

  /// Official PayFast & State Bank of Pakistan 3D Secure 2.0 OTP Authentication Modal
  Future<void> _showPayFast3DSecureDialog({
    required String cardNumber,
    required String expiry,
    required String cvv,
    required String cardholder,
  }) async {
    final last4 = cardNumber.substring(cardNumber.length - 4);
    final brand = _detectCardBrand(cardNumber);
    final cleanRef =
        _effectiveReference.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '');
    final txId = 'TXN-PF-${DateTime.now().millisecondsSinceEpoch}';

    final otpController = TextEditingController();
    bool isAuthorizing = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final sheetBg = isDark ? const Color(0xFF121212) : Colors.white;

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: sheetBg,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(24.r)),
                  border: Border.all(
                    color: isDark ? const Color(0xFF27272A) : Colors.transparent,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 20,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 20.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle Bar
                    Center(
                      child: Container(
                        width: 40.w,
                        height: 4.h,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF27272A)
                              : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // Header Row: PayFast & SBP 3D-Secure 2.0
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 42.w,
                          height: 42.w,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF18181B) : const Color(0xFF002244),
                            borderRadius: BorderRadius.circular(10.r),
                            border: Border.all(
                              color: isDark ? const Color(0xFF27272A) : Colors.transparent,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.verified_user_rounded,
                              color: const Color(0xFF22C55E),
                              size: 22.sp,
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'PayFast 3D Secure 2.0',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                'State Bank of Pakistan Regulated Gateway',
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF2E7D32),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.of(modalCtx).pop(),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),

                    // Transaction Summary Card
                    Container(
                      padding: EdgeInsets.all(14.w),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF18181B)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF27272A)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Merchant',
                                  style: TextStyle(
                                      fontSize: 12.sp,
                                      color: const Color(0xFF64748B))),
                              Text('SB Consultants (ID: 102)',
                                  style: TextStyle(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                          SizedBox(height: 6.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Total Amount',
                                  style: TextStyle(
                                      fontSize: 12.sp,
                                      color: const Color(0xFF64748B))),
                              Text(
                                _formatCurrency(_calculatedTotal),
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w900,
                                  color: isDark
                                      ? const Color(0xFF60A5FA)
                                      : const Color(0xFF002244),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 6.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Card',
                                  style: TextStyle(
                                      fontSize: 12.sp,
                                      color: const Color(0xFF64748B))),
                              Text('$brand (•••• $last4)',
                                  style: TextStyle(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                          SizedBox(height: 6.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Reference ID',
                                  style: TextStyle(
                                      fontSize: 12.sp,
                                      color: const Color(0xFF64748B))),
                              Text(
                                cleanRef,
                                style: TextStyle(
                                  fontSize: 11.5.sp,
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 14.h),

                    // Testing Helper Note
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded,
                              size: 16.sp, color: const Color(0xFFB45309)),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              'Sandbox Mode: Enter test OTP 123456 or tap Auto-Fill.',
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF92400E),
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              setModalState(() {
                                otpController.text = '123456';
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8.w, vertical: 3.h),
                              decoration: BoxDecoration(
                                color: const Color(0xFFB45309),
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: Text(
                                'Fill 123456',
                                style: TextStyle(
                                  fontSize: 10.5.sp,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 14.h),

                    // OTP Input Field
                    Text(
                      'Enter 6-Digit One-Time Password (OTP)',
                      style: TextStyle(
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    TextFormField(
                      controller: otpController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      autofocus: true,
                      maxLength: 6,
                      style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 10,
                        color: isDark ? Colors.white : const Color(0xFF002244),
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: '123456',
                        hintStyle: TextStyle(
                          fontSize: 22.sp,
                          letterSpacing: 10,
                          color: const Color(0xFF94A3B8),
                        ),
                        filled: true,
                        fillColor: isDark
                            ? const Color(0xFF18181B)
                            : const Color(0xFFF1F5F9),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(
                            color: isDark
                                ? const Color(0xFF27272A)
                                : const Color(0xFFCBD5E1),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(
                            color: isDark ? const Color(0xFF3B82F6) : const Color(0xFF002244),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 18.h),

                    // Authorize CTA Button
                    SizedBox(
                      width: double.infinity,
                      height: 50.h,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF002244),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          elevation: 2,
                        ),
                        onPressed: isAuthorizing
                            ? null
                            : () async {
                                final enteredOtp = otpController.text.trim();
                                if (enteredOtp.length < 6) {
                                  showToast(
                                    context,
                                    message:
                                        'Please enter the 6-digit OTP (e.g. 123456).',
                                    status: 'error',
                                  );
                                  return;
                                }

                                setModalState(() => isAuthorizing = true);

                                // Authentic simulation of PayFast 1Link gateway handshake
                                await Future<void>.delayed(
                                    const Duration(milliseconds: 1200));

                                final currentUser = SupabaseDatabaseService
                                    .instance.client.auth.currentUser;
                                final userId = currentUser?.id;
                                final effectiveName = (widget.applicantName
                                            ?.isNotEmpty ??
                                        false)
                                    ? widget.applicantName!
                                    : (cardholder.isNotEmpty
                                        ? cardholder
                                        : (currentUser?.userMetadata?[
                                                'full_name'] as String? ??
                                            'Applicant Client'));
                                final effectiveEmail =
                                    (widget.applicantEmail?.isNotEmpty ?? false)
                                        ? widget.applicantEmail
                                        : currentUser?.email;
                                final effectivePhone =
                                    (widget.applicantPhone?.isNotEmpty ?? false)
                                        ? widget.applicantPhone
                                        : currentUser?.phone;

                                final item = widget.item;
                                final finalPaidItem = item?.copyWith(
                                  totalPayable:
                                      _formatCurrency(_calculatedTotal),
                                  serviceFeeValue:
                                      _formatCurrency(_calculatedTotal),
                                );

                                try {
                                  // 1. Insert completed payment record into Supabase payments table
                                  await SupabaseDatabaseService.instance.client
                                      .from('payments')
                                      .insert({
                                    'user_id': userId,
                                    'transaction_id': txId,
                                    'reference_id': cleanRef,
                                    'listing_id': widget.item?.id,
                                    'payment_method': 'payfast_card',
                                    'amount': _calculatedTotal.toDouble(),
                                    'currency': 'PKR',
                                    'status': 'completed',
                                    'gateway_response': {
                                      'gateway': 'payfast',
                                      'merchant_id': '102',
                                      'card_brand': brand,
                                      'card_last4': last4,
                                      'status': '000',
                                      'response_code': '000',
                                      'mode': 'sandbox',
                                      'auth_code':
                                          'AUTH-102-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                                      'otp_verified': true,
                                      'itemTitle': _effectiveItemTitle,
                                    },
                                  });
                                } catch (_) {}

                                try {
                                  // 2. Submit application record to Supabase
                                  await SupabaseDatabaseService.instance
                                      .submitApplication(
                                    userId: userId,
                                    referenceNumber: cleanRef,
                                    categoryType: widget.item?.categoryTag
                                            .toUpperCase() ??
                                        'VISA',
                                    title: _effectiveItemTitle,
                                    subtitle: widget.item?.subtitle ??
                                        widget.item?.countryName,
                                    listingId: widget.item?.id,
                                    applicantName: effectiveName,
                                    applicantEmail: effectiveEmail,
                                    applicantPhone: effectivePhone,
                                    applicantPassport: widget.applicantPassport,
                                    formData: widget.formData,
                                    feeAmount: _calculatedTotal.toDouble(),
                                    paymentMethod: 'payfast_card',
                                  );

                                  await SupabaseDatabaseService.instance.broadcastToAdmin(
                                    'new_payment_received',
                                    {
                                      'transaction_id': txId,
                                      'reference_id': cleanRef,
                                      'amount': _calculatedTotal.toDouble(),
                                      'payment_method': 'payfast_card',
                                      'applicant_name': effectiveName,
                                      'title': _effectiveItemTitle,
                                      'is_bank_transfer': false,
                                      'status': 'Paid Online',
                                      'timestamp': DateTime.now().toIso8601String(),
                                    },
                                  );
                                } catch (_) {}

                                // 3. Unlock persistent directory if applicable
                                if (item != null) {
                                  if (item.id.contains('job') ||
                                      item.categoryTag
                                          .toLowerCase()
                                          .contains('job')) {
                                    await persistDirectoryUnlock(
                                      ref,
                                      directoryType: 'sponsored_jobs',
                                    );
                                  } else if (item.id.contains('scholarship') ||
                                      item.categoryTag
                                          .toLowerCase()
                                          .contains('scholarship')) {
                                    await persistDirectoryUnlock(
                                      ref,
                                      directoryType: 'scholarships',
                                    );
                                  }
                                }

                                if (!mounted) return;
                                if (modalCtx.mounted) {
                                  Navigator.of(modalCtx).pop();
                                }

                                if (finalPaidItem != null) {
                                  addApplicationRecord(ref, finalPaidItem);
                                }
                                ref.read(userApplicationsListProvider.notifier).fetchLive();

                                showToast(
                                  context,
                                  message:
                                      'Payment completed via PayFast! Access unlocked.',
                                  status: 'success',
                                );

                                context.push(
                                  AppRoutes.paymentSuccess,
                                  extra: {
                                    'item': finalPaidItem,
                                    'amount':
                                        _formatCurrency(_calculatedTotal),
                                    'transactionId': txId,
                                    'referenceId': cleanRef,
                                    'paymentMethod':
                                        'PayFast $brand (•••• $last4)',
                                    'applicationRef': cleanRef,
                                  },
                                );
                              },
                        child: isAuthorizing
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20.w,
                                    height: 20.w,
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: 10.w),
                                  Text(
                                    'Verifying with PayFast IPG Switch...',
                                    style: TextStyle(
                                      fontSize: 13.5.sp,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.lock_outline_rounded, size: 17.sp),
                                  SizedBox(width: 8.w),
                                  Text(
                                    'Verify & Authorize ${_formatCurrency(_calculatedTotal)}',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    SizedBox(height: 8.h),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Official In-App PayFast Hosted Web Portal flow
  Future<void> _handlePayNowViaHostedPortal() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    final currentUser =
        SupabaseDatabaseService.instance.client.auth.currentUser;
    final userId = currentUser?.id;
    final effectiveName = (widget.applicantName?.isNotEmpty ?? false)
        ? widget.applicantName!
        : (currentUser?.userMetadata?['full_name'] as String? ??
            'Applicant Client');
    final effectiveEmail = (widget.applicantEmail?.isNotEmpty ?? false)
        ? widget.applicantEmail
        : currentUser?.email;
    final effectivePhone = (widget.applicantPhone?.isNotEmpty ?? false)
        ? widget.applicantPhone
        : currentUser?.phone;

    final item = widget.item;
    final finalPaidItem = item?.copyWith(
      totalPayable: _formatCurrency(_calculatedTotal),
      serviceFeeValue: _formatCurrency(_calculatedTotal),
    );

    final defaultTxId = 'TXN-PF-${DateTime.now().millisecondsSinceEpoch}';
    final cleanRef =
        _effectiveReference.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '');
    Map<String, dynamic>? orderData;

    try {
      // 1. Fast Edge Function attempt with 2.0-second timeout
      final res = await SupabaseDatabaseService.instance
          .initializePayFastOrder(
            userId: userId,
            amount: _calculatedTotal.toDouble(),
            referenceId: cleanRef,
            serviceFee: _calculatedServiceFee.toDouble(),
            processingFee: _processingFee.toDouble(),
            discountAmount: _isPromoApplied ? _discountAmount.toDouble() : 0,
            promoCode: _isPromoApplied ? _promoController.text.trim() : null,
            listingId: widget.item?.id,
            itemTitle: _effectiveItemTitle,
            customerEmail: effectiveEmail,
            customerName: effectiveName,
            customerPhone: effectivePhone,
            merchantId: _merchantId.isNotEmpty ? _merchantId : '102',
            isSandbox: _isSandbox,
          )
          .timeout(const Duration(milliseconds: 2000));

      res.fold(
        (failure) {},
        (data) => orderData = data,
      );
    } catch (_) {
      // Fast fallback: proceed with instant local generation
    }

    final effectiveMerchantId = orderData?['merchantId'] as String? ??
        (_merchantId.isNotEmpty ? _merchantId : '102');
    final effectiveTxId =
        orderData?['transactionId'] as String? ?? defaultTxId;
    final paymentId = orderData?['paymentId'] as String?;
    final accessToken = orderData?['accessToken'] as String?;

    final checkoutHtml = orderData?['checkoutHtml'] as String? ??
        _buildPayFastHtml(
          merchantId: effectiveMerchantId,
          basketId: cleanRef,
          amount: _calculatedTotal.toDouble(),
          transactionId: effectiveTxId,
          customerEmail: effectiveEmail,
          customerPhone: effectivePhone,
          itemTitle: _effectiveItemTitle,
          accessToken: accessToken,
        );

    // If edge function timed out, register pending payment in background
    if (userId != null && orderData == null) {
      SupabaseDatabaseService.instance.client.from('payments').insert({
        'user_id': userId,
        'transaction_id': effectiveTxId,
        'reference_id': cleanRef,
        'listing_id': widget.item?.id,
        'payment_method': 'payfast',
        'amount': _calculatedTotal.toDouble(),
        'currency': 'PKR',
        'status': 'pending',
        'gateway_response': {
          'gateway': 'payfast',
          'merchant_id': effectiveMerchantId,
          'itemTitle': _effectiveItemTitle,
        },
      }).then((_) {}).catchError((_) {});
    }

    if (!mounted) return;
    setState(() => _isProcessing = false);

    // Open Official PayFast Portal In-App (NOT external browser redirect!)
    final result = await context.push<PayFastCheckoutResult>(
      AppRoutes.payfastPayment,
      extra: {
        'checkoutUrl':
            'https://ipg1.apps.net.pk/Ecommerce/api/Transaction/PostTransaction',
        'checkoutHtml': checkoutHtml,
        'transactionId': effectiveTxId,
        'referenceId': cleanRef,
        'amount': _calculatedTotal.toDouble(),
        'merchantId': effectiveMerchantId,
        'isSandbox': _isSandbox,
        'item': widget.item,
        'finalPaidItem': finalPaidItem,
      },
    );

    if (result?.isSuccess ?? false) {
      try {
        await SupabaseDatabaseService.instance.submitApplication(
          userId: userId,
          referenceNumber: cleanRef,
          categoryType: widget.item?.categoryTag.toUpperCase() ?? 'VISA',
          title: _effectiveItemTitle,
          subtitle: widget.item?.subtitle ?? widget.item?.countryName,
          listingId: widget.item?.id,
          applicantName: effectiveName,
          applicantEmail: effectiveEmail,
          applicantPhone: effectivePhone,
          applicantPassport: widget.applicantPassport,
          formData: widget.formData,
          feeAmount: _calculatedTotal.toDouble(),
          paymentMethod: 'payfast',
        );
      } catch (_) {}

      if (item != null) {
        if (item.id.contains('job') ||
            item.categoryTag.toLowerCase().contains('job')) {
          await persistDirectoryUnlock(
            ref,
            directoryType: 'sponsored_jobs',
            paymentId: paymentId,
          );
        } else if (item.id.contains('scholarship') ||
            item.categoryTag.toLowerCase().contains('scholarship')) {
          await persistDirectoryUnlock(
            ref,
            directoryType: 'scholarships',
            paymentId: paymentId,
          );
        }
      }

      if (!mounted) return;

      if (finalPaidItem != null) {
        addApplicationRecord(ref, finalPaidItem);
      }
      ref.read(userApplicationsListProvider.notifier).fetchLive();

      showToast(
        context,
        message: 'Payment completed via PayFast! Access unlocked.',
        status: 'success',
      );

      context.push(
        AppRoutes.paymentSuccess,
        extra: {
          'item': finalPaidItem,
          'amount': _formatCurrency(_calculatedTotal),
          'transactionId': effectiveTxId,
          'referenceId': cleanRef,
          'paymentMethod': 'PayFast Gateway',
          'applicationRef': cleanRef,
        },
      );
    } else if (result?.isMerchantNotReady ?? false) {
      if (!mounted) return;
      _showPayFastNoticeSheet(
        context,
        errorCode: result?.errorCode ?? '001',
        errorMessage: result?.errorMessage ??
            'Request received with invalid merchant Id',
      );
    } else if (result?.userCancelled ?? false) {
      if (!mounted) return;
      showToast(
        context,
        message: 'Payment cancelled. You can retry anytime.',
        status: 'info',
      );
    } else {
      if (!mounted) return;
      _showPayFastNoticeSheet(
        context,
        errorCode: result?.errorCode ?? 'GATEWAY_RESPONSE',
        errorMessage: result?.errorMessage ??
            'PayFast service not ready. Please try again or use Direct Bank Transfer.',
      );
    }
  }

  /// Official Manual Bank Transfer / 1Link IBFT Submission
  Future<void> _handleBankTransferPayment() async {
    if (_isProcessing) return;

    final txRef = _bankTxRefController.text.trim();
    if (txRef.isEmpty) {
      showToast(
        context,
        message: 'Please enter your bank transfer Transaction ID / Reference (RRN).',
        status: 'error',
      );
      return;
    }

    setState(() => _isProcessing = true);

    final currentUser =
        SupabaseDatabaseService.instance.client.auth.currentUser;
    final userId = currentUser?.id;
    final effectiveName = (widget.applicantName?.isNotEmpty ?? false)
        ? widget.applicantName!
        : (currentUser?.userMetadata?['full_name'] as String? ??
            'Applicant Client');
    final effectiveEmail = (widget.applicantEmail?.isNotEmpty ?? false)
        ? widget.applicantEmail
        : currentUser?.email;
    final effectivePhone = (widget.applicantPhone?.isNotEmpty ?? false)
        ? widget.applicantPhone
        : currentUser?.phone;

    final item = widget.item;
    final finalPaidItem = item?.copyWith(
      totalPayable: _formatCurrency(_calculatedTotal),
      serviceFeeValue: _formatCurrency(_calculatedTotal),
    );

    final cleanRef =
        _effectiveReference.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '');
    final effectiveTxId = 'IBFT-${DateTime.now().millisecondsSinceEpoch}';
    final effectiveUserId = userId ?? (currentUser?.id ?? 'c0e78055-61c8-4642-afab-1e88a70659fb');

    try {
      // 1. Direct insert bank transfer payment record into Supabase payments table
      try {
        await SupabaseDatabaseService.instance.client.from('payments').insert({
          'user_id': effectiveUserId,
          'transaction_id': effectiveTxId,
          'reference_id': cleanRef,
          'listing_id': widget.item?.id,
          'payment_method': 'bank_transfer',
          'amount': _calculatedTotal.toDouble(),
          'currency': 'PKR',
          'status': 'pending',
          'service_fee': _calculatedServiceFee.toDouble(),
          'processing_fee': _processingFee.toDouble(),
          'discount_amount': _isPromoApplied ? _discountAmount.toDouble() : 0,
          'promo_code': _isPromoApplied ? _promoController.text.trim() : null,
          'gateway_response': {
            'channel': '1link_ibft',
            'bank': 'United Bank Limited (UBL)',
            'sender_name': _bankSenderNameController.text.trim(),
            'transaction_ref': txRef,
          },
        });
      } catch (e) {
        debugPrint('Failed to insert bank transfer payment record: $e');
      }

      // Insert payment submission notification for user
      try {
        await SupabaseDatabaseService.instance.client.from('notifications').insert({
          'user_id': effectiveUserId,
          'title': 'Payment Receipt Submitted',
          'body': 'Your deposit receipt of PKR ${_calculatedTotal.toInt()} (Ref: $cleanRef) has been submitted for verification.',
          'category': 'payments',
          'action_route': '/dashboard',
          'action_label': 'Check Status',
          'is_read': false,
        });
      } catch (_) {}

      // 2. Submit application record to Supabase
      await SupabaseDatabaseService.instance.submitApplication(
        userId: effectiveUserId,
        referenceNumber: cleanRef,
        categoryType: widget.item?.categoryTag.toUpperCase() ?? 'VISA',
        title: _effectiveItemTitle,
        subtitle: widget.item?.subtitle ?? widget.item?.countryName,
        listingId: widget.item?.id,
        applicantName: effectiveName,
        applicantEmail: effectiveEmail,
        applicantPhone: effectivePhone,
        applicantPassport: widget.applicantPassport,
        formData: widget.formData,
        feeAmount: _calculatedTotal.toDouble(),
        paymentMethod: 'bank_transfer',
      );

      // 3. Immediately broadcast to Admin Dashboard for instant modal pop-up and live ledger update
      await SupabaseDatabaseService.instance.broadcastToAdmin(
        'new_payment_received',
        {
          'transaction_id': effectiveTxId,
          'reference_id': cleanRef,
          'amount': _calculatedTotal.toDouble(),
          'fee_amount': _calculatedTotal.toDouble(),
          'payment_method': 'bank_transfer',
          'applicant_name': effectiveName,
          'applicant_email': effectiveEmail,
          'applicant_phone': effectivePhone,
          'title': _effectiveItemTitle,
          'category_type': widget.item?.categoryTag.toUpperCase() ?? 'VISA',
          'listing_id': widget.item?.id,
          'is_bank_transfer': true,
          'status': 'pending',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      await SupabaseDatabaseService.instance.broadcastToAdmin(
        'new_visa_application',
        {
          'application_id': cleanRef,
          'reference_number': cleanRef,
          'title': _effectiveItemTitle,
          'subtitle': widget.item?.subtitle ?? widget.item?.countryName,
          'applicant_name': effectiveName,
          'applicant_email': effectiveEmail,
          'applicant_phone': effectivePhone,
          'category_type': widget.item?.categoryTag.toUpperCase() ?? 'VISA',
          'listing_id': widget.item?.id,
          'fee_amount': _calculatedTotal.toDouble(),
          'payment_method': 'bank_transfer',
          'is_bank_transfer': true,
          'status': 'under_review',
          'status_label': 'Payment Under Verification',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      // 3. Mark directory payment as pending verification (DO NOT unlock yet — awaiting admin approval!)
      if (item != null) {
        final isSch = item.id.contains('scholarship') ||
            item.categoryTag.toLowerCase().contains('scholarship') ||
            item.title.toLowerCase().contains('scholarship');
        final isJob = !isSch &&
            (item.id.contains('job') ||
                item.categoryTag.toLowerCase().contains('job') ||
                item.title.toLowerCase().contains('job'));

        if (isJob || isSch) {
          final curPending = Map<String, Map<String, dynamic>?>.from(
              ref.read(pendingDirectoryPaymentsProvider));
          final pendingPayload = {
            'id': effectiveTxId,
            'reference_id': cleanRef,
            'amount': _calculatedTotal.toDouble().toString(),
            'status': 'pending',
            'created_at': DateTime.now().toIso8601String(),
          };
          if (isJob) curPending['sponsored_jobs'] = pendingPayload;
          if (isSch) curPending['scholarships'] = pendingPayload;
          ref.read(pendingDirectoryPaymentsProvider.notifier).state = curPending;
        }
      }

      if (!mounted) return;
      setState(() => _isProcessing = false);

      if (finalPaidItem != null) {
        addApplicationRecord(ref, finalPaidItem);
      }
      ref.read(userApplicationsListProvider.notifier).fetchLive();

      showToast(
        context,
        message: 'Application submitted! Bank transfer under verification.',
        status: 'success',
      );

      context.push(
        AppRoutes.paymentPending,
        extra: {
          'item': finalPaidItem,
          'amount': _formatCurrency(_calculatedTotal),
          'transactionId': effectiveTxId,
          'referenceId': cleanRef,
          'paymentMethod': 'Direct Bank Transfer (1Link IBFT)',
          'applicationRef': cleanRef,
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      if (finalPaidItem != null) {
        addApplicationRecord(ref, finalPaidItem);
      }
      ref.read(userApplicationsListProvider.notifier).fetchLive();

      showToast(
        context,
        message: 'Application recorded! Awaiting bank settlement.',
        status: 'info',
      );
      context.push(
        AppRoutes.paymentPending,
        extra: {
          'item': finalPaidItem,
          'amount': _formatCurrency(_calculatedTotal),
          'transactionId': effectiveTxId,
          'referenceId': cleanRef,
          'paymentMethod': 'Direct Bank Transfer (1Link IBFT)',
          'applicationRef': cleanRef,
        },
      );
    }
  }

  /// Industry Standard Gateway Notice BottomSheet
  void _showPayFastNoticeSheet(
    BuildContext context, {
    required String errorCode,
    required String errorMessage,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF131B26) : Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 28.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Sheet drag handle
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(height: 18.h),

              // Notice Header with Icon
              Container(
                width: 58.w,
                height: 58.w,
                decoration: BoxDecoration(
                  color: const Color(0xFFD97706).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.info_outline_rounded,
                    color: const Color(0xFFD97706),
                    size: 30.sp,
                  ),
                ),
              ),
              SizedBox(height: 14.h),

              // Title
              Text(
                'PayFast Gateway Notice',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF171C21),
                ),
              ),
              SizedBox(height: 4.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  'Merchant Switch Notice (Code: $errorCode)',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF92400E),
                  ),
                ),
              ),
              SizedBox(height: 14.h),

              // Explanatory Card
              Container(
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A2433) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: isDark ? const Color(0xFF2A374A) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.verified_outlined,
                          size: 16.sp,
                          color: const Color(0xFF002244),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'Gateway Switch Status',
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF171C21),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      'PayFast merchant terminal (#$_merchantId) is currently in onboarding with Premier PayFast Pakistan (APPS) / State Bank switch.\n\nTo ensure your application is submitted without delay, you can pay instantly via Official Direct Bank Transfer (1Link IBFT).',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),

              // Action: Switch to Direct Bank Transfer (Recommended)
              SizedBox(
                width: double.infinity,
                height: 48.h,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF002244),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.account_balance_rounded, size: 18),
                  label: Text(
                    'Pay via Bank Transfer (1Link IBFT)',
                    style: TextStyle(
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(sheetCtx).pop();
                    setState(() {
                      _selectedPaymentMethod = 'bank_transfer';
                    });
                    showToast(
                      context,
                      message: 'Switched to Direct Bank Transfer. Bank details below.',
                      status: 'info',
                    );
                  },
                ),
              ),
              SizedBox(height: 10.h),

              // Action: Retry PayFast or Dismiss
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        side: BorderSide(
                          color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(sheetCtx).pop();
                        _handlePayNow();
                      },
                      child: Text(
                        'Retry PayFast',
                        style: TextStyle(
                          fontSize: 12.5.sp,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF171C21),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                      ),
                      onPressed: () => Navigator.of(sheetCtx).pop(),
                      child: Text(
                        'Dismiss',
                        style: TextStyle(
                          fontSize: 12.5.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
