import 'package:flutter_sd_consultant/src/data/models/country_model.dart';
import 'package:flutter_sd_consultant/src/data/models/success_story_model.dart';
import 'package:flutter_sd_consultant/src/data/models/visa_category_model.dart';
import 'package:flutter_sd_consultant/src/data/models/visa_listing_model.dart';
import 'package:flutter_sd_consultant/src/data/repositories/home_repository.dart';
import 'package:flutter_sd_consultant/src/data/repositories/home_repository_impl.dart';
import 'package:flutter_sd_consultant/src/imports/core_imports.dart';
import 'package:flutter_sd_consultant/src/imports/packages_imports.dart';
import 'package:flutter_sd_consultant/src/services/supabase_database_service.dart';

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return HomeRepositoryImpl();
});

/// Visa categories (Study, Work, Visit, Immigration, etc.)
final visaCategoriesProvider = StateNotifierProvider<VisaCategoriesNotifier,
    RequestState<List<VisaCategoryModel>>>((ref) {
  return VisaCategoriesNotifier(ref.read(homeRepositoryProvider))..load();
});

class VisaCategoriesNotifier
    extends StateNotifier<RequestState<List<VisaCategoryModel>>> {
  VisaCategoriesNotifier(this._repo) : super(const RequestInitial());
  final HomeRepository _repo;

  Future<void> load() async {
    state = const RequestLoading();
    final result = await _repo.getVisaCategories();
    result.fold(
      (failure) => state = RequestFailure(failure),
      (data) => state = RequestSuccess(data),
    );
  }
}

/// Promotional banners carousel
final bannerPromotionsProvider = StateNotifierProvider<BannerPromotionsNotifier,
    RequestState<List<Map<String, String>>>>((ref) {
  return BannerPromotionsNotifier(ref.read(homeRepositoryProvider))..load();
});

class BannerPromotionsNotifier
    extends StateNotifier<RequestState<List<Map<String, String>>>> {
  BannerPromotionsNotifier(this._repo) : super(const RequestInitial());
  final HomeRepository _repo;

  Future<void> load() async {
    state = const RequestLoading();
    final result = await _repo.getPromotionalBanners();
    result.fold(
      (failure) => state = RequestFailure(failure),
      (data) => state = RequestSuccess(data),
    );
  }
}

/// Verified client success stories
final successStoriesProvider = StateNotifierProvider<SuccessStoriesNotifier,
    RequestState<List<SuccessStoryModel>>>((ref) {
  return SuccessStoriesNotifier(ref.read(homeRepositoryProvider))..load();
});

class SuccessStoriesNotifier
    extends StateNotifier<RequestState<List<SuccessStoryModel>>> {
  SuccessStoriesNotifier(this._repo) : super(const RequestInitial());
  final HomeRepository _repo;

  Future<void> load() async {
    state = const RequestLoading();
    final result = await _repo.getSuccessStories();
    result.fold(
      (failure) => state = RequestFailure(failure),
      (data) => state = RequestSuccess(data),
    );
  }
}

/// Horizontal countries list (All, Dubai, Australia, Canada, etc.)
final countriesProvider =
    StateNotifierProvider<CountriesNotifier, RequestState<List<CountryModel>>>(
        (ref) {
  return CountriesNotifier(ref.read(homeRepositoryProvider))..load();
});

class CountriesNotifier
    extends StateNotifier<RequestState<List<CountryModel>>> {
  CountriesNotifier(this._repo) : super(const RequestInitial());
  final HomeRepository _repo;

  Future<void> load() async {
    state = const RequestLoading();
    final result = await _repo.getCountries();
    result.fold(
      (failure) => state = RequestFailure(failure),
      (data) => state = RequestSuccess(data),
    );
  }
}

/// Active selected country tab (defaults to "all")
final selectedCountryIdProvider =
    StateProvider<String>((ref) => kAllCountriesId);

/// Active selected category filter (null means all categories)
final selectedCategoryIdProvider = StateProvider<String?>((ref) => null);

/// Search query typed in the search bar
final homeSearchQueryProvider = StateProvider<String>((ref) => '');

/// Active bottom navigation tab index (0 = Home, 1 = Appointments, 2 = Chat, 3 = Profile)
final homeBottomNavIndexProvider = StateProvider<int>((ref) => 0);

/// Local storage keys helper for persistent user-scoped directory unlocks
String kPrefKeySponsoredJobsUnlockedFor(String userId) =>
    'sb_unlocked_sponsored_jobs_$userId';
String kPrefKeyScholarshipsUnlockedFor(String userId) =>
    'sb_unlocked_scholarships_$userId';

/// Legacy keys to clean up
const String kPrefKeySponsoredJobsUnlocked = 'sb_unlocked_sponsored_jobs';
const String kPrefKeyScholarshipsUnlocked = 'sb_unlocked_scholarships';

/// Whether the current user has paid & unlocked the Verified Sponsored Jobs directory.
/// Strictly defaults to false until authenticated Supabase confirmation.
final isSponsoredJobsUnlockedProvider = StateProvider<bool>((ref) {
  try {
    final user = SupabaseDatabaseService.instance.client.auth.currentUser;
    if (user == null) return false;
    return StorageService.instance.getBool(kPrefKeySponsoredJobsUnlockedFor(user.id)) ?? false;
  } catch (_) {
    return false;
  }
});

/// Whether the current user has paid & unlocked the International Scholarships directory.
/// Strictly defaults to false until authenticated Supabase confirmation.
final isScholarshipsUnlockedProvider = StateProvider<bool>((ref) {
  try {
    final user = SupabaseDatabaseService.instance.client.auth.currentUser;
    if (user == null) return false;
    return StorageService.instance.getBool(kPrefKeyScholarshipsUnlockedFor(user.id)) ?? false;
  } catch (_) {
    return false;
  }
});

/// Pending payment details for directories while awaiting admin verification
final pendingDirectoryPaymentsProvider =
    StateProvider<Map<String, Map<String, dynamic>?>>((ref) {
  return {
    'scholarships': null,
    'sponsored_jobs': null,
  };
});

/// Synchronizes directory unlock state from Supabase & user-scoped local storage
Future<void> syncDirectoryUnlocks(dynamic ref) async {
  try {
    // Clean up any stale un-scoped keys from previous sessions
    try {
      StorageService.instance.remove(kPrefKeySponsoredJobsUnlocked);
      StorageService.instance.remove(kPrefKeyScholarshipsUnlocked);
    } catch (_) {}

    final user = SupabaseDatabaseService.instance.client.auth.currentUser;
    if (user == null) {
      // Unauthenticated users are ALWAYS locked
      ref.read(isSponsoredJobsUnlockedProvider.notifier).state = false;
      ref.read(isScholarshipsUnlockedProvider.notifier).state = false;
      ref.read(pendingDirectoryPaymentsProvider.notifier).state = {
        'scholarships': null,
        'sponsored_jobs': null,
      };
      return;
    }

    // 1. Fetch live unlocks from Supabase for this logged-in user (source of truth)
    final res = await SupabaseDatabaseService.instance.fetchUserDirectoryUnlocks(user.id);
    var hasJobs = false;
    var hasSch = false;

    res.fold(
      (_) {
        // If Supabase fetch fails or table has no entry, ensure locked state
        ref.read(isSponsoredJobsUnlockedProvider.notifier).state = false;
        ref.read(isScholarshipsUnlockedProvider.notifier).state = false;
        StorageService.instance.setBool(kPrefKeySponsoredJobsUnlockedFor(user.id), false);
        StorageService.instance.setBool(kPrefKeyScholarshipsUnlockedFor(user.id), false);
      },
      (unlocks) {
        hasJobs = unlocks.contains('sponsored_jobs');
        hasSch = unlocks.contains('scholarships');
        ref.read(isSponsoredJobsUnlockedProvider.notifier).state = hasJobs;
        ref.read(isScholarshipsUnlockedProvider.notifier).state = hasSch;
        StorageService.instance.setBool(kPrefKeySponsoredJobsUnlockedFor(user.id), hasJobs);
        StorageService.instance.setBool(kPrefKeyScholarshipsUnlockedFor(user.id), hasSch);
      },
    );

    // 3. Fetch pending/under-verification directory payments directly from payments table
    Map<String, dynamic>? pendingSch;
    Map<String, dynamic>? pendingJobs;

    try {
      final pendingRows = await SupabaseDatabaseService.instance.client
          .from('payments')
          .select('id, listing_id, reference_id, amount, status, created_at, gateway_response')
          .eq('user_id', user.id)
          .inFilter('status', ['pending', 'under_verification', 'under_review'])
          .order('created_at', ascending: false);

      for (final p in (pendingRows as List)) {
        final map = Map<String, dynamic>.from(p as Map);
        final lId = (map['listing_id']?.toString() ?? '').toLowerCase();
        final rId = (map['reference_id']?.toString() ?? '').toLowerCase();

        // Target scholarships directory unlock specifically
        final isRowSch = lId.contains('unlock-scholarships') ||
            lId.contains('scholarships-pass') ||
            (lId.contains('scholarship') && !lId.contains('job')) ||
            rId.contains('unlock_scholarships') ||
            rId.contains('scholarship-pass');

        // Target sponsored jobs directory unlock specifically
        final isRowJob = !isRowSch && (
            lId.contains('unlock-jobs') ||
            lId.contains('jobs-pass') ||
            (lId.contains('job') && !lId.contains('scholarship')) ||
            rId.contains('unlock_jobs') ||
            rId.contains('job-pass') ||
            (lId.contains('job') && (lId.contains('unlock') || lId.contains('pass'))) ||
            (rId.contains('job') && (rId.contains('unlock') || rId.contains('pass')))
        );

        if (pendingSch == null && isRowSch && !hasSch) {
          pendingSch = map;
        }
        if (pendingJobs == null && isRowJob && !hasJobs) {
          pendingJobs = map;
        }
      }
    } catch (_) {}

    // If unlocked, clear pending state
    if (hasSch) pendingSch = null;
    if (hasJobs) pendingJobs = null;

    ref.read(pendingDirectoryPaymentsProvider.notifier).state = {
      'scholarships': pendingSch,
      'sponsored_jobs': pendingJobs,
    };
  } catch (_) {}
}

/// Resets directory unlock paywall for testing purposes
Future<void> resetDirectoryPaywallForTesting(dynamic ref) async {
  try {
    final user = SupabaseDatabaseService.instance.client.auth.currentUser;
    if (user != null) {
      try {
        StorageService.instance.remove(kPrefKeySponsoredJobsUnlockedFor(user.id));
        StorageService.instance.remove(kPrefKeyScholarshipsUnlockedFor(user.id));
        StorageService.instance.setBool(kPrefKeySponsoredJobsUnlockedFor(user.id), false);
        StorageService.instance.setBool(kPrefKeyScholarshipsUnlockedFor(user.id), false);
      } catch (_) {}

      try {
        await SupabaseDatabaseService.instance.client
            .from('user_directory_unlocks')
            .update({'is_active': false})
            .eq('user_id', user.id);
      } catch (_) {}
    }

    ref.read(isSponsoredJobsUnlockedProvider.notifier).state = false;
    ref.read(isScholarshipsUnlockedProvider.notifier).state = false;
    ref.read(pendingDirectoryPaymentsProvider.notifier).state = {
      'scholarships': null,
      'sponsored_jobs': null,
    };
  } catch (_) {}
}

/// Helper to persist directory unlock when user pays (one-time lifetime access)
Future<void> persistDirectoryUnlock(
  dynamic ref, {
  required String directoryType,
  String? paymentId,
}) async {
  try {
    final cleanType = directoryType.contains('scholarship')
        ? 'scholarships'
        : 'sponsored_jobs';

    final user = SupabaseDatabaseService.instance.client.auth.currentUser;
    if (cleanType == 'sponsored_jobs') {
      ref.read(isSponsoredJobsUnlockedProvider.notifier).state = true;
      if (user != null) {
        await StorageService.instance.setBool(kPrefKeySponsoredJobsUnlockedFor(user.id), true);
      }
    } else {
      ref.read(isScholarshipsUnlockedProvider.notifier).state = true;
      if (user != null) {
        await StorageService.instance.setBool(kPrefKeyScholarshipsUnlockedFor(user.id), true);
      }
    }

    if (user != null) {
      await SupabaseDatabaseService.instance.unlockDirectory(
        userId: user.id,
        directoryType: cleanType,
        paymentId: paymentId,
      );
    }
  } catch (_) {}
}

/// Live real-time stream of all active visa listings directly from Supabase
final liveVisaListingsStreamProvider =
    StreamProvider<List<VisaListingModel>>((ref) {
  try {
    return SupabaseDatabaseService.instance.client
        .from('visa_listings')
        .stream(primaryKey: ['id'])
        .handleError((_) => <Map<String, dynamic>>[])
        .map((rows) {
          final activeRows = rows
              .where((r) => r['is_active'] as bool? ?? true)
              .map((r) => VisaListingModel.fromJson(r))
              .toList();
          return activeRows;
        });
  } catch (_) {
    return const Stream.empty();
  }
});

/// Live real-time stream of published client success stories directly from Supabase
final liveSuccessStoriesStreamProvider =
    StreamProvider<List<SuccessStoryModel>>((ref) {
  try {
    return SupabaseDatabaseService.instance.client
        .from('success_stories')
        .stream(primaryKey: ['id'])
        .order('display_order', ascending: true)
        .handleError((_) => <Map<String, dynamic>>[])
        .map((rows) {
          final published = rows
              .where((r) => r['is_published'] as bool? ?? true)
              .map((r) => SuccessStoryModel.fromJson(r))
              .toList();
          return published;
        });
  } catch (_) {
    return const Stream.empty();
  }
});

/// Live real-time stream of category-targeted promotional banners directly from Supabase
/// Filter placement: 'all', 'visas', 'jobs', 'scholarships', 'study', 'work', 'visit', 'business', 'golden'
final liveTargetedBannersStreamProvider =
    StreamProvider.family<List<Map<String, String>>, String>((ref, placement) {
  try {
    return SupabaseDatabaseService.instance.client
        .from('promotional_banners')
        .stream(primaryKey: ['id'])
        .order('display_order', ascending: true)
        .handleError((_) => <Map<String, dynamic>>[])
        .map((rows) {
          final pFilter = placement.toLowerCase();
          final isVisaCategory = ['visit', 'study', 'work', 'business', 'golden', 'visas'].contains(pFilter);

          final sortedRows = List<Map<String, dynamic>>.from(rows);
          sortedRows.sort((a, b) {
            final rawA = a['display_order'];
            final rawB = b['display_order'];
            final orderA = rawA is num
                ? rawA.toInt()
                : (rawA != null ? int.tryParse(rawA.toString().trim()) ?? 999 : 999);
            final orderB = rawB is num
                ? rawB.toInt()
                : (rawB != null ? int.tryParse(rawB.toString().trim()) ?? 999 : 999);
            if (orderA != orderB) {
              return orderA.compareTo(orderB);
            }
            final aDate = a['created_at']?.toString() ?? '';
            final bDate = b['created_at']?.toString() ?? '';
            return bDate.compareTo(aDate);
          });

          return sortedRows.where((r) {
            final isActive = r['is_active'] as bool? ?? true;
            if (!isActive) return false;
            final rawPlacement = r['placement']?.toString().trim();
            final itemPlacement = (rawPlacement != null && rawPlacement.isNotEmpty
                    ? rawPlacement
                    : 'all')
                .toLowerCase();
            
            // Global banners show on all pages (Home, Visas, Jobs, etc.)
            if (itemPlacement == 'all' || itemPlacement == 'global') return true;

            if (pFilter == 'all') {
              return false;
            }
            
            if (isVisaCategory) {
              return itemPlacement == pFilter || itemPlacement == 'visas';
            }
            return itemPlacement == pFilter;
          }).map((json) {
            return {
              'id': json['id']?.toString() ?? '',
              'title': json['title']?.toString() ?? '',
              'subtitle': json['subtitle']?.toString() ?? '',
              'badge': json['badge']?.toString() ?? '',
              'actionText': json['action_text']?.toString() ?? 'Apply Now',
              'actionUrl': json['action_url']?.toString() ?? '',
              'gradientStart': json['gradient_start']?.toString() ?? '0xFF1B3A5C',
              'gradientEnd': json['gradient_end']?.toString() ?? '0xFF2A5A8C',
              'placement': json['placement']?.toString() ?? 'all',
              'categoryName': json['category_name']?.toString() ?? 'All Pages',
              'imageUrl': json['image_url']?.toString() ?? '',
              'displayOrder': json['display_order']?.toString() ?? '1',
            };
          }).toList();
        });
  } catch (_) {
    return const Stream.empty();
  }
});

/// Special filter from bottom sheet (null = none, 'fast_track', 'top_rated', 'free_consultation')
final homeSpecialFilterProvider = StateProvider<String?>((ref) => null);

/// Visa listings automatically reacting to:
/// 1. Supabase Realtime live stream (millisecond updates on add/edit/delete)
/// 2. selected country (flexible country name / code matching)
/// 3. selected category
/// 4. special bottom sheet filter (fast-track, top-rated, free consultation)
/// 5. search query
final homeVisaListingsProvider =
    Provider<AsyncValue<List<VisaListingModel>>>((ref) {
  final streamAsync = ref.watch(liveVisaListingsStreamProvider);
  final countryId = ref.watch(selectedCountryIdProvider);
  final categoryId = ref.watch(selectedCategoryIdProvider);
  final specialFilter = ref.watch(homeSpecialFilterProvider);
  final searchQuery = ref.watch(homeSearchQueryProvider).trim().toLowerCase();

  return streamAsync.whenData((allVisas) {
    var list = allVisas;

    // Homepage showcase filter: Only display featured/carousel visas on the homepage
    list = list.where((v) => v.isFeatured).toList();

    // 1. Country filter
    if (countryId.isNotEmpty && countryId != kAllCountriesId) {
      final cid = countryId.toLowerCase();
      list = list.where((v) {
        final vCid = v.countryId.toLowerCase();
        final vCname = v.countryName.toLowerCase();
        if (vCid == cid || vCname.contains(cid) || cid.contains(vCid)) return true;
        if (cid == 'dubai' &&
            (vCid.contains('ae') ||
                vCname.contains('dubai') ||
                vCname.contains('uae') ||
                vCname.contains('emirates'))) {
          return true;
        }
        if (cid == 'uk' &&
            (vCid.contains('gb') ||
                vCname.contains('uk') ||
                vCname.contains('united kingdom') ||
                vCname.contains('britain'))) {
          return true;
        }
        if (cid == 'usa' &&
            (vCid.contains('us') ||
                vCname.contains('united states') ||
                vCname.contains('america'))) {
          return true;
        }
        if (cid == 'schengen' &&
            (vCid.contains('eu') ||
                vCname.contains('schengen') ||
                vCname.contains('europe') ||
                vCname.contains('germany') ||
                vCname.contains('italy') ||
                vCname.contains('france'))) {
          return true;
        }
        return false;
      }).toList();
    }

    // 2. Category filter
    if (categoryId != null && categoryId.isNotEmpty && categoryId != 'all') {
      list = list
          .where((v) => v.categoryId.toLowerCase() == categoryId.toLowerCase())
          .toList();
    }

    // 3. Special filter (Fast-track, Top-rated, Free consultation)
    if (specialFilter == 'fast_track') {
      list = list.where((v) {
        final badge = (v.statusBadge ?? '').toLowerCase();
        final time = v.processingTime.toLowerCase();
        return badge.contains('fast') ||
            badge.contains('express') ||
            badge.contains('popular') ||
            time.contains('day') ||
            time.contains('1-2') ||
            time.contains('2-3') ||
            time.contains('express');
      }).toList();
    } else if (specialFilter == 'top_rated') {
      list = list.where((v) {
        final rate = (v.successRate ?? '').toLowerCase();
        final rating = v.rating;
        return rating >= 4.8 ||
            rate.contains('96') ||
            rate.contains('97') ||
            rate.contains('98') ||
            rate.contains('99');
      }).toList();
    } else if (specialFilter == 'free_consultation') {
      list = list.where((v) {
        final fee = v.fee.toLowerCase();
        final badge = (v.statusBadge ?? '').toLowerCase();
        final sub = v.subtitle.toLowerCase();
        final about = (v.aboutDescription ?? '').toLowerCase();
        return fee.contains('free') ||
            fee.contains('0') ||
            badge.contains('free') ||
            sub.contains('free') ||
            about.contains('free');
      }).toList();
    }

    // 4. Search query
    if (searchQuery.isNotEmpty) {
      list = list.where((v) {
        return v.title.toLowerCase().contains(searchQuery) ||
            v.countryName.toLowerCase().contains(searchQuery) ||
            v.categoryName.toLowerCase().contains(searchQuery) ||
            v.subtitle.toLowerCase().contains(searchQuery);
      }).toList();
    }

    return list;
  });
});
