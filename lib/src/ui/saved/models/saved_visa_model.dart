import 'package:flutter/material.dart';

/// Data model representing a bookmarked / saved visa in the application.
class SavedVisaItem {
  SavedVisaItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.countryName,
    this.countryCode = 'INT',
    required this.categoryTag,
    required this.duration,
    this.validity = '1-2 Years',
    required this.approvalRate,
    required this.fee,
    this.badgeText,
    this.badgeBgColor,
    this.badgeTextColor,
    this.avatarBgColor,
    this.avatarTextColor,
    this.flag,
    DateTime? savedAt,
  }) : savedAt = savedAt ?? DateTime.now();

  final String id;
  final String title;
  final String subtitle;
  final String countryName;
  final String countryCode;
  final String categoryTag;
  final String duration;
  final String validity;
  final String approvalRate;
  final String fee;
  final String? badgeText;
  final int? badgeBgColor;
  final int? badgeTextColor;
  final int? avatarBgColor;
  final int? avatarTextColor;
  final String? flag;
  final DateTime savedAt;

  Color? get resolvedBadgeBgColor =>
      badgeBgColor != null ? Color(badgeBgColor!) : null;
  Color? get resolvedBadgeTextColor =>
      badgeTextColor != null ? Color(badgeTextColor!) : null;
  Color? get resolvedAvatarBgColor =>
      avatarBgColor != null ? Color(avatarBgColor!) : null;
  Color? get resolvedAvatarTextColor =>
      avatarTextColor != null ? Color(avatarTextColor!) : null;

  SavedVisaItem copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? countryName,
    String? countryCode,
    String? categoryTag,
    String? duration,
    String? validity,
    String? approvalRate,
    String? fee,
    String? badgeText,
    int? badgeBgColor,
    int? badgeTextColor,
    int? avatarBgColor,
    int? avatarTextColor,
    String? flag,
    DateTime? savedAt,
  }) {
    return SavedVisaItem(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      countryName: countryName ?? this.countryName,
      countryCode: countryCode ?? this.countryCode,
      categoryTag: categoryTag ?? this.categoryTag,
      duration: duration ?? this.duration,
      validity: validity ?? this.validity,
      approvalRate: approvalRate ?? this.approvalRate,
      fee: fee ?? this.fee,
      badgeText: badgeText ?? this.badgeText,
      badgeBgColor: badgeBgColor ?? this.badgeBgColor,
      badgeTextColor: badgeTextColor ?? this.badgeTextColor,
      avatarBgColor: avatarBgColor ?? this.avatarBgColor,
      avatarTextColor: avatarTextColor ?? this.avatarTextColor,
      flag: flag ?? this.flag,
      savedAt: savedAt ?? this.savedAt,
    );
  }
}
