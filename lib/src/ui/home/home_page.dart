import 'package:flutter_sd_consultant/src/data/models/country_model.dart';
import 'package:flutter_sd_consultant/src/data/models/success_story_model.dart';
import 'package:flutter_sd_consultant/src/data/models/visa_category_model.dart';
import 'package:flutter_sd_consultant/src/data/models/visa_listing_model.dart';
import 'package:flutter_sd_consultant/src/data/repositories/detail_repository.dart';
import 'package:flutter_sd_consultant/src/imports/core_imports.dart';
import 'package:flutter_sd_consultant/src/imports/packages_imports.dart';
import 'package:flutter_sd_consultant/src/shared/widgets/app_dashboard_bottom_nav.dart';
import 'package:flutter_sd_consultant/src/ui/auth/providers/session_provider.dart';
import 'package:flutter_sd_consultant/src/ui/home/providers/home_provider.dart';
import 'package:flutter_sd_consultant/src/ui/home/widgets/banner_carousel.dart';
import 'package:flutter_sd_consultant/src/ui/home/widgets/country_tabs_section.dart';
import 'package:flutter_sd_consultant/src/ui/home/widgets/home_header.dart';
import 'package:flutter_sd_consultant/src/ui/home/widgets/home_skeletons.dart';
import 'package:flutter_sd_consultant/src/ui/home/widgets/success_stories_section.dart';
import 'package:flutter_sd_consultant/src/ui/home/widgets/visa_card_item.dart';
import 'package:flutter_sd_consultant/src/ui/home/widgets/visa_category_grid.dart';
import 'package:flutter_sd_consultant/src/ui/notifications/providers/notifications_provider.dart';
import 'package:flutter_sd_consultant/src/ui/profile/providers/profile_picture_provider.dart';


class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = context.colors;
    final tt = context.textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final session = ref.watch(sessionProvider);
    final userName = session.userOrNull?.name ??
        session.userOrNull?.email.split('@').first ??
        'Traveler';

    final RequestState<List<VisaCategoryModel>> categoriesState =
        ref.watch(visaCategoriesProvider);
    final RequestState<List<Map<String, String>>> bannersState =
        ref.watch(bannerPromotionsProvider);
    final AsyncValue<List<Map<String, String>>> liveBannersAsync =
        ref.watch(liveTargetedBannersStreamProvider('all'));
    const advertisePlaceholderBanner = {
      'id': 'advertise-with-us',
      'title': 'Advertise With Us',
      'subtitle': 'Feature your university programs, sponsored jobs, or immigration services here',
      'badge': 'SPONSORSHIP SPOTLIGHT',
      'actionText': 'Contact Us to Feature',
      'actionUrl': '/support',
      'imageUrl': 'assets/images/feature_banner_1.jpg',
      'gradientStart': '0xFF002444',
      'gradientEnd': '0xFF1B3A5C',
      'placement': 'all',
      'categoryName': 'Advertise',
      'displayOrder': '1',
    };

    final List<Map<String, String>> displayBanners = (liveBannersAsync.hasValue && liveBannersAsync.value!.isNotEmpty)
        ? liveBannersAsync.value!
        : (bannersState is RequestSuccess<List<Map<String, String>>> && bannersState.data.isNotEmpty
            ? bannersState.data
            : const [advertisePlaceholderBanner]);
    final RequestState<List<SuccessStoryModel>> successStoriesState =
        ref.watch(successStoriesProvider);
    final AsyncValue<List<SuccessStoryModel>> liveStoriesAsync =
        ref.watch(liveSuccessStoriesStreamProvider);
    final List<SuccessStoryModel> displayStories = (liveStoriesAsync.hasValue && liveStoriesAsync.value!.isNotEmpty)
        ? liveStoriesAsync.value!
        : (successStoriesState is RequestSuccess<List<SuccessStoryModel>>
            ? successStoriesState.data
            : const []);
    final RequestState<List<CountryModel>> countriesState =
        ref.watch(countriesProvider);
    final String selectedCountryId = ref.watch(selectedCountryIdProvider);
    final String? selectedCategoryId = ref.watch(selectedCategoryIdProvider);
    final AsyncValue<List<VisaListingModel>> visaListingsAsync =
        ref.watch(homeVisaListingsProvider);
    final activeSpecial = ref.watch(homeSpecialFilterProvider);
    final activeSearch = ref.watch(homeSearchQueryProvider);
    final hasActiveFilter = selectedCategoryId != null ||
        activeSearch.isNotEmpty ||
        activeSpecial != null ||
        selectedCountryId != kAllCountriesId;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      bottomNavigationBar: const AppDashboardBottomNav(currentIndex: 0),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(homeVisaListingsProvider);
          ref.invalidate(liveSuccessStoriesStreamProvider);
          ref.invalidate(liveTargetedBannersStreamProvider);
          await Future.wait([
            ref.read(visaCategoriesProvider.notifier).load(),
            ref.read(bannerPromotionsProvider.notifier).load(),
            ref.read(successStoriesProvider.notifier).load(),
            ref.read(countriesProvider.notifier).load(),
          ]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Navy Blue Header with User Avatar, Notification, and Search Bar
              HomeHeader(
                userName: userName,
                avatarUrl: ref.watch(profilePictureProvider) ?? session.userOrNull?.photoUrl,
                unreadCount: ref.watch(unreadNotificationsCountProvider),
                onSearchChanged: (query) {
                  ref.read(homeSearchQueryProvider.notifier).state = query;
                },
                onNotificationTap: () {
                  context.push(AppRoutes.notifications);
                },
                onFilterTap: () {
                  _showFilterBottomSheet(context, ref);
                },
              ),
              SizedBox(height: AppSpacing.lg),

              // 2. Visa Category Circular Grid (4 on top, 3 below)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Text(
                  'Visa Categories',
                  style: tt.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.sm),
              switch (categoriesState) {
                RequestInitial() ||
                RequestLoading() =>
                  const HomeCategoriesSkeleton(),
                RequestFailure(:final failure) => Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                    child: AppErrorWidget(
                      title: 'Could not load categories',
                      message: failure.message,
                      onRetry: () =>
                          ref.read(visaCategoriesProvider.notifier).load(),
                    ),
                  ),
                RequestSuccess(:final data) => VisaCategoryGrid(
                    categories: data,
                    selectedCategoryId: selectedCategoryId,
                    onCategoryTap: (category) {
                      switch (category.id) {
                        case 'scholarships':
                          context.push(AppRoutes.scholarships);
                          break;
                        case 'sponsored_jobs':
                          context.push(AppRoutes.sponsoredJobs);
                          break;
                        case 'visit':
                          context.push(AppRoutes.visitVisa);
                          break;
                        case 'business':
                          context.push(AppRoutes.businessVisa);
                          break;
                        case 'golden':
                          context.push(AppRoutes.goldenVisa);
                          break;
                        case 'study':
                          context.push(AppRoutes.studyVisa);
                          break;
                        case 'work':
                          context.push(AppRoutes.workVisa);
                          break;
                        default:
                          context.push(AppRoutes.visitVisa);
                          break;
                      }
                    },
                  ),
              },
              SizedBox(height: AppSpacing.xl),

              // 3. Image Carousel / Banner Slider (Live synced with Admin Dashboard)
              if (displayBanners.isNotEmpty)
                BannerCarousel(
                  banners: displayBanners,
                  onBannerTap: (index) {
                    final banner = displayBanners[index];
                    final actionUrl = (banner['actionUrl'] ?? banner['action_url'] ?? '').trim();
                    if (actionUrl.isNotEmpty) {
                      if (actionUrl.startsWith('http://') || actionUrl.startsWith('https://')) {
                        final uri = Uri.tryParse(actionUrl);
                        if (uri != null) {
                          launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                        return;
                      }
                      if (actionUrl == '/support' || actionUrl == 'support' || actionUrl == 'contact') {
                        final uri = Uri.parse('https://wa.me/923155440606?text=Hello%20SB%20Consultants,%20I%20would%20like%20to%20advertise%20on%20your%20app');
                        launchUrl(uri, mode: LaunchMode.externalApplication);
                        return;
                      }
                      final target = switch (actionUrl) {
                        '/study' || 'study' => AppRoutes.studyVisa,
                        '/work' || 'work' => AppRoutes.workVisa,
                        '/visit' || 'visit' => AppRoutes.visitVisa,
                        '/business' || 'business' => AppRoutes.businessVisa,
                        '/golden' || 'golden' => AppRoutes.goldenVisa,
                        '/jobs' || 'jobs' => AppRoutes.sponsoredJobs,
                        '/scholarships' || 'scholarships' => AppRoutes.scholarships,
                        '/visas' || 'visas' => AppRoutes.home,
                        _ => actionUrl,
                      };
                      if (target.startsWith('/')) {
                        context.push(target);
                        return;
                      }
                      context.push('/visa-detail/$target');
                      return;
                    }
                    context.push(AppRoutes.home);
                  },
                )
              else if (bannersState is RequestLoading)
                const HomeBannerSkeleton(),
              SizedBox(height: AppSpacing.xl),

              // 4. Verified Client Success Stories (Directly after Banner with live realtime updates)
              if (displayStories.isNotEmpty) ...[
                Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.xl),
                  child: SuccessStoriesSection(stories: displayStories),
                ),
              ],

              // 5. Country Tabs Section (All, Dubai, Australia, etc.)
              switch (countriesState) {
                RequestInitial() ||
                RequestLoading() =>
                  const HomeCountriesSkeleton(),
                RequestFailure() => const SizedBox.shrink(),
                RequestSuccess(:final data) => CountryTabsSection(
                    countries: data,
                    selectedCountryId: selectedCountryId,
                    onCountrySelected: (countryId) {
                      ref.read(selectedCountryIdProvider.notifier).state =
                          countryId;
                    },
                    onViewMore: () {
                      showToast(
                        context,
                        message: 'Showing all 15+ destination countries',
                        status: 'info',
                      );
                    },
                  ),
              },
              SizedBox(height: AppSpacing.ms),

              // Active filter indicator if category, country, special filter, or search is active
              if (hasActiveFilter) ...[
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF18181B) : const Color(0xFFEDF2F8),
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                        color: isDark ? const Color(0xFF27272A) : const Color(0xFFD2E0F0),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.filter_list_rounded,
                          size: 16.sp,
                          color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF002444),
                        ),
                        SizedBox(width: 6.w),
                        Expanded(
                          child: Text(
                            activeSpecial != null
                                ? 'Filter: ${activeSpecial == 'fast_track' ? 'Fast-Track Visas' : activeSpecial == 'top_rated' ? 'Top-Rated (4.8+)' : 'Free Consultation'}'
                                : (selectedCountryId != kAllCountriesId
                                    ? 'Country: $selectedCountryId'
                                    : (selectedCategoryId != null
                                        ? 'Category: $selectedCategoryId'
                                        : 'Search: "$activeSearch"')),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: tt.bodySmall?.copyWith(
                              color: isDark ? Colors.white : const Color(0xFF002444),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            ref.read(selectedCountryIdProvider.notifier).state = kAllCountriesId;
                            ref.read(selectedCategoryIdProvider.notifier).state = null;
                            ref.read(homeSpecialFilterProvider.notifier).state = null;
                            ref.read(homeSearchQueryProvider.notifier).state = '';
                            showToast(context, message: 'All filters reset');
                          },
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Reset',
                                  style: tt.bodySmall?.copyWith(
                                    color: cs.error,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: 2.w),
                                Icon(Icons.close_rounded, size: 14.sp, color: cs.error),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.sm),
              ],

              // 5. Visa Cards List (filtered by selected country & category)
              visaListingsAsync.when(
                loading: () => const HomeVisaListSkeleton(),
                error: (error, _) => Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: AppErrorWidget(
                    title: 'Failed to load visas',
                    message: '$error',
                    onRetry: () => ref.invalidate(liveVisaListingsStreamProvider),
                  ),
                ),
                data: (listings) {
                  if (listings.isEmpty) {
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                      child: AppEmptyState(
                        icon: Icons.search_off_rounded,
                        title: 'No visas found matching your filter',
                        subtitle: 'Try selecting "All" or a different category',
                        actionLabel: 'Show All Visas',
                        onAction: () {
                          ref
                              .read(selectedCountryIdProvider.notifier)
                              .state = kAllCountriesId;
                          ref
                              .read(selectedCategoryIdProvider.notifier)
                              .state = null;
                          ref.read(homeSearchQueryProvider.notifier).state = '';
                        },
                      ),
                    );
                  }

                  // Production Home listings logic per requirements:
                  // 1. Exactly one Study Visa remains as the temporary existing item
                  // Only real database-driven visas from Supabase / admin-created records
                  final homeVisas = List<VisaListingModel>.from(listings);

                  if (homeVisas.isEmpty) {
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.lg),
                      child: Center(
                        child: Text(
                          'No visa listings available at the moment.',
                          style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.only(bottom: AppSpacing.xl),
                    itemCount: homeVisas.length,
                    itemBuilder: (context, index) {
                      final visa = homeVisas[index];
                      return VisaCardItem(
                        visa: visa,
                        onTap: () {
                          final detailItem =
                              DetailRepository.getDetailForVisa(visa);
                          context.push(AppRoutes.visaDetail, extra: detailItem);
                        },
                        onApplyTap: () {
                          final detailItem =
                              DetailRepository.getDetailForVisa(visa);
                          context.push(
                            AppRoutes.applicantDetails,
                            extra: detailItem,
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context, WidgetRef ref) {
    final cs = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentFilter = ref.read(homeSpecialFilterProvider);
    final titleColor = isDark ? Colors.white : const Color(0xFF002444);
    final itemTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final sheetBg = isDark ? const Color(0xFF121212) : Colors.white;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: sheetBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filter Visa Options',
                      style: TextStyle(
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w700,
                        color: titleColor,
                      ),
                    ),
                    if (currentFilter != null)
                      TextButton(
                        onPressed: () {
                          ref.read(homeSpecialFilterProvider.notifier).state = null;
                          Navigator.pop(context);
                          showToast(context, message: 'Showing all visa options');
                        },
                        child: Text(
                          'Clear Filter',
                          style: TextStyle(
                            color: const Color(0xFFEF4444),
                            fontWeight: FontWeight.w700,
                            fontSize: 13.sp,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 12.h),
                ListTile(
                  leading: Container(
                    padding: EdgeInsets.all(6.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: const Icon(Icons.speed_rounded, color: Color(0xFF2563EB)),
                  ),
                  title: Text(
                    'Fast-Track Visas Only',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: itemTextColor,
                    ),
                  ),
                  trailing: currentFilter == 'fast_track'
                      ? const Icon(Icons.check_circle_rounded, color: Color(0xFF2563EB))
                      : null,
                  onTap: () {
                    ref.read(homeSpecialFilterProvider.notifier).state = 'fast_track';
                    Navigator.pop(context);
                    showToast(context, message: 'Showing fast-track visas');
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: EdgeInsets.all(6.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: const Icon(Icons.star_rounded, color: Color(0xFFF59E0B)),
                  ),
                  title: Text(
                    'Top Rated Consultations (4.8+)',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: itemTextColor,
                    ),
                  ),
                  trailing: currentFilter == 'top_rated'
                      ? const Icon(Icons.check_circle_rounded, color: Color(0xFFF59E0B))
                      : null,
                  onTap: () {
                    ref.read(homeSpecialFilterProvider.notifier).state = 'top_rated';
                    Navigator.pop(context);
                    showToast(context, message: 'Showing top rated visas');
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: EdgeInsets.all(6.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: const Icon(Icons.attach_money_rounded, color: Color(0xFF10B981)),
                  ),
                  title: Text(
                    'Free Consultation Offers',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: itemTextColor,
                    ),
                  ),
                  trailing: currentFilter == 'free_consultation'
                      ? const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981))
                      : null,
                  onTap: () {
                    ref.read(homeSpecialFilterProvider.notifier).state = 'free_consultation';
                    Navigator.pop(context);
                    showToast(context, message: 'Showing free consultation visas');
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: EdgeInsets.all(6.w),
                    decoration: BoxDecoration(
                      color: cs.outline.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(Icons.restart_alt_rounded, color: cs.outline),
                  ),
                  title: Text(
                    'All Visas (Reset Filter)',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: itemTextColor,
                    ),
                  ),
                  onTap: () {
                    ref.read(homeSpecialFilterProvider.notifier).state = null;
                    Navigator.pop(context);
                    showToast(context, message: 'Reset to all visas');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
