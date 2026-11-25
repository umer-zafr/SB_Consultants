import 'package:flutter/foundation.dart';

@immutable
class SponsoredJobModel {
  const SponsoredJobModel({
    required this.id,
    required this.jobTitle,
    required this.companyName,
    required this.location,
    required this.countryFlag,
    this.avatarInitials,
    this.avatarBgColor,
    this.salary,
    this.salaryPeriod,
    this.salaryRange,
    this.postedTime,
    this.employmentType,
    this.externalUrl,
    this.isBookmarked = false,
  });

  final String id;
  final String jobTitle;
  final String companyName;
  final String location;
  final String countryFlag;
  final String? avatarInitials;
  final int? avatarBgColor;
  final String? salary;
  final String? salaryPeriod;
  final String? salaryRange;
  final String? postedTime;
  final String? employmentType;
  final String? externalUrl;
  final bool isBookmarked;

  SponsoredJobModel copyWith({
    String? id,
    String? jobTitle,
    String? companyName,
    String? location,
    String? countryFlag,
    String? avatarInitials,
    int? avatarBgColor,
    String? salary,
    String? salaryPeriod,
    String? salaryRange,
    String? postedTime,
    String? employmentType,
    String? externalUrl,
    bool? isBookmarked,
  }) {
    return SponsoredJobModel(
      id: id ?? this.id,
      jobTitle: jobTitle ?? this.jobTitle,
      companyName: companyName ?? this.companyName,
      location: location ?? this.location,
      countryFlag: countryFlag ?? this.countryFlag,
      avatarInitials: avatarInitials ?? this.avatarInitials,
      avatarBgColor: avatarBgColor ?? this.avatarBgColor,
      salary: salary ?? this.salary,
      salaryPeriod: salaryPeriod ?? this.salaryPeriod,
      salaryRange: salaryRange ?? this.salaryRange,
      postedTime: postedTime ?? this.postedTime,
      employmentType: employmentType ?? this.employmentType,
      externalUrl: externalUrl ?? this.externalUrl,
      isBookmarked: isBookmarked ?? this.isBookmarked,
    );
  }

  factory SponsoredJobModel.fromJson(Map<String, dynamic> json) {
    return SponsoredJobModel(
      id: json['id'] as String? ?? '',
      jobTitle: json['title'] as String? ?? '',
      companyName: json['company_or_institution'] as String? ?? '',
      location: json['location'] as String? ?? '',
      countryFlag: json['country_flag'] as String? ?? '🌍',
      avatarInitials: json['avatar_initials'] as String?,
      avatarBgColor: (json['avatar_bg_color'] as num?)?.toInt(),
      salary: json['salary_or_funding'] as String?,
      salaryPeriod: json['salary_period'] as String?,
      postedTime: json['posted_time'] as String?,
      employmentType: json['employment_type'] as String?,
      externalUrl: json['external_url'] as String?,
      isBookmarked: false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': jobTitle,
      'company_or_institution': companyName,
      'location': location,
      'country_flag': countryFlag,
      'avatar_initials': avatarInitials,
      'avatar_bg_color': avatarBgColor,
      'salary_or_funding': salary,
      'salary_period': salaryPeriod,
      'posted_time': postedTime,
      'employment_type': employmentType,
      'external_url': externalUrl,
    };
  }
}

