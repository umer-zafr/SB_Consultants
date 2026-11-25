import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sd_consultant/src/imports/packages_imports.dart';
import 'package:flutter_sd_consultant/src/routing/app_routes.dart';
import 'package:flutter_sd_consultant/src/shared/app_assets.dart';
import 'package:flutter_sd_consultant/src/shared/helpers/show_toast.dart';
import 'package:flutter_sd_consultant/src/shared/helpers/whatsapp_helper.dart';
import 'package:flutter_sd_consultant/src/shared/widgets/app_dashboard_bottom_nav.dart';
import 'package:flutter_sd_consultant/src/ui/auth/providers/session_provider.dart';
import 'package:flutter_sd_consultant/src/theme/theme_provider.dart';
import 'package:flutter_sd_consultant/src/ui/dashboard/my_applications_screen.dart';
import 'package:flutter_sd_consultant/src/ui/home/providers/home_provider.dart';
import 'package:flutter_sd_consultant/src/ui/notifications/providers/notifications_provider.dart';
import 'package:flutter_sd_consultant/src/ui/profile/models/transaction_record_model.dart';
import 'package:flutter_sd_consultant/src/ui/profile/providers/profile_picture_provider.dart';
import 'package:flutter_sd_consultant/src/ui/profile/providers/transactions_provider.dart';
import 'package:flutter_sd_consultant/src/ui/saved/providers/saved_visas_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Screen representing the full User Account & Profile.
///
/// Matches specifications of media_1790710788686.png:
/// 1. Top custom AppBar inside Deep Navy Canopy with back button, "Account & Profile" title,
///    and more options button.
/// 2. Profile identity hero:
///    - Large circular avatar with white ring border and camera overlay badge.
///    - Verified checkmark next to user's full name.
///    - Subtitle email address.
///    - Outlined "Edit Profile" pill button with pencil icon.
/// 3. Floating 3-metric summary card:
///    - Applications (4) -> Tapping navigates to Dashboard / Applications.
///    - Saved (12) -> Tapping opens Saved Items modal.
///    - Member Since (2024) -> Tapping opens Member Since advisory modal.
/// 4. ACCOUNT section:
///    - Personal Information (with interactive sheet to view & edit details).
///    - My Documents (with "4 uploaded" tag & interactive documents sheet).
///    - Payment Methods (with interactive saved cards & add card sheet).
///    - Transaction History (with interactive receipts & invoices sheet).
///    - Saved Items (with bookmarked visas, jobs & scholarships).
/// 5. PREFERENCES section:
///    - Dark Mode toggle switch.
///    - Push Notifications toggle switch (enabled by default).
///    - Language selector ("English (UK)" with interactive language picker).
///    - Face ID / Biometric Login toggle switch.
/// 6. SUPPORT section:
///    - Help Center (FAQs & guides sheet).
///    - Contact Support (direct consultant helpline, WhatsApp & live chat).
///    - Terms & Conditions (regulatory & advisory terms sheet).
///    - Privacy Policy (GDPR & data protection sheet).
///    - About SB Consultants ("v1.0.0" badge & company licensing info).
/// 7. Bottom Actions & Regulatory Footer:
///    - Red outlined "Log Out" button with confirmation dialog.
///    - Red "Delete Account" text button with safety confirmation dialog.
///    - "SB Consultants Global Migration Ltd • Regulated Advisory" legal footer.
/// 8. Persistent 4-item bottom navigation bar with active "Profile" pill.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  // User profile state
  String _userName = '';
  String _userEmail = '';
  String _userPhone = '';
  String _userCity = '';
  String _userPassport = '';
  String _userNationality = '';
  String _userDob = '';

  // Preferences toggles state matching reference
  bool _pushNotifications = true;
  String _selectedLanguage = 'English';

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    // 1. Initial hydration from auth user metadata
    final meta = user.userMetadata ?? {};
    final mName = (meta['name'] ?? meta['full_name'] ?? '') as String;
    final mPhone = (meta['phone'] ?? meta['phone_number'] ?? '') as String;
    final mCity = (meta['city'] ?? '') as String;

    if (mounted) {
      setState(() {
        if (mName.isNotEmpty && _userName.isEmpty) _userName = mName;
        if (user.email != null && user.email!.isNotEmpty) _userEmail = user.email!;
        if (mPhone.isNotEmpty && _userPhone.isEmpty) _userPhone = mPhone;
        if (mCity.isNotEmpty && _userCity.isEmpty) _userCity = mCity;
      });
    }

    // 2. Fetch fresh record from public.profiles table
    try {
      final profile = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (profile != null && mounted) {
        setState(() {
          final pName = (profile['full_name'] as String?)?.trim();
          final pEmail = (profile['email'] as String?)?.trim();
          final pPhone = (profile['phone'] as String?)?.trim();
          final pCity = (profile['city'] as String?)?.trim();
          final pPassport = (profile['passport_number'] as String?)?.trim();
          final pNationality = (profile['nationality'] as String?)?.trim();
          final pDob = (profile['dob'] as String?)?.trim();

          if (pName != null && pName.isNotEmpty) _userName = pName;
          if (pEmail != null && pEmail.isNotEmpty) _userEmail = pEmail;
          if (pPhone != null && pPhone.isNotEmpty) _userPhone = pPhone;
          if (pCity != null && pCity.isNotEmpty) _userCity = pCity;
          if (pPassport != null && pPassport.isNotEmpty) _userPassport = pPassport;
          if (pNationality != null && pNationality.isNotEmpty) _userNationality = pNationality;
          if (pDob != null && pDob.isNotEmpty) _userDob = pDob;
        });

        // If phone was in userMetadata but not in profiles table, backfill it now
        if ((profile['phone'] == null || (profile['phone'] as String).isEmpty) && mPhone.isNotEmpty) {
          try {
            await Supabase.instance.client.from('profiles').update({
              'phone': mPhone,
              'updated_at': DateTime.now().toIso8601String(),
            }).eq('id', user.id);
          } catch (_) {}
        }
      }
    } catch (_) {}
  }

  String _formatMonthYear(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final session = ref.watch(sessionProvider);
    final supabaseUser = Supabase.instance.client.auth.currentUser;

    // Actual user authenticated email
    final authEmail = supabaseUser?.email ?? session.userOrNull?.email;
    final displayEmail = (authEmail != null && authEmail.isNotEmpty)
        ? authEmail
        : (_userEmail.isNotEmpty ? _userEmail : 'No Email');

    // Actual user name
    final authName = session.userOrNull?.name ??
        (supabaseUser?.userMetadata?['name'] as String?) ??
        (supabaseUser?.userMetadata?['full_name'] as String?) ??
        (authEmail != null && authEmail.contains('@')
            ? authEmail.split('@').first
            : null);
    final displayName = _userName.isNotEmpty
        ? _userName
        : (authName != null && authName.isNotEmpty ? authName : 'Client User');

    // Actual user phone
    final authPhone = (supabaseUser?.userMetadata?['phone'] as String?) ??
        (supabaseUser?.userMetadata?['phone_number'] as String?) ??
        session.userOrNull?.phone;
    final displayPhone = _userPhone.isNotEmpty
        ? _userPhone
        : (authPhone != null && authPhone.isNotEmpty ? authPhone : '');

    // Actual registration date (Member Since)
    DateTime? registrationDate;
    if (supabaseUser?.createdAt != null) {
      registrationDate = DateTime.tryParse(supabaseUser!.createdAt);
    }
    registrationDate ??= session.userOrNull?.createdAt;

    final String memberSinceYear = registrationDate != null
        ? '${registrationDate.year}'
        : '2024';
    final String memberSinceFull = registrationDate != null
        ? _formatMonthYear(registrationDate)
        : 'October 2024';

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF000000) : const Color(0xFFF7F9FF),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // 1. Deep Navy Hero Canopy with Profile Header
            _buildHeroCanopy(
              context,
              displayName: displayName,
              displayEmail: displayEmail,
              displayPhone: displayPhone,
            ),

            // 2. Floating 3-Metric Summary Card
            Transform.translate(
              offset: Offset(0, -22.h),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: _buildMetricSummaryCard(
                  context,
                  memberSinceYear: memberSinceYear,
                  memberSinceFull: memberSinceFull,
                ),
              ),
            ),

            // Profile Sections Content
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 3. ACCOUNT Section
                  _buildSectionHeader('ACCOUNT'),
                  SizedBox(height: 8.h),
                  _buildAccountCard(context),
                  SizedBox(height: 24.h),

                  // 4. PREFERENCES Section
                  _buildSectionHeader('PREFERENCES'),
                  SizedBox(height: 8.h),
                  _buildPreferencesCard(context),
                  SizedBox(height: 24.h),

                  // 5. SUPPORT Section
                  _buildSectionHeader('SUPPORT'),
                  SizedBox(height: 8.h),
                  _buildSupportCard(context),
                  SizedBox(height: 28.h),

                  // 6. Bottom Actions: Log Out & Delete Account
                  _buildBottomActions(context),
                  SizedBox(height: 18.h),

                  // 7. Regulatory Footer
                  Center(
                    child: Text(
                      'SB Consultants Global Migration Ltd • Regulated Advisory',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10.5.sp,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF8FAEC9),
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  SizedBox(height: 32.h),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppDashboardBottomNav(currentIndex: 3),
    );
  }

  // ===========================================================================
  // 1. HERO CANOPY (Matches media_1790710788686.png)
  // ===========================================================================
  Widget _buildHeroCanopy(
    BuildContext context, {
    required String displayName,
    required String displayEmail,
    String displayPhone = '',
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121212) : const Color(0xFF1B3A5C),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(32.r),
        ),
        border: isDark
            ? const Border(
                bottom: BorderSide(color: Color(0xFF27272A), width: 1),
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.4)
                : const Color(0xFF1B3A5C).withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 42.h),
          child: Column(
            children: [
              // Top Bar: Back Button, Title, and More Options
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Circular Back Button
                  InkWell(
                    onTap: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go(AppRoutes.home);
                      }
                    },
                    borderRadius: BorderRadius.circular(20.r),
                    child: Container(
                      width: 38.w,
                      height: 38.w,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
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

                  // Center Title
                  Text(
                    'Account & Profile',
                    style: TextStyle(
                      fontSize: 16.5.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.2,
                    ),
                  ),

                  // Top right spacer to keep "Account & Profile" title centered (3 dots removed)
                  SizedBox(width: 38.w),
                ],
              ),
              SizedBox(height: 18.h),

              // Avatar with White Ring & Camera Overlay Badge
              Stack(
                alignment: Alignment.center,
                children: [
                  // Outer White Ring Border
                  Container(
                    width: 88.w,
                    height: 88.w,
                    padding: EdgeInsets.all(3.w),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2.2.w,
                      ),
                    ),
                    child: ClipOval(
                      child: _buildAvatarContent(
                        ref.watch(profilePictureProvider),
                        displayName,
                      ),
                    ),
                  ),

                  // Camera Badge Icon on Bottom Right
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: InkWell(
                      onTap: () => _showChangePhotoSheet(context),
                      borderRadius: BorderRadius.circular(16.r),
                      child: Container(
                        width: 28.w,
                        height: 28.w,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.18),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.camera_alt_rounded,
                            size: 15,
                            color: Color(0xFF1B3A5C),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),

              // User Name + Verified Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        displayName,
                        style: TextStyle(
                          fontSize: 18.5.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 6.w),
                  Icon(
                    Icons.verified_rounded,
                    size: 17.sp,
                    color: const Color(0xFF60A5FA),
                  ),
                ],
              ),
              SizedBox(height: 4.h),

              // User Email
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  displayEmail,
                  style: TextStyle(
                    fontSize: 12.5.sp,
                    color: const Color(0xFFABC9F2),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              if (displayPhone.isNotEmpty) ...[
                SizedBox(height: 3.h),
                Text(
                  displayPhone,
                  style: TextStyle(
                    fontSize: 11.5.sp,
                    color: const Color(0xFFABC9F2).withValues(alpha: 0.85),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
              SizedBox(height: 14.h),

              // "Edit Profile" Pill Outlined Button
              InkWell(
                onTap: () => _showEditProfileSheet(context),
                borderRadius: BorderRadius.circular(20.r),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 7.h),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.65),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.edit_outlined,
                        size: 14.sp,
                        color: Colors.white,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        'Edit Profile',
                        style: TextStyle(
                          fontSize: 12.5.sp,
                          fontWeight: FontWeight.w600,
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
      ),
    );
  }

  // ===========================================================================
  // 2. FLOATING 3-METRIC SUMMARY CARD (Matches media_1790710788686.png)
  // ===========================================================================
  Widget _buildMetricSummaryCard(
    BuildContext context, {
    required String memberSinceYear,
    required String memberSinceFull,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final savedCount = ref.watch(savedVisasProvider).length;
    final liveApplications = ref.watch(userApplicationsListProvider);
    final applicationsCount = liveApplications.length;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 8.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121212) : Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: isDark ? const Color(0xFF27272A) : const Color(0xFFE8EEF5),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : const Color(0xFF1B3A5C).withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // 1. Applications (Live dynamic count -> routes to My Applications)
          Expanded(
            child: _buildMetricItem(
              context: context,
              icon: Icons.assignment_ind_outlined,
              value: '$applicationsCount',
              label: 'Applications',
              onTap: () => context.push(AppRoutes.dashboard),
            ),
          ),

          // Divider
          Container(
            height: 38.h,
            width: 1,
            color: isDark ? const Color(0xFF27272A) : const Color(0xFFE8EEF5),
          ),

          // 2. Saved (Dynamic live count -> routes to SavedVisasScreen)
          Expanded(
            child: _buildMetricItem(
              context: context,
              icon: Icons.bookmark_rounded,
              value: '$savedCount',
              label: 'Saved',
              onTap: () => context.push(AppRoutes.savedVisas),
            ),
          ),

          // Divider
          Container(
            height: 38.h,
            width: 1,
            color: isDark ? const Color(0xFF27272A) : const Color(0xFFE8EEF5),
          ),

          // 3. Member Since
          Expanded(
            child: _buildMetricItem(
              context: context,
              icon: Icons.calendar_today_outlined,
              value: memberSinceYear,
              label: 'Member Since',
              onTap: () => _showMemberSinceSheet(context, memberSinceFull, memberSinceYear),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem({
    required BuildContext context,
    required IconData icon,
    required String value,
    required String label,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32.w,
            height: 32.w,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E1E1E)
                  : const Color(0xFFEDF4FC),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Center(
              child: Icon(
                icon,
                size: 16.sp,
                color: isDark
                    ? const Color(0xFF93C5FD)
                    : const Color(0xFF1B3A5C),
              ),
            ),
          ),
          SizedBox(height: 6.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF171C21),
                letterSpacing: -0.4,
              ),
            ),
          ),
          SizedBox(height: 2.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? const Color(0xFFA1A1AA)
                    : const Color(0xFF5A626A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SECTION HEADERS
  // ===========================================================================
  Widget _buildSectionHeader(String title) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Padding(
          padding: EdgeInsets.only(left: 4.w),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 11.5.sp,
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF3D6186),
              letterSpacing: 0.8,
            ),
          ),
        );
      },
    );
  }

  // ===========================================================================
  // 3. ACCOUNT CARD (Matches media_1790710788686.png)
  // ===========================================================================
  Widget _buildAccountCard(BuildContext context) {
    final liveApplications = ref.watch(userApplicationsListProvider);
    final transactions = ref.watch(transactionHistoryProvider);

    return DecoratedBox(
      decoration: _cardBoxDecoration(),
      child: Column(
        children: [
          _buildActionRow(
            icon: Icons.assignment_ind_outlined,
            title: 'My Applications',
            trailingBadge: liveApplications.isEmpty
                ? '0 Active'
                : '${liveApplications.length} Active',
            onTap: () => context.push(AppRoutes.dashboard),
          ),
          _buildItemDivider(),
          _buildActionRow(
            icon: Icons.person_outline_rounded,
            title: 'Personal Information',
            onTap: () => _showPersonalInfoSheet(context),
          ),
          _buildItemDivider(),
          _buildActionRow(
            icon: Icons.account_balance_outlined,
            title: 'Bank & Wire Details',
            trailingBadge: 'Bank Wire',
            onTap: () => _showPaymentMethodsSheet(context),
          ),
          _buildItemDivider(),
          _buildActionRow(
            icon: Icons.receipt_long_outlined,
            title: 'Transaction History',
            trailingBadge: transactions.isEmpty ? '0 Records' : '${transactions.length} Records',
            onTap: () => _showTransactionHistorySheet(context),
          ),
          _buildItemDivider(),
          _buildActionRow(
            icon: Icons.bookmark_border_rounded,
            title: 'Saved Items',
            trailingBadge: '${ref.watch(savedVisasProvider).length} Saved',
            onTap: () => context.push(AppRoutes.savedVisas),
          ),
          if (ref.watch(isAdminProvider)) ...[
            _buildItemDivider(),
            _buildActionRow(
              icon: Icons.admin_panel_settings_rounded,
              title: 'Admin Management Portal',
              trailingBadge: 'Admin',
              onTap: () => context.push(AppRoutes.adminDashboard),
            ),
          ],
          if (_userEmail.toLowerCase().trim() == 'umerzafar781@gmail.com' || ref.watch(isAdminProvider)) ...[
            _buildItemDivider(),
            _buildActionRow(
              icon: Icons.lock_reset_rounded,
              title: 'Reset Directory Paywall (Test Mode)',
              trailingBadge: 'Paywall Locked',
              onTap: () async {
                await resetDirectoryPaywallForTesting(ref);
                if (context.mounted) {
                  showGlobalToast(
                    message:
                        'Directory paywalls locked for testing. Sponsored Jobs and Scholarships require unlock pass.',
                    status: 'info',
                  );
                }
              },
            ),
          ],
        ],
      ),
    );
  }

  // ===========================================================================
  // 4. PREFERENCES CARD (Matches media_1790710788686.png)
  // ===========================================================================
  Widget _buildPreferencesCard(BuildContext context) {
    final unreadNotifs = ref.watch(unreadNotificationsCountProvider);

    return DecoratedBox(
      decoration: _cardBoxDecoration(),
      child: Column(
        children: [
          // Notification Center
          _buildActionRow(
            icon: Icons.notifications_active_outlined,
            title: 'Notification Center',
            trailingBadge: unreadNotifs > 0 ? '$unreadNotifs New' : 'Up to date',
            onTap: () => context.push(AppRoutes.notifications),
          ),
          _buildItemDivider(),

          // Dark Mode Toggle
          _buildSwitchRow(
            icon: Icons.dark_mode_outlined,
            title: 'Dark Mode',
            value: ref.watch(themeModeProvider) == ThemeMode.dark,
            onChanged: (val) async {
              await ref.read(themeModeProvider.notifier).setDarkMode(val);
              if (context.mounted) {
                showToast(
                  context,
                  message: val ? 'Dark theme enabled' : 'Light theme enabled',
                  status: 'info',
                );
              }
            },
          ),
          _buildItemDivider(),

          // Push Notifications Toggle
          _buildSwitchRow(
            icon: Icons.notifications_none_rounded,
            title: 'Push Notifications',
            value: _pushNotifications,
            onChanged: (val) {
              setState(() => _pushNotifications = val);
              showToast(
                context,
                message: val
                    ? 'Push notifications activated'
                    : 'Push notifications paused',
                status: 'info',
              );
            },
          ),
          _buildItemDivider(),

          // Language Selector
          _buildActionRow(
            icon: Icons.language_rounded,
            title: 'Language',
            trailingBadge: _selectedLanguage,
            onTap: () => _showLanguageSelectorSheet(context),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 5. SUPPORT CARD (Matches media_1790710788686.png)
  // ===========================================================================
  Widget _buildSupportCard(BuildContext context) {
    return DecoratedBox(
      decoration: _cardBoxDecoration(),
      child: Column(
        children: [
          _buildActionRow(
            icon: Icons.help_outline_rounded,
            title: 'Help Center',
            onTap: () => _showHelpCenterSheet(context),
          ),
          _buildItemDivider(),
          _buildActionRow(
            icon: Icons.chat_bubble_outline_rounded,
            title: 'Contact Support',
            onTap: () => _showContactSupportSheet(context),
          ),
          _buildItemDivider(),
          _buildActionRow(
            icon: Icons.article_outlined,
            title: 'Terms & Conditions',
            onTap: () => _showTermsSheet(context),
          ),
          _buildItemDivider(),
          _buildActionRow(
            icon: Icons.assignment_return_outlined,
            title: 'Return & Refund Policy',
            onTap: () => _showReturnPolicySheet(context),
          ),
          _buildItemDivider(),
          _buildActionRow(
            icon: Icons.shield_outlined,
            title: 'Privacy Policy',
            onTap: () => _showPrivacyPolicySheet(context),
          ),
          _buildItemDivider(),
          _buildActionRow(
            icon: Icons.info_outline_rounded,
            title: 'About SB Consultants',
            trailingBadge: 'v1.0.0',
            onTap: () => _showAboutSheet(context),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 6. BOTTOM ACTIONS: LOG OUT & DELETE ACCOUNT
  // ===========================================================================
  Widget _buildBottomActions(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final logoutBtnBg = isDark ? const Color(0xFF121212) : Colors.white;
    return Column(
      children: [
        // Outlined Log Out Button
        SizedBox(
          width: double.infinity,
          height: 48.h,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              backgroundColor: logoutBtnBg,
              side: const BorderSide(color: Color(0xFFBA1A1A), width: 1.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14.r),
              ),
            ),
            onPressed: () => _showLogoutConfirmDialog(context),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.logout_rounded,
                  color: Color(0xFFBA1A1A),
                  size: 18,
                ),
                SizedBox(width: 8.w),
                Text(
                  'Log Out',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFBA1A1A),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // REUSABLE ROW BUILDERS & DECORATIONS
  // ===========================================================================
  BoxDecoration _cardBoxDecoration() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: isDark ? const Color(0xFF121212) : Colors.white,
      borderRadius: BorderRadius.circular(16.r),
      border: Border.all(
        color: isDark ? const Color(0xFF27272A) : const Color(0xFFE8EEF5),
      ),
      boxShadow: [
        BoxShadow(
          color: isDark
              ? Colors.black.withValues(alpha: 0.25)
              : const Color(0xFF1B3A5C).withValues(alpha: 0.035),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }

  Widget _buildItemDivider() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Divider(
      height: 1,
      thickness: 1,
      color: isDark ? const Color(0xFF27272A) : const Color(0xFFF1F5F9),
      indent: 48.w,
      endIndent: 14.w,
    );
  }

  Widget _buildActionRow({
    required IconData icon,
    required String title,
    String? trailingBadge,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
        child: Row(
          children: [
            // Icon Pill
            Container(
              width: 32.w,
              height: 32.w,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E1E1E)
                    : const Color(0xFFEDF4FC),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: 17.sp,
                  color: isDark
                      ? const Color(0xFF93C5FD)
                      : const Color(0xFF1B3A5C),
                ),
              ),
            ),
            SizedBox(width: 12.w),

            // Title
            Expanded(
              child: Text(
                title,
                softWrap: true,
                style: TextStyle(
                  fontSize: 13.5.sp,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF171C21),
                ),
              ),
            ),

            // Optional Trailing Badge Text
            if (trailingBadge != null) ...[
              SizedBox(width: 8.w),
              Text(
                trailingBadge,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? const Color(0xFF93C5FD)
                      : const Color(0xFF3D6186),
                ),
              ),
            ],

            SizedBox(width: 4.w),

            // Chevron Right
            Icon(
              Icons.chevron_right_rounded,
              size: 20.sp,
              color: isDark
                  ? const Color(0xFFA1A1AA)
                  : const Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchRow({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      child: Row(
        children: [
          // Icon Pill
          Container(
            width: 32.w,
            height: 32.w,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E1E1E)
                  : const Color(0xFFEDF4FC),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Center(
              child: Icon(
                icon,
                size: 17.sp,
                color: isDark
                    ? const Color(0xFF93C5FD)
                    : const Color(0xFF1B3A5C),
              ),
            ),
          ),
          SizedBox(width: 12.w),

          // Title
          Expanded(
            child: Text(
              title,
              softWrap: true,
              style: TextStyle(
                fontSize: 13.5.sp,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF171C21),
              ),
            ),
          ),

          // Switch
          Switch(
            value: value,
            activeThumbColor: Colors.white,
            activeTrackColor: isDark
                ? const Color(0xFF3B82F6)
                : const Color(0xFF002444),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: isDark
                ? const Color(0xFF475569)
                : const Color(0xFFE2E8F0),
            trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // INTERACTIVE SHEETS & MODALS (Enabling all options)
  // ===========================================================================

  // 1. Edit Profile Sheet
  void _showEditProfileSheet(BuildContext context) {
    final supabaseUser = Supabase.instance.client.auth.currentUser;
    final meta = supabaseUser?.userMetadata ?? {};
    final authName = (meta['name'] ?? meta['full_name']) as String?;
    final authPhone = (meta['phone'] ?? meta['phone_number']) as String?;
    final authEmail = supabaseUser?.email;

    final initialName = _userName.isNotEmpty
        ? _userName
        : (authName ?? '');
    final initialEmail = _userEmail.isNotEmpty
        ? _userEmail
        : (authEmail ?? '');
    final initialPhone = _userPhone.isNotEmpty
        ? _userPhone
        : (authPhone ?? '');

    final nameCtrl = TextEditingController(text: initialName);
    final emailCtrl = TextEditingController(text: initialEmail);
    final phoneCtrl = TextEditingController(text: initialPhone);
    final cityCtrl = TextEditingController(text: _userCity);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.85,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF121212) : Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 28.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSheetHandle(),
                  SizedBox(height: 14.h),
                  Text(
                    'Edit Personal Profile',
                    style: TextStyle(
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF171C21),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Update your verified contact and identification info',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF5A626A),
                    ),
                  ),
                  SizedBox(height: 16.h),

                  _buildInputField(label: 'Full Name', controller: nameCtrl, isDark: isDark),
                  SizedBox(height: 12.h),
                  _buildInputField(label: 'Email Address', controller: emailCtrl, isDark: isDark),
                  SizedBox(height: 12.h),
                  _buildInputField(label: 'Phone Number', controller: phoneCtrl, isDark: isDark),
                  SizedBox(height: 12.h),
                  _buildInputField(label: 'Current City & Country', controller: cityCtrl, isDark: isDark),
                  SizedBox(height: 20.h),

                  SizedBox(
                    width: double.infinity,
                    height: 48.h,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? const Color(0xFF2563EB) : const Color(0xFF002444),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      onPressed: () async {
                        final newName = nameCtrl.text.trim();
                        final newPhone = phoneCtrl.text.trim();
                        final newCity = cityCtrl.text.trim();
                        final user = Supabase.instance.client.auth.currentUser;

                        if (user != null) {
                          try {
                            // 1. Update public.profiles
                            await Supabase.instance.client.from('profiles').update({
                              if (newName.isNotEmpty) 'full_name': newName,
                              'phone': newPhone,
                              'city': newCity,
                              'updated_at': DateTime.now().toIso8601String(),
                            }).eq('id', user.id);

                            // 2. Update user metadata in auth.users
                            await Supabase.instance.client.auth.updateUser(
                              UserAttributes(
                                data: {
                                  'name': newName,
                                  'full_name': newName,
                                  'phone': newPhone,
                                  'phone_number': newPhone,
                                  'city': newCity,
                                },
                              ),
                            );
                          } catch (_) {}
                        }

                        if (ctx.mounted) {
                          Navigator.of(ctx).pop();
                        }
                        if (mounted && context.mounted) {
                          setState(() {
                            if (newName.isNotEmpty) _userName = newName;
                            _userPhone = newPhone;
                            _userCity = newCity;
                          });
                          showToast(
                            context,
                            message: 'Profile information updated successfully',
                            status: 'success',
                          );
                        }
                      },
                      child: Text(
                        'Save Changes',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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

  // 2. Change Photo Sheet
  void _showChangePhotoSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
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
              _buildSheetHandle(),
              SizedBox(height: 14.h),
              Text(
                'Change Profile Photo',
                style: TextStyle(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF171C21),
                ),
              ),
              SizedBox(height: 16.h),
              ListTile(
                leading: Icon(
                  Icons.photo_camera_rounded,
                  color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF002444),
                ),
                title: Text(
                  'Take a New Photo',
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF171C21),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  final success = await ref
                      .read(profilePictureProvider.notifier)
                      .takePhotoWithCamera();
                  if (context.mounted && success) {
                    showToast(
                      context,
                      message: 'Profile photo updated successfully!',
                      status: 'success',
                    );
                  }
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.photo_library_rounded,
                  color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF002444),
                ),
                title: Text(
                  'Choose from Gallery',
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF171C21),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  final success = await ref
                      .read(profilePictureProvider.notifier)
                      .pickImageFromGallery();
                  if (context.mounted && success) {
                    showToast(
                      context,
                      message: 'Profile photo selected from gallery!',
                      status: 'success',
                    );
                  }
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.refresh_rounded,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF5A626A),
                ),
                title: Text(
                  'Reset to Default Initials',
                  style: TextStyle(
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF5A626A),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  await ref.read(profilePictureProvider.notifier).removePhoto();
                  if (context.mounted) {
                    showToast(
                      context,
                      message: 'Reset to default initials badge',
                      status: 'info',
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // 3. Personal Information Sheet
  void _showPersonalInfoSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final supabaseUser = Supabase.instance.client.auth.currentUser;
    final meta = supabaseUser?.userMetadata ?? {};
    final authName = (meta['name'] ?? meta['full_name']) as String?;
    final authPhone = (meta['phone'] ?? meta['phone_number']) as String?;
    final authEmail = supabaseUser?.email;

    final resolvedName = _userName.isNotEmpty
        ? _userName
        : (authName != null && authName.isNotEmpty ? authName : 'Client User');
    final resolvedEmail = _userEmail.isNotEmpty
        ? _userEmail
        : (authEmail != null && authEmail.isNotEmpty ? authEmail : 'Not Provided');
    final resolvedPhone = _userPhone.isNotEmpty
        ? _userPhone
        : (authPhone != null && authPhone.isNotEmpty ? authPhone : 'Not Provided');
    final resolvedCity = _userCity.isNotEmpty ? _userCity : 'Not Provided';
    final resolvedPassport = _userPassport.isNotEmpty ? _userPassport : 'Not Provided';
    final resolvedNationality = _userNationality.isNotEmpty ? _userNationality : 'Not Provided';
    final resolvedDob = _userDob.isNotEmpty ? _userDob : 'Not Provided';

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
              _buildSheetHandle(),
              SizedBox(height: 14.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Personal Information',
                    style: TextStyle(
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF171C21),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _showEditProfileSheet(context);
                    },
                    child: Text(
                      'Edit',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF002444),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              _buildInfoRow('Full Legal Name', resolvedName, isDark: isDark),
              _buildInfoRow('Passport Number', resolvedPassport, isDark: isDark),
              _buildInfoRow('Nationality', resolvedNationality, isDark: isDark),
              _buildInfoRow('Date of Birth', resolvedDob, isDark: isDark),
              _buildInfoRow('Phone', resolvedPhone, isDark: isDark),
              _buildInfoRow('Email', resolvedEmail, isDark: isDark),
              _buildInfoRow('Current Address', resolvedCity, isDark: isDark),
              SizedBox(height: 20.h),
              SizedBox(
                width: double.infinity,
                height: 46.h,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? const Color(0xFF2563EB) : const Color(0xFF002444),
                    foregroundColor: Colors.white,
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
        );
      },
    );
  }



  // 5. Payment Methods Sheet (Only Official Corporate Bank Wire Details)
  void _showPaymentMethodsSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.90,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF121212) : Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSheetHandle(),
                SizedBox(height: 12.h),

                // Top Header with explicit Back Button
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back_rounded,
                        color: isDark ? Colors.white : const Color(0xFF1B3A5C),
                        size: 22.sp,
                      ),
                      onPressed: () => Navigator.of(ctx).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Back',
                    ),
                    SizedBox(width: 8.w),
                    Container(
                      padding: EdgeInsets.all(7.w),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F263E) : const Color(0xFFEDF4FC),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Icon(
                        Icons.account_balance_rounded,
                        color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1B3A5C),
                        size: 19.sp,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Official Bank Details',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF171C21),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Direct Corporate Banking & Escrow',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 6.w),
                    IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        size: 20.sp,
                      ),
                      onPressed: () => Navigator.of(ctx).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Close',
                    ),
                  ],
                ),
                SizedBox(height: 16.h),

                // Corporate Bank Card
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF002444), Color(0xFF1B3A5C)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF002444).withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(6.w),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: const Icon(
                                    Icons.account_balance_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                Flexible(
                                  child: Text(
                                    'United Bank Limited (UBL)',
                                    style: TextStyle(
                                      fontSize: 13.5.sp,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: 0.3,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 6.w),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                            decoration: BoxDecoration(
                              color: const Color(0xFF16A34A),
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Text(
                              'VERIFIED ESCROW',
                              style: TextStyle(
                                fontSize: 9.sp,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        'ACCOUNT TITLE',
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.7),
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'SB Consultants',
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 14.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'IBAN',
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withValues(alpha: 0.7),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'PK62UNIL0109000340439603',
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: 0.8,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 8.w),
                          InkWell(
                            onTap: () {
                              Clipboard.setData(
                                const ClipboardData(text: 'PK62UNIL0109000340439603'),
                              );
                              showToast(
                                context,
                                message: 'IBAN copied to clipboard',
                                status: 'success',
                              );
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.copy_rounded, color: Colors.white, size: 13.sp),
                                  SizedBox(width: 4.w),
                                  Text(
                                    'Copy',
                                    style: TextStyle(
                                      fontSize: 11.sp,
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
                    ],
                  ),
                ),
                SizedBox(height: 18.h),

                Text(
                  'Account Information & Routing',
                  style: TextStyle(
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF171C21),
                  ),
                ),
                SizedBox(height: 10.h),

                _buildBankDetailRow(context, 'Bank Name', 'United Bank Limited (UBL)', isDark),
                _buildBankDetailRow(context, 'Account Title', 'SB Consultants', isDark),
                _buildBankDetailRow(context, 'Account Number', '1495340439603', isDark, canCopy: true),
                _buildBankDetailRow(context, 'IBAN', 'PK62UNIL0109000340439603', isDark, canCopy: true),

                SizedBox(height: 14.h),

                // Instructions Notice
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF18181B) : const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: isDark ? const Color(0xFF27272A) : const Color(0xFFFDE68A),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 18),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Text(
                          'For visa retainers and application processing fees, transfer directly via online banking or counter deposit. Upload your deposit slip or screenshot in your application portal for immediate verification.',
                          style: TextStyle(
                            fontSize: 11.5.sp,
                            color: isDark ? Colors.white70 : const Color(0xFF92400E),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20.h),

                // Back / Close action row
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 11.h, horizontal: 8.w),
                          side: BorderSide(
                            color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        onPressed: () {
                          Clipboard.setData(
                            const ClipboardData(text: 'PK62UNIL0109000340439603'),
                          );
                          showToast(
                            context,
                            message: 'IBAN copied to clipboard',
                            status: 'success',
                          );
                        },
                        icon: const Icon(Icons.copy_rounded, size: 15),
                        label: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('Copy IBAN'),
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B3A5C),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 11.h, horizontal: 8.w),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        onPressed: () => Navigator.of(ctx).pop(),
                        icon: const Icon(Icons.arrow_back_rounded, size: 15),
                        label: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('Back to Profile'),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBankDetailRow(BuildContext context, String label, String value, bool isDark, {bool canCopy = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 102.w,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12.5.sp,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF171C21),
              ),
            ),
          ),
          if (canCopy) ...[
            SizedBox(width: 6.w),
            InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
                showToast(context, message: '$label copied to clipboard', status: 'success');
              },
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: Icon(Icons.copy_rounded, size: 16.sp, color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1B3A5C)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 6. Transaction History Sheet (Real User Transactions or Modern Empty State)
  void _showTransactionHistorySheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, _) {
            final transactions = ref.watch(transactionHistoryProvider);

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.88,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF121212) : Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
              ),
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSheetHandle(),
                  SizedBox(height: 16.h),

                  // Header with explicit Back and Close buttons
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back_rounded,
                          color: isDark ? Colors.white : const Color(0xFF1B3A5C),
                          size: 22.sp,
                        ),
                        onPressed: () => Navigator.of(ctx).pop(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Back',
                      ),
                      SizedBox(width: 10.w),
                      Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F263E) : const Color(0xFFEDF4FC),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Icon(
                          Icons.receipt_long_rounded,
                          color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1B3A5C),
                          size: 20.sp,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Transaction History',
                              style: TextStyle(
                                fontSize: 16.5.sp,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : const Color(0xFF171C21),
                              ),
                            ),
                            Text(
                              transactions.isEmpty
                                  ? 'No transactions recorded'
                                  : '${transactions.length} verified transaction records',
                              style: TextStyle(
                                fontSize: 11.5.sp,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
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
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                  SizedBox(height: 18.h),

                  // If empty: Modern empty state!
                  if (transactions.isEmpty) ...[
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 28.h),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 68.w,
                            height: 68.w,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF18181B) : const Color(0xFFEFF6FF),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.receipt_long_outlined,
                              color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1B3A5C),
                              size: 34.sp,
                            ),
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            'No Transactions Yet',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF1E293B),
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20.w),
                            child: Text(
                              'When you pay for visa retainers, consultation sessions, or embassy submissions, verified payment receipts and tax invoices will automatically appear here.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                height: 1.4,
                              ),
                            ),
                          ),
                          SizedBox(height: 20.h),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1B3A5C),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                            onPressed: () {
                              Navigator.of(ctx).pop();
                              context.go(AppRoutes.home);
                            },
                            icon: const Icon(Icons.explore_outlined, size: 18),
                            label: const Text('Browse Visa Programs'),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Real transactions list
                    Expanded(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: transactions.length,
                        separatorBuilder: (_, __) => SizedBox(height: 10.h),
                        itemBuilder: (listCtx, index) {
                          final tx = transactions[index];
                          return _buildTransactionItemTile(context, tx, isDark);
                        },
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTransactionItemTile(BuildContext context, TransactionRecord tx, bool isDark) {
    Color statusBg;
    Color statusColor;
    IconData statusIcon;
    String statusLabel;

    if (tx.isCompleted) {
      statusBg = const Color(0xFFE6F4EA);
      statusColor = const Color(0xFF16A34A);
      statusIcon = Icons.check_circle_rounded;
      statusLabel = 'COMPLETED';
    } else if (tx.isPending) {
      statusBg = const Color(0xFFFEF3C7);
      statusColor = const Color(0xFFD97706);
      statusIcon = Icons.schedule_rounded;
      statusLabel = 'VERIFYING';
    } else {
      statusBg = const Color(0xFFFEE2E2);
      statusColor = const Color(0xFFDC2626);
      statusIcon = Icons.cancel_rounded;
      statusLabel = 'FAILED';
    }

    return InkWell(
      onTap: () => _showReceiptDetailsSheet(context, tx),
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF18181B) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38.w,
              height: 38.w,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF18181B) : statusBg,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(statusIcon, color: statusColor, size: 20.sp),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          tx.title,
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF171C21),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        tx.amount,
                        style: TextStyle(
                          fontSize: 13.5.sp,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF171C21),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 3.h),
                  Row(
                    children: [
                      Text(
                        _formatTxDate(tx.date),
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                      Text(
                        ' • ',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          tx.paymentMethod,
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Ref: ${tx.referenceId}',
                          style: TextStyle(
                            fontSize: 10.5.sp,
                            fontFamily: 'monospace',
                            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
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
    );
  }

  void _showReceiptDetailsSheet(BuildContext context, TransactionRecord tx) {
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
          padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 28.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildSheetHandle(),
              SizedBox(height: 12.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      color: isDark ? Colors.white : const Color(0xFF1B3A5C),
                      size: 22.sp,
                    ),
                    onPressed: () => Navigator.of(ctx).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Back',
                  ),
                  Text(
                    'Payment Receipt',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF171C21),
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
                    tooltip: 'Close',
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Container(
                width: 56.w,
                height: 56.w,
                decoration: BoxDecoration(
                  color: tx.isCompleted
                      ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7))
                      : (isDark ? const Color(0xFF451A03) : const Color(0xFFFEF3C7)),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  tx.isCompleted ? Icons.check_circle_rounded : Icons.schedule_rounded,
                  color: tx.isCompleted ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                  size: 32.sp,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                'Payment Receipt',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF171C21),
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                'SB Consultants Global Migration Ltd',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
              SizedBox(height: 14.h),
              Text(
                tx.amount,
                style: TextStyle(
                  fontSize: 26.sp,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF1B3A5C),
                ),
              ),
              SizedBox(height: 18.h),
              Container(
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF18181B) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  children: [
                    _buildReceiptDetailRow('Service', tx.title, isDark),
                    _buildReceiptDetailRow('Date & Time', _formatTxDate(tx.date), isDark),
                    _buildReceiptDetailRow('Payment Channel', tx.paymentMethod, isDark),
                    _buildReceiptDetailRow('Reference ID', tx.referenceId, isDark, canCopy: true, context: context),
                    if (tx.applicationRef != null && tx.applicationRef!.isNotEmpty)
                      _buildReceiptDetailRow('Application Ref', tx.applicationRef!, isDark),
                    _buildReceiptDetailRow(
                      'Status',
                      tx.isCompleted ? 'Verified & Completed' : (tx.isPending ? 'Under Verification' : 'Failed'),
                      isDark,
                      valueColor: tx.isCompleted ? const Color(0xFF16A34A) : const Color(0xFFD97706),
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
                    backgroundColor: const Color(0xFF1B3A5C),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text(
                    'Close',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReceiptDetailRow(String label, String value, bool isDark, {bool canCopy = false, BuildContext? context, Color? valueColor}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110.w,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    value,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w600,
                      color: valueColor ?? (isDark ? Colors.white : const Color(0xFF171C21)),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (canCopy && context != null) ...[
                  SizedBox(width: 6.w),
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: value));
                      showToast(context, message: '$label copied', status: 'success');
                    },
                    child: Icon(Icons.copy_rounded, size: 14.sp, color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1B3A5C)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTxDate(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final day = dt.day.toString().padLeft(2, '0');
    final month = months[dt.month - 1];
    final year = dt.year;
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$day $month $year, $hour:$minute $period';
  }



  // 8. Member Since Sheet
  void _showMemberSinceSheet(
    BuildContext context,
    String memberSinceFull,
    String memberSinceYear,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet<void>(
      context: context,
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildSheetHandle(),
              SizedBox(height: 16.h),
              Container(
                width: 52.w,
                height: 52.w,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0F263E)
                      : const Color(0xFFEDF4FC),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.military_tech_rounded,
                    color: isDark
                        ? const Color(0xFF60A5FA)
                        : const Color(0xFF1B3A5C),
                    size: 30,
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                'Member Since $memberSinceYear',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF171C21),
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                'Registered: $memberSinceFull\nVerified Premier Client\nAccess to priority legal consultation and accredited case management.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5.sp,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF5A626A),
                  height: 1.4,
                ),
              ),
              SizedBox(height: 20.h),
              SizedBox(
                width: double.infinity,
                height: 46.h,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark
                        ? const Color(0xFF3B82F6)
                        : const Color(0xFF1B3A5C),
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
        );
      },
    );
  }

  // 9. Language Selector Sheet
  void _showLanguageSelectorSheet(BuildContext context) {
    const languages = ['English'];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet<void>(
      context: context,
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
              _buildSheetHandle(),
              SizedBox(height: 14.h),
              Text(
                'Select Application Language',
                style: TextStyle(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF171C21),
                ),
              ),
              SizedBox(height: 14.h),
              for (final lang in languages) ...[
                ListTile(
                  title: Text(
                    lang,
                    style: TextStyle(
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? const Color(0xFF60A5FA)
                          : const Color(0xFF1B3A5C),
                    ),
                  ),
                  trailing: Icon(
                    Icons.check_circle_rounded,
                    color: isDark
                        ? const Color(0xFF60A5FA)
                        : const Color(0xFF1B3A5C),
                  ),
                  onTap: () {
                    setState(() => _selectedLanguage = lang);
                    Navigator.of(ctx).pop();
                    showToast(
                      context,
                      message: 'Language set to $lang',
                      status: 'info',
                    );
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // 10. Help Center Sheet
  void _showHelpCenterSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 32.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSheetHandle(),
              SizedBox(height: 14.h),
              Text(
                'Help Center & FAQs',
                style: TextStyle(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF171C21),
                ),
              ),
              SizedBox(height: 12.h),
              _buildFaqItem(
                question: 'How long does UK visa assessment take?',
                answer: 'Initial evaluation is completed within 48 hours. Embassy processing takes 3–6 weeks.',
              ),
              _buildFaqItem(
                question: 'Can I reschedule my consultant call?',
                answer: 'Yes, you can reschedule at any time via the Step 2 item in your case procedure timeline.',
              ),
              _buildFaqItem(
                question: 'What financial proof is accepted?',
                answer: 'Official bank statements showing 28-day consecutive funds holding, stamped by an accredited bank.',
              ),
              SizedBox(height: 16.h),
              SizedBox(
                width: double.infinity,
                height: 46.h,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF002444),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Close Help Center'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 11. Contact Support Sheet
  void _showContactSupportSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 32.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSheetHandle(),
              SizedBox(height: 14.h),
              Text(
                'Contact Advisory Support',
                style: TextStyle(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF171C21),
                ),
              ),
              SizedBox(height: 14.h),
              ListTile(
                leading: const Icon(Icons.phone_rounded, color: Color(0xFF002444)),
                title: const Text('Official Helpline'),
                subtitle: const Text('+92 315 5440606 (Direct Desk)'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  WhatsAppHelper.launchCall(phone: '+923155440606');
                },
              ),
              ListTile(
                leading: const Icon(Icons.mail_outline_rounded, color: Color(0xFF002444)),
                title: const Text('Client Advisory Email'),
                subtitle: const Text('sbconsultantofficial@gmail.com'),
                trailing: IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 18, color: Color(0xFF6B7280)),
                  tooltip: 'Copy Email',
                  onPressed: () {
                    Clipboard.setData(const ClipboardData(text: 'sbconsultantofficial@gmail.com'));
                    showToast(context, message: 'Email copied to clipboard', status: 'success');
                  },
                ),
                onLongPress: () {
                  Clipboard.setData(const ClipboardData(text: 'sbconsultantofficial@gmail.com'));
                  showToast(context, message: 'Email copied to clipboard', status: 'success');
                },
                onTap: () {
                  Navigator.of(ctx).pop();
                  WhatsAppHelper.launchEmail(
                    email: 'sbconsultantofficial@gmail.com',
                    subject: 'Client Advisory & Visa Support Inquiry',
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.chat_rounded, color: Color(0xFF25D366)),
                title: const Text('WhatsApp Consultant Chat'),
                subtitle: const Text('+92 315 5440606 • Instant Response'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  WhatsAppHelper.launchChat(
                    phone: '923155440606',
                    message:
                        'Hello SB Consultants, I need assistance with my profile/application.',
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // 12. Terms & Conditions Sheet
  void _showTermsSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 32.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSheetHandle(),
              SizedBox(height: 14.h),
              Text(
                'Terms & Conditions',
                style: TextStyle(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF171C21),
                ),
              ),
              SizedBox(height: 10.h),
              Text(
                'SB Consultants acts strictly in advisory and case-preparation capacities. '
                'All visa approvals and statutory timelines remain subject to the sole jurisdiction of embassy and consular visa authorities. '
                'Case retainers cover legal drafting and accredited document curation.',
                style: TextStyle(
                  fontSize: 12.5.sp,
                  color: const Color(0xFF5A626A),
                  height: 1.45,
                ),
              ),
              SizedBox(height: 20.h),
              SizedBox(
                width: double.infinity,
                height: 46.h,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF002444),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Accept & Close'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 12B. Return & Refund Policy Sheet
  void _showReturnPolicySheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF18181B) : Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 32.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSheetHandle(),
              SizedBox(height: 14.h),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFF002444).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: const Icon(
                      Icons.assignment_return_outlined,
                      color: Color(0xFF1B3A5C),
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Return & Refund Policy',
                          style: TextStyle(
                            fontSize: 16.5.sp,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF171C21),
                          ),
                        ),
                        Text(
                          '24-Hour Withdrawal & Cancellation Window',
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w500,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
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
                  color: isDark ? const Color(0xFF27272A) : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: isDark ? const Color(0xFF3F3F46) : const Color(0xFFFDE68A),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.timer_outlined, color: Color(0xFFD97706), size: 18),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        'Users can withdraw their payment or stop the process within 24 hours of payment. After 24 hours, there is no refund.',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF92400E),
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                '• 24-Hour Cancellation Privilege:\n'
                'You may withdraw your payment or cancel the visa application process within 24 hours from your transaction timestamp for a full refund.\n\n'
                '• Strict Non-Refundable Period After 24 Hours:\n'
                'After 24 hours, fees become strictly non-refundable as our legal team immediately reserves appointment slots, prepares institutional dossiers, assigns immigration caseworkers, and incurs non-recoverable embassy and administrative expenses.\n\n'
                '• Processing Your Withdrawal:\n'
                'To cancel within the eligible 24-hour period, submit a request via Contact Support or reach our official desk with your application reference number and payment deposit proof.',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: isDark ? const Color(0xFFD4D4D8) : const Color(0xFF5A626A),
                  height: 1.45,
                ),
              ),
              SizedBox(height: 20.h),
              SizedBox(
                width: double.infinity,
                height: 46.h,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF002444),
                    foregroundColor: Colors.white,
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
        );
      },
    );
  }

  // 13. Privacy Policy Sheet
  void _showPrivacyPolicySheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF18181B) : Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 32.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSheetHandle(),
              SizedBox(height: 14.h),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFF002444).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: const Icon(
                      Icons.shield_outlined,
                      color: Color(0xFF1B3A5C),
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      'Privacy Policy & Data Security',
                      style: TextStyle(
                        fontSize: 16.5.sp,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF171C21),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 14.h),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF27272A) : const Color(0xFFEDF4FC),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: isDark ? const Color(0xFF3F3F46) : const Color(0xFFBFDBFE),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 18),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        'All your info is secure, confidential, and protected.',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF1B3A5C),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                'All your personal information, passport identity, financial records, and academic documents are strictly safeguarded with comprehensive data privacy controls. '
                'SB Consultants maintains rigorous institutional confidentiality protocols to ensure your data is always safe.\n\n'
                'We never share, transfer, or disclose applicant dossiers with any unauthorized third parties without your direct written authorization.',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: isDark ? const Color(0xFFD4D4D8) : const Color(0xFF5A626A),
                  height: 1.45,
                ),
              ),
              SizedBox(height: 20.h),
              SizedBox(
                width: double.infinity,
                height: 46.h,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF002444),
                    foregroundColor: Colors.white,
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
        );
      },
    );
  }

  // 14. About Sheet
  void _showAboutSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 32.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildSheetHandle(),
              SizedBox(height: 14.h),
              Container(
                width: 54.w,
                height: 54.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(
                    color: const Color(0xFF1B3A5C).withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
                child: ClipOval(
                  child: Padding(
                    padding: EdgeInsets.all(3.w),
                    child: Image.asset(
                      AppAssets.logo,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 10.h),
              Text(
                'SB Consultants Mobile',
                style: TextStyle(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF171C21),
                ),
              ),
              Text(
                'Version 1.0.0 (Build 2026.09)',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: const Color(0xFF5A626A),
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Regulated Global Migration & Education Advisory\nAll rights reserved © 2026',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11.5.sp,
                  color: const Color(0xFF8FAEC9),
                  height: 1.4,
                ),
              ),
              SizedBox(height: 20.h),
              SizedBox(
                width: double.infinity,
                height: 46.h,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF002444),
                    foregroundColor: Colors.white,
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
        );
      },
    );
  }

  // 15. Log Out Confirmation Dialog
  void _showLogoutConfirmDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          title: Row(
            children: [
              Container(
                width: 36.w,
                height: 36.w,
                decoration: BoxDecoration(
                  color: const Color(0xFFBA1A1A).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: Color(0xFFBA1A1A),
                  size: 20,
                ),
              ),
              SizedBox(width: 10.w),
              Text(
                'Log Out',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF171C21),
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to log out of SB Consultants? You will need to sign in again to access and track your applications.',
            style: TextStyle(
              fontSize: 13.sp,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF5A626A),
              height: 1.4,
            ),
          ),
          actionsPadding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF5A626A),
                  fontSize: 13.5.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFBA1A1A),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
              onPressed: () async {
                Navigator.of(dialogCtx).pop();
                await ref.read(sessionProvider.notifier).logout();
                if (!context.mounted) return;
                context.go(AppRoutes.login);
                showToast(
                  context,
                  message: 'Successfully logged out',
                  status: 'info',
                );
              },
              child: Text(
                'Log Out',
                style: TextStyle(
                  fontSize: 13.5.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ===========================================================================
  // HELPER WIDGETS
  // ===========================================================================
  Widget _buildSheetHandle() {
    return Center(
      child: Container(
        width: 40.w,
        height: 4.h,
        decoration: BoxDecoration(
          color: const Color(0xFFCBD5E1),
          borderRadius: BorderRadius.circular(2.r),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    bool isDark = false,
  }) {
    final textColor = isDark ? Colors.white : const Color(0xFF171C21);
    final inputBg = isDark ? const Color(0xFF18181B) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        SizedBox(height: 6.h),
        TextField(
          controller: controller,
          style: TextStyle(fontSize: 13.5.sp, color: textColor),
          decoration: InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            filled: true,
            fillColor: inputBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF002444),
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isDark = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5.sp,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF5A626A),
            ),
          ),
          SizedBox(width: 12.w),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF171C21),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildFaqItem({required String question, required String answer}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF171C21),
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            answer,
            style: TextStyle(
              fontSize: 12.sp,
              color: const Color(0xFF5A626A),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarContent(String? profilePicPath, String displayName) {
    if (profilePicPath != null && profilePicPath.isNotEmpty) {
      if (profilePicPath.startsWith('http://') || profilePicPath.startsWith('https://')) {
        return CachedNetworkImage(
          imageUrl: profilePicPath,
          fit: BoxFit.cover,
          width: 82.w,
          height: 82.w,
          placeholder: (context, url) => const ColoredBox(
            color: Color(0xFF0F263E),
            child: Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
            ),
          ),
          errorWidget: (context, url, error) => _buildInitialsAvatar(displayName),
        );
      } else {
        final file = File(profilePicPath);
        if (file.existsSync()) {
          return Image.file(
            file,
            fit: BoxFit.cover,
            width: 82.w,
            height: 82.w,
            errorBuilder: (context, error, stackTrace) => _buildInitialsAvatar(displayName),
          );
        }
      }
    }
    return _buildInitialsAvatar(displayName);
  }

  Widget _buildInitialsAvatar(String displayName) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xFF0F263E),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          _getUserInitials(displayName),
          style: TextStyle(
            fontSize: 26.sp,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  String _getUserInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0].substring(0, 1).toUpperCase();
    }
    return 'ZA';
  }
}
