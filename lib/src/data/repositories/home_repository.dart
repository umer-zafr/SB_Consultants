import 'package:flutter_sd_consultant/src/data/models/country_model.dart';
import 'package:flutter_sd_consultant/src/data/models/success_story_model.dart';
import 'package:flutter_sd_consultant/src/data/models/visa_category_model.dart';
import 'package:flutter_sd_consultant/src/data/models/visa_listing_model.dart';
import 'package:flutter_sd_consultant/src/utils/typedefs.dart';

abstract class HomeRepository {
  FutureEither<List<VisaCategoryModel>> getVisaCategories();
  FutureEither<List<Map<String, String>>> getPromotionalBanners();
  FutureEither<List<SuccessStoryModel>> getSuccessStories();
  FutureEither<List<CountryModel>> getCountries();
  FutureEither<List<VisaListingModel>> getVisaListings({
    required String countryId,
    String? categoryId,
    String? searchQuery,
  });
}
