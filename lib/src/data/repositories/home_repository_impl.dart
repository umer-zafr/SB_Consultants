import 'package:flutter/material.dart';
import 'package:flutter_sd_consultant/src/data/models/country_model.dart';
import 'package:flutter_sd_consultant/src/data/models/success_story_model.dart';
import 'package:flutter_sd_consultant/src/data/models/visa_category_model.dart';
import 'package:flutter_sd_consultant/src/data/models/visa_listing_model.dart';
import 'package:flutter_sd_consultant/src/data/repositories/home_repository.dart';
import 'package:flutter_sd_consultant/src/services/supabase_database_service.dart';
import 'package:flutter_sd_consultant/src/utils/failure.dart';
import 'package:flutter_sd_consultant/src/utils/typedefs.dart';
import 'package:fpdart/fpdart.dart';

class HomeRepositoryImpl implements HomeRepository {
  final _supabaseDb = SupabaseDatabaseService.instance;

  @override
  FutureEither<List<VisaCategoryModel>> getVisaCategories() async {
    try {
      final result = await _supabaseDb.getVisaCategories();
      final either = result.fold<Either<Failure, List<VisaCategoryModel>>>(
        (_) => const Right(_defaultVisaCategories),
        (data) {
          if (data.isEmpty) return const Right(_defaultVisaCategories);
          return Right(data.map((json) => VisaCategoryModel.fromJson(json)).toList());
        },
      );
      return either;
    } catch (_) {
      return const Right(_defaultVisaCategories);
    }
  }

  @override
  FutureEither<List<SuccessStoryModel>> getSuccessStories() async {
    try {
      final result = await _supabaseDb.getSuccessStories();
      final either = result.fold<Either<Failure, List<SuccessStoryModel>>>(
        (_) => const Right([]),
        (data) {
          return Right(data.map((json) => SuccessStoryModel.fromJson(json)).toList());
        },
      );
      return either;
    } catch (_) {
      return const Right([]);
    }
  }

  @override
  FutureEither<List<Map<String, String>>> getPromotionalBanners() async {
    try {
      final result = await _supabaseDb.getPromotionalBanners();
      final either = result.fold<Either<Failure, List<Map<String, String>>>>(
        (_) => const Right(_defaultBanners),
        (data) {
          if (data.isEmpty) return const Right(_defaultBanners);
          final sorted = List<Map<String, dynamic>>.from(data);
          sorted.sort((a, b) {
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
          return Right(sorted.map((json) {
            return {
              'id': json['id'] as String? ?? '',
              'title': json['title'] as String? ?? '',
              'subtitle': json['subtitle'] as String? ?? '',
              'badge': json['badge'] as String? ?? '',
              'actionText': json['action_text'] as String? ?? 'Apply Now',
              'actionUrl': json['action_url'] as String? ?? '',
              'imageUrl': json['image_url'] as String? ?? '',
              'gradientStart': json['gradient_start'] as String? ?? '0xFF1B3A5C',
              'gradientEnd': json['gradient_end'] as String? ?? '0xFF2A5A8C',
              'displayOrder': json['display_order']?.toString() ?? '1',
            };
          }).toList());
        },
      );
      return either;
    } catch (_) {
      return const Right(_defaultBanners);
    }
  }

  @override
  FutureEither<List<CountryModel>> getCountries() async {
    try {
      final result = await _supabaseDb.getCountries();
      final either = result.fold<Either<Failure, List<CountryModel>>>(
        (_) => const Right(_defaultCountries),
        (data) {
          if (data.isEmpty) return const Right(_defaultCountries);
          return Right(data.map((json) => CountryModel.fromJson(json)).toList());
        },
      );
      return either;
    } catch (_) {
      return const Right(_defaultCountries);
    }
  }

  @override
  FutureEither<List<VisaListingModel>> getVisaListings({
    required String countryId,
    String? categoryId,
    String? searchQuery,
  }) async {
    try {
      final result = await _supabaseDb.getVisaListings(
        countryId: countryId,
        categoryId: categoryId,
        searchQuery: searchQuery,
      );

      return result.map((data) {
        return data.map((json) => VisaListingModel.fromJson(json)).toList();
      });
    } catch (e) {
      return Left(ServerFailure('Failed to load visa listings: $e'));
    }
  }

  // ===========================================================================
  // OFFLINE FALLBACK / BASELINE DEFAULTS
  // ===========================================================================

  static const List<VisaCategoryModel> _defaultVisaCategories = [
    VisaCategoryModel(
      id: 'scholarships',
      label: 'Scholarships',
      icon: Icons.auto_stories_rounded,
      color: Color(0xFF00897B),
      imageAsset: 'assets/images/scholarships_transparent.png',
    ),
    VisaCategoryModel(
      id: 'sponsored_jobs',
      label: 'Sponsored Jobs',
      icon: Icons.handshake_rounded,
      color: Color(0xFFED6C02),
      imageAsset: 'assets/images/sponsored_jobs_transparent.png',
    ),
    VisaCategoryModel(
      id: 'visit',
      label: 'Visit Visa',
      icon: Icons.flight_takeoff_rounded,
      color: Color(0xFF0288D1),
      imageAsset: 'assets/images/visit_visa_transparent.png',
    ),
    VisaCategoryModel(
      id: 'business',
      label: 'Business Visa',
      icon: Icons.business_center_rounded,
      color: Color(0xFF6A1B9A),
      imageAsset: 'assets/images/business_visa_transparent.png',
    ),
    VisaCategoryModel(
      id: 'golden',
      label: 'Golden Visa',
      icon: Icons.workspace_premium_rounded,
      color: Color(0xFFC98A1D),
      imageAsset: 'assets/images/golden_visa_transparent.png',
    ),
    VisaCategoryModel(
      id: 'study',
      label: 'Study Visa',
      icon: Icons.school_rounded,
      color: Color(0xFF1B3A5C),
      imageAsset: 'assets/images/study_visa_transparent.png',
    ),
    VisaCategoryModel(
      id: 'work',
      label: 'Work Visa',
      icon: Icons.work_rounded,
      color: Color(0xFF2E7D32),
      imageAsset: 'assets/images/work_visa_transparent.png',
    ),
  ];

  static const List<Map<String, String>> _defaultBanners = [
    {
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
    },
  ];

  static const List<CountryModel> _defaultCountries = [
    CountryModel(id: kAllCountriesId, name: 'All', flagEmoji: '🌍'),
    CountryModel(id: 'dubai', name: 'Dubai (UAE)', flagEmoji: '🇦🇪'),
    CountryModel(id: 'australia', name: 'Australia', flagEmoji: '🇦🇺'),
    CountryModel(id: 'canada', name: 'Canada', flagEmoji: '🇨🇦'),
    CountryModel(id: 'uk', name: 'United Kingdom', flagEmoji: '🇬🇧'),
    CountryModel(id: 'usa', name: 'United States', flagEmoji: '🇺🇸'),
    CountryModel(id: 'schengen', name: 'Schengen Europe', flagEmoji: '🇪🇺'),
  ];
}
