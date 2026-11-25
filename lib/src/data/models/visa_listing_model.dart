class VisaListingModel {
  const VisaListingModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.countryId,
    required this.countryName,
    required this.categoryId,
    required this.categoryName,
    required this.processingTime,
    required this.fee,
    this.rating = 4.9,
    this.reviewsCount = 120,
    required this.imageUrl,
    this.isFeatured = false,
    this.isActive = true,
    this.aboutTitle,
    this.aboutDescription,
    this.validity,
    this.successRate,
    this.applicantsCount,
    this.serviceFeeLabel,
    this.serviceFeeValue,
    this.totalPayable,
    this.timelineSteps,
    this.eligibilityCriteria,
    this.mandatoryDocuments,
    this.feeBreakdown,
    this.externalUrl,
    this.statusBadge,
    this.applicationRequirements,
    this.salary,
    this.salaryOrFunding,
  });

  final String id;
  final String title;
  final String subtitle;
  final String countryId;
  final String countryName;
  final String categoryId;
  final String categoryName;
  final String processingTime;
  final String fee;
  final double rating;
  final int reviewsCount;
  final String imageUrl;
  final bool isFeatured;
  final bool isActive;
  final String? aboutTitle;
  final String? aboutDescription;
  final String? validity;
  final String? successRate;
  final String? applicantsCount;
  final String? serviceFeeLabel;
  final String? serviceFeeValue;
  final String? totalPayable;
  final dynamic timelineSteps;
  final dynamic eligibilityCriteria;
  final dynamic mandatoryDocuments;
  final dynamic feeBreakdown;
  final String? externalUrl;
  final String? statusBadge;
  final dynamic applicationRequirements;
  final String? salary;
  final String? salaryOrFunding;

  factory VisaListingModel.fromJson(Map<String, dynamic> json) {
    return VisaListingModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      countryId: json['country_id'] as String? ?? '',
      countryName: json['country_name'] as String? ?? '',
      categoryId: json['category_id'] as String? ?? '',
      categoryName: json['category_name'] as String? ?? '',
      processingTime: json['processing_time'] as String? ?? '',
      fee: json['fee'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 4.9,
      reviewsCount: json['reviews_count'] as int? ?? 120,
      imageUrl: json['image_url'] as String? ?? '',
      isFeatured: json['is_featured'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      aboutTitle: json['about_title'] as String?,
      aboutDescription: json['about_description'] as String?,
      validity: json['validity'] as String?,
      successRate: json['success_rate'] as String?,
      applicantsCount: json['applicants_count'] as String?,
      serviceFeeLabel: json['service_fee_label'] as String?,
      serviceFeeValue: json['service_fee_value'] as String?,
      totalPayable: json['total_payable'] as String?,
      timelineSteps: json['timeline_steps'],
      eligibilityCriteria: json['eligibility_criteria'],
      mandatoryDocuments: json['mandatory_documents'],
      feeBreakdown: json['fee_breakdown'],
      externalUrl: json['external_url'] as String?,
      statusBadge: json['status_badge'] as String?,
      applicationRequirements: json['application_requirements'],
      salary: json['salary'] as String?,
      salaryOrFunding: json['salary_or_funding'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'country_id': countryId,
      'country_name': countryName,
      'category_id': categoryId,
      'category_name': categoryName,
      'processing_time': processingTime,
      'fee': fee,
      'rating': rating,
      'reviews_count': reviewsCount,
      'image_url': imageUrl,
      'is_featured': isFeatured,
      'is_active': isActive,
      'about_title': aboutTitle,
      'about_description': aboutDescription,
      'validity': validity,
      'success_rate': successRate,
      'applicants_count': applicantsCount,
      'service_fee_label': serviceFeeLabel,
      'service_fee_value': serviceFeeValue,
      'total_payable': totalPayable,
      'timeline_steps': timelineSteps,
      'eligibility_criteria': eligibilityCriteria,
      'mandatory_documents': mandatoryDocuments,
      'fee_breakdown': feeBreakdown,
      'external_url': externalUrl,
      'status_badge': statusBadge,
      'application_requirements': applicationRequirements,
      'salary': salary,
      'salary_or_funding': salaryOrFunding,
    };
  }
}

