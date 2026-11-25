import 'package:flutter/material.dart';

class TimelineStepItem {
  const TimelineStepItem({
    required this.title,
    required this.duration,
    required this.description,
    required this.icon,
  });

  final String title;
  final String duration;
  final String description;
  final IconData icon;
}

class DocumentItem {
  const DocumentItem({
    required this.title,
    required this.note,
    required this.icon,
  });

  final String title;
  final String note;
  final IconData icon;
}

class FeeItem {
  const FeeItem({
    required this.label,
    required this.amount,
    this.subNote,
    this.tag,
  });

  final String label;
  final String amount;
  final String? subNote;
  final String? tag;
}

class DetailItemModel {
  const DetailItemModel({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.categoryTag,
    required this.countryName,
    required this.countryFlag,
    required this.statusBadge,
    required this.heroImageUrl,
    required this.processingTime,
    required this.validity,
    required this.successRate,
    required this.applicantsCount,
    required this.aboutTitle,
    required this.aboutDescription,
    required this.timelineSteps,
    required this.eligibilityCriteria,
    required this.mandatoryDocuments,
    required this.feeBreakdown,
    required this.totalPayable,
    required this.serviceFeeLabel,
    required this.serviceFeeValue,
    this.externalUrl,
    this.applicationRequirements,
    this.salary,
  });

  final String id;
  final String type; // 'visa' or 'job'
  final String title;
  final String subtitle;
  final String categoryTag;
  final String countryName;
  final String countryFlag;
  final String statusBadge;
  final String heroImageUrl;
  final String processingTime;
  final String validity;
  final String successRate;
  final String applicantsCount;
  final String aboutTitle;
  final String aboutDescription;
  final List<TimelineStepItem> timelineSteps;
  final List<String> eligibilityCriteria;
  final List<DocumentItem> mandatoryDocuments;
  final List<FeeItem> feeBreakdown;
  final String totalPayable;
  final String serviceFeeLabel;
  final String serviceFeeValue;
  final String? externalUrl;
  final dynamic applicationRequirements;
  final String? salary;

  DetailItemModel copyWith({
    String? id,
    String? type,
    String? title,
    String? subtitle,
    String? categoryTag,
    String? countryName,
    String? countryFlag,
    String? statusBadge,
    String? heroImageUrl,
    String? processingTime,
    String? validity,
    String? successRate,
    String? applicantsCount,
    String? aboutTitle,
    String? aboutDescription,
    List<TimelineStepItem>? timelineSteps,
    List<String>? eligibilityCriteria,
    List<DocumentItem>? mandatoryDocuments,
    List<FeeItem>? feeBreakdown,
    String? totalPayable,
    String? serviceFeeLabel,
    String? serviceFeeValue,
    String? externalUrl,
    dynamic applicationRequirements,
    String? salary,
  }) {
    return DetailItemModel(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      categoryTag: categoryTag ?? this.categoryTag,
      countryName: countryName ?? this.countryName,
      countryFlag: countryFlag ?? this.countryFlag,
      statusBadge: statusBadge ?? this.statusBadge,
      heroImageUrl: heroImageUrl ?? this.heroImageUrl,
      processingTime: processingTime ?? this.processingTime,
      validity: validity ?? this.validity,
      successRate: successRate ?? this.successRate,
      applicantsCount: applicantsCount ?? this.applicantsCount,
      aboutTitle: aboutTitle ?? this.aboutTitle,
      aboutDescription: aboutDescription ?? this.aboutDescription,
      timelineSteps: timelineSteps ?? this.timelineSteps,
      eligibilityCriteria: eligibilityCriteria ?? this.eligibilityCriteria,
      mandatoryDocuments: mandatoryDocuments ?? this.mandatoryDocuments,
      feeBreakdown: feeBreakdown ?? this.feeBreakdown,
      totalPayable: totalPayable ?? this.totalPayable,
      serviceFeeLabel: serviceFeeLabel ?? this.serviceFeeLabel,
      serviceFeeValue: serviceFeeValue ?? this.serviceFeeValue,
      externalUrl: externalUrl ?? this.externalUrl,
      applicationRequirements:
          applicationRequirements ?? this.applicationRequirements,
      salary: salary ?? this.salary,
    );
  }
}
